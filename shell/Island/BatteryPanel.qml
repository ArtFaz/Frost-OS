import QtQuick
import QtQuick.Layouts
import qs.Core

Item {
    id: root

    property bool available: false
    property int level: 0
    property bool charging: false
    property real health: -1
    property int cycles: -1
    property real fullCapacityWh: -1
    property real designCapacityWh: -1
    property real voltage: -1
    property real power: -1
    property string status: ""
    property string model: ""
    property bool thresholdSupported: false
    property bool thresholdEnabled: false
    property bool thresholdBusy: false
    property int thresholdStart: -1
    property int thresholdEnd: -1
    property string thresholdStatusText: ""
    property bool profilesAvailable: false
    property var availableProfiles: []
    property string activeProfile: ""
    property bool profileBusy: false
    property string profileStatusText: ""
    property string performanceDegraded: ""
    property string performanceInhibited: ""
    property string fontFamily: Style.fontFamily
    property real morph: 0

    readonly property color primaryText: Theme.foreground
    readonly property color secondaryText: Theme.secondaryText
    readonly property int panelPadding: 16
    readonly property int headerHeight: 32
    readonly property int overviewHeight: 70
    readonly property int tileHeight: 54
    readonly property int profileHeight: 52
    readonly property int footerHeight: 12
    readonly property int sectionSpacing: 10
    readonly property int gridSpacing: 6
    readonly property real contentHeight: root.panelPadding * 2 + root.headerHeight + root.sectionSpacing + root.overviewHeight + root.sectionSpacing + root.tileHeight + root.sectionSpacing + root.profileHeight + root.sectionSpacing + root.footerHeight
    readonly property real panelProgress: Math.max(0, Math.min(1, (root.morph - 0.22) / 0.78))

    signal closeRequested
    signal toggleThresholdRequested
    signal powerProfileRequested(string profile)

    function formattedNumber(value, digits, suffix, fallback) {
        return value >= 0 && isFinite(value) ? value.toFixed(digits) + suffix : fallback;
    }

    function healthColor() {
        if (root.health < 0)
            return Theme.secondaryText;
        if (root.health >= 85)
            return Theme.success;
        if (root.health >= 70)
            return Theme.warning;
        return Theme.urgent;
    }

    function profileAvailable(profile) {
        return root.profilesAvailable && root.availableProfiles.indexOf(profile) !== -1;
    }

    function profileSubtitle() {
        if (root.profileStatusText !== "")
            return root.profileStatusText;
        if (root.profileBusy)
            return "Switching…";
        if (!root.profilesAvailable)
            return "Unavailable";
        if (root.activeProfile === "performance" && (root.performanceDegraded !== "" || root.performanceInhibited !== ""))
            return "Performance limited";

        return "System-wide";
    }

    component PowerProfileButton: Rectangle {
        id: profileButton

        required property string profileId
        required property string label

        readonly property bool profileEnabled: root.profileAvailable(profileId)
        readonly property bool selected: root.activeProfile === profileId

        Layout.fillWidth: true
        Layout.preferredHeight: 30
        radius: Style.controlRadius
        color: selected ? Theme.selected : (profileMouse.containsMouse && profileEnabled ? Theme.controlHover : Theme.controlNormal)
        border.width: 1
        border.color: selected ? Theme.accent : Theme.border
        opacity: profileEnabled ? 1 : 0.35

        Behavior on color {
            ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            text: profileButton.label
            color: Theme.foreground
            font.family: root.fontFamily
            font.pixelSize: 10
            font.weight: profileButton.selected ? Font.Bold : Font.DemiBold
        }

        MouseArea {
            id: profileMouse

            anchors.fill: parent
            enabled: profileButton.profileEnabled && !root.profileBusy && !profileButton.selected
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.powerProfileRequested(profileButton.profileId)
        }
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
            icon: root.charging ? "battery_charging_full" : (root.level <= 20 ? "battery_alert" : "battery_full")
            iconDimmed: !root.available
            title: "Bateria"
            fontFamily: root.fontFamily
            onCloseRequested: root.closeRequested()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.overviewHeight
            radius: Style.radius
            color: Theme.controlNormal
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 14

                ColumnLayout {
                    Layout.preferredWidth: 64
                    spacing: -2

                    Text {
                        text: root.level + "%"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: 24
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.status !== "" ? root.status : (root.charging ? "Charging" : "Battery")
                        color: root.charging ? Theme.success : root.secondaryText
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "Battery health"
                            color: Theme.foreground
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.health >= 0 ? root.health.toFixed(1) + "%" : "—"
                            color: root.healthColor()
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5
                        radius: height / 2
                        color: Theme.controlHover

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.health / 100))
                            height: parent.height
                            radius: height / 2
                            color: root.healthColor()

                            Behavior on width {
                                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            columnSpacing: root.gridSpacing
            rowSpacing: root.gridSpacing

            Repeater {
                model: [
                    {
                        icon: "cached",
                        label: "Cycles",
                        value: root.cycles >= 0 ? String(root.cycles) : "—"
                    },
                    {
                        icon: "battery_5_bar",
                        label: "Full capacity",
                        value: root.formattedNumber(root.fullCapacityWh, 1, " Wh", "—")
                    },
                    {
                        icon: "electric_bolt",
                        label: "Voltage",
                        value: root.formattedNumber(root.voltage, 2, " V", "—")
                    },
                    {
                        icon: "battery_saver",
                        label: root.thresholdSupported && root.thresholdStart >= 0 && root.thresholdEnd > 0 ? "Limit · " + root.thresholdStart + "→" + root.thresholdEnd : "Charge limit",
                        value: root.thresholdSupported && root.thresholdEnd > 0 ? root.thresholdEnd + "% " + (root.thresholdEnabled ? "on" : "off") : "Unsupported",
                        action: "threshold"
                    }
                ]

                delegate: Rectangle {
                    id: infoTile

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.tileHeight
                    radius: Style.rowRadius
                    color: tileMouse.containsMouse && modelData.action === "threshold" && root.thresholdSupported ? Theme.controlHover : Theme.controlNormal
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        MIcon {
                            name: modelData.icon
                            size: 15
                            color: modelData.action === "threshold" && root.thresholdEnabled ? Theme.success : Theme.secondaryText
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: root.primaryText
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: root.secondaryText
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    MouseArea {
                        id: tileMouse

                        anchors.fill: parent
                        enabled: modelData.action === "threshold" && root.thresholdSupported && !root.thresholdBusy
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.toggleThresholdRequested()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.profileHeight
            radius: Style.rowRadius
            color: Theme.controlNormal
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 9

                MIcon {
                    name: "speed"
                    size: 16
                    color: root.activeProfile === "performance" ? Theme.warning : Theme.secondaryText
                }

                ColumnLayout {
                    Layout.minimumWidth: 82
                    Layout.preferredWidth: 82
                    Layout.maximumWidth: 82
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Power mode"
                        color: root.primaryText
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.profileSubtitle()
                        color: root.profileStatusText.indexOf("Could not") === 0 ? Theme.urgent : Theme.secondaryText
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Medium
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 280
                    spacing: 5

                    PowerProfileButton {
                        profileId: "power-saver"
                        label: "Saver"
                    }

                    PowerProfileButton {
                        profileId: "balanced"
                        label: "Balanced"
                    }

                    PowerProfileButton {
                        profileId: "performance"
                        label: "Performance"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.footerHeight
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.thresholdStatusText !== "" ? root.thresholdStatusText : (root.designCapacityWh > 0 ? "Factory capacity " + root.designCapacityWh.toFixed(1) + " Wh" : "")
                visible: text !== ""
                color: root.thresholdStatusText !== "" ? Theme.accent : Theme.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 9
                font.weight: Font.Medium
            }

            Text {
                text: root.power >= 0.05 ? root.power.toFixed(1) + " W" : ""
                visible: text !== ""
                color: Theme.secondaryText
                font.family: root.fontFamily
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }
    }
}
