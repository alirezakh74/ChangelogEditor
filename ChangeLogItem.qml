import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property string version: ""
    property string date: ""
    property var changes: []

    implicitHeight: contentColumn.height + 24
    color: mouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
    radius: 8
    border.color: "#e0e0e0"
    border.width: 1

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        // Header: Version ... Date
        RowLayout {
            width: parent.width
            spacing: 0

            Text {
                text: "Version " + root.version
                font.pixelSize: 16
                font.bold: true
                color: "#333"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.date
                font.pixelSize: 13
                color: "#888"
            }
        }

        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: "#e8e8e8"
        }

        // Changes list
        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: root.changes

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: (index + 1) + "."
                        font.pixelSize: 14
                        color: "#555"
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        text: modelData
                        font.pixelSize: 14
                        color: "#444"
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
