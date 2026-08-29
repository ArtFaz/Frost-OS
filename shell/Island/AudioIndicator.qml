import QtQuick
import qs.Core

// Three bars that rise and fall while a player is active. Purely an activity
// tell: it reads MPRIS playback state and never touches the sink.
Item {
    id: root

    property bool active: false
    property bool playing: false
    property bool interactive: true
    property color barColor: Theme.accent
    property color idleColor: Theme.secondaryText
    property real barWidth: 3
    property real maxBarHeight: 14

    signal clicked

    implicitWidth: bars.width
    implicitHeight: root.maxBarHeight
    opacity: root.active ? 1 : 0
    visible: opacity > 0.001

    Behavior on opacity {
        NumberAnimation { duration: 180 }
    }

    Row {
        id: bars

        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: 3

            Rectangle {
                width: root.barWidth
                height: root.playing ? (root.maxBarHeight - 4 + index * 2) : root.barWidth
                radius: root.barWidth / 2
                color: root.playing ? root.barColor : root.idleColor
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on height {
                    running: root.active && root.playing
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: Math.max(root.barWidth, root.maxBarHeight * 0.35 + index * 2)
                        duration: 360 + index * 80
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: root.maxBarHeight - index * 2
                        duration: 420 + index * 80
                        easing.type: Easing.InOutSine
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        enabled: root.active && root.interactive
        onClicked: root.clicked()
    }
}
