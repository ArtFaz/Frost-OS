import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property var items: []
    property string filterText: ""
    property int selectedIndex: 0
    readonly property var filteredItems: items.filter((item) => !filterText || String(item.name || "").toLowerCase().indexOf(filterText.toLowerCase()) >= 0)
    readonly property var selectedItem: filteredItems.length > 0 ? filteredItems[Math.max(0, Math.min(selectedIndex, filteredItems.length - 1))] : null

    signal backRequested()
    signal closeRequested()

    onVisibleChanged: {
        if (visible) {
            filterText = "";
            selectedIndex = 0;
            ShellBackend.query("images");
        }
    }

    Connections {
        function onDataReady(kind, payload) {
            if (kind === "images") {
                root.items = payload && payload.schemaVersion === 1 && Array.isArray(payload.items) ? payload.items : [];
                root.selectedIndex = 0;
            }
        }
        target: ShellBackend
    }

    Column {
        anchors.fill: parent
        anchors.margins: Style.panelPadding
        spacing: Style.space(2)

        Row {
            width: parent.width
            height: Style.headerHeight
            spacing: Style.space(2)

            PanelHeader {
                width: 245
                height: parent.height
                title: "Image picker"
                subtitle: root.filteredItems.length + " recent pictures"
                showBack: true
                onBack: root.backRequested()
            }

            SearchField {
                width: parent.width - 245 - 102 - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: "Filter images"
                onTextChanged: {
                    root.filterText = text;
                    root.selectedIndex = 0;
                }
            }

            SurfaceButton {
                width: 102
                height: Style.compactHeaderHeight
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                title: "Copy image"
                enabled: root.selectedItem !== null
                onActivated: {
                    if (root.selectedItem && ShellBackend.action("image-copy", root.selectedItem.path))
                        root.closeRequested();
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - y - 96
            radius: Style.rowRadius
            color: Theme.controlNormal

            Image {
                anchors.fill: parent
                anchors.margins: Style.space(2)
                visible: root.selectedItem !== null
                source: root.selectedItem ? "file://" + encodeURI(root.selectedItem.path) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }

            Text {
                anchors.centerIn: parent
                visible: root.selectedItem === null
                text: "No supported images found"
                color: Theme.muted
                font.family: Style.fontFamily
                font.pixelSize: Style.body
            }

            Rectangle {
                visible: root.selectedItem !== null
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 32
                color: Theme.alpha(Theme.background, 0.72)

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Style.space(4)
                    text: root.selectedItem ? root.selectedItem.name : ""
                    color: Theme.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Style.bodySmall
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }
            }
        }

        ListView {
            id: thumbnailList
            width: parent.width
            height: 84
            orientation: ListView.Horizontal
            spacing: Style.space(1)
            clip: true
            model: root.filteredItems
            currentIndex: root.selectedIndex

            delegate: InteractiveSurface {
                required property var modelData
                required property int index
                width: 112
                height: 78
                selected: index === root.selectedIndex
                onActivated: root.selectedIndex = index

                Image {
                    anchors.fill: parent
                    anchors.margins: 5
                    source: "file://" + encodeURI(modelData.path)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
            }
        }
    }
}
