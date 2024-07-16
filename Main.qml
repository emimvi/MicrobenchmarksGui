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
    property QtObject memLat // Test results
    property QtObject memLatRunner // Test runner

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
                                id : privateArray
                                checked: true
                                text: "Private array per thread"
                            }
                            RadioButton {
                                enabled : dataReadButton.checked || instructionFetchButton.checked
                                text: "One array shared by all threads"
                                onEnabledChanged: enabled => {
                                                      if (!enabled) privateArray.checked = true
                                                  }
                            }
                        }
                    }
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Access Mode"
                        ColumnLayout {
                            id : accessModelOptions
                            RadioButton {
                                id: dataReadButton
                                checked: true
                                text: "Data Read"
                            }
                            RadioButton {
                                id: dataStringOpsButton
                                text: "Data Microcoded String Ops"
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
                                id : instructionFetchButton
                                text: "Instruction Fetch"
                            }
                        }
                    }
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Test Method"
                        visible : !(dataStringOpsButton.checked || instructionFetchButton.checked)
                        ColumnLayout {
                            id : vectorOpOptions
                            anchors.fill : parent
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
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Test Method"
                        visible : dataStringOpsButton.checked
                        ColumnLayout {
                            id : dataStringOptions
                            RadioButton {
                                checked: true
                                text: "4B NOPs (0F 1F 40 00)"
                            }
                            RadioButton {
                                text: "8B NOPs (0F 1F 84 00 00 00 00 00)"
                            }
                            RadioButton {
                                text: "4B NOPs (66 66 66 90)"
                            }
                            RadioButton {
                                text: "Taken Branch Per 16B"
                            }
                        }
                    }
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Test Method"
                        visible : instructionFetchButton.checked
                        ColumnLayout {
                            id : instructionFetchOptions
                            RadioButton {
                                checked: true
                                text: "REP MOVSB (Copy)"
                            }
                            RadioButton {
                                text: "REP STOSB (Write)"
                            }
                            RadioButton {
                                text: "REP MOVSD (Copy)"
                            }
                            RadioButton {
                                text: "REP STOSD (Write)"
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
                    enabled : !memLatRunner.running
                    text: "Run"
                    onClicked: memLatRunner.run(!defaultPagesButton.checked, Number(iterationsText.text))
                }
                Button {
                    enabled : memLatRunner.running
                    text: "Cancel Run"
                    onClicked: memLatRunner.cancelRun()
                }
            }
        }

        StackLayout {
            currentIndex: tabBar.currentIndex
            ResultPane {
            }
            ResultPane {
                resultsModel : memLat.resultsModel()
                tableModel : memLat.latestResultModel()
            }
        }
    }
    }
}
