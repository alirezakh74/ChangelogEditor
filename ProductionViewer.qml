import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: productionViewerRoot
    color: windowRoot.themeBgDeep

    function synchronizeView() {
        productionModelVisualizer.model = [];
        productionModelVisualizer.model = BackendEngine.fetchSerializedEntries();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 16

        Text {
            text: "🔍 Application Changelog Production Render Stack"
            color: windowRoot.themeTextMain
            font.bold: true
            font.pixelSize: 18
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: productionModelVisualizer
                spacing: 14
                model: []

                delegate: Rectangle {
                    width: productionModelVisualizer.width - 20
                    implicitHeight: layoutElementContainer.height + 28
                    color: windowRoot.themeBgCard
                    radius: 8
                    border.color: windowRoot.themeBorder
                    border.width: 1

                    ColumnLayout {
                        id: layoutElementContainer
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Build Release: v" + modelData.version
                                font.pixelSize: 15
                                font.bold: true
                                color: windowRoot.isDarkTheme ? "#f5e0dc" : "#2f3542"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "📅 Deployment Date: " + modelData.date
                                font.pixelSize: 12
                                color: windowRoot.themeTextSub
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: windowRoot.themeBorder
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: modelData.changes
                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    Text { text: "•"; font.bold: true; color: windowRoot.themeAccent; font.pixelSize: 14 }
                                    Text {
                                        text: modelData
                                        font.pixelSize: 13
                                        color: windowRoot.themeTextSub
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
