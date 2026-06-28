import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import ChangeLogManager 1.0

Rectangle {
    id: root
    color: "#f8f9fa"
    signal saved()

    function fileUrlToPath(url) {
        var urlString = url.toString()
        // Standard cleaning to completely safely handle file scheme variations across environments
        if (urlString.startsWith("file:///")) {
            if (Qt.platform.os === "windows") {
                return urlString.substring(8)
            } else {
                return urlString.substring(7)
            }
        } else if (urlString.startsWith("file://")) {
            return urlString.substring(7)
        }
        return urlString;
    }

    property string editVersion: ""
    property string editDate: ChangeLogManager.suggestDate()
    property var editChanges: []
    property string editMode: "add"
    property int editIndex: -1

    function resetForm() {
        editVersion = ""
        editDate = ChangeLogManager.suggestDate()
        editChanges = []
        editMode = "add"
        editIndex = -1
        versionInput.text = ""
        dateInput.text = editDate
        changesList.model = []
        changeInput.text = ""
    }

    function startEdit(index) {
        editMode = "edit"
        editIndex = index
        editVersion = ChangeLogManager.version(index)
        editDate = ChangeLogManager.date(index)
        editChanges = ChangeLogManager.changes(index)

        versionInput.text = editVersion
        dateInput.text = editDate
        changesList.model = [...editChanges]
        changeInput.text = ""
        versionInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#2c3e50"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Text {
                    text: "📝 Changelog Editor"
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: ChangeLogManager.modified
                    text: "● Unsaved"
                    font.pixelSize: 12
                    color: "#e74c3c"
                }

                Button {
                    text: "📂 New File"
                    flat: true
                    contentItem: Text { text: parent.text; color: "#ecf0f1"; font.pixelSize: 13 }
                    onClicked: newFileDialog.open()
                }

                Button {
                    text: "📁 Open"
                    flat: true
                    contentItem: Text { text: parent.text; color: "#ecf0f1"; font.pixelSize: 13 }
                    onClicked: openFileDialog.open()
                }

                Button {
                    text: "💾 Save"
                    enabled: ChangeLogManager.modified
                    background: Rectangle {
                        radius: 4
                        color: parent.enabled ? (parent.hovered ? "#27ae60" : "#2ecc71") : "#7f8c8d"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (ChangeLogManager.filePath === "" || ChangeLogManager.filePath === "changelog.json") {
                            saveAsDialog.open()
                        } else {
                            ChangeLogManager.save()
                            root.saved()
                        }
                    }
                }

                Button {
                    text: "💾 Save As..."
                    flat: true
                    contentItem: Text { text: parent.text; color: "#ecf0f1"; font.pixelSize: 13 }
                    onClicked: saveAsDialog.open()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#ecf0f1"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Text { text: "File:"; font.pixelSize: 12; color: "#7f8c8d"; font.bold: true }
                Text {
                    text: ChangeLogManager.filePath || "No file loaded"
                    font.pixelSize: 12
                    color: ChangeLogManager.filePath ? "#2c3e50" : "#bdc3c7"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                Text { text: ChangeLogManager.count + " versions"; font.pixelSize: 12; color: "#7f8c8d" }
            }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                SplitView.minimumWidth: 320
                SplitView.preferredWidth: 400
                color: "white"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Text {
                        text: editMode === "add" ? "➕ Add New Version" : "✏️ Edit Version"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#2c3e50"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "Version"; font.pixelSize: 12; font.bold: true; color: "#7f8c8d" }
                        TextField {
                            id: versionInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. 1.2.3"
                            font.pixelSize: 14
                            background: Rectangle {
                                radius: 6
                                border.color: versionInput.activeFocus ? "#3498db" : "#bdc3c7"
                                border.width: versionInput.activeFocus ? 2 : 1
                            }
                            onTextChanged: editVersion = text
                            color: {
                                if (text === "") return "#2c3e50"
                                var regex = /^(\d+\.)*\d+$/
                                return regex.test(text) ? "#27ae60" : "#e74c3c"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "Date"; font.pixelSize: 12; font.bold: true; color: "#7f8c8d" }
                        TextField {
                            id: dateInput
                            Layout.fillWidth: true
                            text: ChangeLogManager.suggestDate()
                            font.pixelSize: 14
                            background: Rectangle {
                                radius: 6
                                border.color: dateInput.activeFocus ? "#3498db" : "#bdc3c7"
                                border.width: dateInput.activeFocus ? 2 : 1
                            }
                            onTextChanged: editDate = text
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Changes"; font.pixelSize: 12; font.bold: true; color: "#7f8c8d" }
                            Item { Layout.fillWidth: true }
                            Text { text: changesList.count + " items"; font.pixelSize: 11; color: "#bdc3c7" }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#f8f9fa"
                            radius: 6
                            border.color: "#e0e0e0"
                            border.width: 1
                            clip: true

                            ListView {
                                id: changesList
                                anchors.fill: parent
                                anchors.margins: 4
                                model: []
                                spacing: 2

                                delegate: Rectangle {
                                    width: changesList.width - 8
                                    height: 32
                                    radius: 4
                                    color: deleteBtn.hovered ? "#fdecea" : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8

                                        Text { text: (index + 1) + "."; font.pixelSize: 12; color: "#95a5a6"; Layout.preferredWidth: 24 }
                                        Text { text: modelData; font.pixelSize: 13; color: "#2c3e50"; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text {
                                            id: deleteBtn
                                            text: "✕"
                                            font.pixelSize: 14
                                            color: deleteBtn.hovered ? "#e74c3c" : "#bdc3c7"

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                onClicked: {
                                                    var newList = []
                                                    for (var i = 0; i < changesList.model.length; ++i) {
                                                        if (i !== index) newList.push(changesList.model[i])
                                                    }
                                                    changesList.model = newList
                                                }
                                                onEntered: deleteBtn.color = "#e74c3c"
                                                onExited: deleteBtn.color = "#bdc3c7"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            TextField {
                                id: changeInput
                                Layout.fillWidth: true
                                placeholderText: "Enter a change..."
                                font.pixelSize: 13
                                background: Rectangle {
                                    radius: 6
                                    border.color: changeInput.activeFocus ? "#3498db" : "#bdc3c7"
                                    border.width: changeInput.activeFocus ? 2 : 1
                                }
                                onAccepted: addChangeBtn.clicked()
                            }
                            Button {
                                id: addChangeBtn
                                text: "+"
                                implicitWidth: 36
                                implicitHeight: 36
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2980b9" : "#3498db" }
                                contentItem: Text { text: parent.text; color: "white"; font.pixelSize: 18; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: {
                                    var text = changeInput.text.trim()
                                    if (text !== "") {
                                        changesList.model = changesList.model.concat([text])
                                        changeInput.text = ""
                                        changeInput.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            visible: editMode === "edit"
                            text: "Cancel"
                            Layout.fillWidth: true
                            background: Rectangle { radius: 6; color: parent.hovered ? "#ecf0f1" : "white"; border.color: "#bdc3c7"; border.width: 1 }
                            contentItem: Text { text: parent.text; color: "#7f8c8d"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: root.resetForm()
                        }
                        Button {
                            text: editMode === "add" ? "Add Version" : "Update Version"
                            Layout.fillWidth: true
                            enabled: versionInput.text.trim() !== "" && changesList.count > 0
                            background: Rectangle { radius: 6; color: parent.enabled ? (parent.hovered ? "#2980b9" : "#3498db") : "#bdc3c7" }
                            contentItem: Text { text: parent.text; color: "white"; font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: {
                                var changes = []
                                for (var i = 0; i < changesList.count; ++i) {
                                    changes.push(changesList.model[i])
                                }
                                if (editMode === "add") {
                                    ChangeLogManager.addVersion(versionInput.text.trim(), dateInput.text, changes)
                                } else {
                                    ChangeLogManager.updateVersion(editIndex, versionInput.text.trim(), dateInput.text, changes)
                                }
                                root.resetForm()
                            }
                        }
                    }
                }
            }

            Rectangle {
                SplitView.minimumWidth: 250
                color: "#f8f9fa"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "📋 Preview"; font.pixelSize: 16; font.bold: true; color: "#2c3e50" }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "🗑️ Clear All"
                            visible: ChangeLogManager.count > 0
                            flat: true
                            contentItem: Text { text: parent.text; color: "#e74c3c"; font.pixelSize: 12 }
                            onClicked: clearDialog.open()
                        }
                    }

                    ListView {
                        id: previewList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 12
                        model: ChangeLogManager.count

                        delegate: Rectangle {
                            width: previewList.width
                            implicitHeight: versionColumn.height + 24
                            color: "white"
                            radius: 8
                            border.color: "#e0e0e0"
                            border.width: 1

                            Column {
                                id: versionColumn
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Version " + ChangeLogManager.version(index); font.pixelSize: 14; font.bold: true; color: "#2c3e50" }
                                    Item { Layout.fillWidth: true }
                                    Text { text: ChangeLogManager.date(index); font.pixelSize: 11; color: "#95a5a6" }
                                    Text {
                                        text: "✏️"
                                        font.pixelSize: 14
                                        color: editHovered ? "#3498db" : "#bdc3c7"
                                        property bool editHovered: false
                                        MouseArea {
                                            anchors.fill: parent; anchors.margins: -4; hoverEnabled: true
                                            onClicked: root.startEdit(index)
                                            onEntered: parent.editHovered = true
                                            onExited: parent.editHovered = false
                                        }
                                    }
                                    Text {
                                        text: "🗑️"
                                        font.pixelSize: 14
                                        color: deleteHovered ? "#e74c3c" : "#bdc3c7"
                                        property bool deleteHovered: false
                                        MouseArea {
                                            anchors.fill: parent; anchors.margins: -4; hoverEnabled: true
                                            onClicked: deleteDialog.show(index)
                                            onEntered: parent.deleteHovered = true
                                            onExited: parent.deleteHovered = false
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: "#ecf0f1" }

                                Repeater {
                                    model: ChangeLogManager.changes(index)
                                    RowLayout {
                                        width: parent.width; spacing: 6
                                        Text { text: (index + 1) + "."; font.pixelSize: 12; color: "#95a5a6"; Layout.preferredWidth: 20; horizontalAlignment: Text.AlignRight }
                                        Text { text: modelData; font.pixelSize: 13; color: "#444"; Layout.fillWidth: true; wrapMode: Text.Wrap }
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
        id: newFileDialog
        title: "Create New Changelog File"
        nameFilters: ["JSON files (*.json)"]
        selectExisting: false
        onAccepted: {
            var path = root.fileUrlToPath(fileUrl)
            ChangeLogManager.createNew(path)
            root.resetForm()
        }
    }

    FileDialog {
        id: openFileDialog
        title: "Open Changelog File"
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        selectExisting: true
        onAccepted: {
            var path = root.fileUrlToPath(fileUrl)
            ChangeLogManager.filePath = path
            ChangeLogManager.load()
        }
    }

    FileDialog {
        id: saveAsDialog
        title: "Save Changelog As"
        nameFilters: ["JSON files (*.json)"]
        selectExisting: false
        onAccepted: {
            var path = root.fileUrlToPath(fileUrl)
            ChangeLogManager.saveAs(path)
            root.saved()
        }
    }

    Dialog {
        id: deleteDialog
        property int deleteIndex: -1
        function show(index) { deleteIndex = index; open() }
        title: "Delete Version"
        Label { text: "Are you sure you want to delete version \"" + ChangeLogManager.version(deleteDialog.deleteIndex) + "\"?"; wrapMode: Text.Wrap; width: parent.width }
        standardButtons: Dialog.Cancel | Dialog.Discard
        onDiscard: {
            ChangeLogManager.removeVersion(deleteDialog.deleteIndex)
            if (root.editIndex === deleteDialog.deleteIndex) { root.resetForm() }
        }
    }

    Dialog {
        id: clearDialog
        title: "Clear All"
        Label { text: "Are you sure you want to delete ALL versions?\nThis cannot be undone."; wrapMode: Text.Wrap; width: parent.width }
        standardButtons: Dialog.Cancel | Dialog.Discard
        onDiscard: { ChangeLogManager.clearAll(); root.resetForm() }
    }

    Rectangle {
        id: toast
        property string message: ""
        width: toastText.implicitWidth + 32; height: 40; radius: 20; color: "#2c3e50"; opacity: 0; y: -60; anchors.horizontalCenter: parent.horizontalCenter; z: 100
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Text { id: toastText; anchors.centerIn: parent; text: toast.message; color: "white"; font.pixelSize: 13 }
        function show(msg) { toast.message = msg; toast.opacity = 1; toast.y = 20; hideTimer.start() }
        Timer { id: hideTimer; interval: 2500; onTriggered: { toast.opacity = 0; toast.y = -60 } }
    }

    Connections {
        target: ChangeLogManager
        function onEntriesChanged() {
            root.resetForm()
            if (ChangeLogManager.count > 0 && editMode === "edit") {
                root.startEdit(0)
            }
        }
        function onSaveSuccess(path) { toast.show("✅ Saved to: " + path) }
        function onSaveError(error) { toast.show("❌ Error: " + error) }
        function onLoadError(error) { toast.show("❌ Load error: " + error) }
    }
}
