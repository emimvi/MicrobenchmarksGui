import QtQuick
import QtQuick.Controls 2.15

ApplicationWindow {
    id : appWindow
    title: 'Microbenchmark GUI test'
    visible: true

    minimumWidth: main.implicitWidth
    minimumHeight: main.implicitHeight

    property alias hasAvx : main.hasAvx
    property alias hasAvx512 : main.hasAvx512
    property alias tableModel : main.tableModel
    property alias resultsModel : main.resultsModel
    property alias memLat : main.memLat
    Main {
        id: main
    }
}
