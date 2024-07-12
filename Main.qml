import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import QtCharts
import Qt.labs.qmlmodels

Pane {
    anchors.fill: parent
    id: root
    property alias hasAvx : avxButton.enabled
    property alias hasAvx512 : avx512Button.enabled
    property QtObject tableModel
    property QtObject resultsModel // ListModel<TableModel>
    property QtObject memLat // Test runner

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        ColumnLayout {
            Layout.fillWidth: false
            GroupBox {
                Layout.fillWidth: true
                title: "Test type"
                ColumnLayout {
                    RadioButton {
                        checked : true
                        id : memBandwidthButton
                        text: "Memory Bandwith"
                    }
                    RadioButton {
                        id: memLatencyButton
                        text: "Memory Latency"
                    }
                }
            }
            StackLayout {
                currentIndex: memLatencyButton.checked ? 1 : 0
                ColumnLayout {
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Threads: " + threadSlider.value
                        Slider {
                            id: threadSlider
                            anchors.fill: parent
                            from: 1
                            to: 4
                            snapMode: Slider.SnapAlways
                            stepSize: 1
                        }
                    }

                    GroupBox {
                        Layout.fillWidth: true
                        title: "Threading Mode"
                        ColumnLayout {
                            RadioButton {
                                checked: true
                                text: "Private array per thread"
                            }
                            RadioButton {
                                text: "One array shared by all threads"
                            }
                        }
                    }
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Access Mode"
                        ColumnLayout {
                            RadioButton {
                                checked: true
                                text: "Data Read"
                            }
                            RadioButton {
                                text: "Data Non-Temporal Read"
                            }
                            RadioButton {
                                text: "Data Write"
                            }
                            RadioButton {
                                text: "Data Non-Temporal Write"
                            }
                            RadioButton {
                                text: "Data Read-Modify-Write (Add)"
                            }
                            RadioButton {
                                text: "Instruction Fetch"
                            }
                        }
                    }
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Test Method"
                        ColumnLayout {
                            RadioButton {
                                checked: true
                                text: "SSE (128-bit)"
                            }
                            RadioButton {
                                id: avxButton
                                text: "AVX (256-bit)"
                            }
                            RadioButton {
                                id: avx512Button
                                text: "AVX-512 (512-bit)"
                            }
                            RadioButton {
                                text: "MMX (64-bit)"
                            }
                        }
                    }

                    RowLayout {
                        Text {
                            text: "Base Data to Transfer:"
                        }
                        TextField {
                            text: "32"
                        }
                        Text {
                            text: "GB"
                        }
                    }
                }
                ColumnLayout {
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Access Mode"
                        ColumnLayout {
                            RadioButton {
                                checked: true
                                text: "Simple Addressing (ASM)"
                            }
                            RadioButton {
                                text: "Indexed Adressing (C)"
                            }
                        }
                    }
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Paging Mode"
                        ColumnLayout {
                            RadioButton {
                                id : defaultPagesButton
                                checked: true
                                text: "Default (4 KB Pages)"
                            }
                            RadioButton {
                                text: "Large Pages (2 MB Pages)"
                            }
                        }
                    }
                    RowLayout {
                        Text {
                            text: "Base Iterations:"
                        }
                        TextField {
                            id: iterationsText
                            text: "200000000"
                        }
                        Text {
                            text: "times"
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
            }
            RowLayout {
                Button {
                    enabled : !memLat.running
                    text: "Run"
                    onClicked: memLat.run(!defaultPagesButton.checked, Number(iterationsText.text))
                }
                Button {
                    enabled : memLat.running
                    text: "Cancel Run"
                    onClicked: memLat.cancelRun()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: false
            RowLayout {
                Text {
                    text: qsTr("Run Progress:")
                }
                Text {
                    text: memLat.running ? 'Running...' : qsTr("Run Finished")
                }
            }
            HorizontalHeaderView {
                id: horizontalHeader
                Layout.minimumHeight: 20
                syncView: myTable
            }
            TableView {
                id: myTable
                topMargin: horizontalHeader.implicitHeight / 2
                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true

                model: root.tableModel
                delegate: Rectangle {
                    implicitWidth: 80
                    implicitHeight: 20

                    Text {
                        x : 1
                        y : 1
                        text: model.formattedRole
                    }
                }
            }
        }
        ColumnLayout {
            RowLayout {
                Layout.fillHeight: false
                GroupBox {
                    title: "Chart Controls"
                    RowLayout {
                        ColumnLayout {
                            RadioButton {
                                checked: true
                                text: "Random Next Color"
                            }
                            RadioButton {
                                id: specifyColorButton
                                text: "Specify Next Color"
                            }
                            RadioButton {
                                text: "Default Next Color"
                            }
                            Button {
                                text: "Clear Results"
                                onClicked: {
                                    var m = root.resultsModel
                                    m.removeRows(0, m.rowCount())
                                }
                            }
                        }
                        ColumnLayout {
                            enabled: specifyColorButton.checked
                            RowLayout {
                                Label { text: "Red" }
                                Item { Layout.fillWidth:  true }
                                TextField { text: "50"
                                    Layout.preferredWidth: 40
                                }
                            }
                            RowLayout {
                                Label { text: "Green" }
                                Item { Layout.fillWidth:  true }
                                TextField { text: "50"
                                    Layout.preferredWidth: 40}
                            }
                            RowLayout {
                                Label { text: "Blue" }
                                Item { Layout.fillWidth:  true }
                                TextField { text: "50"
                                    Layout.preferredWidth: 40}
                            }
                            Rectangle {
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
                GroupBox {
                    title: "Export"
                    Layout.fillHeight: true
                    RowLayout {
                        anchors.fill: parent
                        ColumnLayout {
                            RadioButton {
                                id : csvRadioButton
                                checked : true
                                text: "CSV Format"
                            }
                            RadioButton {
                                text: "CnC JS Format"
                            }
                            Rectangle {
                                Layout.fillHeight: true
                            }
                            Button {
                                text: "Export"
                            }
                        }
                        ListView {
                            id: list
                            property string csv;
                            property string js;
                            Layout.preferredWidth: 140
                            Layout.fillHeight: true
                            focus: true
                            highlight: Rectangle { color: "lightsteelblue" }
                            currentIndex: -1
                            model: root.resultsModel
                            delegate: Item {
                                width: ListView.view.width
                                height: 20
                                Text {
                                    x: 3
                                    y: 1
                                    text : display
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        list.currentIndex = index
                                        // TODO: Alternative solution that stays in sync.
                                        list.csv = root.resultsModel.data(root.resultsModel.index(index, 0), 0x102)
                                        list.js = root.resultsModel.data(root.resultsModel.index(index, 0), 0x103)
                                    }
                                }
                            }
                        }
                    }
                }
                ScrollView {
                    Layout.preferredHeight: 100
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    TextArea {
                        anchors.fill: parent
                        readOnly: true
                        text: (csvRadioButton.checked ? list.csv : list.js)
                    }
                }
            }
            ChartView {
                id : chartView
                title: "Result Plot"
                antialiasing: true
                Layout.fillHeight: true
                Layout.fillWidth: true

                axes: [
                    LogValueAxis {
                        id: axisX
                        labelFormat: '%g'
                        base: 8
                        min: 1
                        max: 1048576
                        titleText: 'Data (KB)'
                    },
                    LogValueAxis {
                        id: axisY
                        labelFormat: '%g'
                        base: 2
                        min: 0.5
                        max: 256
                    }
                ]

                Connections {
                    target: root.resultsModel
                    function onDataChanged(topLeft, buttomRight) {
                        let row = topLeft.row
                        let data = root.resultsModel.data(topLeft)
                        chartView.series(topLeft.row).name = data
                    }
                }

                Instantiator {

                    model: root.resultsModel

                    onObjectAdded: {
                        var resName = root.resultsModel.data(root.resultsModel.index(index, 0))
                        var series = chartView.createSeries(ChartView.SeriesTypeLine, resName, axisX, axisY)
                        var model = root.resultsModel.getModel(index)
                        object.model = model
                        object.series = series

                        series.pointAdded.connect(i => {
                                          axisY.max = Math.max(axisY.max, series.at(i).y)
                                      })

                        //var minX = axisX.min
                        //var maxX = axisX.max
                        //var minY = axisY.min
                        //var maxY = axisY.max
                        //for (var i = 0; i < model.rowCount(); i++) {
                        //    var x = model.data(model.index(i, 0))
                        //    var y = model.data(model.index(i, 1))
                        //    minX = Math.min(x, minX)
                        //    minY = Math.min(y, minY)
                        //    maxX = Math.max(x, maxX)
                        //    maxY = Math.max(y, maxY)
                        //}
                        //axisX.min = minX
                        //axisX.max = maxX
                        //axisY.min = minY
                        //axisY.max = maxY
                    }

                    onObjectRemoved: {
                        chartView.removeSeries(chartView.series(index))
                    }

                    VXYModelMapper {
                        xColumn: 0
                        yColumn: 1
                    }
                }
            }
        }
    }
}
