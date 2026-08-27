import QtQuick
import Quickshell.Networking
import qs.Core
import qs.Primitives

Item {
    id: root

    property var pendingNetwork: null
    property string password: ""
    readonly property var networks: SystemState.wifiNetworks

    signal backRequested()

    function activateNetwork(network) {
        if (!network || network.stateChanging)
            return ;

        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
        } else {
            pendingNetwork = network;
            password = "";
            passwordField.takeFocus();
        }
    }

    onVisibleChanged: {
        if (SystemState.wifiDevice)
            SystemState.wifiDevice.scannerEnabled = visible && Networking.wifiEnabled;

        if (!visible) {
            pendingNetwork = null;
            password = "";
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 12

        PanelHeader {
            width: parent.width
            title: "Network"
            subtitle: SystemState.networkAvailable ? SystemState.networkName : "NetworkManager unavailable"
            showBack: true
            onBack: root.backRequested()
        }

        Rectangle {
            width: parent.width
            height: 58
            radius: Theme.rowRadius
            color: Theme.controlNormal

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "Wi-Fi"
                    color: Theme.foreground
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    text: Networking.wifiHardwareEnabled ? (Networking.wifiEnabled ? "Enabled" : "Disabled") : "Hardware blocked"
                    color: Theme.muted
                    font.pixelSize: 11
                }

            }

            ToggleSwitch {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                enabled: SystemState.networkAvailable && Networking.wifiHardwareEnabled
                checked: Networking.wifiEnabled
                onToggled: SystemState.toggleWifi()
            }

        }

        Rectangle {
            visible: root.pendingNetwork !== null
            width: parent.width
            height: visible ? 118 : 0
            radius: Theme.rowRadius
            color: Theme.selected
            border.color: Theme.border
            border.width: Theme.borderWidth

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "Password for " + (root.pendingNetwork ? root.pendingNetwork.name : "network")
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                }

                SearchField {
                    id: passwordField

                    width: parent.width
                    placeholderText: "Wi-Fi password"
                    echoMode: TextInput.Password
                    onTextChanged: root.password = text
                    onAccepted: connectButton.activated()
                }

                Row {
                    spacing: 6

                    SurfaceButton {
                        width: 82
                        compact: true
                        title: "Cancel"
                        onActivated: root.pendingNetwork = null
                    }

                    SurfaceButton {
                        id: connectButton

                        width: 90
                        compact: true
                        title: "Connect"
                        selected: true
                        enabled: root.password.length >= 8
                        onActivated: {
                            if (root.pendingNetwork) {
                                root.pendingNetwork.connectWithPsk(root.password);
                                root.pendingNetwork = null;
                                root.password = "";
                            }
                        }
                    }

                }

            }

        }

        Text {
            text: "Available networks"
            color: Theme.muted
            font.pixelSize: 11
            font.bold: true
        }

        ListView {
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: 4
            model: Networking.wifiEnabled ? root.networks : []

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: Networking.wifiEnabled ? "No Wi-Fi networks found" : "Wi-Fi is disabled"
                color: Theme.muted
                font.pixelSize: 12
            }

            delegate: SurfaceButton {
                required property var modelData

                width: ListView.view.width
                title: modelData.name || "Hidden network"
                subtitle: modelData.connected ? "Connected" : modelData.stateChanging ? ConnectionState.toString(modelData.state) : modelData.known ? "Saved" : WifiSecurityType.toString(modelData.security)
                trailingText: modelData.connected ? "Disconnect" : Math.round(modelData.signalStrength * 100) + "%"
                selected: modelData.connected
                onActivated: root.activateNetwork(modelData)
            }

        }

    }

}
