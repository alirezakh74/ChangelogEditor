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
        anchors.fill: parent; anchors.margins: 25; spacing: 16

        Text { text: "🔍 Application Changelog Production Render Stack"; color: windowRoot.themeTextMain; font.bold: true; font.pixelSize: 18 }

        ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true

            ListView {
                id: productionModelVisualizer
                spacing: 14; model: []

                delegate: Rectangle {
                    id: versionCardItem
                    width: productionModelVisualizer.width - 20
                    implicitHeight: layoutElementContainer.height + 28
                    color: windowRoot.themeBgCard; radius: 8; border.color: windowRoot.themeBorder; border.width: 1

                    property var entryImages: modelData.images

                    ColumnLayout {
                        id: layoutElementContainer
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Build Release: v" + modelData.version; font.pixelSize: 15; font.bold: true; color: windowRoot.isDarkTheme ? "#f5e0dc" : "#2f3542" }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "📅 Deployment Date: " + modelData.date + " (" + BackendEngine.convertToJalali(modelData.date) + ")"
                                font.pixelSize: 12; color: windowRoot.themeTextSub
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: windowRoot.themeBorder }

                        // Upgraded Changelog List View supporting Child Images
                        Column {
                            Layout.fillWidth: true; spacing: 10

                            Repeater {
                                model: modelData.changes
                                ColumnLayout {
                                    width: parent.width; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        Text { text: "•"; font.bold: true; color: windowRoot.themeAccent; font.pixelSize: 14 }
                                        Text { text: modelData.text; font.pixelSize: 13; color: windowRoot.themeTextSub; Layout.fillWidth: true; wrapMode: Text.WrapPrefix }
                                    }

                                    // Description Specific Images Gallery Render
                                    Flow {
                                        Layout.fillWidth: true; Layout.leftMargin: 18; spacing: 6
                                        visible: modelData.images && modelData.images.length > 0
                                        property var childImages: modelData.images

                                        Repeater {
                                            model: parent.childImages
                                            Image {
                                                id: descImgItem; source: modelData; width: 64; height: 64; fillMode: Image.PreserveAspectCrop
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { prodImagePopupOverlay.imageList = parent.parent.childImages; prodImagePopupOverlay.currentIndex = index; prodImagePopupOverlay.visible = true; } }
                                                Rectangle { anchors.fill: parent; color: windowRoot.themeBgDeep; visible: descImgItem.status === Image.Error; Text { anchors.centerIn: parent; text: "⚠️"; color: "#ff4757"; font.pixelSize: 10 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Profile/Version Attached Media Gallery (Like before)
                        Flow {
                            Layout.fillWidth: true; spacing: 8
                            visible: versionCardItem.entryImages && versionCardItem.entryImages.length > 0
                            Repeater {
                                model: versionCardItem.entryImages
                                Image {
                                    id: prodImage; source: modelData; width: 90; height: 90; fillMode: Image.PreserveAspectCrop
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { prodImagePopupOverlay.imageList = versionCardItem.entryImages; prodImagePopupOverlay.currentIndex = index; prodImagePopupOverlay.visible = true; } }
                                    Rectangle { anchors.fill: parent; color: windowRoot.themeBgDeep; border.color: windowRoot.themeBorder; border.width: 1; radius: 4; visible: prodImage.status === Image.Error; Text { anchors.centerIn: parent; text: "⚠️ Missing"; color: "#ff4757"; font.pixelSize: 10; font.bold: true } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Popup View Component Overlay
    Rectangle {
        id: prodImagePopupOverlay; anchors.fill: parent; color: "#f0000000"; visible: false; z: 99999
        property var imageList: []; property int currentIndex: 0
        MouseArea { anchors.fill: parent }
        Item {
            anchors.fill: parent; anchors.margins: 30
            Button { text: "✕ Close Preview"; anchors.top: parent.top; anchors.right: parent.right; z: 10; background: Rectangle { color: "#2f3542"; radius: 4; border.color: "#747d8c" } contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; padding: 8 } onClicked: prodImagePopupOverlay.visible = false }
            RowLayout {
                anchors.fill: parent; anchors.topMargin: 60; spacing: 20
                Button { text: "◀"; Layout.preferredWidth: 55; Layout.preferredHeight: 55; visible: prodImagePopupOverlay.currentIndex > 0; background: Rectangle { color: "#2f3542"; radius: 28; border.color: "#747d8c"; opacity: parent.hovered ? 1.0 : 0.7 } contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } onClicked: if (prodImagePopupOverlay.currentIndex > 0) prodImagePopupOverlay.currentIndex-- }
                Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"; clip: true; Image { anchors.fill: parent; source: (prodImagePopupOverlay.imageList && prodImagePopupOverlay.imageList.length > prodImagePopupOverlay.currentIndex) ? prodImagePopupOverlay.imageList[prodImagePopupOverlay.currentIndex] : ""; fillMode: Image.PreserveAspectFit } }
                Button { text: "▶"; Layout.preferredWidth: 55; Layout.preferredHeight: 55; visible: prodImagePopupOverlay.currentIndex < (prodImagePopupOverlay.imageList.length - 1); background: Rectangle { color: "#2f3542"; radius: 28; border.color: "#747d8c"; opacity: parent.hovered ? 1.0 : 0.7 } contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } onClicked: if (prodImagePopupOverlay.currentIndex < prodImagePopupOverlay.imageList.length - 1) prodImagePopupOverlay.currentIndex++ }
            }
        }
    }
}
