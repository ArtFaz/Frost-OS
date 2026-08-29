import QtQuick
import Quickshell
import qs.Core

// Context menu for a background application. It renders inside the island's own
// window rather than opening a second surface, so the existing input mask stays
// the single description of where the shell accepts clicks.
Rectangle {
    id: root

    property var trayItem: null
    readonly property bool active: root.trayItem !== null

    readonly property int rowHeight: 26
    readonly property int separatorHeight: 9
    readonly property int menuPadding: 6

    signal dismissed

    function bodyHeight() {
        const entries = opener.children?.values ?? [];
        let total = 0;

        for (let i = 0; i < entries.length; i += 1)
            total += entries[i].isSeparator ? root.separatorHeight : root.rowHeight;

        return total;
    }

    width: 190
    height: Math.min(360, root.menuPadding * 2 + root.bodyHeight())
    radius: Style.rowRadius
    color: Theme.surfaceColor("menu")
    border.width: Style.borderWidth
    border.color: Theme.border
    visible: root.active && opacity > 0.001
    opacity: root.active ? 1 : 0
    scale: root.active ? 1 : 0.98

    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    QsMenuOpener {
        id: opener

        menu: root.trayItem?.menu ?? null
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.menuPadding

        Repeater {
            model: opener.children

            Item {
                id: entry

                required property var modelData

                width: parent.width
                height: entry.modelData.isSeparator ? root.separatorHeight : root.rowHeight

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: Style.borderWidth
                    color: Theme.border
                    visible: entry.modelData.isSeparator
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Style.controlRadius
                    visible: !entry.modelData.isSeparator
                    color: entryMouse.containsMouse && entry.modelData.enabled ? Theme.controlHover : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.text
                        color: Theme.foreground
                        opacity: entry.modelData.enabled ? 1 : 0.4
                        elide: Text.ElideRight
                        font.family: Style.fontFamily
                        font.pixelSize: Style.bodySmall
                    }

                    MouseArea {
                        id: entryMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: entry.modelData.enabled && !entry.modelData.hasChildren
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            entry.modelData.triggered();
                            root.dismissed();
                        }
                    }
                }
            }
        }
    }
}
