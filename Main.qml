import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: windowRoot
    width: 1200
    height: 850
    visible: true
    title: "Changelog Workspace Pro"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Navigation Ribbon / Tab Bar Panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "#1e272e"

            RowLayout {
                anchors.fill: parent
                spacing: 4
                anchors.leftMargin: 10

                Button {
                    id: tabBtnEditor
                    text: "✏️ Layout Workspace Editor"
                    Layout.preferredHeight: 40
                    flat: true
                    background: Rectangle {
                        color: viewDeck.currentIndex === 0 ? "#3d4e5d" : "transparent"
                        radius: 4
                    }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: viewDeck.currentIndex = 0
                }

                Button {
                    id: tabBtnViewer
                    text: "📋 Rendered Production View"
                    Layout.preferredHeight: 40
                    flat: true
                    background: Rectangle {
                        color: viewDeck.currentIndex === 1 ? "#3d4e5d" : "transparent"
                        radius: 4
                    }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: {
                        viewDeck.currentIndex = 1
                        viewerScreen.synchronizeView()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: BackendEngine.isDirty ? "⚠️ Unsaved Alterations" : "📦 Synchronized"
                    color: BackendEngine.isDirty ? "#ffdd59" : "#05c46b"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.rightMargin: 20
                }
            }
        }

        // Execution Deck Layout
        StackLayout {
            id: viewDeck
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            WorkspaceEditor {
                id: editorScreen
            }

            ProductionViewer {
                id: viewerScreen
            }
        }
    }

    // Dynamic Context Notifications Global Component
    Rectangle {
        id: notificationToast
        property string msg: ""
        width: Math.max(300, lblToast.implicitWidth + 40)
        height: 44
        radius: 6
        color: "#2f3542"
        border.width: 1
        border.color: "#747d8c"
        opacity: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        z: 9999

        Behavior on opacity { NumberAnimation { duration: 250 } }

        Text {
            id: lblToast
            anchors.centerIn: parent
            text: notificationToast.msg
            color: "white"
            font.pixelSize: 13
        }

        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: notificationToast.opacity = 0
        }

        function triggerPopup(info, isSuccess) {
            notificationToast.msg = info
            notificationToast.color = isSuccess ? "#05c46b" : "#ff5e57"
            notificationToast.border.color = isSuccess ? "#2ed573" : "#ff4757"
            notificationToast.opacity = 1
            toastTimer.restart()
        }
    }

    Connections {
        target: BackendEngine
        function onStatusMessageAlert(message, isSuccess) {
            notificationToast.triggerPopup(message, isSuccess)
        }
    }
}
