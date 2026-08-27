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
        contentHeight: content.implicitHeight + Theme.panelPadding * 2
        clip: true

        Column {
            id: content

            x: Theme.panelPadding
            y: Theme.panelPadding
            width: parent.width - Theme.panelPadding * 2
            spacing: 12

            PanelHeader {
                width: parent.width
                title: "Control Center"
                subtitle: "Frost system controls"
                actionText: "Close"
                onAction: root.closeRequested()
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                ModuleCard {
                    width: (content.width - 8) / 2
                    iconText: "Wi-Fi"
                    title: "Network"
                    status: SystemState.networkAvailable ? SystemState.networkName : "Unavailable"
                    available: SystemState.networkAvailable
                    toggleVisible: SystemState.networkAvailable
                    toggleChecked: Networking.wifiEnabled
                    onToggleRequested: SystemState.toggleWifi()
                    onActivated: root.surfaceRequested("network")
                }

                ModuleCard {
                    width: (content.width - 8) / 2
                    iconText: "BT"
                    title: "Bluetooth"
                    status: !SystemState.bluetoothAvailable ? "Unavailable" : SystemState.bluetoothConnectedCount > 0 ? SystemState.bluetoothConnectedCount + " connected" : SystemState.bluetoothAdapter.enabled ? "On" : "Off"
                    available: SystemState.bluetoothAvailable
                    toggleVisible: SystemState.bluetoothAvailable
                    toggleChecked: SystemState.bluetoothAdapter ? SystemState.bluetoothAdapter.enabled : false
                    onToggleRequested: SystemState.toggleBluetooth()
                    onActivated: root.surfaceRequested("bluetooth")
                }

                ModuleCard {
                    width: (content.width - 8) / 2
                    iconText: "Audio"
                    title: "Sound"
                    status: SystemState.audioAvailable ? (SystemState.muted ? "Muted" : Math.round(SystemState.volume * 100) + "%") : "Unavailable"
                    available: SystemState.audioAvailable
                    progress: SystemState.audioAvailable ? Math.min(1, SystemState.volume) : -1
                    onActivated: root.surfaceRequested("audio")
                }

                ModuleCard {
                    width: (content.width - 8) / 2
                    iconText: "Power"
                    title: "Display & power"
                    status: SystemState.batteryAvailable ? SystemState.batteryPercent + "% battery" : "Displays and session"
                    progress: SystemState.batteryAvailable ? SystemState.batteryPercent / 100 : -1
                    onActivated: root.surfaceRequested("display-power")
                }

            }

            MediaCard {
                width: parent.width
            }

            Text {
                text: "Tools"
                color: Theme.muted
                font.pixelSize: 11
                font.bold: true
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 6

                Repeater {
                    model: [{
                        "label": "Clipboard",
                        "detail": "Text history",
                        "surface": "clipboard",
                        "enabled": Config.surfaces.clipboard
                    }, {
                        "label": "Emoji",
                        "detail": "Search and copy",
                        "surface": "emoji",
                        "enabled": Config.surfaces.emojiPicker
                    }, {
                        "label": "Images",
                        "detail": "Recent pictures",
                        "surface": "images",
                        "enabled": Config.surfaces.imagePicker
                    }, {
                        "label": "Applications",
                        "detail": "Build an install plan",
                        "surface": "app-installer",
                        "enabled": Config.surfaces.appInstaller
                    }, {
                        "label": "Notifications",
                        "detail": "Mako history",
                        "surface": "notifications",
                        "enabled": Config.surfaces.notificationCenter
                    }]

                    SurfaceButton {
                        required property var modelData

                        visible: modelData.enabled
                        width: visible ? (content.width - 6) / 2 : 0
                        title: modelData.label
                        subtitle: modelData.detail
                        trailingText: "›"
                        onActivated: root.surfaceRequested(modelData.surface)
                    }

                }

                SurfaceButton {
                    visible: Config.surfaces.tailscale
                    width: visible ? (content.width - 6) / 2 : 0
                    title: "Tailscale"
                    subtitle: "Optional feature"
                    onActivated: root.surfaceRequested("tailscale")
                }

                SurfaceButton {
                    visible: Config.surfaces.agents
                    width: visible ? (content.width - 6) / 2 : 0
                    title: "Agents"
                    subtitle: "Optional feature"
                    onActivated: root.surfaceRequested("agents")
                }

            }

        }

    }

}
