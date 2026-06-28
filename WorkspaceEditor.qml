import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

Rectangle {
    id: editorContainer
    color: "#f1f2f6"

    property string workingMode: "CREATE"
    property int selectionPointerIndex: -1

    // Tracks the live changes list as a reactive array when adding or editing a node
    property var currentStagingChanges: []

    function appendItemToBuffer() {
        var cleanInput = txtItemEntry.text.trim();
        if(cleanInput !== "") {
            var items = currentStagingChanges;
            items.push(cleanInput);
            currentStagingChanges = [...items]; // Force re-evaluation layout update
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

        // File Management Context Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#ffffff"
            border.color: "#dcdde1"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15

                Button { text: "🆕 New Profile"; onClicked: { BackendEngine.resetWorkspace(); editorContainer.clearFormInput(); } flat: true }
                Button { text: "📁 Load File"; onClicked: openDialog.open(); flat: true }
                Button {
                    text: "💾 Write Save"
                    highlighted: BackendEngine.isDirty
                    onClicked: {
                        if (BackendEngine.currentFilePath === "") {
                            saveAsDialog.open()
                        } else {
                            BackendEngine.saveToFile()
                        }
                    }
                }
                Button { text: "💾 Save File As..."; onClicked: saveAsDialog.open(); flat: true }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Target Workspace: " + (BackendEngine.currentFilePath || "Unsaved Buffer Instance")
                    font.italic: true
                    color: "#57606f"
                }
            }
        }

        // Workspace Working Split Layout
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Left Layout Input Controller
            Rectangle {
                SplitView.minimumWidth: 440
                SplitView.preferredWidth: 480
                color: "#ffffff"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Text {
                        text: workingMode === "CREATE" ? "➕ Add Document Version" : "📝 Modify Version Node"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#2f3542"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        TextField {
                            id: txtVersion
                            placeholderText: "Version (e.g. 1.0.4)"
                            Layout.fillWidth: true
                        }
                        TextField {
                            id: txtDate
                            placeholderText: "Date (YYYY-MM-DD)"
                            text: BackendEngine.getSystemDateString()
                            Layout.preferredWidth: 140
                        }
                    }

                    Text { text: "Manage Changes Staging Stack (" + currentStagingChanges.length + ")"; font.bold: true; font.pixelSize: 11; color: "#747d8c" }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#f8f9fa"
                        border.color: "#ced6e0"
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
                                height: 36
                                color: "white"
                                radius: 4
                                border.color: "#e2e8f0"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text { text: "•"; font.bold: true; color: "#3498db" }

                                    TextField {
                                        text: modelData
                                        Layout.fillWidth: true
                                        font.pixelSize: 13
                                        color: "#2c3e50"
                                        selectByMouse: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: parent.activeFocus ? "#3498db" : "transparent"
                                            border.width: 1
                                        }

                                        // Applies modifications when Enter/Return key is clicked
                                        onAccepted: {
                                            modifyItemInBuffer(index, text)
                                            focus = false // Release keyboard focus after entering
                                        }
                                        // Also falls back to saving changes if clicking completely outside the element
                                        onEditingFinished: modifyItemInBuffer(index, text)
                                    }

                                    Button {
                                        text: "✕"
                                        flat: true
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        contentItem: Text { text: "✕"; color: "#ff4757"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                        onClicked: removeItemFromBuffer(index)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "No active changes pushed into this node yet."
                            anchors.centerIn: parent
                            color: "#a4b0be"
                            visible: currentStagingChanges.length === 0
                            font.italic: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: txtItemEntry
                            placeholderText: "Type description & press Enter or Push..."
                            Layout.fillWidth: true
                            onAccepted: editorContainer.appendItemToBuffer()
                        }
                        Button {
                            text: "➕ Push"
                            onClicked: editorContainer.appendItemToBuffer()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Button {
                            text: "Clear Fields"
                            Layout.fillWidth: true
                            onClicked: editorContainer.clearFormInput()
                        }
                        Button {
                            text: workingMode === "CREATE" ? "Inject Version Node" : "Modify Node Vector"
                            Layout.fillWidth: true
                            highlighted: true
                            enabled: txtVersion.text.trim() !== "" && currentStagingChanges.length > 0
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

            // Right Array Mirror Preview Panel
            Rectangle {
                SplitView.minimumWidth: 400
                color: "#f8f9fa"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20

                    Text {
                        text: "📋 Local Memory Nodes Vector (" + BackendEngine.totalVersions + ")"
                        font.pixelSize: 14
                        font.bold: true
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
                            color: "#ffffff"
                            radius: 6
                            border.color: "#e1b12c"
                            border.width: selectionPointerIndex === index ? 2 : 1

                            ColumnLayout {
                                id: innerColumnLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Version: " + BackendEngine.fetchVersionName(index); font.bold: true; font.pixelSize: 14 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: BackendEngine.fetchVersionDate(index); color: "#7f8c8d" }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#f1f2f6" }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Repeater {
                                        model: BackendEngine.fetchVersionChangesJoined(index).split("\n")
                                        RowLayout {
                                            width: parent.width
                                            spacing: 6
                                            Text { text: "•"; color: "#7f8c8d" }
                                            Text { text: modelData; font.pixelSize: 12; color: "#2c3e50"; Layout.fillWidth: true; wrapMode: Text.Wrap }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: "Load Node"
                                        onClicked: editorContainer.loadActiveEntryToForm(index)
                                    }
                                    Button {
                                        text: "Delete Node"
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

    FileDialog {
        id: openDialog
        title: "Load Schema File"
        nameFilters: ["JSON Documents (*.json)"]
        selectExisting: true
        onAccepted: {
            BackendEngine.loadFromFile(fileUrl);
            editorContainer.clearFormInput();
            editorContainer.refreshVectorList();
        }
    }

    FileDialog { id: saveAsDialog; title: "Save Schema File As"; nameFilters: ["JSON Documents (*.json)"]; selectExisting: false; onAccepted: BackendEngine.saveAsFile(fileUrl) }
}
