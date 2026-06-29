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
            items.push({ "text": cleanInput, "images": [] });
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
        items[idx].text = newText.trim();
        currentStagingChanges = [...items];
    }

    function removeImageFromBuffer(idx) {
        var imgs = currentStagingImages;
        if (idx >= 0 && idx < imgs.length) {
            imgs.splice(idx, 1);
            currentStagingImages = [...imgs];
        }
    }

    function loadActiveEntryToForm(idx) {
        workingMode = "UPDATE";
        selectionPointerIndex = idx;
        txtVersion.text = BackendEngine.fetchVersionName(idx);
        txtDate.text = BackendEngine.fetchVersionDate(idx);
        currentStagingChanges = BackendEngine.fetchVersionChangesList(idx);

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

        // Context File Utilities Toolbar Operations Bar
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
                    onClicked: {
                        BackendEngine.resetWorkspace();
                        editorContainer.clearFormInput();
                        editorContainer.refreshVectorList();
                    }
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

            // Left Layout Input Controller Side
            Rectangle {
                SplitView.minimumWidth: 460
                SplitView.preferredWidth: 520
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

                    // Interactive Staging Component Back Panel
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
                            spacing: 8

                            delegate: Rectangle {
                                width: stagingListView.width
                                implicitHeight: childItemColumn.height + 12
                                color: windowRoot.themeBgCard
                                radius: 4
                                border.color: windowRoot.themeBorder
                                property int changeIndex: index

                                ColumnLayout {
                                    id: childItemColumn
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 6
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text { text: "•"; font.bold: true; color: windowRoot.themeAccent; font.pixelSize: 14 }

                                        TextField {
                                            text: modelData.text
                                            Layout.fillWidth: true
                                            font.pixelSize: 13
                                            color: windowRoot.themeTextMain
                                            selectByMouse: true
                                            background: Rectangle { color: "transparent" }
                                            onAccepted: { modifyItemInBuffer(changeIndex, text); focus = false; }
                                            onEditingFinished: modifyItemInBuffer(changeIndex, text)
                                        }

                                        Button {
                                            id: attachImgBtn
                                            text: "📷 Attach Image"
                                            flat: true
                                            implicitWidth: 110 // Slightly increased to ensure full text padding fits well across themes
                                            implicitHeight: 28

                                            // Theme-driven background container
                                            background: Rectangle {
                                                // Changes color subtly when hovered, otherwise blends with the deep theme background
                                                color: attachImgBtn.hovered ? windowRoot.themeBorder : windowRoot.themeBgDeep
                                                border.color: windowRoot.themeBorder
                                                border.width: 1
                                                radius: 4
                                            }

                                            // Theme-driven text layout
                                            contentItem: Text {
                                                text: attachImgBtn.text
                                                // Uses the primary theme accent color (or swap to themeTextMain if you prefer plain text)
                                                color: windowRoot.themeAccent
                                                font.pixelSize: 11
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            onClicked: {
                                                descriptionSpecificImagePickerDialog.targetChangeIndex = changeIndex;
                                                descriptionSpecificImagePickerDialog.open();
                                            }
                                        }

                                        Button {
                                            text: "✕"
                                            flat: true
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            contentItem: Text { text: "✕"; color: "#ff4757"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                            onClicked: removeItemFromBuffer(changeIndex)
                                        }
                                    }

                                    // Description Specific Flow Gallery
                                    Flow {
                                        id: stagingDescFlow
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 16
                                        spacing: 6
                                        visible: modelData.images && modelData.images.length > 0
                                        property var descImages: modelData.images

                                        Repeater {
                                            model: stagingDescFlow.descImages
                                            Rectangle {
                                                width: 48
                                                height: 48
                                                radius: 4
                                                clip: true
                                                border.color: windowRoot.themeBorder

                                                Image {
                                                    anchors.fill: parent
                                                    source: modelData
                                                    fillMode: Image.PreserveAspectCrop

                                                    // Click to view full image overlay preview
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            imagePopupOverlay.imageList = stagingDescFlow.descImages;
                                                            imagePopupOverlay.currentIndex = index;
                                                            imagePopupOverlay.visible = true;
                                                        }
                                                    }
                                                }

                                                Button {
                                                    anchors.top: parent.top; anchors.right: parent.right
                                                    implicitWidth: 16; implicitHeight: 16
                                                    background: Rectangle { color: "#ff4757"; radius: 8 }
                                                    contentItem: Text { text: "✕"; color: "#ffffff"; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                    onClicked: {
                                                        var baseStructure = currentStagingChanges;
                                                        baseStructure[changeIndex].images.splice(index, 1);
                                                        currentStagingChanges = [...baseStructure];
                                                    }
                                                }
                                            }
                                        }
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

                    // GLOBAL VERSION IMAGES MANAGEMENT SECTION (Like before)
                    // text: "Manage Profile Version Attached Media Assets (" + currentStagingImages.length + ")"
                    // font.bold: true; font.pixelSize: 11; color: windowRoot.themeTextSub

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        color: windowRoot.themeBgDeep
                        border.color: windowRoot.themeBorder
                        radius: 4
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Button {
                                text: "📷\nAttach"
                                Layout.fillHeight: true
                                Layout.preferredWidth: 68
                                background: Rectangle { color: windowRoot.themeBgCard; radius: 4; border.color: windowRoot.themeBorder }
                                contentItem: Text { text: parent.text; color: windowRoot.themeTextMain; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: imagePickerDialog.open()
                            }

                            ListView {
                                id: stagingImagesListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                orientation: ListView.Horizontal
                                model: currentStagingImages
                                spacing: 8
                                clip: true

                                delegate: Rectangle {
                                    width: 78; height: 78
                                    color: windowRoot.themeBgCard; radius: 4; border.color: windowRoot.themeBorder

                                    Image {
                                        id: stageImg; anchors.fill: parent; anchors.margins: 2
                                        source: modelData; fillMode: Image.PreserveAspectCrop
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { imagePopupOverlay.imageList = currentStagingImages; imagePopupOverlay.currentIndex = index; imagePopupOverlay.visible = true; }
                                        }
                                        Rectangle { anchors.fill: parent; color: windowRoot.themeBgDeep; visible: stageImg.status === Image.Error; Text { anchors.centerIn: parent; text: "⚠️ Missing"; color: "#ff4757"; font.pixelSize: 9; font.bold: true } }
                                    }
                                    Button {
                                        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 3
                                        implicitWidth: 18; implicitHeight: 18; z: 10
                                        background: Rectangle { color: "#ff4757"; radius: 9 }
                                        contentItem: Text { text: "✕"; color: "#ffffff"; font.bold: true; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        onClicked: removeImageFromBuffer(index)
                                    }
                                }
                            }
                        }
                        Text { text: "No profile level images attached yet."; anchors.centerIn: parent; anchors.leftMargin: 80; color: windowRoot.isDarkTheme ? "#585b70" : "#a4b0be"; visible: currentStagingImages.length === 0; font.italic: true; font.pixelSize: 12 }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
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
                            contentItem: Text { text: parent.text; color: injectNodeBtn.enabled ? (windowRoot.isDarkTheme ? "#11111b" : "#ffffff") : (windowRoot.isDarkTheme ? "#585b70" : "#a4b0be"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: {
                                var compositeImages = currentStagingImages.join("\n");
                                if (workingMode === "CREATE") {
                                    BackendEngine.appendVersionEntry(txtVersion.text, txtDate.text, currentStagingChanges, compositeImages);
                                } else {
                                    BackendEngine.commitVersionEntry(selectionPointerIndex, txtVersion.text, txtDate.text, currentStagingChanges, compositeImages);
                                }
                                editorContainer.clearFormInput();
                                editorContainer.refreshVectorList();
                            }
                        }
                    }
                }
            }

            // Right Array Mirror Preview Panel (Vector Cards Stack View)
            Rectangle {
                SplitView.minimumWidth: 400
                color: windowRoot.themeBgDeep

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "📋 Local Memory Nodes Vector (" + BackendEngine.totalVersions + ")"; font.pixelSize: 14; font.bold: true; color: windowRoot.themeTextMain }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "🗑️ Delete All Nodes"; flat: true
                            contentItem: Text { text: parent.text; color: BackendEngine.totalVersions > 0 ? "#ff4757" : (windowRoot.isDarkTheme ? "#45475a" : "#a4b0be"); font.bold: true; font.pixelSize: 12 }
                            enabled: BackendEngine.totalVersions > 0
                            onClicked: { BackendEngine.resetWorkspace(); editorContainer.clearFormInput(); editorContainer.refreshVectorList(); }
                        }
                    }

                    ListView {
                        id: localMemoryNodesListView
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 10
                        model: BackendEngine.totalVersions

                        delegate: Rectangle {
                            id: localNodeCard
                            width: localMemoryNodesListView.width
                            implicitHeight: innerColumnLayout.height + 20
                            color: windowRoot.themeBgCard; radius: 6
                            border.color: selectionPointerIndex === index ? "#e1b12c" : windowRoot.themeBorder
                            border.width: selectionPointerIndex === index ? 2 : 1
                            property int versionIndex: index

                            ColumnLayout {
                                id: innerColumnLayout; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Version: " + BackendEngine.fetchVersionName(localNodeCard.versionIndex); font.bold: true; font.pixelSize: 14; color: windowRoot.themeTextMain }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        property string gDate: BackendEngine.fetchVersionDate(localNodeCard.versionIndex)
                                        text: gDate + " (" + BackendEngine.convertToJalali(gDate) + ")"
                                        color: windowRoot.themeTextSub; font.pixelSize: 11
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: windowRoot.themeBorder }

                                Column {
                                    Layout.fillWidth: true; spacing: 6
                                    Repeater {
                                        model: BackendEngine.fetchVersionChangesList(localNodeCard.versionIndex)
                                        ColumnLayout {
                                            width: parent.width; spacing: 2
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 6
                                                Text { text: "•"; color: windowRoot.themeAccent }
                                                Text { text: modelData.text; font.pixelSize: 12; color: windowRoot.themeTextSub; Layout.fillWidth: true; wrapMode: Text.Wrap }
                                            }
                                            Flow {
                                                id: mirrorDescFlow
                                                Layout.fillWidth: true
                                                Layout.leftMargin: 12
                                                spacing: 4
                                                visible: modelData.images && modelData.images.length > 0
                                                property var mirrorImages: modelData.images

                                                Repeater {
                                                    model: mirrorDescFlow.mirrorImages
                                                    Image {
                                                        source: modelData
                                                        width: 24
                                                        height: 24
                                                        fillMode: Image.PreserveAspectCrop

                                                        // Click to view full image overlay preview
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                imagePopupOverlay.imageList = mirrorDescFlow.mirrorImages;
                                                                imagePopupOverlay.currentIndex = index;
                                                                imagePopupOverlay.visible = true;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Core Version Images Row Layout
                                Flow {
                                    id: previewImagesFlow; Layout.fillWidth: true; spacing: 6
                                    property var nodeImagesList: {
                                        var rawStr = BackendEngine.fetchVersionImagesJoined(localNodeCard.versionIndex);
                                        return (rawStr.trim() !== "") ? rawStr.split("\n") : [];
                                    }
                                    visible: nodeImagesList.length > 0
                                    Repeater {
                                        model: previewImagesFlow.nodeImagesList
                                        Image {
                                            id: previewNodeImg; source: modelData; width: 36; height: 36; fillMode: Image.PreserveAspectCrop
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { imagePopupOverlay.imageList = previewImagesFlow.nodeImagesList; imagePopupOverlay.currentIndex = index; imagePopupOverlay.visible = true; } }
                                            Rectangle { anchors.fill: parent; color: windowRoot.themeBgDeep; visible: previewNodeImg.status === Image.Error; Text { anchors.centerIn: parent; text: "⚠️"; color: "#ff4757"; font.pixelSize: 10 } }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; Item { Layout.fillWidth: true }
                                    Button {
                                        text: "Load Node";
                                        background: Rectangle {
                                            color: windowRoot.themeBgDeep;
                                            radius: 4;
                                            border.color: windowRoot.themeBorder
                                        }
                                        contentItem: Text {
                                            text: parent.text;
                                            color: windowRoot.themeTextMain;
                                            font.pixelSize: 11;
                                            horizontalAlignment: Text.AlignHCenter;
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: editorContainer.loadActiveEntryToForm(localNodeCard.versionIndex)
                                    }
                                    Button {
                                        text: "Delete Node";
                                        background: Rectangle {
                                            color: windowRoot.themeBgDeep;
                                            radius: 4;
                                            border.color: windowRoot.themeBorder
                                        }
                                        contentItem: Text {
                                            text: parent.text;
                                            color: "#ff4757";
                                            font.pixelSize: 11;
                                            horizontalAlignment: Text.AlignHCenter;
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: {
                                            BackendEngine.removeVersionEntry(localNodeCard.versionIndex);
                                            editorContainer.clearFormInput();
                                            editorContainer.refreshVectorList();
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

    FileDialog { id: openDialog; title: "Load Schema File"; nameFilters: ["JSON Documents (*.json)"]; selectExisting: true; onAccepted: { BackendEngine.loadFromFile(fileUrl); editorContainer.clearFormInput(); editorContainer.refreshVectorList(); } }
    FileDialog { id: saveAsDialog; title: "Save Schema File As"; nameFilters: ["JSON Documents (*.json)"]; selectExisting: false; onAccepted: BackendEngine.saveAsFile(fileUrl) }

    // Picker for Profile Version Level Images
    FileDialog {
        id: imagePickerDialog
        title: "Attach Workspace Resource Images"
        nameFilters: ["Image Files (*.png *.jpg *.jpeg *.bmp)"]
        selectExisting: true; selectMultiple: true
        onAccepted: {
            var currentList = editorContainer.currentStagingImages;
            for (var i = 0; i < fileUrls.length; ++i) {
                var sandboxedUrl = BackendEngine.copyImageToUploads(fileUrls[i]);
                if (sandboxedUrl && sandboxedUrl !== "") currentList.push(sandboxedUrl);
            }
            editorContainer.currentStagingImages = [...currentList];
        }
    }

    // Picker for Description Specific Items
    FileDialog {
        id: descriptionSpecificImagePickerDialog
        property int targetChangeIndex: -1
        title: "Attach Specific Change Line Item Images"
        nameFilters: ["Image Files (*.png *.jpg *.jpeg *.bmp)"]
        selectExisting: true; selectMultiple: true
        onAccepted: {
            if(targetChangeIndex >= 0) {
                var items = editorContainer.currentStagingChanges;
                for (var i = 0; i < fileUrls.length; ++i) {
                    var sandboxedUrl = BackendEngine.copyImageToUploads(fileUrls[i]);
                    if (sandboxedUrl && sandboxedUrl !== "") {
                        items[targetChangeIndex].images.push(sandboxedUrl);
                    }
                }
                editorContainer.currentStagingChanges = [...items];
            }
        }
    }

    // Pop-up Media Viewer layout
    Rectangle {
        id: imagePopupOverlay; anchors.fill: parent; color: "#f0000000"; visible: false; z: 99999
        property var imageList: []; property int currentIndex: 0
        MouseArea { anchors.fill: parent }
        Item {
            anchors.fill: parent; anchors.margins: 30
            Button { text: "✕ Close Preview"; anchors.top: parent.top; anchors.right: parent.right; z: 10; background: Rectangle { color: "#2f3542"; radius: 4; border.color: "#747d8c" } contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; padding: 8 } onClicked: imagePopupOverlay.visible = false }
            RowLayout {
                anchors.fill: parent; anchors.topMargin: 60; spacing: 20
                Button { text: "◀"; Layout.preferredWidth: 55; Layout.preferredHeight: 55; visible: imagePopupOverlay.currentIndex > 0; background: Rectangle { color: "#2f3542"; radius: 28; border.color: "#747d8c"; opacity: parent.hovered ? 1.0 : 0.7 } contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } onClicked: if (imagePopupOverlay.currentIndex > 0) imagePopupOverlay.currentIndex-- }
                Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"; clip: true; Image { anchors.fill: parent; source: (imagePopupOverlay.imageList && imagePopupOverlay.imageList.length > imagePopupOverlay.currentIndex) ? imagePopupOverlay.imageList[imagePopupOverlay.currentIndex] : ""; fillMode: Image.PreserveAspectFit } }
                Button { text: "▶"; Layout.preferredWidth: 55; Layout.preferredHeight: 55; visible: imagePopupOverlay.currentIndex < (imagePopupOverlay.imageList.length - 1); background: Rectangle { color: "#2f3542"; radius: 28; border.color: "#747d8c"; opacity: parent.hovered ? 1.0 : 0.7 } contentItem: Text { text: parent.text; color: "#ffffff"; font.bold: true; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } onClicked: if (imagePopupOverlay.currentIndex < imagePopupOverlay.imageList.length - 1) imagePopupOverlay.currentIndex++ }
            }
        }
    }
}
