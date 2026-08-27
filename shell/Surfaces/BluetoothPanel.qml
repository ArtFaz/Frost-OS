import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property bool ownsDiscovery: false

    signal backRequested()

    function activateDevice(device) {
        if (!device || device.pairing)
            return ;

        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }

    onVisibleChanged: {
        const adapter = SystemState.bluetoothAdapter;
        if (!adapter)
            return ;

        if (visible && adapter.enabled && !adapter.discovering) {
            adapter.discovering = true;
            ownsDiscovery = true;
        } else if (!visible && ownsDiscovery) {
            adapter.discovering = false;
            ownsDiscovery = false;
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 12

        PanelHeader {
            width: parent.width
            title: "Bluetooth"
            subtitle: !SystemState.bluetoothAvailable ? "No adapter" : SystemState.bluetoothConnectedCount > 0 ? SystemState.bluetoothConnectedCount + " connected" : SystemState.bluetoothAdapter.enabled ? "Discovering nearby devices" : "Disabled"
            showBack: true
            onBack: root.backRequested()
        }

        Rectangle {
            width: parent.width
            height: 58
            radius: Theme.rowRadius
            color: Theme.controlNormal

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Bluetooth"
                color: Theme.foreground
                font.pixelSize: 13
                font.bold: true
            }

            ToggleSwitch {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                enabled: SystemState.bluetoothAvailable
                checked: SystemState.bluetoothAdapter ? SystemState.bluetoothAdapter.enabled : false
                onToggled: SystemState.toggleBluetooth()
            }

        }

        Text {
            text: "Devices"
            color: Theme.muted
            font.pixelSize: 11
            font.bold: true
        }

        ListView {
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: 4
            model: SystemState.bluetoothAdapter && SystemState.bluetoothAdapter.enabled ? SystemState.bluetoothDevices : []

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: SystemState.bluetoothAvailable ? "No devices to show" : "Bluetooth is unavailable"
                color: Theme.muted
                font.pixelSize: 12
            }

            delegate: SurfaceButton {
                required property var modelData

                width: ListView.view.width
                title: modelData.name || modelData.deviceName || modelData.address
                subtitle: modelData.connected ? "Connected" : modelData.pairing ? "Pairing" : modelData.paired ? "Paired" : "Available"
                trailingText: modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : modelData.connected ? "Disconnect" : modelData.paired ? "Connect" : "Pair"
                selected: modelData.connected
                onActivated: root.activateDevice(modelData)
            }

        }

    }

}
