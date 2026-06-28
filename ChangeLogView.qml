import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ChangeLogManager 1.0

Rectangle {
    id: root
    color: "#1e1e2e"

    property bool showOnlyNew: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#181825"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                Text {
                    text: "📋 Changelog Viewer"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#cdd6f4"
                }

                Item { Layout.fillWidth: true }

                Switch {
                    id: filterSwitch
                    text: "Show new only"
                    checked: root.showOnlyNew
                    onCheckedChanged: root.showOnlyNew = checked
                    palette.windowText: "#cdd6f4"
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            clip: true
            spacing: 12

            model: root.showOnlyNew ? ChangeLogManager.getEntriesSinceVersion(ChangeLogManager.lastSeenVersion) : ChangeLogManager.getAllEntries()

            delegate: ChangeLogItem {
                width: listView.width
                version: modelData.version
                date: modelData.date
                changes: modelData.changes
            }

            Text {
                anchors.centerIn: parent
                visible: listView.count === 0
                text: "No changes found to display."
                color: "#a6adc8"
                font.pixelSize: 16
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#181825"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                Text {
                    text: "Current Version: " + ChangeLogManager.currentVersion
                    color: "#a6adc8"
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Mark as read"
                    visible: ChangeLogManager.hasNewChanges

                    contentItem: Text {
                        text: parent.text
                        color: "#a6e3a1"
                        font.pixelSize: 12
                    }

                    background: Rectangle {
                        radius: 6
                        color: parent.hovered ? "#313244" : "transparent"
                        border.color: "#a6e3a1"
                        border.width: 1
                    }

                    onClicked: {
                        ChangeLogManager.markVersionAsSeen(ChangeLogManager.currentVersion)
                    }
                }
            }
        }
    }
}
