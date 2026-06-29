import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

Rectangle {
    id: editorContainer
    color: windowRoot.themeBgDeep

    property string workingMode: "CREATE"
    property int selectionPointerIndex: -1
    property var currentStagingChanges: []
    property var currentStagingImages: []

    function appendItemToBuffer() {
        var cleanInput = txtItemEntry.text.trim();
        if(cleanInput !== "") {
            var items = currentStagingChanges;
            items.push(cleanInput);
            currentStagingChanges = [...items];
            txtItemEntry.text = "";
            txtItemEntry.forceActiveFocus();
        }
    }

    function removeItemFromBuffer(idx) {
        var items = currentStagingChanges;
        items.splice(idx, 1);
        currentStagingChanges = [...items];
    }

    function modifyItemInBuffer(idx, newText) {
        var items = currentStagingChanges;
        items[idx] = newText.trim();
        currentStagingChanges = [...items];
    }

    function removeImageFromBuffer(idx) {
        var imgs = currentStagingImages;
        if (idx >= 0 && idx < imgs.length) {
            // Transactional state updates only. Disk mutations are handled safely by C++ GC upon save/load.
            imgs.splice(idx, 1);
            currentStagingImages = [...imgs];
        }
    }

    function loadActiveEntryToForm(idx) {
        workingMode = "UPDATE";
        selectionPointerIndex = idx;
        txtVersion.text = BackendEngine.fetchVersionName(idx);
        txtDate.text = BackendEngine.fetchVersionDate(idx);

        var rawJoined = BackendEngine.fetchVersionChangesJoined(idx);
        if (rawJoined.trim() === "") {
            currentStagingChanges = [];
        } else {
            currentStagingChanges = rawJoined.split("\n");
        }

        var rawImagesJoined = BackendEngine.fetchVersionImagesJoined(idx);
        if (rawImagesJoined.trim() === "") {
            currentStagingImages = [];
        } else {
            currentStagingImages = rawImagesJoined.split("\n");
        }
    }

    function clearFormInput() {
        workingMode = "CREATE";
        selectionPointerIndex = -1;
        txtVersion.text = "";
        txtDate.text = BackendEngine.getSystemDateString();
        currentStagingChanges = [];
        currentStagingImages = [];
        txtItemEntry.text = "";
    }

    function refreshVectorList() {
        var cachedCount = BackendEngine.totalVersions;
        localMemoryNodesListView.model = 0;
        localMemoryNodesListView.model = cachedCount;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Toolbar Operations
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: windowRoot.themeBgCard
            border.color: windowRoot.themeBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 12

                Button {
                    text: "🆕 New Profile"
                    flat: true
                    implicitHeight: 38
                    contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; verticalAlignment: Text.AlignVCenter }
                    onClicked: { BackendEngine.resetWorkspace(); editorContainer.clearFormInput(); editorContainer.refreshVectorList(); }
                }
                Button {
                    text: "📁 Load File"
                    flat: true
                    implicitHeight: 38
                    contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; verticalAlignment: Text.AlignVCenter }
                    onClicked: openDialog.open()
                }
                Button {
                    text: "💾 Save"
                    highlighted: BackendEngine.isDirty
                    implicitHeight: 38
                    background: Rectangle {
                        color: BackendEngine.isDirty ? "#2ed573" : (parent.hovered ? windowRoot.themeBorder : windowRoot.themeBgDeep)
                        radius: 4
                        opacity: BackendEngine.isDirty ? 0.2 : 1.0
                        border.color: windowRoot.themeBorder
                        border.width: BackendEngine.isDirty ? 0 : 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: BackendEngine.isDirty ? "#2ed573" : windowRoot.themeTextMain
                        font.bold: BackendEngine.isDirty
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (BackendEngine.currentFilePath === "") {
                            saveAsDialog.open()
                        } else {
                            BackendEngine.saveToFile()
                        }
                    }
                }
                Button {
                    text: "💾 Save File As..."
                    flat: true
                    implicitHeight: 38
                    contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; verticalAlignment: Text.AlignVCenter }
                    onClicked: saveAsDialog.open()
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Target Workspace: " + (BackendEngine.currentFilePath || "Unsaved Buffer Instance")
                    font.italic: true
                    color: windowRoot.themeTextSub
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Left Panel Input Controller Side
            Rectangle {
                SplitView.minimumWidth: 460
                SplitView.preferredWidth: 500
                color: windowRoot.themeBgCard

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Text {
                        text: workingMode === "CREATE" ? "➕ Add Document Version" : "📝 Modify Version Node"
                        font.pixelSize: 16
                        font.bold: true
                        color: windowRoot.themeAccent
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        TextField {
                            id: txtVersion
                            placeholderText: "Version (e.g. 1.0.4)"
                            color: windowRoot.themeTextMain
                            placeholderTextColor: windowRoot.isDarkTheme ? "#6c7086" : "#a4b0be"
                            Layout.fillWidth: true
                            background: Rectangle { color: windowRoot.themeBgDeep; border.color: parent.activeFocus ? windowRoot.themeAccent : windowRoot.themeBorder; radius: 4 }
                        }
                        TextField {
                            id: txtDate
                            placeholderText: "Date (YYYY-MM-DD)"
                            text: BackendEngine.getSystemDateString()
                            color: windowRoot.themeTextMain
                            placeholderTextColor: windowRoot.isDarkTheme ? "#6c7086" : "#a4b0be"
                            Layout.preferredWidth: 140
                            background: Rectangle { color: windowRoot.themeBgDeep; border.color: parent.activeFocus ? windowRoot.themeAccent : windowRoot.themeBorder; radius: 4 }
                        }
                    }

                    Text { text: "Manage Changes Staging Stack (" + currentStagingChanges.length + ")"; font.bold: true; font.pixelSize: 11; color: windowRoot.themeTextSub }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: windowRoot.themeBgDeep
                        border.color: windowRoot.themeBorder
                        radius: 4
                        clip: true

                        ListView {
                            id: stagingListView
                            anchors.fill: parent
                            anchors.margins: 8
                            model: currentStagingChanges
                            spacing: 6

                            delegate: Rectangle {
                                width: stagingListView.width
                                height: 38
                                color: windowRoot.themeBgCard
                                radius: 4
                                border.color: windowRoot.themeBorder

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    Text { text: "•"; font.bold: true; color: windowRoot.themeAccent; font.pixelSize: 14 }

                                    TextField {
                                        text: modelData
                                        Layout.fillWidth: true
                                        font.pixelSize: 13
                                        color: windowRoot.themeTextMain
                                        selectByMouse: true
                                        background: Rectangle { color: "transparent"; border.color: parent.activeFocus ? windowRoot.themeAccent : "transparent"; border.width: 1 }
                                        onAccepted: { modifyItemInBuffer(index, text); focus = false; }
                                        onEditingFinished: modifyItemInBuffer(index, text)
                                    }

                                    Button {
                                        text: "✕"
                                        flat: true
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        contentItem: Text { text: "✕"; color: "#ff4757"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                        onClicked: removeItemFromBuffer(index)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "No active changes pushed into this node yet."
                            anchors.centerIn: parent
                            color: windowRoot.isDarkTheme ? "#585b70" : "#a4b0be"
                            visible: currentStagingChanges.length === 0
                            font.italic: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: txtItemEntry
                            placeholderText: "Type change description here..."
                            color: windowRoot.themeTextMain
                            placeholderTextColor: windowRoot.isDarkTheme ? "#6c7086" : "#a4b0be"
                            Layout.fillWidth: true
                            background: Rectangle { color: windowRoot.themeBgDeep; border.color: parent.activeFocus ? windowRoot.themeAccent : windowRoot.themeBorder; radius: 4 }
                            onAccepted: editorContainer.appendItemToBuffer()
                        }
                        Button {
                            text: "➕ Push"
                            background: Rectangle { color: windowRoot.themeBgDeep; radius: 4; border.color: windowRoot.themeBorder }
                            contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: editorContainer.appendItemToBuffer()
                        }
                    }

                    Text { text: "Attached Media Assets (" + currentStagingImages.length + ")"; font.bold: true; font.pixelSize: 11; color: windowRoot.themeTextSub }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            text: "🖼️ Attach Images"
                            Layout.preferredHeight: 36
                            background: Rectangle { color: windowRoot.themeBgDeep; radius: 4; border.color: windowRoot.themeBorder }
                            contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: imagePickerDialog.open()
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                            RowLayout {
                                spacing: 8
                                Repeater {
                                    model: currentStagingImages
                                    Rectangle {
                                        id: stagingImageWrapper
                                        width: 60; height: 60
                                        color: windowRoot.themeBgDeep
                                        border.color: windowRoot.themeBorder
                                        radius: 4

                                        // Explicitly capture index context to avoid shadowing bugs
                                        property int itemIndex: index

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            source: modelData
                                            fillMode: Image.PreserveAspectCrop
                                            clip: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: lightboxPopup.openGallery(editorContainer.currentStagingImages, stagingImageWrapper.itemIndex)
                                        }

                                        Rectangle {
                                            width: 16; height: 16; radius: 8
                                            color: "#ff4757"
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: -4
                                            z: 10
                                            Text { text: "×"; color: "white"; font.bold: true; font.pixelSize: 12; anchors.centerIn: parent }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: removeImageFromBuffer(stagingImageWrapper.itemIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Button {
                            text: "Clear Fields"
                            Layout.fillWidth: true
                            background: Rectangle { color: windowRoot.themeBgDeep; radius: 4; border.color: windowRoot.themeBorder }
                            contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: editorContainer.clearFormInput()
                        }
                        Button {
                            id: injectNodeBtn
                            text: workingMode === "CREATE" ? "Inject Version Node" : "Modify Node Vector"
                            Layout.fillWidth: true
                            enabled: txtVersion.text.trim() !== "" && currentStagingChanges.length > 0
                            background: Rectangle { color: parent.enabled ? windowRoot.themeAccent : windowRoot.themeBgDeep; radius: 4; border.color: windowRoot.themeBorder }
                            contentItem: Text {
                                text: parent.text;
                                color: injectNodeBtn.enabled ? (windowRoot.isDarkTheme ? "#11111b" : "#ffffff") : (windowRoot.isDarkTheme ? "#585b70" : "#a4b0be");
                                font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                var compositeString = currentStagingChanges.join("\n");
                                var compositeImagesString = currentStagingImages.join("\n");
                                if (workingMode === "CREATE") {
                                    BackendEngine.appendVersionEntry(txtVersion.text, txtDate.text, compositeString, compositeImagesString);
                                } else {
                                    BackendEngine.commitVersionEntry(selectionPointerIndex, txtVersion.text, txtDate.text, compositeString, compositeImagesString);
                                }
                                editorContainer.clearFormInput();
                                editorContainer.refreshVectorList();
                            }
                        }
                    }
                }
            }

            // Right Panel (Preview Saved Node Cards Container)
            Rectangle {
                SplitView.minimumWidth: 400
                color: windowRoot.themeBgDeep

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "📋 Local Memory Nodes Vector (" + BackendEngine.totalVersions + ")"; font.pixelSize: 14; font.bold: true; color: windowRoot.themeTextMain }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "🗑️ Delete All Nodes"
                            flat: true
                            contentItem: Text { text: parent.text; color: BackendEngine.totalVersions > 0 ? "#ff4757" : (windowRoot.isDarkTheme ? "#45475a" : "#a4b0be"); font.bold: true; font.pixelSize: 12 }
                            enabled: BackendEngine.totalVersions > 0
                            onClicked: { BackendEngine.resetWorkspace(); editorContainer.clearFormInput(); editorContainer.refreshVectorList(); }
                        }
                    }

                    ListView {
                        id: localMemoryNodesListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 10
                        model: BackendEngine.totalVersions

                        delegate: Rectangle {
                            id: versionCardNode
                            width: localMemoryNodesListView.width
                            implicitHeight: innerColumnLayout.height + 20
                            color: windowRoot.themeBgCard
                            radius: 6
                            border.color: selectionPointerIndex === index ? "#e1b12c" : windowRoot.themeBorder
                            border.width: selectionPointerIndex === index ? 2 : 1

                            property int cardRecordIndex: index

                            ColumnLayout {
                                id: innerColumnLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 14
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Version: " + BackendEngine.fetchVersionName(cardRecordIndex); font.bold: true; font.pixelSize: 14; color: windowRoot.themeTextMain }
                                    Item { Layout.fillWidth: true }
                                    Text { text: BackendEngine.fetchVersionDate(cardRecordIndex); color: windowRoot.themeTextSub; font.pixelSize: 12 }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: windowRoot.themeBorder }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Repeater {
                                        model: BackendEngine.fetchVersionChangesJoined(versionCardNode.cardRecordIndex).split("\n")
                                        RowLayout {
                                            width: parent.width; spacing: 6
                                            Text { text: "•"; color: windowRoot.themeAccent }
                                            Text { text: modelData; font.pixelSize: 12; color: windowRoot.themeTextSub; Layout.fillWidth: true; wrapMode: Text.Wrap }
                                        }
                                    }
                                }

                                Flow {
                                    id: savedCardImagesFlow
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: BackendEngine.fetchVersionImagesJoined(versionCardNode.cardRecordIndex) !== ""

                                    // Calculate array once at layout scope level
                                    property var imageArray: BackendEngine.fetchVersionImagesJoined(versionCardNode.cardRecordIndex).split("\n")

                                    Repeater {
                                        model: savedCardImagesFlow.imageArray
                                        Rectangle {
                                            id: savedImageThumbnailWrapper
                                            width: 40; height: 40; radius: 3; color: windowRoot.themeBgDeep; border.color: windowRoot.themeBorder

                                            property int thumbIndex: index

                                            Image { anchors.fill: parent; anchors.margins: 1; source: modelData; fillMode: Image.PreserveAspectCrop; clip: true }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: lightboxPopup.openGallery(savedCardImagesFlow.imageArray, savedImageThumbnailWrapper.thumbIndex)
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: "Load Node"
                                        background: Rectangle { color: windowRoot.themeBgDeep; radius: 4; border.color: windowRoot.themeBorder }
                                        contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        onClicked: editorContainer.loadActiveEntryToForm(cardRecordIndex)
                                    }
                                    Button {
                                        text: "Delete Node"
                                        background: Rectangle { color: windowRoot.themeBgDeep; radius: 4; border.color: windowRoot.themeBorder }
                                        contentItem: Text { text: parent.text; color: "#ff4757"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        onClicked: { BackendEngine.removeVersionEntry(cardRecordIndex); editorContainer.clearFormInput(); editorContainer.refreshVectorList(); }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FileDialog { id: openDialog; title: "Load Schema File"; nameFilters: ["JSON Documents (*.json)"]; selectExisting: true; onAccepted: { BackendEngine.loadFromFile(fileUrl); editorContainer.clearFormInput(); editorContainer.refreshVectorList(); } }
    FileDialog { id: saveAsDialog; title: "Save Schema File As"; nameFilters: ["JSON Documents (*.json)"]; selectExisting: false; onAccepted: BackendEngine.saveAsFile(fileUrl) }

    FileDialog {
        id: imagePickerDialog
        title: "Select Changelog Images Asset Elements"
        nameFilters: ["Image files (*.png *.jpg *.jpeg)"]
        selectMultiple: true
        selectExisting: true
        onAccepted: {
            var items = currentStagingImages;
            for (var i = 0; i < fileUrls.length; i++) {
                var uploadedUrlPath = BackendEngine.copyImageToUploads(fileUrls[i]);
                if (uploadedUrlPath !== "") {
                    items.push(uploadedUrlPath);
                }
            }
            currentStagingImages = [...items];
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

        // Left Navigation Arrow Button
        Button {
            anchors.left: parent.left
            anchors.leftMargin: 25
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 50; implicitHeight: 50
            visible: lightboxPopup.activeIndex > 0
            background: Rectangle { color: parent.hovered ? "#313244" : "#1e1e2e"; radius: 25; border.color: "#45475a"; border.width: 1 }
            contentItem: Text { text: "◀"; color: "white"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: lightboxPopup.activeIndex--
        }

        // Right Navigation Arrow Button
        Button {
            anchors.right: parent.right
            anchors.rightMargin: 25
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 50; implicitHeight: 50
            visible: lightboxPopup.activeIndex < lightboxPopup.imageList.length - 1
            background: Rectangle { color: parent.hovered ? "#313244" : "#1e1e2e"; radius: 25; border.color: "#45475a"; border.width: 1 }
            contentItem: Text { text: "▶"; color: "white"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: lightboxPopup.activeIndex++
        }

        // Close Lightbox Button
        Button {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 25
            implicitWidth: 44; implicitHeight: 44
            background: Rectangle { color: parent.hovered ? "#ff4757" : "#1e1e2e"; radius: 22; border.color: parent.hovered ? "transparent" : "#45475a" }
            contentItem: Text { text: "✕"; color: "white"; font.bold: true; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: lightboxPopup.visible = false
        }

        // Progress Label
        Text {
            text: (lightboxPopup.activeIndex + 1) + " / " + lightboxPopup.imageList.length
            color: "#a6adc8"
            font.pixelSize: 14
            font.bold: true
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
