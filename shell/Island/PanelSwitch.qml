import QtQuick
import qs.Core

// The one switch shape the island uses. Every binary panel control goes through
// it so radio toggles, do-not-disturb and charge thresholds read identically.
Rectangle {
    id: root

    property bool checked: false
    property bool busy: false

    signal toggled

    implicitWidth: 26
    implicitHeight: 14
    radius: height / 2
    color: root.checked ? Theme.selected : Theme.controlPressed
    border.width: 1
    border.color: root.checked ? Theme.accent : Theme.border
    opacity: root.busy ? 0.5 : 1

    Behavior on color {
        ColorAnimation { duration: 180 }
    }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? parent.width - width - 2 : 2
        color: root.checked ? Theme.accent : Theme.muted

        Behavior on x {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: 180 }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.busy
        onClicked: root.toggled()
    }
}
