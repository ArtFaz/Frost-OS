import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Core
import qs.Primitives

Item {
    id: root

    property int brightness: 50
    property int pendingBrightness: 50
    property bool brightnessAvailable: false
    property string confirmAction: ""

    signal backRequested()
    signal closeRequested()

    function profileName() {
        if (PowerProfiles.profile === PowerProfile.PowerSaver)
            return "Power saver";

        if (PowerProfiles.profile === PowerProfile.Performance)
            return "Performance";

        return "Balanced";
    }

    function requestPower(action) {
        if (action === "lock" || action === "suspend") {
            if (ShellBackend.action(action))
                closeRequested();
        } else {
            confirmAction = action;
        }
    }

    onVisibleChanged: {
        if (visible) {
            confirmAction = "";
            ShellBackend.query("brightness");
        }
    }

    Connections {
        function onDataReady(kind, payload) {
            if (kind === "brightness" && payload && payload.schemaVersion === 1) {
                root.brightnessAvailable = payload.available === true;
                root.brightness = Math.max(0, Math.min(100, Number(payload.percent) || 0));
                root.pendingBrightness = root.brightness;
            }
        }

        target: ShellBackend
    }

    Timer {
        id: brightnessCommit

        interval: 140
        onTriggered: ShellBackend.action("brightness-set", root.pendingBrightness)
    }

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
                title: "Display & power"
                subtitle: SystemState.batteryAvailable ? SystemState.batteryPercent + "% battery" : "Display and session controls"
                showBack: true
                onBack: root.backRequested()
            }

            Rectangle {
                width: parent.width
                height: 82
                radius: Theme.rowRadius
                color: Theme.controlNormal

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: root.brightnessAvailable ? "Brightness · " + root.brightness + "%" : "Brightness unavailable"
                        color: Theme.foreground
                        font.family: Style.fontFamily
                        font.pixelSize: Style.body
                        font.bold: true
                    }

                    ValueSlider {
                        width: parent.width
                        value: root.brightness / 100
                        enabled: root.brightnessAvailable
                        onMoved: (value) => {
                            root.brightness = Math.round(value * 100);
                            root.pendingBrightness = root.brightness;
                            brightnessCommit.restart();
                        }
                    }

                }

            }

            Text {
                text: "Displays"
                color: Theme.muted
                font.family: Style.fontFamily
                font.pixelSize: Style.bodySmall
                font.bold: true
            }

            Repeater {
                model: Quickshell.screens

                SurfaceButton {
                    required property var modelData

                    width: parent.width
                    title: modelData.name
                    subtitle: modelData.width + " × " + modelData.height
                    trailingText: "Active"
                    selected: true
                }

            }

            Text {
                text: "Power profile · " + root.profileName()
                color: Theme.muted
                font.family: Style.fontFamily
                font.pixelSize: Style.bodySmall
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: 6

                SurfaceButton {
                    width: (parent.width - 12) / 3
                    compact: true
                    title: "Saver"
                    selected: PowerProfiles.profile === PowerProfile.PowerSaver
                    onActivated: PowerProfiles.profile = PowerProfile.PowerSaver
                }

                SurfaceButton {
                    width: (parent.width - 12) / 3
                    compact: true
                    title: "Balanced"
                    selected: PowerProfiles.profile === PowerProfile.Balanced
                    onActivated: PowerProfiles.profile = PowerProfile.Balanced
                }

                SurfaceButton {
                    width: (parent.width - 12) / 3
                    compact: true
                    title: "Fast"
                    enabled: PowerProfiles.hasPerformanceProfile
                    selected: PowerProfiles.profile === PowerProfile.Performance
                    onActivated: PowerProfiles.profile = PowerProfile.Performance
                }

            }

            Text {
                text: "Session"
                color: Theme.muted
                font.family: Style.fontFamily
                font.pixelSize: Style.bodySmall
                font.bold: true
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 6

                Repeater {
                    model: [{
                        "label": "Lock",
                        "action": "lock"
                    }, {
                        "label": "Suspend",
                        "action": "suspend"
                    }, {
                        "label": "Log out",
                        "action": "logout"
                    }, {
                        "label": "Restart",
                        "action": "reboot"
                    }, {
                        "label": "Power off",
                        "action": "poweroff"
                    }]

                    SurfaceButton {
                        required property var modelData

                        width: (content.width - 6) / 2
                        title: modelData.label
                        subtitle: ""
                        selected: root.confirmAction === modelData.action
                        onActivated: root.requestPower(modelData.action)
                    }

                }

            }

        }

    }

    Rectangle {
        anchors.fill: parent
        visible: root.confirmAction !== ""
        color: Theme.alpha(Theme.background, 0.54)
        radius: Style.radius

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(340, parent.width - Style.space(6))
            height: 180
            radius: Style.radius
            color: Theme.surfaceColor("menu")
            border.color: Theme.border
            border.width: Style.borderWidth

            Column {
                anchors.fill: parent
                anchors.margins: Style.panelPadding
                spacing: Style.space(2)

                Text {
                    width: parent.width
                    text: root.confirmAction === "poweroff" ? "Power off?" : root.confirmAction === "reboot" ? "Restart?" : "Log out?"
                    color: Theme.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Style.heading
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: "Open applications may contain unsaved work."
                    color: Theme.muted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.body
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: Style.space(2)

                    SurfaceButton {
                        width: (parent.width - parent.spacing) / 2
                        compact: true
                        title: "Cancel"
                        onActivated: root.confirmAction = ""
                    }

                    SurfaceButton {
                        width: (parent.width - parent.spacing) / 2
                        compact: true
                        title: "Confirm"
                        selected: true
                        onActivated: {
                            const action = root.confirmAction;
                            root.confirmAction = "";
                            if (ShellBackend.action(action))
                                root.closeRequested();
                        }
                    }
                }
            }
        }
    }

}
