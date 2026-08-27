import QtQuick
import qs.Core

Item {
    id: root

    property real value: 0
    property real minimum: 0
    property real maximum: 1
    property real step: 0.05

    signal moved(real value)

    function clamped(next) {
        return Math.max(minimum, Math.min(maximum, next));
    }

    function fromPosition(position) {
        return clamped(minimum + (maximum - minimum) * position / Math.max(1, width));
    }

    function adjust(delta) {
        const next = clamped(value + delta * step);
        moved(next);
    }

    implicitHeight: 28
    activeFocusOnTab: enabled
    Keys.onLeftPressed: adjust(-1)
    Keys.onRightPressed: adjust(1)

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.alpha(Theme.foreground, 0.16)

        Rectangle {
            width: parent.width * (root.value - root.minimum) / Math.max(0.001, root.maximum - root.minimum)
            height: parent.height
            radius: parent.radius
            color: Theme.accent

            Behavior on width {
                NumberAnimation {
                    duration: Motion.fast
                    easing.type: Motion.easing
                }

            }

        }

    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.width * (root.value - root.minimum) / Math.max(0.001, root.maximum - root.minimum) - width / 2))
        width: 14
        height: 14
        radius: 7
        color: Theme.foreground
        border.color: Theme.alpha(Theme.background, 0.3)
        border.width: 1
    }

    FocusRing {
        anchors.fill: parent
        shown: root.activeFocus
        cornerRadius: Theme.controlRadius
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => {
            root.forceActiveFocus(Qt.MouseFocusReason);
            root.moved(root.fromPosition(mouse.x));
        }
        onPositionChanged: (mouse) => {
            if (pressed)
                root.moved(root.fromPosition(mouse.x));

        }
    }

}
