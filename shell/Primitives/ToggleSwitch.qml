import QtQuick
import qs.Core

Rectangle {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    function activate() {
        if (enabled)
            toggled(!checked);

    }

    implicitWidth: 42
    implicitHeight: 24
    activeFocusOnTab: enabled
    radius: height / 2
    color: checked ? Theme.accent : Theme.alpha(Theme.foreground, 0.18)
    opacity: enabled ? 1 : 0.42
    Keys.onEnterPressed: activate()
    Keys.onReturnPressed: activate()
    Keys.onSpacePressed: activate()

    Rectangle {
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 3 : 3
        radius: width / 2
        color: root.checked ? Theme.background : Theme.foreground

        Behavior on x {
            NumberAnimation {
                duration: Motion.fast
                easing.type: Motion.easing
            }

        }

    }

    FocusRing {
        anchors.fill: parent
        anchors.margins: -2
        shown: root.activeFocus
        cornerRadius: root.radius + 2
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.activate()
    }

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
            easing.type: Motion.easing
        }

    }

}
