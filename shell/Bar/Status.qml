import QtQuick
import qs.Core
import qs.Primitives

Row {
    id: root

    signal surfaceRequested(string surface)

    spacing: 2

    InteractiveSurface {
        width: audioLabel.implicitWidth + 14
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("audio")

        Text {
            id: audioLabel

            anchors.centerIn: parent
            text: SystemState.muted ? "Mute" : Math.round(SystemState.volume * 100) + "%"
            color: SystemState.muted ? Theme.muted : Theme.foreground
            font.pixelSize: 11
        }

    }

    InteractiveSurface {
        width: networkLabel.implicitWidth + 14
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("network")

        Text {
            id: networkLabel

            anchors.centerIn: parent
            text: SystemState.networkName
            color: SystemState.networkName === "Offline" ? Theme.muted : Theme.foreground
            font.pixelSize: 11
            elide: Text.ElideRight
        }

    }

    InteractiveSurface {
        visible: SystemState.bluetoothAvailable
        width: visible ? bluetoothLabel.implicitWidth + 14 : 0
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("bluetooth")

        Text {
            id: bluetoothLabel

            anchors.centerIn: parent
            text: SystemState.bluetoothConnectedCount > 0 ? "BT " + SystemState.bluetoothConnectedCount : "BT"
            color: SystemState.bluetoothAdapter && SystemState.bluetoothAdapter.enabled ? Theme.foreground : Theme.muted
            font.pixelSize: 11
        }

    }

    InteractiveSurface {
        visible: SystemState.batteryAvailable
        width: visible ? batteryLabel.implicitWidth + 14 : 0
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("display-power")

        Text {
            id: batteryLabel

            anchors.centerIn: parent
            text: SystemState.batteryPercent + "%"
            color: SystemState.batteryPercent <= 15 ? Theme.urgent : Theme.foreground
            font.pixelSize: 11
        }

    }

    InteractiveSurface {
        width: 30
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("notifications")

        Text {
            anchors.centerIn: parent
            text: "•"
            color: Theme.accent
            font.pixelSize: 20
        }

    }

}
