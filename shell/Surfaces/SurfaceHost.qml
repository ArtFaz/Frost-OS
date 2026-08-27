import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Core
import qs.Primitives

Item {
    id: root

    property string activeSurface: ""

    signal closeRequested()
    signal surfaceRequested(string surface)

    function focusedScreen(screen) {
        const focused = Hyprland.focusedMonitor;
        return focused === null || !focused.name || screen.name === focused.name;
    }

    function centeredSurface(surface) {
        return ["app-installer", "clipboard", "emoji", "images", "launcher"].indexOf(surface) >= 0;
    }

    function surfaceWidth(surface) {
        const widths = {
            "launcher": Style.menuWidth,
            "control-center": Style.panelWidth,
            "notifications": Style.notificationWidth,
            "clipboard": Style.clipboardWidth,
            "emoji": Style.emojiWidth,
            "images": Style.imageWidth,
            "app-installer": Style.installerWidth
        };
        return widths[surface] || Style.panelWidth;
    }

    function surfaceHeight(surface) {
        const heights = {
            "launcher": Style.menuMaxHeight,
            "control-center": 590,
            "calendar": 400,
            "notifications": Style.notificationHeight,
            "reminders": 390,
            "clipboard": Style.clipboardHeight,
            "emoji": Style.emojiHeight,
            "images": Style.imageHeight,
            "app-installer": Style.installerHeight
        };
        return heights[surface] || 560;
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            visible: root.activeSurface !== "" && root.focusedScreen(modelData)
            color: "transparent"
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "frost-surfaces"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            Item {
                id: keyCatcher

                anchors.fill: parent
                focus: panel.visible
                Keys.onEscapePressed: root.closeRequested()

                Rectangle {
                    anchors.fill: parent
                    color: Theme.scrim
                    opacity: panel.visible ? 1 : 0

                    TapHandler {
                        onTapped: root.closeRequested()
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.standard
                            easing.type: Motion.easing
                        }

                    }

                }

                GlassSurface {
                    id: card

                    width: Math.min(root.surfaceWidth(root.activeSurface), panel.width - 28)
                    height: Math.min(root.surfaceHeight(root.activeSurface), panel.height - Theme.barHeight - 28)
                    anchors.top: parent.top
                    anchors.topMargin: Theme.barHeight + 12
                    anchors.right: root.centeredSurface(root.activeSurface) ? undefined : parent.right
                    anchors.rightMargin: root.centeredSurface(root.activeSurface) ? 0 : 14
                    anchors.horizontalCenter: root.centeredSurface(root.activeSurface) ? parent.horizontalCenter : undefined
                    surfaceRole: root.activeSurface === "launcher" ? "menu" : "panel"
                    opacity: panel.visible ? 1 : 0
                    scale: panel.visible ? 1 : 0.975
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                    }

                    Launcher {
                        anchors.fill: parent
                        visible: root.activeSurface === "launcher"
                        onCloseRequested: root.closeRequested()
                        onSurfaceRequested: (surface) => {
                            return root.surfaceRequested(surface);
                        }
                    }

                    ControlCenter {
                        anchors.fill: parent
                        visible: root.activeSurface === "control-center"
                        onCloseRequested: root.closeRequested()
                        onSurfaceRequested: (surface) => {
                            return root.surfaceRequested(surface);
                        }
                    }

                    CalendarPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "calendar"
                        onBackRequested: root.closeRequested()
                    }

                    WeatherPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "weather"
                        onBackRequested: root.closeRequested()
                    }

                    ReminderPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "reminders"
                        onBackRequested: root.closeRequested()
                    }

                    NetworkPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "network"
                        onBackRequested: root.surfaceRequested("control-center")
                    }

                    BluetoothPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "bluetooth"
                        onBackRequested: root.surfaceRequested("control-center")
                    }

                    AudioPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "audio"
                        onBackRequested: root.surfaceRequested("control-center")
                    }

                    DisplayPowerPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "display-power"
                        onBackRequested: root.surfaceRequested("control-center")
                        onCloseRequested: root.closeRequested()
                    }

                    ClipboardPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "clipboard"
                        onBackRequested: root.surfaceRequested("control-center")
                        onCloseRequested: root.closeRequested()
                    }

                    EmojiPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "emoji"
                        onBackRequested: root.surfaceRequested("control-center")
                        onCloseRequested: root.closeRequested()
                    }

                    ImagePickerPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "images"
                        onBackRequested: root.surfaceRequested("control-center")
                        onCloseRequested: root.closeRequested()
                    }

                    AppInstallerPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "app-installer"
                        onBackRequested: root.surfaceRequested("control-center")
                    }

                    NotificationPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "notifications"
                        onBackRequested: root.surfaceRequested("control-center")
                    }

                    OptionalPanel {
                        anchors.fill: parent
                        visible: root.activeSurface === "tailscale" || root.activeSurface === "agents"
                        feature: root.activeSurface
                        onBackRequested: root.surfaceRequested("control-center")
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.standard
                            easing.type: Motion.easing
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.deliberate
                            easing.type: Motion.easing
                        }

                    }

                }

            }

        }

    }

}
