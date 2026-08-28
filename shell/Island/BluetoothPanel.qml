import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Core

Item {
    id: root

    property bool radioEnabled: false
    property bool discovering: false
    property var devices: []
    property string connectedDeviceName: ""
    property string statusText: ""
    property string fontFamily: Style.fontFamily
    property real morph: 0
    property int maxPanelHeight: 420

    readonly property color primaryText: Theme.foreground
    readonly property int panelPadding: 16
    readonly property int headerHeight: 32
    readonly property int sectionSpacing: 12
    readonly property int columnCount: 2
    readonly property int rowHeight: 52
    readonly property int rowSpacing: 6
    readonly property int columnSpacing: 6
    readonly property int placeholderHeight: 58
    readonly property int deviceRowCount: Math.ceil(root.devices.length / root.columnCount)
    readonly property real bodyHeight: root.radioEnabled && root.devices.length > 0 ? root.deviceRowCount * root.rowHeight + Math.max(0, root.deviceRowCount - 1) * root.rowSpacing : root.placeholderHeight
    readonly property real contentHeight: Math.min(root.maxPanelHeight, root.panelPadding * 2 + root.headerHeight + root.sectionSpacing + root.bodyHeight)
    readonly property real panelProgress: Math.max(0, Math.min(1, (root.morph - 0.22) / 0.78))

    signal closeRequested
    signal toggleRadioRequested
    signal refreshRequested
    signal deviceRequested(var device)
    signal deviceForgetRequested(var device)

    function deviceName(device) {
        return device?.name || device?.deviceName || device?.address || "Unknown device";
    }

    function deviceGlyph(device) {
        const icon = (device?.icon || "").toLowerCase();

        if (icon.indexOf("head") !== -1 || icon.indexOf("audio") !== -1)
            return "headphones";
        if (icon.indexOf("keyboard") !== -1)
            return "keyboard";
        if (icon.indexOf("mouse") !== -1 || icon.indexOf("input-gaming") !== -1)
            return "mouse";
        if (icon.indexOf("phone") !== -1)
            return "smartphone";

        return "bluetooth";
    }

    function deviceStatus(device) {
        if (device?.pairing)
            return "Pairing…";
        if (device?.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device?.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";

        let status = device?.connected ? "Connected" : ((device?.paired || device?.bonded) ? "Paired" : "Not paired");

        if (device?.batteryAvailable)
            status += "  ·  " + Math.round(device.battery * 100) + "%";

        return status;
    }

    opacity: root.panelProgress
    visible: opacity > 0.001
    scale: 0.94 + 0.06 * root.panelProgress
    transformOrigin: Item.Top

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: root.sectionSpacing

        PanelHeader {
            Layout.preferredHeight: root.headerHeight
            icon: root.discovering ? "bluetooth_searching" : (root.radioEnabled ? "bluetooth" : "bluetooth_disabled")
            iconDimmed: !root.radioEnabled
            title: "Bluetooth"
            subtitle: !root.radioEnabled ? "Desligado" : (root.connectedDeviceName !== "" ? root.connectedDeviceName : (root.discovering ? "Procurando…" : "Nenhum dispositivo"))
            subtitleHighlighted: root.connectedDeviceName !== ""
            statusText: root.statusText
            fontFamily: root.fontFamily
            onCloseRequested: root.closeRequested()

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                radius: Style.controlRadius
                visible: root.radioEnabled
                color: refreshMouse.containsMouse ? Theme.controlHover : Theme.controlNormal
                border.width: 1
                border.color: Theme.border

                MIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    size: 12
                    color: root.discovering ? Theme.accent : Theme.muted
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refreshRequested()
                }
            }

            PanelSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: root.radioEnabled
                onToggled: root.toggleRadioRequested()
            }
        }

        Flickable {
            id: deviceList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            interactive: contentHeight > height
            contentHeight: deviceGrid.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            visible: root.radioEnabled && root.devices.length > 0

            GridLayout {
                id: deviceGrid

                width: deviceList.width
                columns: root.columnCount
                columnSpacing: root.columnSpacing
                rowSpacing: root.rowSpacing

                Repeater {
                    model: root.devices

                    delegate: Rectangle {
                        id: deviceRow

                        required property var modelData
                        required property int index

                        readonly property bool busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                        readonly property real appear: Math.max(0, Math.min(1, (root.morph - Math.min(index, 6) * 0.045) / 0.55))

                        Layout.fillWidth: true
                        Layout.preferredWidth: (deviceList.width - root.columnSpacing) / root.columnCount
                        Layout.preferredHeight: root.rowHeight
                        radius: Style.rowRadius
                        color: modelData.connected ? Theme.controlNormal : (deviceMouse.containsMouse ? Theme.controlHover : "transparent")
                        border.width: 1
                        border.color: modelData.connected ? Theme.border : "transparent"
                        opacity: appear

                        transform: Translate { y: (1 - deviceRow.appear) * 12 }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 9

                            MIcon {
                                name: root.deviceGlyph(deviceRow.modelData)
                                size: 16
                                color: deviceRow.modelData.connected ? Theme.accent : Theme.foreground
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: root.deviceName(deviceRow.modelData)
                                    color: root.primaryText
                                    elide: Text.ElideRight
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.deviceStatus(deviceRow.modelData)
                                    color: deviceRow.modelData.connected ? Theme.accent : Theme.muted
                                    elide: Text.ElideRight
                                    font.family: root.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: Style.controlRadius
                                visible: (deviceRow.modelData.paired || deviceRow.modelData.bonded) && !deviceRow.busy && deviceMouse.containsMouse
                                color: forgetMouse.containsMouse ? Theme.alpha(Theme.urgent, 0.14) : "transparent"

                                MIcon {
                                    anchors.centerIn: parent
                                    name: "close"
                                    size: 12
                                    color: forgetMouse.containsMouse ? Theme.urgent : Theme.muted
                                }

                                MouseArea {
                                    id: forgetMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.deviceForgetRequested(deviceRow.modelData)
                                }
                            }

                            MIcon {
                                name: deviceRow.busy ? "hourglass_top" : (deviceRow.modelData.connected ? "link_off" : ((deviceRow.modelData.paired || deviceRow.modelData.bonded) ? "link" : "add"))
                                size: 14
                                color: deviceRow.modelData.connected ? Theme.foreground : Theme.muted
                            }
                        }

                        MouseArea {
                            id: deviceMouse

                            anchors.fill: parent
                            enabled: !deviceRow.busy
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.WaitCursor
                            onClicked: root.deviceRequested(deviceRow.modelData)
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.radioEnabled || root.devices.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 4

                MIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: root.radioEnabled ? "bluetooth_searching" : "bluetooth_disabled"
                    size: 20
                    color: Theme.muted
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: !root.radioEnabled ? "Bluetooth is off" : (root.discovering ? "Looking for devices…" : "No devices found")
                    color: Theme.muted
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.statusText !== ""
            text: root.statusText
            color: Theme.urgent
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
    }
}
