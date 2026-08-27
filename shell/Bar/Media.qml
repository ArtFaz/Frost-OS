import QtQuick
import qs.Core
import qs.Primitives

InteractiveSurface {
    id: root

    readonly property var player: SystemState.activePlayer

    signal surfaceRequested(string surface)

    visible: player !== null
    width: visible ? Math.min(230, mediaRow.implicitWidth + 18) : 0
    height: Theme.barHeight - 8
    radius: Theme.barHoverRadius
    onActivated: {
        if (player && player.canTogglePlaying)
            player.togglePlaying();

    }

    Row {
        id: mediaRow

        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.player && root.player.isPlaying ? "Ⅱ" : "▶"
            color: Theme.accent
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(180, implicitWidth)
            text: root.player ? (root.player.trackTitle || root.player.identity || "Media") : ""
            color: Theme.foreground
            font.family: "sans-serif"
            font.pixelSize: 12
            elide: Text.ElideRight
        }

    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.surfaceRequested("control-center")
    }

}
