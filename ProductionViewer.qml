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
                            Text { text: "Build Release: v" + modelData.version; font.pixelSize: 15; font.bold: true; color: windowRoot.isDarkTheme ? "#f5e0dc" : "#2f3542" }
                            Item { Layout.fillWidth: true }
                            Text { text: "📅 Deployment Date: " + modelData.date; font.pixelSize: 12; color: windowRoot.themeTextSub }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: windowRoot.themeBorder }

                        Column {
                            Layout.fillWidth: true; spacing: 8
                            Repeater {
                                model: modelData.changes
                                RowLayout {
                                    width: parent.width; spacing: 10
                                    Text { text: "•"; font.bold: true; color: windowRoot.themeAccent; font.pixelSize: 14 }
                                    Text { text: modelData; font.pixelSize: 13; color: windowRoot.themeTextSub; Layout.fillWidth: true; wrapMode: Text.Wrap }
                                }
                            }
                        }

                        // Production Media Gallery Stack Items View
                        Flow {
                            Layout.fillWidth: true
                            spacing: 12
                            visible: modelData.images && modelData.images.length > 0

                            // Explicit reference alias payload sequence arrays mapping injection pointers safely
                            property var attachedImagesArrayRef: modelData.images

                            Repeater {
                                model: parent.attachedImagesArrayRef
                                Rectangle {
                                    width: 140; height: 95; radius: 6; color: windowRoot.themeBgDeep; border.color: windowRoot.themeBorder; border.width: 1

                                    Image {
                                        anchors.fill: parent; anchors.margins: 3
                                        source: modelData
                                        fillMode: Image.PreserveAspectCrop
                                        clip: true

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: lightboxPopup.openGallery(parent.parent.parent.attachedImagesArrayRef, index)
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

    // High-Resolution Lightbox Viewer Popup Overlay
    Rectangle {
        id: lightboxPopup
        anchors.fill: parent
        color: "#f30b0b14"
        visible: false
        z: 50000

        property var imageList: []
        property int activeIndex: 0

        function openGallery(imagesArray, startingIndex) {
            imageList = imagesArray;
            activeIndex = startingIndex;
            visible = true;
        }

        MouseArea { anchors.fill: parent; propagateComposedEvents: false }

        Image {
            id: targetFullImage
            anchors.centerIn: parent
            width: parent.width * 0.85
            height: parent.height * 0.78
            source: lightboxPopup.imageList.length > 0 ? lightboxPopup.imageList[lightboxPopup.activeIndex] : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Button {
            anchors.left: parent.left; anchors.leftMargin: 25; anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 50; implicitHeight: 50
            visible: lightboxPopup.activeIndex > 0
            background: Rectangle { color: parent.hovered ? "#313244" : "#1e1e2e"; radius: 25; border.color: "#45475a"; border.width: 1 }
            contentItem: Text { text: "◀"; color: "white"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: lightboxPopup.activeIndex--
        }

        Button {
            anchors.right: parent.right; anchors.rightMargin: 25; anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 50; implicitHeight: 50
            visible: lightboxPopup.activeIndex < lightboxPopup.imageList.length - 1
            background: Rectangle { color: parent.hovered ? "#313244" : "#1e1e2e"; radius: 25; border.color: "#45475a"; border.width: 1 }
            contentItem: Text { text: "▶"; color: "white"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: lightboxPopup.activeIndex++
        }

        Button {
            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 25
            implicitWidth: 44; implicitHeight: 44
            background: Rectangle { color: parent.hovered ? "#ff4757" : "#1e1e2e"; radius: 22; border.color: parent.hovered ? "transparent" : "#45475a" }
            contentItem: Text { text: "✕"; color: "white"; font.bold: true; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: lightboxPopup.visible = false
        }

        Text {
            text: (lightboxPopup.activeIndex + 1) + " / " + lightboxPopup.imageList.length
            color: "#a6adc8"
            font.pixelSize: 14; font.bold: true
            anchors.bottom: parent.bottom; anchors.bottomMargin: 30; anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
