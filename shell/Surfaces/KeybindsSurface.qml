import QtQuick
import Quickshell.Io
import qs.Core

// Read-only keyboard-shortcut reference. The catalog is a package-owned JSON
// file authored to match default/hypr/hyprland.lua; nothing here runs a bind or
// spawns a process. Filtering is a plain substring match over the key string
// and the action label; empty groups drop out.
Item {
    id: root

    property bool active: false
    property int hostWidth: 0
    property int hostHeight: 0

    property var catalog: []
    property string filterText: ""

    readonly property int cardPadding: Style.panelPadding
    readonly property int headerHeight: Style.compactHeaderHeight
    readonly property int sectionSpacing: 6
    readonly property int rowUnit: 32
    readonly property int groupHeaderUnit: 30
    readonly property var rows: root.buildRows()

    width: Math.min(Style.keybindsWidth, root.hostWidth - 10)
    height: Math.min(Style.keybindsHeight, root.hostHeight - 10)
    visible: root.active

    function buildRows() {
        const query = root.filterText.trim().toLowerCase();
        const groups = Array.isArray(root.catalog) ? root.catalog : [];
        const out = [];

        for (let g = 0; g < groups.length; g += 1) {
            const group = groups[g];
            const items = Array.isArray(group?.items) ? group.items : [];
            const matched = [];

            for (let i = 0; i < items.length; i += 1) {
                const keys = String(items[i].keys || "");
                const action = String(items[i].action || "");
                if (query === "" || keys.toLowerCase().indexOf(query) >= 0
                    || action.toLowerCase().indexOf(query) >= 0)
                    matched.push({ "type": "item", "keys": keys, "action": action });
            }

            if (matched.length === 0)
                continue;

            out.push({ "type": "header", "title": String(group?.title || "") });
            for (let m = 0; m < matched.length; m += 1)
                out.push(matched[m]);
        }

        return out;
    }

    function scrollBy(delta) {
        const max = Math.max(0, bindList.contentHeight - bindList.height);
        bindList.contentY = Math.max(0, Math.min(max, bindList.contentY + delta));
    }

    function editFilter(mode) {
        if (root.filterText === "")
            return;

        if (mode === "clear")
            root.filterText = "";
        else if (mode === "word")
            root.filterText = root.filterText.replace(/\s*\S+\s*$/, "");
        else
            root.filterText = root.filterText.slice(0, -1);
    }

    onActiveChanged: {
        if (!root.active)
            return;

        root.filterText = "";
        bindList.contentY = 0;
        keyCatcher.forceActiveFocus();
    }

    FileView {
        id: catalogFile

        path: Config.sourceRoot !== "" ? Config.sourceRoot + "/config/data/keybinds.json"
                                       : "/usr/share/frost/config/data/keybinds.json"
        preload: true
        printErrors: false
        onLoaded: {
            try {
                const parsed = JSON.parse(catalogFile.text());
                root.catalog = Array.isArray(parsed?.groups) ? parsed.groups : [];
            } catch (error) {
                root.catalog = [];
            }
        }
    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: root.active
        Keys.priority: Keys.BeforeItem

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.filterText !== "")
                    root.filterText = "";
                else
                    Surfaces.close();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Backspace) {
                root.editFilter(event.modifiers & Qt.ControlModifier ? "word" : "character");
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
                root.editFilter("clear");
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Down) {
                root.scrollBy(root.rowUnit);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Up) {
                root.scrollBy(-root.rowUnit);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageDown) {
                root.scrollBy(bindList.height);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageUp) {
                root.scrollBy(-bindList.height);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Home) {
                bindList.contentY = 0;
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_End) {
                root.scrollBy(bindList.contentHeight);
                event.accepted = true;
                return;
            }
            if (event.text.length === 1 && event.text.charCodeAt(0) >= 0x20 && event.text.charCodeAt(0) !== 0x7f
                && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                root.filterText += event.text;
                bindList.contentY = 0;
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Theme.surfaceColor("menu")
            border.width: Style.borderWidth
            border.color: Theme.border

            Column {
                anchors.fill: parent
                anchors.margins: root.cardPadding
                spacing: root.sectionSpacing

                SurfaceSearchField {
                    width: parent.width
                    height: root.headerHeight
                    text: root.filterText
                    placeholder: "Search shortcuts…"
                    glyph: "󰍉"
                }

                Item {
                    width: parent.width
                    height: parent.height - root.headerHeight - root.sectionSpacing

                    ListView {
                        id: bindList

                        anchors.fill: parent
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.rows

                        delegate: Item {
                            id: rowItem

                            required property var modelData
                            required property int index

                            readonly property bool isHeader: rowItem.modelData.type === "header"

                            width: ListView.view.width
                            height: rowItem.isHeader ? root.groupHeaderUnit : root.rowUnit

                            Text {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 5
                                visible: rowItem.isHeader
                                text: rowItem.modelData.title || ""
                                color: Theme.secondaryText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.bodySmall
                                font.capitalization: Font.AllUppercase
                            }

                            Text {
                                id: keysLabel

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(parent.width * 0.42)
                                visible: !rowItem.isHeader
                                text: rowItem.modelData.keys || ""
                                color: Theme.foreground
                                elide: Text.ElideRight
                                font.family: Style.fontFamily
                                font.pixelSize: Style.body
                            }

                            Text {
                                anchors.left: keysLabel.right
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !rowItem.isHeader
                                text: rowItem.modelData.action || ""
                                color: Theme.secondaryText
                                elide: Text.ElideRight
                                font.family: Style.fontFamily
                                font.pixelSize: Style.body
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: root.rows.length === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰈉"
                            color: Theme.foreground
                            opacity: 0.8
                            font.family: Style.iconFontFamily
                            font.pixelSize: Style.displayLarge
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No shortcuts match “" + root.filterText + "”"
                            color: Theme.foreground
                            opacity: 0.7
                            font.family: Style.fontFamily
                            font.pixelSize: Style.title
                        }
                    }
                }
            }
        }
    }
}
