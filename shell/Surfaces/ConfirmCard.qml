import QtQuick
import QtQuick.Layouts
import qs.Core

// Confirmation for a destructive session action. Presentation only: it emits
// confirmed/canceled and the caller decides what that means.
Item {
    id: root

    property bool opened: false
    property string message: ""
    property string confirmLabel: ""
    property int selectedIndex: 1

    readonly property int cardPadding: 18
    readonly property int messageGap: 20
    readonly property int buttonGap: 10
    readonly property int buttonHeight: 38

    signal confirmed
    signal canceled

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            root.canceled();
            return true;
        }
        // All four keys do the same flip; there is no directional semantics.
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
            || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.selectedIndex = root.selectedIndex === 0 ? 1 : 0;
            return true;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.selectedIndex === 1)
                root.confirmed();
            else
                root.canceled();
            return true;
        }
        return false;
    }

    // The destructive button is preselected, matching the donor.
    onOpenedChanged: {
        if (root.opened)
            root.selectedIndex = 1;
    }

    implicitWidth: 370
    implicitHeight: root.cardPadding * 2 + messageText.implicitHeight + root.messageGap + root.buttonHeight
    visible: root.opened || opacity > 0
    enabled: root.opened
    opacity: root.opened ? 1 : 0
    scale: root.opened ? 1 : 0.98

    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    // Descends from above — the opposite of the OSD and the launcher card.
    transform: Translate {
        y: root.opened ? 0 : -6

        Behavior on y {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: Theme.cardBackground

        // Swallow clicks so they never reach the dismiss layer behind.
        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: messageText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.cardPadding
            text: root.message
            color: Theme.foreground
            wrapMode: Text.WordWrap
            font.family: Style.fontFamily
            font.pixelSize: Style.title
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.cardPadding
            height: root.buttonHeight
            spacing: root.buttonGap

            Repeater {
                model: [{"index": 0, "label": "Cancel", "destructive": false},
                        {"index": 1, "label": root.confirmLabel, "destructive": true}]

                Rectangle {
                    id: button

                    required property var modelData

                    readonly property color stateColor: button.modelData.destructive ? Theme.urgent : Theme.foreground
                    readonly property bool current: root.selectedIndex === button.modelData.index

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.buttonHeight
                    radius: Style.controlRadius
                    color: buttonMouse.pressed ? Theme.alpha(button.stateColor, 0.18)
                                               : (button.current ? Theme.alpha(button.stateColor, 0.14)
                                                                 : Theme.alpha(button.stateColor, 0.04))
                    border.width: button.current ? Style.focusWidth : 0
                    border.color: Theme.alpha(Theme.accent, 0.20)

                    Behavior on color {
                        ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: button.modelData.label
                        color: button.stateColor
                        font.family: Style.fontFamily
                        font.pixelSize: Style.caption
                        font.weight: button.current ? Font.Medium : Font.Normal
                    }

                    MouseArea {
                        id: buttonMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = button.modelData.index
                        onClicked: {
                            if (button.modelData.destructive)
                                root.confirmed();
                            else
                                root.canceled();
                        }
                    }
                }
            }
        }
    }
}
