import QtQuick
import qs.Core

// The search field every full-screen surface uses. It is deliberately NOT a
// TextInput: the surface owns a key catcher and this only renders the resulting
// string, which is how the donor behaves and is why there is no caret and no
// focus ring here.
Rectangle {
    id: root

    property string text: ""
    property string placeholder: ""
    property string glyph: ""
    property real glyphOpacity: 0.72
    property real placeholderOpacity: 0.58
    property int textSize: Style.heading
    property real fillAlpha: 0.04
    property real borderAlpha: 0.20
    property int glyphLeftMargin: 8
    property int textLeftMargin: 4
    property int textRightMargin: 12

    implicitHeight: Style.compactHeaderHeight
    radius: Style.rowRadius
    color: Theme.alpha(Theme.foreground, root.fillAlpha)
    border.width: Style.borderWidth
    border.color: Theme.alpha(Theme.foreground, root.borderAlpha)

    Text {
        id: glyphLabel

        anchors.left: parent.left
        anchors.leftMargin: root.glyphLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        text: root.glyph
        color: Theme.foreground
        opacity: root.glyphOpacity
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: Style.iconFontFamily
        font.pixelSize: Style.icon
    }

    Text {
        anchors.left: glyphLabel.right
        anchors.leftMargin: root.textLeftMargin
        anchors.right: parent.right
        anchors.rightMargin: root.textRightMargin
        anchors.verticalCenter: parent.verticalCenter
        text: root.text !== "" ? root.text : root.placeholder
        color: Theme.foreground
        opacity: root.text !== "" ? 1 : root.placeholderOpacity
        elide: Text.ElideRight
        font.family: Style.fontFamily
        font.pixelSize: root.textSize
    }
}
