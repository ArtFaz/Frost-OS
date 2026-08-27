import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property var items: []
    property string filterText: ""
    readonly property var filteredItems: items.filter((item) => {
        return !filterText || String(item.name || "").toLowerCase().indexOf(filterText.toLowerCase()) >= 0;
    })

    signal backRequested()
    signal closeRequested()

    onVisibleChanged: {
        if (visible) {
            filterText = "";
            ShellBackend.query("images");
        }
    }

    Connections {
        function onDataReady(kind, payload) {
            if (kind === "images")
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
            title: "Image picker"
            subtitle: "Recent files from Pictures"
            showBack: true
            actionText: "Refresh"
            onBack: root.backRequested()
            onAction: ShellBackend.query("images")
        }

        SearchField {
            width: parent.width
            placeholderText: "Filter images"
            onTextChanged: root.filterText = text
        }

        GridView {
            width: parent.width
            height: parent.height - y
            clip: true
            cellWidth: 156
            cellHeight: 142
            model: root.filteredItems

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "No supported images found"
                color: Theme.muted
                font.pixelSize: 12
            }

            delegate: InteractiveSurface {
                required property var modelData

                width: 146
                height: 132
                radius: Theme.rowRadius
                onActivated: {
                    ShellBackend.action("image-copy", modelData.path);
                    root.closeRequested();
                }

                Image {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 6
                    height: 96
                    source: "file://" + encodeURI(modelData.path)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 7
                    text: modelData.name
                    color: Theme.foreground
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }

            }

        }

    }

}
