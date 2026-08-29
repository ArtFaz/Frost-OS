import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

// Emoji picker on the donor geometry: 400x500 card, 44px cells with no grid
// spacing (the gutter is optical, inside the cell), eight columns. Selection is
// fill only — no side bar, unlike the clipboard list.
Item {
    id: root

    property bool active: false
    property int hostWidth: 0
    property int hostHeight: 0

    property var catalog: []
    property string filterText: ""
    property int selectedIndex: 0

    readonly property int cardPadding: Style.panelPadding
    readonly property int headerHeight: Style.compactHeaderHeight
    readonly property int sectionSpacing: 6
    readonly property int cellSize: 44
    readonly property int columns: Math.max(1, Math.floor((root.width - root.cardPadding * 2) / root.cellSize))
    readonly property var visibleEmojis: root.filteredEmojis()

    width: Math.min(Style.emojiWidth, root.hostWidth - 10)
    height: Math.min(Style.emojiHeight, root.hostHeight - 10)
    visible: root.active

    function filteredEmojis() {
        const query = root.filterText.trim().toLowerCase();
        const source = root.catalog;
        const matched = [];

        for (let i = 0; i < source.length && matched.length < 1000; i += 1) {
            const item = source[i];
            if (query === "" || String(item.k || "").indexOf(query) >= 0)
                matched.push(item);
        }

        return matched;
    }

    function select(delta, wrap) {
        const count = root.visibleEmojis.length;
        if (count === 0)
            return;

        const next = root.selectedIndex + delta;
        root.selectedIndex = wrap ? ((next % count) + count) % count : Math.max(0, Math.min(count - 1, next));
        emojiGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    function insertSelected() {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.visibleEmojis.length)
            return;

        Quickshell.clipboardText = String(root.visibleEmojis[root.selectedIndex].e || "");
        Surfaces.close();
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
    }

    onActiveChanged: {
        if (!root.active)
            return;

        root.filterText = "";
        root.selectedIndex = 0;
        keyCatcher.forceActiveFocus();
    }

    FileView {
        id: catalogFile

        path: Config.sourceRoot !== "" ? Config.sourceRoot + "/config/data/emojis.json"
                                       : "/usr/share/frost/config/data/emojis.json"
        preload: true
        printErrors: false
        onLoaded: {
            try {
                const parsed = JSON.parse(catalogFile.text());
                root.catalog = Array.isArray(parsed) ? parsed : [];
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
            // Horizontal wraps, vertical clamps — the donor is asymmetric here.
            if (event.key === Qt.Key_Left) {
                root.select(-1, true);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Right) {
                root.select(1, true);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Up) {
                root.select(-root.columns, false);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Down) {
                root.select(root.columns, false);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageUp) {
                root.select(-root.columns * emojiGrid.visibleRows, false);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageDown) {
                root.select(root.columns * emojiGrid.visibleRows, false);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.insertSelected();
                event.accepted = true;
                return;
            }
            if (event.text.length === 1 && event.text.charCodeAt(0) >= 0x20 && event.text.charCodeAt(0) !== 0x7f
                && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                root.filterText += event.text;
                root.selectedIndex = 0;
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
                    placeholder: "Search emojis…"
                    glyph: "󰍉"
                }

                Item {
                    width: parent.width
                    height: parent.height - root.headerHeight - root.sectionSpacing

                    GridView {
                        id: emojiGrid

                        readonly property int visibleRows: Math.max(1, Math.floor(height / root.cellSize))

                        anchors.fill: parent
                        cellWidth: root.cellSize
                        cellHeight: root.cellSize
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.visibleEmojis

                        delegate: Rectangle {
                            id: emojiCell

                            required property var modelData
                            required property int index

                            width: root.cellSize
                            height: root.cellSize
                            radius: Style.rowRadius
                            color: root.selectedIndex === emojiCell.index ? Theme.selected : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: String(emojiCell.modelData.e || "")
                                font.family: Style.emojiFontFamily
                                font.pixelSize: Style.display
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onContainsMouseChanged: {
                                    if (containsMouse)
                                        root.selectedIndex = emojiCell.index;
                                }
                                onClicked: {
                                    root.selectedIndex = emojiCell.index;
                                    root.insertSelected();
                                }
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.visibleEmojis.length === 0

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
                    text: "No matches for “" + root.filterText + "”"
                    color: Theme.foreground
                    opacity: 0.7
                    font.family: Style.fontFamily
                    font.pixelSize: Style.title
                }
            }
        }
    }
}
