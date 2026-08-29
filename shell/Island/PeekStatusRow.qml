import QtQuick
import QtQuick.Layouts
import qs.Core

RowLayout {
    id: root

    property int volume: 0
    property bool muted: false
    property string batteryText: ""
    property bool batteryCharging: false
    property int batteryLevel: 0
    property string statusText: ""
    property string fontFamily: Style.fontFamily
    property bool showBattery: false
    property bool showNotifications: false
    property bool showMicrophone: false
    property bool microphoneMuted: false
    property bool microphoneActive: false
    property bool notificationsDnd: false
    property int notificationCount: 0
    property bool compact: false
    // When false the row hugs its contents instead of claiming the free space,
    // so a caller can place its own controls immediately to the right.
    property bool expandStatus: true

    signal batteryRequested
    signal audioPanelRequested
    signal audioMuteRequested
    signal audioStepRequested(int steps)
    signal notificationsRequested
    signal microphoneMuteRequested

    readonly property string volumeGlyph: root.muted || root.volume <= 0 ? "volume_off" : (root.volume < 50 ? "volume_down" : "volume_up")

    Layout.fillWidth: root.expandStatus
    Layout.preferredHeight: root.compact ? 15 : 17
    spacing: root.compact ? 7 : 8

    // Audio: reflects the live sink level. Wheel adjusts it, left click opens the
    // mixer, middle and right click mute — no shell, the writes are native.
    Item {
        Layout.preferredWidth: audioRow.width
        Layout.preferredHeight: parent.height

        Row {
            id: audioRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            MIcon {
                name: root.volumeGlyph
                size: root.compact ? 12 : 13
                color: root.muted ? Theme.secondaryText : (audioMouse.containsMouse ? Theme.highlight : Theme.foreground)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.muted ? "Mudo" : root.volume + "%"
                color: root.muted ? Theme.secondaryText : Theme.foreground
                font.family: root.fontFamily
                font.pixelSize: root.compact ? 10 : 11
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: audioMouse

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    root.audioPanelRequested();
                else
                    root.audioMuteRequested();
            }
            onWheel: wheel => root.audioStepRequested(wheel.angleDelta.y)
        }
    }

    // Microphone: shown while something is capturing, or whenever it is muted so
    // the state is never invisible. Writes go straight to PipeWire.
    Item {
        visible: root.showMicrophone && (root.microphoneActive || root.microphoneMuted)
        Layout.preferredWidth: micRow.width
        Layout.preferredHeight: parent.height

        Row {
            id: micRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            MIcon {
                name: "mic"
                size: root.compact ? 12 : 13
                color: root.microphoneMuted ? Theme.secondaryText : (root.microphoneActive ? Theme.warning : Theme.foreground)
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 9
                height: 1
                radius: 0.5
                rotation: -45
                color: Theme.secondaryText
                visible: root.microphoneMuted
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -5
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.microphoneMuteRequested()
        }
    }

    // Notifications live with Mako; this only opens Frost's viewer onto them.
    Item {
        visible: root.showNotifications
        Layout.preferredWidth: notificationsRow.width
        Layout.preferredHeight: parent.height

        Row {
            id: notificationsRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            MIcon {
                name: root.notificationsDnd ? "notifications_off" : "notifications"
                size: root.compact ? 12 : 13
                color: root.notificationsDnd ? Theme.secondaryText : (notificationsMouse.containsMouse ? Theme.highlight : Theme.foreground)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.notificationCount > 9 ? "9+" : root.notificationCount
                visible: root.notificationCount > 0
                color: Theme.foreground
                font.family: root.fontFamily
                font.pixelSize: root.compact ? 10 : 11
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: notificationsMouse

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.notificationsRequested()
        }
    }

    Item {
        Layout.fillWidth: root.expandStatus
        visible: root.expandStatus

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.statusText
            color: Theme.secondaryText
            visible: root.statusText !== ""
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: root.compact ? 10 : 11
            font.weight: Font.DemiBold
        }
    }

    Item {
        visible: root.showBattery && root.batteryLevel > 0
        Layout.preferredWidth: batteryRow.width
        Layout.preferredHeight: batteryRow.height

        Row {
            id: batteryRow

            spacing: 3

            MIcon {
                name: root.batteryCharging ? "bolt" : root.batteryLevel <= 20 ? "battery_alert" : "battery_full"
                size: root.compact ? 12 : 13
                color: root.batteryCharging ? Theme.success : root.batteryLevel <= 20 ? Theme.urgent : Theme.foreground
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.batteryLevel + "%"
                color: batteryMouse.containsMouse ? Theme.highlight : Theme.foreground
                font.family: root.fontFamily
                font.pixelSize: root.compact ? 10 : 11
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: batteryMouse

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.batteryRequested()
        }
    }
}
