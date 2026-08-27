import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Core
import qs.Primitives

Item {
    id: root

    property string filterText: ""
    readonly property var applications: filteredApplications()

    signal closeRequested()
    signal surfaceRequested(string surface)

    function filteredApplications() {
        const query = filterText.trim().toLowerCase();
        const source = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        const result = [];
        for (let index = 0; index < source.length; index++) {
            const entry = source[index];
            if (!entry || entry.noDisplay)
                continue;

            const haystack = (entry.name + " " + entry.genericName + " " + entry.comment).toLowerCase();
            if (!query || haystack.indexOf(query) >= 0)
                result.push(entry);

        }
        result.sort((left, right) => {
            return String(left.name).localeCompare(String(right.name));
        });
        return result.slice(0, 120);
    }

    onVisibleChanged: {
        if (visible) {
            filterText = "";
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer

        interval: 0
        onTriggered: search.takeFocus()
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 12

        PanelHeader {
            width: parent.width
            title: "Frost"
            subtitle: "Applications and places"
            actionText: "Close"
            onAction: root.closeRequested()
        }

        SearchField {
            id: search

            width: parent.width
            placeholderText: "Search applications"
            onTextChanged: root.filterText = text
            onAccepted: {
                if (root.applications.length > 0) {
                    root.applications[0].execute();
                    root.closeRequested();
                }
            }
        }

        Row {
            width: parent.width
            spacing: 6

            Repeater {
                model: [{
                    "label": "Clipboard",
                    "surface": "clipboard"
                }, {
                    "label": "Emoji",
                    "surface": "emoji"
                }, {
                    "label": "Images",
                    "surface": "images"
                }, {
                    "label": "Install",
                    "surface": "app-installer"
                }]

                SurfaceButton {
                    required property var modelData

                    width: (root.width - Theme.panelPadding * 2 - 18) / 4
                    compact: true
                    title: modelData.label
                    onActivated: root.surfaceRequested(modelData.surface)
                }

            }

        }

        Text {
            width: parent.width
            text: root.applications.length + " applications"
            color: Theme.muted
            font.pixelSize: 11
        }

        ListView {
            id: applicationList

            width: parent.width
            height: parent.height - y
            clip: true
            spacing: 4
            model: root.applications

            delegate: SurfaceButton {
                required property var modelData

                width: applicationList.width
                iconSource: Quickshell.iconPath(modelData.icon, true)
                title: modelData.name
                subtitle: modelData.comment || modelData.genericName
                trailingText: "Open"
                onActivated: {
                    modelData.execute();
                    root.closeRequested();
                }
            }

        }

    }

}
