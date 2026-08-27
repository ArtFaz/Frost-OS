import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Core
import qs.Primitives

Rectangle {
    id: root

    readonly property var player: SystemState.activePlayer

    implicitHeight: player ? 116 : 70
    radius: Theme.rowRadius
    color: Theme.controlNormal
    border.color: Theme.border
    border.width: Theme.borderWidth

    IconImage {
        id: artwork

        visible: root.player !== null
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 64
        height: 64
        source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
    }

    Column {
        anchors.left: artwork.visible ? artwork.right : parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            width: parent.width
            text: root.player ? (root.player.trackTitle || root.player.identity || "Media") : "Nothing playing"
            color: Theme.foreground
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.player !== null
            text: root.player ? (root.player.trackArtist || root.player.trackAlbum || root.player.identity) : ""
            color: Theme.muted
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Row {
            visible: root.player !== null
            spacing: 8

            InteractiveSurface {
                width: 34
                height: 30
                enabled: root.player && root.player.canGoPrevious
                onActivated: root.player.previous()

                Text {
                    anchors.centerIn: parent
                    text: "‹‹"
                    color: Theme.foreground
                    font.pixelSize: 12
                }

            }

            InteractiveSurface {
                width: 42
                height: 30
                selected: root.player && root.player.isPlaying
                enabled: root.player && root.player.canTogglePlaying
                onActivated: root.player.togglePlaying()

                Text {
                    anchors.centerIn: parent
                    text: root.player && root.player.isPlaying ? "Pause" : "Play"
                    color: Theme.foreground
                    font.pixelSize: 10
                    font.bold: true
                }

            }

            InteractiveSurface {
                width: 34
                height: 30
                enabled: root.player && root.player.canGoNext
                onActivated: root.player.next()

                Text {
                    anchors.centerIn: parent
                    text: "››"
                    color: Theme.foreground
                    font.pixelSize: 12
                }

            }

        }

    }

}
