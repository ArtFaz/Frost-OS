import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Primitives

Item {
    id: root

    property var items: []
    property string filterText: ""
    readonly property var filteredItems: items.filter((item) => {
        return !filterText || String(item.keywords || "").toLowerCase().indexOf(filterText.toLowerCase()) >= 0 || String(item.emoji).indexOf(filterText) >= 0;
    })

    signal backRequested()
    signal closeRequested()

    onVisibleChanged: {
        if (visible)
            filterText = "";

    }

    FileView {
        path: "/usr/share/frost/config/data/emojis.json"
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                const value = JSON.parse(text());
                root.items = value.schemaVersion === 1 && Array.isArray(value.items) ? value.items : [];
            } catch (error) {
                root.items = [];
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Style.panelPadding
        spacing: Style.space(2)

        PanelHeader {
            width: parent.width
            title: "Emoji"
            subtitle: "Search and copy"
            showBack: true
            onBack: root.backRequested()
        }

        SearchField {
            width: parent.width
            placeholderText: "Search emoji"
            onTextChanged: root.filterText = text
        }

        GridView {
            width: parent.width
            height: parent.height - y
            clip: true
            cellWidth: 44
            cellHeight: 44
            model: root.filteredItems

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "No emoji found"
                color: Theme.muted
                font.family: Style.fontFamily
                font.pixelSize: Style.body
            }

            delegate: InteractiveSurface {
                required property var modelData

                width: 40
                height: 40
                radius: Theme.rowRadius
                onActivated: {
                    Quickshell.clipboardText = modelData.emoji;
                    root.closeRequested();
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData.emoji
                    font.family: Style.emojiFontFamily
                    font.pixelSize: Style.display
                }

            }

        }

    }

}
