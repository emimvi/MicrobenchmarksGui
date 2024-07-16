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
    property alias memLat : main.memLat
    property alias memLatRunner : main.memLatRunner
    Main {
        id: main
    }
}
