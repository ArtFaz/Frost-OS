import QtQuick
import qs.Core
import qs.Primitives

InteractiveSurface {
    id: root

    signal surfaceRequested(string surface)

    width: 30
    height: Theme.barHeight - 8
    radius: Theme.barHoverRadius
    onActivated: surfaceRequested("launcher")

    Text {
        anchors.centerIn: parent
        text: "✦"
        color: Theme.accent
        font.family: "sans-serif"
        font.pixelSize: 15
        font.bold: true
    }

}
