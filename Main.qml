import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: windowRoot
    width: 1200
    height: 850
    visible: true
    title: "Changelog Workspace Pro [Dark Edition]"
    color: "#11111b" // Deepest structural base

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Dark Navigation Ribbon / Tab Bar Panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "#181825" // Dark header surface
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 6
                anchors.leftMargin: 15

                Button {
                    id: tabBtnEditor
                    text: "✏️ Layout Workspace Editor"
                    Layout.preferredHeight: 38
                    flat: true
                    background: Rectangle {
                        color: viewDeck.currentIndex === 0 ? "#2ed573" : "transparent"
                        radius: 4
                        opacity: viewDeck.currentIndex === 0 ? 0.15 : 1.0
                    }
                    contentItem: Text {
                        text: parent.text
                        color: viewDeck.currentIndex === 0 ? "#2ed573" : "#a6adc8"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: viewDeck.currentIndex = 0
                }

                Button {
                    id: tabBtnViewer
                    text: "📋 Rendered Production View"
                    Layout.preferredHeight: 38
                    flat: true
                    background: Rectangle {
                        color: viewDeck.currentIndex === 1 ? "#2ed573" : "transparent"
                        radius: 4
                        opacity: viewDeck.currentIndex === 1 ? 0.15 : 1.0
                    }
                    contentItem: Text {
                        text: parent.text
                        color: viewDeck.currentIndex === 1 ? "#2ed573" : "#a6adc8"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        viewDeck.currentIndex = 1
                        viewerScreen.synchronizeView()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: BackendEngine.isDirty ? "⚠️ Unsaved Alterations" : "📦 Synchronized"
                    color: BackendEngine.isDirty ? "#f9e2af" : "#2ed573"
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
        color: "#1e1e2e"
        border.width: 1
        border.color: "#313244"
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
            color: "#cdd6f4"
            font.pixelSize: 13
        }

        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: notificationToast.opacity = 0
        }

        function triggerPopup(info, isSuccess) {
            notificationToast.msg = info
            notificationToast.color = isSuccess ? "#1e1e2e" : "#1e1e2e"
            notificationToast.border.color = isSuccess ? "#2ed573" : "#f38ba8"
            notificationToast.opacity = 1
            lblToast.color = isSuccess ? "#2ed573" : "#f38ba8"
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
