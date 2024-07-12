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

    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            Layout.fillHeight: false
            TabBar {
                Layout.fillWidth: true
                id : tabBar
                TabButton {
                    width: implicitWidth
                    text: 'Memory Bandwidth'
                }
                TabButton {
                    width: implicitWidth
                    text: 'Memory Latency'
                }
            }
        }

    RowLayout {
        id: mainLayout
        ColumnLayout {
            Layout.fillWidth: false
            StackLayout {
                currentIndex: tabBar.currentIndex
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

        StackLayout {
            currentIndex: tabBar.currentIndex
            ResultPane {
            }
            ResultPane {
                resultsModel : root.resultsModel
                tableModel : root.tableModel
            }
        }
    }
    }
}
