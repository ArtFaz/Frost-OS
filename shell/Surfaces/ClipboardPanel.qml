import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property var items: []
    property string filterText: ""
    property int selectedIndex: 0
    readonly property var filteredItems: items.filter((item) => !filterText || String(item.preview || "").toLowerCase().indexOf(filterText.toLowerCase()) >= 0)
    readonly property var selectedItem: filteredItems.length > 0 ? filteredItems[Math.max(0, Math.min(selectedIndex, filteredItems.length - 1))] : null

    signal backRequested()
    signal closeRequested()

    onVisibleChanged: {
        if (visible) {
            filterText = "";
            selectedIndex = 0;
            ShellBackend.query("clipboard");
        }
    }

    Connections {
        function onDataReady(kind, payload) {
            if (kind === "clipboard") {
                root.items = payload && payload.schemaVersion === 1 && Array.isArray(payload.items) ? payload.items : [];
                root.selectedIndex = 0;
            }
        }
        target: ShellBackend
    }

    Row {
        anchors.fill: parent

        Item {
            width: 350
            height: parent.height

            Column {
                anchors.fill: parent
                anchors.margins: Style.panelPadding
                spacing: Style.space(2)

                PanelHeader {
                    width: parent.width
                    title: "Clipboard"
                    subtitle: root.filteredItems.length + " recent text entries"
                    showBack: true
                    actionText: "Refresh"
                    onBack: root.backRequested()
                    onAction: ShellBackend.query("clipboard")
                }

                SearchField {
                    width: parent.width
                    placeholderText: "Filter history"
                    onTextChanged: {
                        root.filterText = text;
                        root.selectedIndex = 0;
                    }
                }

                ListView {
                    id: clipboardList
                    width: parent.width
                    height: parent.height - y
                    clip: true
                    spacing: Style.space(1)
                    model: root.filteredItems
                    currentIndex: root.selectedIndex

                    delegate: SurfaceButton {
                        required property var modelData
                        required property int index
                        width: clipboardList.width
                        title: String(modelData.preview || "").replace(/\s+/g, " ")
                        subtitle: "Entry " + modelData.id
                        trailingText: index === root.selectedIndex ? "Selected" : ""
                        selected: index === root.selectedIndex
                        onActivated: root.selectedIndex = index
                    }
                }
            }
        }

        Rectangle {
            width: 1
            height: parent.height - Style.panelPadding * 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.border
        }

        Item {
            width: parent.width - 351
            height: parent.height

            Column {
                anchors.fill: parent
                anchors.margins: Style.panelPadding
                spacing: Style.space(2)

                Item {
                    width: parent.width
                    height: Style.compactHeaderHeight

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PREVIEW"
                        color: Theme.muted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.caption
                        font.bold: true
                    }

                    SurfaceButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 86
                        height: Style.compactHeaderHeight
                        compact: true
                        title: "Copy"
                        enabled: root.selectedItem !== null
                        onActivated: {
                            if (root.selectedItem && ShellBackend.action("clipboard-copy", root.selectedItem.id))
                                root.closeRequested();
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - y
                    radius: Style.rowRadius
                    color: Theme.controlNormal

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: Style.popupPadding
                        clip: true
                        contentHeight: previewText.implicitHeight

                        Text {
                            id: previewText
                            width: parent.width
                            text: root.selectedItem ? root.selectedItem.preview : "Clipboard history is empty"
                            color: root.selectedItem ? Theme.foreground : Theme.muted
                            font.family: Style.fontFamily
                            font.pixelSize: Style.body
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }
    }
}
