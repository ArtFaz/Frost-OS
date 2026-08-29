import QtQuick
import Qt5Compat.GraphicalEffects
import qs.Core

// Image browser on the donor carousel geometry: one preview flanked by two
// slices per side. The donor uses this surface to set a wallpaper; Frost has no
// wallpaper stack, so the action here is the one the CLI actually supports —
// copying the selected image to the clipboard.
Item {
    id: root

    property bool active: false
    property int hostWidth: 0
    property int hostHeight: 0

    property var images: []
    property string filterText: ""
    property int selectedIndex: 0

    readonly property int cardPadding: Style.panelPadding
    readonly property int headerHeight: 38
    readonly property int headerSpacing: 14
    readonly property int footerHeight: 50
    readonly property int previewWidth: 720
    readonly property int previewHeight: 450
    readonly property int sliceWidth: 126
    readonly property int sliceHeight: 352
    readonly property int sliceSpacing: 12
    readonly property int itemStep: root.sliceWidth + root.sliceSpacing

    readonly property var visibleImages: root.filteredImages()
    readonly property var selectedImage: root.selectedIndex >= 0 && root.selectedIndex < root.visibleImages.length
                                         ? root.visibleImages[root.selectedIndex] : null

    width: Math.min(root.hostWidth - 80, root.previewWidth + 4 * root.itemStep + root.cardPadding * 2)
    height: Math.min(root.hostHeight - 80,
                     root.cardPadding * 2 + root.headerHeight + root.headerSpacing + root.previewHeight + root.footerHeight)
    visible: root.active && root.visibleImages.length > 0
    opacity: root.visible ? 1 : 0
    scale: root.visible ? 1 : 0.985

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    function filteredImages() {
        const query = root.filterText.trim().toLowerCase();
        const source = root.images;

        if (query === "")
            return source;

        const matched = [];
        for (let i = 0; i < source.length; i += 1) {
            if (String(source[i].name || "").toLowerCase().indexOf(query) >= 0)
                matched.push(source[i]);
        }

        return matched;
    }

    function refresh() {
        ShellBackend.query("images");
    }

    function selectAdjacent(delta) {
        const count = root.visibleImages.length;
        if (count === 0)
            return;

        root.selectedIndex = ((root.selectedIndex + delta) % count + count) % count;
    }

    function applySelected() {
        if (!root.selectedImage)
            return;

        ShellBackend.action("image-copy", String(root.selectedImage.path));
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
        root.refresh();
        keyCatcher.forceActiveFocus();
    }

    Connections {
        target: ShellBackend

        function onDataReady(kind, payload) {
            if (kind !== "images" || !payload)
                return;

            root.images = Array.isArray(payload.items) ? payload.items : [];
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
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                root.selectAdjacent(-1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.selectAdjacent(1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.applySelected();
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

            Item {
                id: header

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.cardPadding
                height: root.headerHeight

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Imagens"
                    color: Theme.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Style.title
                    font.weight: Font.DemiBold
                }

                SurfaceSearchField {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(320, parent.width * 0.45)
                    height: 36
                    text: root.filterText
                    placeholder: "Buscar imagens…"
                    glyph: "󰍉"
                    textSize: Style.body
                }
            }

            Item {
                id: carousel

                readonly property real previewSpan: Math.min(root.previewWidth, carousel.width)
                readonly property real previewX: (carousel.width - carousel.previewSpan) / 2
                readonly property int sideCount: Math.max(0, Math.min(2, Math.floor((carousel.width - carousel.previewSpan) / (2 * root.itemStep))))

                anchors.top: header.bottom
                anchors.topMargin: root.headerSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(root.previewWidth + 4 * root.itemStep, parent.width - root.cardPadding * 2)
                height: Math.min(root.previewHeight, parent.height - root.cardPadding * 2 - root.headerHeight - root.headerSpacing - root.footerHeight)
                clip: true

                Repeater {
                    model: root.visibleImages

                    Item {
                        id: tile

                        required property var modelData
                        required property int index

                        readonly property int relative: tile.index - root.selectedIndex
                        readonly property bool current: tile.relative === 0
                        readonly property bool nearby: Math.abs(tile.relative) <= carousel.sideCount

                        width: tile.current ? carousel.previewSpan : root.sliceWidth
                        height: tile.current ? carousel.height : Math.min(root.sliceHeight, carousel.height - 24)
                        y: tile.current ? 0 : (carousel.height - tile.height) / 2
                        x: tile.current ? carousel.previewX
                                        : (tile.relative < 0
                                           ? carousel.previewX + tile.relative * root.itemStep
                                           : carousel.previewX + carousel.previewSpan + root.sliceSpacing + (tile.relative - 1) * root.itemStep)
                        z: tile.current ? 100 : 50 - Math.min(Math.abs(tile.relative), 40)
                        opacity: tile.current ? 1 : 0.76
                        visible: tile.nearby

                        Behavior on x { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        // Highlight plate behind the selected tile.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -4
                            radius: Style.rowRadius + 4
                            color: Theme.alpha(Theme.accent, 0.10)
                            visible: tile.current
                        }

                        Rectangle {
                            id: letterbox

                            anchors.fill: parent
                            radius: Style.rowRadius
                            color: Theme.cardBackground
                            clip: true

                            Image {
                                id: tileImage

                                anchors.fill: parent
                                source: tile.nearby ? "file://" + tile.modelData.path : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                visible: false
                            }

                            OpacityMask {
                                anchors.fill: parent
                                source: tileImage
                                visible: tileImage.status === Image.Ready

                                maskSource: Rectangle {
                                    width: letterbox.width
                                    height: letterbox.height
                                    radius: letterbox.radius
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Theme.alpha(Theme.background, tile.current ? 0 : 0.28)
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Style.rowRadius
                            color: "transparent"
                            border.width: tile.current ? 2 : 1
                            border.color: tile.current ? Theme.accent : Theme.border
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: tile.current ? Qt.LeftButton : Qt.NoButton
                            cursorShape: tile.current ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.applySelected()
                        }
                    }
                }

                WheelHandler {
                    onWheel: wheel => root.selectAdjacent(wheel.angleDelta.y > 0 ? -1 : 1)
                }
            }

            Text {
                anchors.top: carousel.bottom
                anchors.topMargin: 12
                anchors.horizontalCenter: carousel.horizontalCenter
                width: carousel.previewSpan
                text: root.selectedImage ? String(root.selectedImage.name || "") : "No matches"
                color: Theme.foreground
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.fontFamily
                font.pixelSize: Style.subtitle
                font.weight: Font.Medium
            }
        }
    }
}
