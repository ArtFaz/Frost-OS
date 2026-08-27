import QtQuick
import qs.Core

Rectangle {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholderText: "Search"

    signal accepted()

    function takeFocus() {
        input.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    implicitHeight: 38
    color: Theme.controlNormal
    radius: Theme.controlRadius
    border.color: input.activeFocus ? Theme.focus : Theme.border
    border.width: Theme.focusWidth

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "⌕"
        color: Theme.muted
        font.pixelSize: 16
    }

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.leftMargin: 38
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.foreground
        selectionColor: Theme.selected
        selectedTextColor: Theme.foreground
        font.family: "sans-serif"
        font.pixelSize: 13
        clip: true
        onAccepted: root.accepted()

        Text {
            anchors.fill: parent
            visible: input.text === ""
            text: root.placeholderText
            color: Theme.muted
            font: input.font
            verticalAlignment: Text.AlignVCenter
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus(Qt.MouseFocusReason)
    }

}
