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
                    id: versionCardItem
                    width: productionModelVisualizer.width - 20
                    implicitHeight: layoutElementContainer.height + 28
                    color: windowRoot.themeBgCard
                    radius: 8
                    border.color: windowRoot.themeBorder
                    border.width: 1

                    // FIXED: Store the outer entry's images array here to prevent inner Repeater shadowing
                    property var entryImages: modelData.images

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

                        // Changelog Bullet List
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

                        // Production Attached Media Gallery
                        Flow {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: versionCardItem.entryImages && versionCardItem.entryImages.length > 0

                            Repeater {
                                model: versionCardItem.entryImages
                                Image {
                                    id: prodImage
                                    source: modelData
                                    width: 90
                                    height: 90
                                    fillMode: Image.PreserveAspectCrop
                                    layer.enabled: true

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // FIXED: Safely fetch the array from the unshadowed outer card property
                                            prodImagePopupOverlay.imageList = versionCardItem.entryImages
                                            prodImagePopupOverlay.currentIndex = index
                                            prodImagePopupOverlay.visible = true
                                        }
                                    }

                                    // Safety Fallback Layer if physical file is wiped off disk
                                    Rectangle {
                                        anchors.fill: parent
                                        color: windowRoot.themeBgDeep
                                        border.color: windowRoot.themeBorder
                                        border.width: 1
                                        radius: 4
                                        visible: prodImage.status === Image.Error

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⚠️ Missing"
                                            color: "#ff4757"
                                            font.pixelSize: 10
                                            font.bold: true
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

    // Older pop-up dynamic navigation image viewer layout
    Rectangle {
        id: prodImagePopupOverlay
        anchors.fill: parent
        color: "#f0000000"
        visible: false
        z: 99999

        property var imageList: []
        property int currentIndex: 0

        MouseArea { anchors.fill: parent } // Blocks click leaks through backdrop layers

        Item {
            anchors.fill: parent
            anchors.margins: 30

            // Explicit Top Close Button
            Button {
                text: "✕ Close Preview"
                anchors.top: parent.top
                anchors.right: parent.right
                z: 10
                background: Rectangle { color: "#2f3542"; radius: 4; border.color: "#747d8c" }
                contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; padding: 8 }
                onClicked: prodImagePopupOverlay.visible = false
            }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 60
                spacing: 20

                // Previous Image Arrow Navigation Component
                Button {
                    text: "◀"
                    Layout.preferredWidth: 55
                    Layout.preferredHeight: 55
                    visible: prodImagePopupOverlay.currentIndex > 0
                    background: Rectangle { color: "#2f3542"; radius: 28; border.color: "#747d8c"; opacity: parent.hovered ? 1.0 : 0.7 }
                    contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: if (prodImagePopupOverlay.currentIndex > 0) prodImagePopupOverlay.currentIndex--
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: (prodImagePopupOverlay.imageList && prodImagePopupOverlay.imageList.length > prodImagePopupOverlay.currentIndex) ? prodImagePopupOverlay.imageList[prodImagePopupOverlay.currentIndex] : ""
                        fillMode: Image.PreserveAspectFit
                    }
                }

                // Next Image Arrow Navigation Component
                Button {
                    text: "▶"
                    Layout.preferredWidth: 55
                    Layout.preferredHeight: 55
                    visible: prodImagePopupOverlay.currentIndex < (prodImagePopupOverlay.imageList.length - 1)
                    background: Rectangle { color: "#2f3542"; radius: 28; border.color: "#747d8c"; opacity: parent.hovered ? 1.0 : 0.7 }
                    contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: if (prodImagePopupOverlay.currentIndex < prodImagePopupOverlay.imageList.length - 1) prodImagePopupOverlay.currentIndex++
                }
            }
        }
    }
}
