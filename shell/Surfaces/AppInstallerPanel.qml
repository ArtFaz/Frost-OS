import "InstallerModel.js" as InstallerModel
import QtQuick
import Quickshell.Io
import qs.Core
import qs.Primitives

Item {
    id: root

    property var items: []
    property var selected: ({
    })
    property string filterText: ""
    property bool reviewing: false
    readonly property var filteredItems: items.filter((item) => {
        return !filterText || (item.name + " " + item.summary + " " + item.category).toLowerCase().indexOf(filterText.toLowerCase()) >= 0;
    })
    readonly property var plan: InstallerModel.planFor(items, selected)

    signal backRequested()

    function toggleItem(id) {
        const next = Object.assign({
        }, selected);
        next[id] = !next[id];
        selected = next;
    }

    FileView {
        path: "/usr/share/frost/config/data/app-inventory.json"
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                root.items = InstallerModel.validateInventory(JSON.parse(text()));
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
            title: root.reviewing ? "Installation plan" : "Applications"
            subtitle: root.reviewing ? root.plan.packages.length + " selected · no changes will be applied" : "Build a typed Frost application plan"
            showBack: true
            actionText: root.reviewing ? "Edit" : "Review"
            onBack: root.reviewing ? root.reviewing = false : root.backRequested()
            onAction: root.reviewing = !root.reviewing
        }

        SearchField {
            visible: !root.reviewing
            width: parent.width
            placeholderText: "Search application catalog"
            onTextChanged: root.filterText = text
        }

        Row {
            visible: root.reviewing
            width: parent.width
            spacing: 8

            Repeater {
                model: [{
                    "label": "Arch",
                    "count": root.plan.counts.arch
                }, {
                    "label": "Frost",
                    "count": root.plan.counts.frost
                }, {
                    "label": "AUR",
                    "count": root.plan.counts.aur
                }]

                Rectangle {
                    required property var modelData

                    width: (root.width - Theme.panelPadding * 2 - 16) / 3
                    height: 62
                    radius: Theme.rowRadius
                    color: Theme.controlNormal

                    Column {
                        anchors.centerIn: parent

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.count
                            color: Theme.accent
                            font.family: Style.fontFamily
                            font.pixelSize: Style.display
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: Theme.muted
                            font.family: Style.fontFamily
                            font.pixelSize: Style.bodySmall
                        }

                    }

                }

            }

        }

        ListView {
            width: parent.width
            height: parent.height - y - footer.height - 8
            clip: true
            spacing: 4
            model: root.reviewing ? root.plan.packages : root.filteredItems

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: root.reviewing ? "No applications selected" : "No catalog entries found"
                color: Theme.muted
                font.family: Style.fontFamily
                font.pixelSize: Style.body
            }

            delegate: SurfaceButton {
                required property var modelData

                width: ListView.view.width
                title: root.reviewing ? modelData.package : modelData.name
                subtitle: root.reviewing ? "Source: " + modelData.source.toUpperCase() : modelData.summary + " · " + modelData.category
                trailingText: root.reviewing ? modelData.source.toUpperCase() : root.selected[modelData.id] ? "Selected" : modelData.source.toUpperCase()
                selected: !root.reviewing && root.selected[modelData.id] === true
                onActivated: {
                    if (!root.reviewing)
                        root.toggleItem(modelData.id);

                }
            }

        }

        Rectangle {
            id: footer

            width: parent.width
            height: 46
            radius: Theme.rowRadius
            color: root.reviewing && root.plan.packages.length > 0 ? Theme.selected : Theme.controlNormal

            Text {
                anchors.centerIn: parent
                text: root.reviewing ? "Application is disabled until the Phase 6 backend" : root.plan.packages.length + " applications selected"
                color: root.reviewing ? Theme.foreground : Theme.muted
                font.family: Style.fontFamily
                font.pixelSize: Style.bodySmall
                font.bold: root.reviewing
            }

        }

    }

}
