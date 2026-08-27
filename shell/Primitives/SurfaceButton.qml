import QtQuick
import Quickshell.Widgets
import qs.Core

InteractiveSurface {
    id: root

    property string iconText: ""
    property string iconSource: ""
    property string title: ""
    property string subtitle: ""
    property string trailingText: ""
    property bool compact: false

    implicitHeight: compact ? Style.compactHeaderHeight : Style.rowHeight

    Item {
        id: iconSlot

        anchors.left: parent.left
        anchors.leftMargin: root.compact ? 10 : 12
        anchors.verticalCenter: parent.verticalCenter
        width: root.iconText || root.iconSource ? (root.compact ? 18 : 26) : 0
        height: width
        visible: width > 0

        Text {
            anchors.centerIn: parent
            visible: root.iconSource === ""
            text: root.iconText
            color: root.selected ? Theme.accent : Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: root.compact ? Style.body : Style.iconLarge
            horizontalAlignment: Text.AlignHCenter
        }

        IconImage {
            anchors.fill: parent
            visible: root.iconSource !== ""
            source: root.iconSource
        }

    }

    Column {
        anchors.left: iconSlot.visible ? iconSlot.right : parent.left
        anchors.leftMargin: iconSlot.visible ? 10 : 12
        anchors.right: trailing.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            color: Theme.foreground
            font.family: Style.fontFamily
            font.pixelSize: root.compact ? Style.bodySmall : Style.body
            font.bold: !root.compact
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: !root.compact && root.subtitle !== ""
            text: root.subtitle
            color: Theme.muted
            font.family: Style.fontFamily
            font.pixelSize: Style.bodySmall
            elide: Text.ElideRight
        }

    }

    Text {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: implicitWidth
        text: root.trailingText
        color: root.selected ? Theme.accent : Theme.muted
        font.family: Style.fontFamily
        font.pixelSize: Style.bodySmall
    }

}
