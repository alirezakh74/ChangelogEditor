import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: productionViewerRoot
    color: "#2c3e50"

    function synchronizeView() {
        productionModelVisualizer.model = [];
        productionModelVisualizer.model = BackendEngine.fetchSerializedEntries();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 15

        Text {
            text: "🔍 Application Changelog Production Render Stack"
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 18
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: productionModelVisualizer
                spacing: 16
                model: []

                delegate: Rectangle {
                    width: productionModelVisualizer.width - 20
                    implicitHeight: layoutElementContainer.height + 24
                    color: "#ffffff"
                    radius: 8

                    ColumnLayout {
                        id: layoutElementContainer
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Build Release: v" + modelData.version
                                font.pixelSize: 16
                                font.bold: true
                                color: "#2c3e50"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "📅 Deployment Date: " + modelData.date
                                font.pixelSize: 13
                                color: "#7f8c8d"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#b2bec3"
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: modelData.changes
                                RowLayout {
                                    width: parent.width
                                    spacing: 8
                                    Text { text: "•"; font.bold: true; color: "#2980b9" }
                                    Text {
                                        text: modelData
                                        font.pixelSize: 13
                                        color: "#2d3436"
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
