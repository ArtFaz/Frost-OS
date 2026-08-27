import QtQuick
import qs.Core

Rectangle {
    id: root

    property bool selected: false
    readonly property alias hovered: hoverHandler.hovered
    readonly property alias pressed: tapHandler.pressed

    signal activated()

    activeFocusOnTab: enabled
    color: selected ? Theme.selected : pressed ? Theme.controlPressed : hovered ? Theme.controlHover : "transparent"
    radius: Theme.controlRadius
    opacity: enabled ? 1 : 0.42
    Keys.onEnterPressed: root.activated()
    Keys.onReturnPressed: root.activated()
    Keys.onSpacePressed: root.activated()

    FocusRing {
        anchors.fill: parent
        shown: root.activeFocus
        cornerRadius: root.radius
    }

    HoverHandler {
        id: hoverHandler

        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler

        enabled: root.enabled
        onTapped: root.activated()
    }

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
            easing.type: Motion.easing
        }

    }

}
