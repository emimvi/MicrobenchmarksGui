#include <QApplication>
#include <QLineSeries>
#include <QQmlApplicationEngine>
#include <QStandardItemModel>
#include <QXYSeries>

#include <QHXYModelMapper>
#include <QThread>

#include "MemoryLatency.h"
#include <vector>

#include <QIdentityProxyModel>

enum CustomRoles {
    TableModel = Qt::UserRole + 1,
    ExportCSV,
    ExportJS
};

class ResultItem : public QStandardItem {
public:
    ResultItem(QString text) : QStandardItem(text) {}
    ~ResultItem() {
        if (auto model = data().value<QStandardItemModel*>()) {
            model->deleteLater();
        }
    }
};

struct ResultFormat {
    QString csvHeader;
    QStringList tableHeaderLabels;
    QString keyFormat;
    QString valueFormat;
};

ResultFormat memoryLatencyFormat {
    "Data Size (KB), Latency (ns)\n",
    {"Data Size", "Latency"},
    "%1 KB",
    "%1 ns"
};


class TestRunner : public QThread {
    Q_OBJECT
public:
    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)

    TestRunner() {
        connect(this, &QThread::started, this, &TestRunner::runningChanged);
        connect(this, &QThread::finished, this, &TestRunner::runningChanged);
    };

    Q_INVOKABLE void cancelRun() {
        requestInterruption();
    }

signals:
    void runningChanged();
    void testStarted(const QString& title);
    void resultReady(int size, float value);

};

class LatencyRunner : public TestRunner {
    Q_OBJECT

    void run() override {
        const static QString pageNames[]{ "Default Pages", "Large Pages" };
        emit testStarted("ASM, " + pageNames[hugePages]);

        static std::vector<int> default_test_sizes { 2, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 600, 768, 1024, 1536, 2048,
            3072, 4096, 5120, 6144, 8192, 10240, 12288, 16384, 24567, 32768, 65536, 98304, 131072, 262144, 393216, 524288, 1048576 }; //2097152 };
        uint32_t* prealloc_arr = nullptr;
        if (hugePages) {
            prealloc_arr = preallocate_arr(default_test_sizes.back());
            if (prealloc_arr == (void *)-1) { // on failure, mmap will return MAP_FAILED, or (void *)-1
                prealloc_arr = nullptr;
                return; //TODO error handling;
            }
        }
        for (const auto size : default_test_sizes){
            if (isInterruptionRequested()) {
                break;
            }
            float latency = asmTest ? RunAsmLatencyTest(size, numIterations) : RunTest(size, numIterations, prealloc_arr);
            emit resultReady(size, latency);
        }
        if (prealloc_arr) {
            free_preallocate_arr(prealloc_arr, default_test_sizes.back());
        }
    }
public:
    Q_INVOKABLE void run(bool hugePages, bool asmTest, size_t numIterations) {
        if (isRunning()) {
            throw std::logic_error("Another run already in progress");
        }
        this->hugePages = hugePages;
        this->numIterations = numIterations;
        this->asmTest = asmTest;
        start();
    }

    bool hugePages = false;
    bool asmTest = false;
    unsigned int numIterations = 100000000;
};

class ResultsModel : public QObject {
    Q_OBJECT

    QStandardItemModel* results;
    QStandardItemModel* model = nullptr;
    QPersistentModelIndex runningIndex;
    QIdentityProxyModel* latestModel;
    ResultFormat format;

public:

    void addResult(int size, float value) {
        if (!runningIndex.isValid()) {
            return;
        }
        auto model = results->data(runningIndex, CustomRoles::TableModel).value<QStandardItemModel*>();
        auto a = new QStandardItem{QString::number(size)};
        a->setData(format.keyFormat.arg(size));
        auto b = new QStandardItem{QString::number(value)};
        b->setData(format.valueFormat.arg(value));
        model->appendRow({a, b});
    }

    void generateCSV() {
        if (!runningIndex.isValid()) {
            return;
        }
        QString res {this->format.csvHeader};
        for (int i = 0; i < model->rowCount(); i++){
            QString size = model->data(model->index(i, 0)).toString();
            QString value = model->data(model->index(i, 1)).toString();
            res += size + ',' + value + '\n';
        }
        this->results->setData(runningIndex, res, CustomRoles::ExportCSV);
    }

    ResultsModel(ResultFormat format) : format(format), results(new QStandardItemModel(this)), latestModel(new QIdentityProxyModel(this)){ }

    Q_INVOKABLE QAbstractItemModel* resultsModel() {
        return results;
    }

    Q_INVOKABLE QAbstractItemModel* latestResultModel() {
        return latestModel;
    }

    void prepareResult(const QString& title) {
        // Prepare the result
        model = new QStandardItemModel(this);
        auto roleNames = model->roleNames();
        roleNames.insert(Qt::UserRole + 1, "formattedRole");
        model->setItemRoleNames(roleNames);
        model->setHorizontalHeaderLabels(format.tableHeaderLabels);
        latestModel->setSourceModel(model);

        // GUI crashes if the proxy model is not manually reset
        auto currentModel = model;
        connect(model, &QObject::destroyed, latestModel, [this, currentModel]() {
            if (model == currentModel) {
                latestModel->setSourceModel(nullptr);
            }
        });

        // Append to existing results
        auto resultItem = new ResultItem{title};
        resultItem->setData(QVariant::fromValue(model));
        results->appendRow(resultItem);
        runningIndex = results->indexFromItem(resultItem);
    }
};

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    qputenv("QSG_RHI_BACKEND", "opengl"); // Window drag stutters with the default D3D backend on Windows
    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:qt/qml/untitled2/App.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    LatencyRunner runner;
    ResultsModel memLat(memoryLatencyFormat);
    QObject::connect(&runner, &TestRunner::testStarted, &memLat, &ResultsModel::prepareResult);
    QObject::connect(&runner, &TestRunner::resultReady, &memLat, &ResultsModel::addResult);
    QObject::connect(&runner, &QThread::finished, &memLat, &ResultsModel::generateCSV);

    engine.setInitialProperties(
        {
         {"hasAvx", false},
         {"hasAvx512", false},
         {"memLatRunner", QVariant::fromValue(&runner)},
         {"memLat", QVariant::fromValue(&memLat)},
        } );
    engine.load(url);

    return app.exec();
}

#include "main.moc"
