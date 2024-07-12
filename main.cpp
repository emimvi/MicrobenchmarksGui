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

class Results : public QStandardItemModel {
    Q_OBJECT
    std::vector<QStandardItemModel*> models;
    QIdentityProxyModel* latestModel;

public:
    Results() : QStandardItemModel(), latestModel(new QIdentityProxyModel(this)) {
        auto roleNames = this->roleNames();
        roleNames.insert(CustomRoles::TableModel, "itemModel");
        roleNames.insert(CustomRoles::ExportCSV, "exportCSV");
        roleNames.insert(CustomRoles::ExportJS, "exportJS");
        setItemRoleNames(roleNames);
    }

    int prepareResultModel() {
        auto model = new QStandardItemModel{0, 2, this};
        latestModel->setSourceModel(model);
        models.push_back(model);

        auto i = new QStandardItem{"Bla Bla"};
        appendRow(i);

        return models.size() - 1;
    }

    QAbstractItemModel* latestResultModel() {
        return latestModel;
    }

    Q_INVOKABLE QAbstractItemModel* getModel(int i) {
        return models[i];
    }
};


class LatencyRunner : public QThread {
    Q_OBJECT

    uint32_t* prealloc_arr = nullptr;

    void run() override {
        static std::vector<int> default_test_sizes { 2, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 600, 768, 1024, 1536, 2048,
            3072, 4096, 5120, 6144, 8192, 10240, 12288, 16384, 24567, 32768, 65536, 98304, 131072, 262144, 393216, 524288, 1048576 }; //2097152 };
        if (hugePages) {
            prealloc_arr = preallocate_arr(default_test_sizes.back());
            if (prealloc_arr == (void *)-1) { // on failure, mmap will return MAP_FAILED, or (void *)-1
                fprintf(stderr, "Failed to mmap huge pages, errno %d = %s\nWill try to use madvise\n", errno, strerror(errno));
                prealloc_arr = nullptr;
                return; //TODO error handling;
            }
        }
        for (int i = 0; i < default_test_sizes.size(); i++){
            if (isInterruptionRequested()) {
                if (prealloc_arr) {
                    free_preallocate_arr(prealloc_arr, default_test_sizes.back());
                }
                break;
            }
            float latency = RunTest(default_test_sizes[i], numIterations, prealloc_arr);
            emit resultReady(i, default_test_sizes[i], latency);
        }
    }
public:
    bool hugePages = false;
    unsigned int numIterations = 100000000;
signals:
    void resultReady(int idx, int size, float latency);
};

class MemoryLatency : public QObject {
    Q_OBJECT

    Results& results;
    QStandardItemModel* model;
    int modelIdx;
    LatencyRunner runner;

signals:
    void runningChanged();
public:

    bool isRunning() {
        return runner.isRunning();
    }

    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)

    void addResult(int idx, int size, float latency) {
            auto a = new QStandardItem{QString::number(size)};
            a->setData(QString("%1 KB").arg(size));
            auto b = new QStandardItem{QString::number(latency)};
            b->setData(QString("%1 ns").arg(latency));
            model->setItem(idx, 0, a);
            model->setItem(idx, 1, b);
    }

    MemoryLatency(Results& results): results(results) {
        connect(&runner, &QThread::started, this, &MemoryLatency::runningChanged);
        connect(&runner, &QThread::finished, this, &MemoryLatency::runningChanged);

        connect(&runner, &LatencyRunner::resultReady, this, &MemoryLatency::addResult);
        connect(&runner, &QThread::finished, this, [this](){
            QString res {"Data Size (KB),Latency (ns)\n"};
            for (int i = 0; i < model->rowCount(); i++){
                QString size = model->data(model->index(i, 0)).toString();
                QString latency = model->data(model->index(i, 1)).toString();
                res += size + ',' + latency + '\n';
            }
            this->results.setData(this->results.index(modelIdx, 0), res, CustomRoles::ExportCSV);
        });
    }

    Q_INVOKABLE void cancelRun() {
        runner.requestInterruption();
    }

    Q_INVOKABLE void run(bool hugePages, int iterations) {
        if (runner.isRunning()) {
            // TODO: Error handling
            return;
        }
        const static QString pageNames[] { "Default Pages", "Large Pages"};
        modelIdx = results.prepareResultModel();
        results.setData(results.index(modelIdx, 0), "ASM, " + pageNames[hugePages]);
        model = (QStandardItemModel*) results.getModel(modelIdx);
        auto roleNames = model->roleNames();
        roleNames.insert(Qt::UserRole + 1, "formattedRole");
        model->setItemRoleNames(roleNames);
        model->setHorizontalHeaderLabels({"Data Size", "Latency"});
        model->setRowCount(0);
        runner.hugePages = hugePages;
        runner.numIterations = iterations;
        runner.start();
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

    Results results;
    MemoryLatency memLat{results};

    engine.setInitialProperties(
        {
         {"hasAvx", false},
         {"hasAvx512", false},
         {"resultsModel", QVariant::fromValue(&results)},
         {"tableModel", QVariant::fromValue(results.latestResultModel())},
         {"memLat", QVariant::fromValue(&memLat)},
        } );
    engine.load(url);

    return app.exec();
}

#include "main.moc"
