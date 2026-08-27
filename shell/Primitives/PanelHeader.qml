import QtQuick
import qs.Core

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool showBack: false
    property string actionText: ""

    signal back()
    signal action()

    implicitHeight: subtitle ? 54 : 44

    InteractiveSurface {
        id: backButton

        visible: root.showBack
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        onActivated: root.back()

        Text {
            anchors.centerIn: parent
            text: "‹"
            color: Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.display
        }

    }

    Column {
        anchors.left: root.showBack ? backButton.right : parent.left
        anchors.leftMargin: root.showBack ? 8 : 0
        anchors.right: actionButton.visible ? actionButton.left : parent.right
        anchors.rightMargin: actionButton.visible ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: Theme.foreground
            font.family: Style.fontFamily
            font.pixelSize: Style.heading
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.muted
            font.family: Style.fontFamily
            font.pixelSize: Style.bodySmall
            elide: Text.ElideRight
        }

    }

    InteractiveSurface {
        id: actionButton

        visible: root.actionText !== ""
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: actionLabel.implicitWidth + 18
        height: 32
        onActivated: root.action()

        Text {
            id: actionLabel

            anchors.centerIn: parent
            text: root.actionText
            color: Theme.accent
            font.family: Style.fontFamily
            font.pixelSize: Style.bodySmall
            font.bold: true
        }

    }

}
