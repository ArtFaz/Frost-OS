import QtQuick
import qs.Core

Rectangle {
    property bool shown: false
    property real cornerRadius: Theme.controlRadius

    visible: shown
    color: "transparent"
    radius: cornerRadius
    border.color: Theme.focus
    border.width: Theme.focusWidth
    z: 1000
}
