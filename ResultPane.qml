
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

RowLayout {
    property QtObject resultsModel;
    property QtObject tableModel;

    ColumnLayout {
        Layout.fillWidth: false
        RowLayout {
            Text {
                text: qsTr("Run Progress:")
            }
            Text {
                //TODO : Don't depend on memLatRunner
                text: memLatRunner.running ? 'Running...' : qsTr("Run Finished")
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

            model: tableModel
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
                                var m = resultsModel
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
                        model: resultsModel
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
                                    list.csv = resultsModel.data(resultsModel.index(index, 0), 0x102)
                                    list.js = resultsModel.data(resultsModel.index(index, 0), 0x103)
                                }
                            }
                        }
                    }
                }
            }
            ScrollView {
                Layout.preferredHeight: 100
                Layout.preferredWidth: 200
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
                target: resultsModel
                function onDataChanged(topLeft, buttomRight) {
                    let row = topLeft.row
                    let data = resultsModel.data(topLeft)
                    chartView.series(topLeft.row).name = data
                }
            }

            Instantiator {

                model: resultsModel

                onObjectAdded: {
                    var resName = resultsModel.data(resultsModel.index(index, 0))
                    var series = chartView.createSeries(ChartView.SeriesTypeLine, resName, axisX, axisY)
                    var model = resultsModel.data(resultsModel.index(index, 0), 0x101)
                    object.model = model
                    object.series = series

                    series.pointAdded.connect(i => {
                                      axisY.max = Math.max(axisY.max, series.at(i).y)
                                  })
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
