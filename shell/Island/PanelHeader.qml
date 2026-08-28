import QtQuick
import QtQuick.Layouts
import qs.Core

// Shared hero for every expanded panel: a chevron back to the peek, the domain
// glyph, the title with an optional subtitle, and a slot for the panel's own
// controls. A panel whose body already states its state passes no subtitle.
// Children declared on a PanelHeader land in that trailing slot.
RowLayout {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool subtitleHighlighted: false
    property string statusText: ""
    property bool iconDimmed: false
    property string fontFamily: Style.fontFamily

    signal closeRequested

    default property alias trailing: trailingRow.data

    Layout.fillWidth: true
    spacing: 9

    Rectangle {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter
        radius: Style.controlRadius
        color: backMouse.containsMouse ? Theme.controlHover : "transparent"

        MIcon {
            anchors.centerIn: parent
            name: "chevron_left"
            size: 13
            color: backMouse.containsMouse ? Theme.foreground : Theme.muted
        }

        MouseArea {
            id: backMouse

            anchors.fill: parent
            anchors.margins: -3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()
        }

        Behavior on color {
            ColorAnimation { duration: 140 }
        }
    }

    MIcon {
        Layout.alignment: Qt.AlignVCenter
        name: root.icon
        size: 16
        color: root.iconDimmed ? Theme.muted : Theme.foreground
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.foreground
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        Text {
            Layout.fillWidth: true
            // A failure always wins this line; otherwise it carries whatever the
            // panel cannot already show in its body.
            text: root.statusText !== "" ? root.statusText : root.subtitle
            visible: text !== ""
            color: root.statusText !== "" ? Theme.urgent : (root.subtitleHighlighted ? Theme.foreground : Theme.muted)
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    RowLayout {
        id: trailingRow

        Layout.alignment: Qt.AlignVCenter
        spacing: 7
    }
}
