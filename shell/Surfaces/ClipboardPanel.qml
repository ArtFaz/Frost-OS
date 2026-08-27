import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property var items: []
    property string filterText: ""
    readonly property var filteredItems: items.filter((item) => {
        return !filterText || String(item.preview || "").toLowerCase().indexOf(filterText.toLowerCase()) >= 0;
    })

    signal backRequested()
    signal closeRequested()

    onVisibleChanged: {
        if (visible) {
            filterText = "";
            ShellBackend.query("clipboard");
        }
    }

    Connections {
        function onDataReady(kind, payload) {
            if (kind === "clipboard")
                root.items = payload && payload.schemaVersion === 1 && Array.isArray(payload.items) ? payload.items : [];

        }

        target: ShellBackend
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 12

        PanelHeader {
            width: parent.width
            title: "Clipboard"
            subtitle: root.items.length + " recent text entries"
            showBack: true
            actionText: "Refresh"
            onBack: root.backRequested()
            onAction: ShellBackend.query("clipboard")
        }

        SearchField {
            width: parent.width
            placeholderText: "Filter clipboard history"
            onTextChanged: root.filterText = text
        }

        ListView {
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: 4
            model: root.filteredItems

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "Clipboard history is empty"
                color: Theme.muted
                font.pixelSize: 12
            }

            delegate: SurfaceButton {
                required property var modelData

                width: ListView.view.width
                title: String(modelData.preview || "").replace(/\s+/g, " ")
                subtitle: "Clipboard entry " + modelData.id
                trailingText: "Copy"
                onActivated: {
                    ShellBackend.action("clipboard-copy", modelData.id);
                    root.closeRequested();
                }
            }

        }

    }

}
