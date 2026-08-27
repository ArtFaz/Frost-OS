import QtQuick
import qs.Core

InteractiveSurface {
    id: root

    property string iconText: ""
    property string title: ""
    property string status: ""
    property real progress: -1
    property bool available: true
    property bool toggleVisible: false
    property bool toggleChecked: false

    signal toggleRequested(bool checked)

    implicitHeight: 76
    enabled: available
    color: selected ? Theme.selected : pressed ? Theme.controlPressed : hovered ? Theme.controlHover : Theme.controlNormal

    Text {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.iconText
        color: root.available ? Theme.foreground : Theme.muted
        font.pixelSize: 20
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: toggle.visible ? toggle.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: root.title
            color: Theme.foreground
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.status
            color: Theme.muted
            font.pixelSize: 11
            elide: Text.ElideRight
        }

    }

    ToggleSwitch {
        id: toggle

        visible: root.toggleVisible
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        checked: root.toggleChecked
        onToggled: (checked) => {
            return root.toggleRequested(checked);
        }
    }

    Rectangle {
        visible: root.progress >= 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 2
        radius: 1
        color: Theme.alpha(Theme.foreground, 0.12)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }

    }

}
