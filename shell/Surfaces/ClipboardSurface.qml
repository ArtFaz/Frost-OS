import QtQuick
import qs.Core

// Clipboard history, laid out to the donor specification: 875x600 card, split in
// half between a 50px row list and a preview pane. Static by design — the donor
// animates nothing here, and matching that is the point.
Item {
    id: root

    property bool active: false
    property int hostWidth: 0
    property int hostHeight: 0

    property var entries: []
    property string filterText: ""
    property int selectedIndex: 0
    property bool cursorActive: false

    readonly property int cardPadding: Style.panelPadding
    readonly property int headerHeight: Style.compactHeaderHeight
    readonly property int rowHeight: 50
    readonly property int sectionSpacing: 6
    readonly property var visibleEntries: root.filteredEntries()
    readonly property var selectedEntry: root.selectedIndex >= 0 && root.selectedIndex < root.visibleEntries.length
                                         ? root.visibleEntries[root.selectedIndex] : null

    width: Math.min(Style.clipboardWidth, root.hostWidth - 10)
    height: Math.min(Style.clipboardHeight, root.hostHeight - 10)
    visible: root.active

    function filteredEntries() {
        const query = root.filterText.trim().toLowerCase();
        const source = root.entries;

        if (query === "")
            return source;

        const matched = [];
        for (let i = 0; i < source.length; i += 1) {
            if (String(source[i].preview || "").toLowerCase().indexOf(query) >= 0)
                matched.push(source[i]);
        }

        return matched;
    }

    function refresh() {
        ShellBackend.query("clipboard");
    }

    function disarmPointer() {
        root.cursorActive = false;
    }

    function select(delta) {
        const count = root.visibleEntries.length;
        if (count === 0)
            return;

        root.cursorActive = true;
        root.selectedIndex = ((root.selectedIndex + delta) % count + count) % count;
        entryList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function selectAbsolute(index) {
        const count = root.visibleEntries.length;
        if (count === 0)
            return;

        root.cursorActive = true;
        root.selectedIndex = Math.max(0, Math.min(count - 1, index));
        entryList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
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

        root.selectedIndex = 0;
        root.disarmPointer();
    }

    function copySelected() {
        if (!root.selectedEntry)
            return;

        ShellBackend.action("clipboard-copy", String(root.selectedEntry.id));
        Surfaces.close();
    }

    onActiveChanged: {
        if (!root.active)
            return;

        root.filterText = "";
        root.selectedIndex = 0;
        root.cursorActive = true;
        root.refresh();
        keyCatcher.forceActiveFocus();
    }

    Connections {
        target: ShellBackend

        function onDataReady(kind, payload) {
            if (kind !== "clipboard" || !payload)
                return;

            root.entries = Array.isArray(payload.items) ? payload.items : [];
            root.selectedIndex = 0;
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
            if (event.key === Qt.Key_Up) {
                root.select(-1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Down) {
                root.select(1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageUp) {
                root.select(-6);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageDown) {
                root.select(6);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Home) {
                root.selectAbsolute(0);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_End) {
                root.selectAbsolute(root.visibleEntries.length - 1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                // The first Enter only arms the cursor, matching the donor.
                if (!root.cursorActive)
                    root.cursorActive = true;
                else
                    root.copySelected();
                event.accepted = true;
                return;
            }
            if (event.text.length === 1 && event.text.charCodeAt(0) >= 0x20 && event.text.charCodeAt(0) !== 0x7f
                && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                root.filterText += event.text;
                root.selectedIndex = 0;
                root.disarmPointer();
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
                    placeholder: "Search clipboard…"
                    glyph: "󰍉"
                }

                Item {
                    width: parent.width
                    height: parent.height - root.headerHeight - root.sectionSpacing

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            width: parent.width / 2
                            height: parent.height
                            clip: true

                            ListView {
                                id: entryList

                                anchors.fill: parent
                                anchors.rightMargin: 18
                                spacing: 4
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: root.visibleEntries

                                delegate: Rectangle {
                                    id: entryRow

                                    required property var modelData
                                    required property int index

                                    readonly property bool hasCursor: root.cursorActive && root.selectedIndex === entryRow.index

                                    width: ListView.view.width
                                    height: root.rowHeight
                                    radius: Style.rowRadius
                                    color: entryRow.hasCursor ? Theme.selected : "transparent"

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3
                                        height: root.rowHeight - 14
                                        radius: 2
                                        color: Theme.accent
                                        visible: entryRow.hasCursor
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: String(entryRow.modelData.preview || "")
                                        color: Theme.foreground
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        verticalAlignment: Text.AlignVCenter
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.title
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            root.cursorActive = true;
                                            root.selectedIndex = entryRow.index;
                                        }
                                        onClicked: {
                                            root.selectedIndex = entryRow.index;
                                            root.copySelected();
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width / 2
                            height: parent.height
                            clip: true

                            Rectangle {
                                anchors.left: parent.left
                                width: Style.borderWidth
                                height: parent.height
                                color: Theme.alpha(Theme.foreground, 0.28)
                            }

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                text: root.selectedEntry ? String(root.selectedEntry.preview || "") : ""
                                color: Theme.foreground
                                wrapMode: Text.WrapAnywhere
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop
                                font.family: Style.fontFamily
                                font.pixelSize: Style.title
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.visibleEntries.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰅌"
                    color: Theme.foreground
                    opacity: 0.8
                    font.family: Style.iconFontFamily
                    font.pixelSize: Style.displayLarge
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.entries.length === 0 ? "Clipboard is empty" : "No matches for “" + root.filterText + "”"
                    color: Theme.foreground
                    opacity: 0.7
                    font.family: Style.fontFamily
                    font.pixelSize: Style.title
                }
            }
        }
    }
}
