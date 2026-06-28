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

    // Global State management property for Theme switching
    property bool isDarkTheme: true

    // Theme Palette Definitions
    readonly property color themeBgDeep: isDarkTheme ? "#11111b" : "#f1f2f6"
    readonly property color themeBgSurface: isDarkTheme ? "#181825" : "#ffffff"
    readonly property color themeBgCard: isDarkTheme ? "#1e1e2e" : "#ffffff"
    readonly property color themeTextMain: isDarkTheme ? "#cdd6f4" : "#2f3542"
    readonly property color themeTextSub: isDarkTheme ? "#a6adc8" : "#747d8c"
    readonly property color themeBorder: isDarkTheme ? "#313244" : "#dcdde1"
    readonly property color themeAccent: isDarkTheme ? "#b4befe" : "#3498db"

    color: themeBgDeep

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Upper Navigation Ribbon panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: themeBgSurface
            border.color: themeBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 6
                anchors.leftMargin: 15
                anchors.rightMargin: 15

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
                        color: viewDeck.currentIndex === 0 ? "#2ed573" : themeTextSub
                        font.bold: true
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
                        color: viewDeck.currentIndex === 1 ? "#2ed573" : themeTextSub
                        font.bold: true
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
                    color: BackendEngine.isDirty ? "#e1b12c" : "#2ed573"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.rightMargin: 15
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle { height: 20; width: 1; color: themeBorder; Layout.rightMargin: 10 }

                // Theme Switch Selection Controls
                Button {
                    text: "☀️ Light"
                    Layout.preferredHeight: 32
                    background: Rectangle {
                        color: !windowRoot.isDarkTheme ? "#3498db" : (parent.hovered ? themeBorder : "transparent")
                        radius: 4
                        opacity: !windowRoot.isDarkTheme ? 0.2 : 1.0
                    }
                    contentItem: Text {
                        text: parent.text
                        color: !windowRoot.isDarkTheme ? "#3498db" : themeTextMain
                        font.bold: !windowRoot.isDarkTheme
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: windowRoot.isDarkTheme = false
                }

                Button {
                    text: "🌙 Dark"
                    Layout.preferredHeight: 32
                    background: Rectangle {
                        color: windowRoot.isDarkTheme ? "#b4befe" : (parent.hovered ? themeBorder : "transparent")
                        radius: 4
                        opacity: windowRoot.isDarkTheme ? 0.2 : 1.0
                    }
                    contentItem: Text {
                        text: parent.text
                        color: windowRoot.isDarkTheme ? "#b4befe" : themeTextMain
                        font.bold: windowRoot.isDarkTheme
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: windowRoot.isDarkTheme = true
                }
            }
        }

        StackLayout {
            id: viewDeck
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            WorkspaceEditor { id: editorScreen }
            ProductionViewer { id: viewerScreen }
        }
    }

    // Context Dynamic Toast Container Component
    Rectangle {
        id: notificationToast
        property string msg: ""
        width: Math.max(300, lblToast.implicitWidth + 40)
        height: 44
        radius: 6
        color: themeBgCard
        border.width: 1
        border.color: themeBorder
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
            color: themeTextMain
            font.pixelSize: 13
        }

        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: notificationToast.opacity = 0
        }

        function triggerPopup(info, isSuccess) {
            notificationToast.msg = info
            notificationToast.border.color = isSuccess ? "#2ed573" : "#ff4757"
            notificationToast.opacity = 1
            lblToast.color = isSuccess ? "#2ed573" : "#ff4757"
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
