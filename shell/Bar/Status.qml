import QtQuick
import qs.Core
import qs.Primitives

Row {
    id: root

    signal surfaceRequested(string surface)

    spacing: 2

    InteractiveSurface {
        visible: Config.surfaces.tailscale
        width: visible ? 28 : 0
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("tailscale")

        Text {
            anchors.centerIn: parent
            text: "󰲛"
            color: Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }

    InteractiveSurface {
        visible: Config.surfaces.agents
        width: visible ? 28 : 0
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("agents")

        Text {
            anchors.centerIn: parent
            text: "󱚣"
            color: Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }

    InteractiveSurface {
        visible: SystemState.bluetoothAvailable
        width: visible ? 28 : 0
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("bluetooth")

        Text {
            anchors.centerIn: parent
            text: SystemState.bluetoothAdapter && SystemState.bluetoothAdapter.enabled ? "󰂯" : "󰂲"
            color: SystemState.bluetoothAdapter && SystemState.bluetoothAdapter.enabled ? Theme.foreground : Theme.muted
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }

    InteractiveSurface {
        width: 28
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("network")

        Text {
            anchors.centerIn: parent
            text: SystemState.wiredConnected ? "󰈀" : SystemState.connectedWifi ? "󰤨" : "󰤭"
            color: SystemState.networkName === "Offline" ? Theme.muted : Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }

    InteractiveSurface {
        width: 28
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("audio")

        Text {
            anchors.centerIn: parent
            text: SystemState.muted ? "󰝟" : SystemState.volume > 0.55 ? "󰕾" : "󰖀"
            color: SystemState.muted ? Theme.muted : Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }

    InteractiveSurface {
        width: 28
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("display-power")

        Text {
            anchors.centerIn: parent
            text: SystemState.batteryAvailable ? (SystemState.batteryPercent <= 15 ? "󰂃" : "󰁹") : "󰍹"
            color: SystemState.batteryAvailable && SystemState.batteryPercent <= 15 ? Theme.urgent : Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }

    InteractiveSurface {
        width: 28
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("display-power")

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            color: Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }

    InteractiveSurface {
        width: 28
        height: Theme.barHeight - 8
        radius: Theme.barHoverRadius
        onActivated: root.surfaceRequested("control-center")

        Text {
            anchors.centerIn: parent
            text: "󰒓"
            color: Theme.foreground
            font.family: Style.iconFontFamily
            font.pixelSize: Style.icon
        }
    }
}
