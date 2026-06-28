import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

Rectangle {
    id: editorContainer
    color: "#11111b" // Deep canvas backdrop

    property string workingMode: "CREATE"
    property int selectionPointerIndex: -1
    property var currentStagingChanges: []

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
    }

    function clearFormInput() {
        workingMode = "CREATE";
        selectionPointerIndex = -1;
        txtVersion.text = "";
        txtDate.text = BackendEngine.getSystemDateString();
        currentStagingChanges = [];
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

        // Dark Upper Context Operations Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#1e1e2e"
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 12

                Button {
                    text: "🆕 New Profile"
                    flat: true
                    contentItem: Text { text: parent.text; color: "#cdd6f4" }
                    onClicked: { BackendEngine.resetWorkspace(); editorContainer.clearFormInput(); editorContainer.refreshVectorList(); }
                }
                Button {
                    text: "📁 Load File"
                    flat: true
                    contentItem: Text { text: parent.text; color: "#cdd6f4" }
                    onClicked: openDialog.open()
                }
                Button {
                    text: "💾 Write Save"
                    highlighted: BackendEngine.isDirty
                    background: Rectangle {
                        color: BackendEngine.isDirty ? "#2ed573" : "#313244"
                        radius: 4
                        opacity: BackendEngine.isDirty ? 0.2 : 1.0
                    }
                    contentItem: Text { text: parent.text; color: BackendEngine.isDirty ? "#2ed573" : "#cdd6f4"; font.bold: BackendEngine.isDirty }
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
                    contentItem: Text { text: parent.text; color: "#cdd6f4" }
                    onClicked: saveAsDialog.open()
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Target Workspace: " + (BackendEngine.currentFilePath || "Unsaved Buffer Instance")
                    font.italic: true
                    color: "#7f849c"
                    font.pixelSize: 12
                }
            }
        }

        // Workspace Working Split Layout
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Left Layout Input Form Control Side
            Rectangle {
                SplitView.minimumWidth: 440
                SplitView.preferredWidth: 480
                color: "#1e1e2e"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Text {
                        text: workingMode === "CREATE" ? "➕ Add Document Version" : "📝 Modify Version Node"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#b4befe"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        TextField {
                            id: txtVersion
                            placeholderText: "Version (e.g. 1.0.4)"
                            color: "#cdd6f4"
                            placeholderTextColor: "#6c7086"
                            Layout.fillWidth: true
                            background: Rectangle { color: "#11111b"; border.color: parent.activeFocus ? "#b4befe" : "#313244"; radius: 4 }
                        }
                        TextField {
                            id: txtDate
                            placeholderText: "Date (YYYY-MM-DD)"
                            text: BackendEngine.getSystemDateString()
                            color: "#cdd6f4"
                            placeholderTextColor: "#6c7086"
                            Layout.preferredWidth: 140
                            background: Rectangle { color: "#11111b"; border.color: parent.activeFocus ? "#b4befe" : "#313244"; radius: 4 }
                        }
                    }

                    Text { text: "Manage Changes Staging Stack (" + currentStagingChanges.length + ")"; font.bold: true; font.pixelSize: 11; color: "#a6adc8" }

                    // Interactive Staging Container Panel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#11111b"
                        border.color: "#313244"
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
                                color: "#181825"
                                radius: 4
                                border.color: "#313244"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    Text { text: "•"; font.bold: true; color: "#b4befe"; font.pixelSize: 14 }

                                    TextField {
                                        text: modelData
                                        Layout.fillWidth: true
                                        font.pixelSize: 13
                                        color: "#cdd6f4"
                                        selectByMouse: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: parent.activeFocus ? "#b4befe" : "transparent"
                                            border.width: 1
                                        }

                                        onAccepted: {
                                            modifyItemInBuffer(index, text)
                                            focus = false
                                        }
                                        onEditingFinished: modifyItemInBuffer(index, text)
                                    }

                                    Button {
                                        text: "✕"
                                        flat: true
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        contentItem: Text { text: "✕"; color: "#f38ba8"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                        onClicked: removeItemFromBuffer(index)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "No active changes pushed into this node yet."
                            anchors.centerIn: parent
                            color: "#585b70"
                            visible: currentStagingChanges.length === 0
                            font.italic: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: txtItemEntry
                            placeholderText: "Type bullet description here..."
                            color: "#cdd6f4"
                            placeholderTextColor: "#6c7086"
                            Layout.fillWidth: true
                            background: Rectangle { color: "#11111b"; border.color: parent.activeFocus ? "#b4befe" : "#313244"; radius: 4 }
                            onAccepted: editorContainer.appendItemToBuffer()
                        }
                        Button {
                            text: "➕ Push"
                            background: Rectangle { color: "#313244"; radius: 4 }
                            contentItem: Text { text: parent.text; color: "#cdd6f4"; font.bold: true }
                            onClicked: editorContainer.appendItemToBuffer()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Button {
                            text: "Clear Fields"
                            Layout.fillWidth: true
                            background: Rectangle { color: "#313244"; radius: 4 }
                            contentItem: Text { text: parent.text; color: "#cdd6f4" }
                            onClicked: editorContainer.clearFormInput()
                        }
                        Button {
                            text: workingMode === "CREATE" ? "Inject Version Node" : "Modify Node Vector"
                            Layout.fillWidth: true
                            enabled: txtVersion.text.trim() !== "" && currentStagingChanges.length > 0
                            background: Rectangle {
                                color: parent.enabled ? "#b4befe" : "#181825"
                                radius: 4
                            }
                            contentItem: Text {
                                text: parent.text;
                                color: parent.enabled ? "#11111b" : "#585b70";
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            onClicked: {
                                var compositeString = currentStagingChanges.join("\n");
                                if (workingMode === "CREATE") {
                                    BackendEngine.appendVersionEntry(txtVersion.text, txtDate.text, compositeString);
                                } else {
                                    BackendEngine.commitVersionEntry(selectionPointerIndex, txtVersion.text, txtDate.text, compositeString);
                                }
                                editorContainer.clearFormInput();
                                editorContainer.refreshVectorList();
                            }
                        }
                    }
                }
            }

            // Right Array Mirror Preview Panel (Dark Vector Cards Stack)
            Rectangle {
                SplitView.minimumWidth: 400
                color: "#11111b"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "📋 Local Memory Nodes Vector (" + BackendEngine.totalVersions + ")"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#cdd6f4"
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "🗑️ Delete All Nodes"
                            flat: true
                            contentItem: Text {
                                text: parent.text
                                color: BackendEngine.totalVersions > 0 ? "#f38ba8" : "#45475a"
                                font.bold: true
                                font.pixelSize: 12
                            }
                            enabled: BackendEngine.totalVersions > 0
                            onClicked: {
                                BackendEngine.resetWorkspace();
                                editorContainer.clearFormInput();
                                editorContainer.refreshVectorList();
                            }
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
                            width: localMemoryNodesListView.width
                            implicitHeight: innerColumnLayout.height + 20
                            color: "#1e1e2e"
                            radius: 6
                            border.color: selectionPointerIndex === index ? "#f9e2af" : "#313244"
                            border.width: selectionPointerIndex === index ? 2 : 1

                            ColumnLayout {
                                id: innerColumnLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 14
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Version: " + BackendEngine.fetchVersionName(index); font.bold: true; font.pixelSize: 14; color: "#cdd6f4" }
                                    Item { Layout.fillWidth: true }
                                    Text { text: BackendEngine.fetchVersionDate(index); color: "#9399b2"; font.pixelSize: 12 }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Repeater {
                                        model: BackendEngine.fetchVersionChangesJoined(index).split("\n")
                                        RowLayout {
                                            width: parent.width
                                            spacing: 6
                                            Text { text: "•"; color: "#b4befe" }
                                            Text { text: modelData; font.pixelSize: 12; color: "#a6adc8"; Layout.fillWidth: true; wrapMode: Text.Wrap }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: "Load Node"
                                        background: Rectangle { color: "#313244"; radius: 4 }
                                        contentItem: Text { text: parent.text; color: "#cdd6f4"; font.pixelSize: 11 }
                                        onClicked: editorContainer.loadActiveEntryToForm(index)
                                    }
                                    Button {
                                        text: "Delete Node"
                                        background: Rectangle { color: "#45475a"; radius: 4 }
                                        contentItem: Text { text: parent.text; color: "#f38ba8"; font.pixelSize: 11 }
                                        onClicked: {
                                            BackendEngine.removeVersionEntry(index);
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
}
