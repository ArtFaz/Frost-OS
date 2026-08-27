import QtQuick
import Quickshell.Networking
import qs.Core
import qs.Primitives

Item {
    id: root

    signal closeRequested()
    signal surfaceRequested(string surface)

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + Style.panelPadding * 2
        clip: true

        Column {
            id: content

            x: Style.panelPadding
            y: Style.panelPadding
            width: parent.width - Style.panelPadding * 2
            spacing: Style.space(2)

            Item {
                width: parent.width
                height: Style.compactHeaderHeight

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Control Center"
                    color: Theme.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Style.title
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SYSTEM"
                    color: Theme.muted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.caption
                    font.bold: true
                }
            }

            Rectangle {
                width: parent.width
                height: connectivity.implicitHeight + 8
                radius: Style.controlRadius
                color: Theme.controlNormal

                Column {
                    id: connectivity

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 4

                    ModuleCard {
                        width: parent.width
                        implicitHeight: Style.rowHeight
                        iconText: SystemState.connectedWifi ? "󰤨" : "󰤭"
                        title: "Network"
                        status: SystemState.networkAvailable ? SystemState.networkName : "Unavailable"
                        available: SystemState.networkAvailable
                        toggleVisible: SystemState.networkAvailable
                        toggleChecked: Networking.wifiEnabled
                        color: hovered ? Theme.controlHover : "transparent"
                        onToggleRequested: SystemState.toggleWifi()
                        onActivated: root.surfaceRequested("network")
                    }

                    ModuleCard {
                        width: parent.width
                        implicitHeight: Style.rowHeight
                        iconText: SystemState.bluetoothAdapter && SystemState.bluetoothAdapter.enabled ? "󰂯" : "󰂲"
                        title: "Bluetooth"
                        status: !SystemState.bluetoothAvailable ? "Unavailable" : SystemState.bluetoothConnectedCount > 0 ? SystemState.bluetoothConnectedCount + " connected" : SystemState.bluetoothAdapter.enabled ? "On" : "Off"
                        available: SystemState.bluetoothAvailable
                        toggleVisible: SystemState.bluetoothAvailable
                        toggleChecked: SystemState.bluetoothAdapter ? SystemState.bluetoothAdapter.enabled : false
                        color: hovered ? Theme.controlHover : "transparent"
                        onToggleRequested: SystemState.toggleBluetooth()
                        onActivated: root.surfaceRequested("bluetooth")
                    }

                    ModuleCard {
                        visible: Config.surfaces.tailscale
                        width: parent.width
                        implicitHeight: visible ? Style.rowHeight : 0
                        iconText: "󰲛"
                        title: "Tailscale"
                        status: "Optional feature"
                        color: hovered ? Theme.controlHover : "transparent"
                        onActivated: root.surfaceRequested("tailscale")
                    }
                }
            }

            ModuleCard {
                width: parent.width
                implicitHeight: Style.detailRowHeight
                iconText: SystemState.muted ? "󰝟" : "󰕾"
                title: "Audio"
                status: SystemState.audioAvailable ? (SystemState.muted ? "Muted" : Math.round(SystemState.volume * 100) + "%") : "Unavailable"
                available: SystemState.audioAvailable
                progress: SystemState.audioAvailable ? Math.min(1, SystemState.volume) : -1
                onActivated: root.surfaceRequested("audio")
            }

            ModuleCard {
                width: parent.width
                implicitHeight: Style.detailRowHeight
                iconText: "󰍹"
                title: "Display"
                status: SystemState.batteryAvailable ? SystemState.batteryPercent + "% battery" : "Brightness and monitors"
                progress: SystemState.batteryAvailable ? SystemState.batteryPercent / 100 : -1
                onActivated: root.surfaceRequested("display-power")
            }

            MediaCard {
                width: parent.width
            }

            Row {
                width: parent.width
                spacing: Style.space(2)

                ModuleCard {
                    width: (parent.width - parent.spacing) / 2
                    implicitHeight: Style.detailRowHeight
                    iconText: "󰐥"
                    title: "Power"
                    status: "Session"
                    onActivated: root.surfaceRequested("display-power")
                }

                ModuleCard {
                    visible: Config.surfaces.agents
                    width: visible ? (parent.width - parent.spacing) / 2 : 0
                    implicitHeight: Style.detailRowHeight
                    iconText: "󱚣"
                    title: "Agents"
                    status: "Optional feature"
                    onActivated: root.surfaceRequested("agents")
                }

                ModuleCard {
                    visible: !Config.surfaces.agents
                    width: visible ? (parent.width - parent.spacing) / 2 : 0
                    implicitHeight: Style.detailRowHeight
                    iconText: "󰂚"
                    title: "Notifications"
                    status: "Mako history"
                    onActivated: root.surfaceRequested("notifications")
                }
            }
        }
    }
}
