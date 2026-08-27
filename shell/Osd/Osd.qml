import "OsdModel.js" as OsdModel
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Core

Item {
    id: root

    property bool opened: false
    property bool panelVisible: false
    property string label: "FROST"
    property string message: ""
    property int value: 0
    property int maxValue: 100
    property int duration: 1200
    readonly property int percent: Math.round(value * 100 / Math.max(1, maxValue))

    function onFocusedScreen(screen) {
        const focused = Hyprland.focusedMonitor;
        return focused === null || !focused.name || screen.name === focused.name;
    }

    function showPayload(payload) {
        if (!enabled)
            return "error:disabled";

        const state = OsdModel.stateForPayload(payload);
        if (state === null)
            return "error:invalid-payload";

        label = state.label;
        message = state.message;
        value = state.value;
        maxValue = state.max;
        duration = state.duration;
        closeTimer.stop();
        retireTimer.stop();
        panelVisible = true;
        opened = true;
        if (duration > 0)
            closeTimer.restart();

        return "ok";
    }

    function close() {
        closeTimer.stop();
        if (!panelVisible)
            return ;

        opened = false;
        retireTimer.restart();
    }

    Timer {
        id: closeTimer

        interval: root.duration
        onTriggered: root.close()
    }

    Timer {
        id: retireTimer

        interval: 180
        onTriggered: {
            if (!root.opened)
                root.panelVisible = false;

        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            visible: root.panelVisible && root.onFocusedScreen(modelData)
            color: "transparent"
            focusable: false
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "frost-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            Rectangle {
                id: card

                width: 300
                height: 82
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 64
                radius: Theme.radius
                color: Theme.cardBackground
                border.color: Theme.border
                border.width: 1
                opacity: root.opened ? 1 : 0
                scale: root.opened ? 1 : 0.97

                Text {
                    id: iconLabel

                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.label
                    color: Theme.accent
                    font.family: "sans-serif"
                    font.pixelSize: 13
                    font.bold: true
                }

                Item {
                    anchors.left: iconLabel.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 38

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: root.message || root.percent + "%"
                        color: Theme.foreground
                        horizontalAlignment: Text.AlignRight
                        font.family: "sans-serif"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 6
                        radius: 3
                        color: Theme.alpha(Theme.foreground, 0.16)

                        Rectangle {
                            width: parent.width * root.percent / 100
                            height: parent.height
                            radius: parent.radius
                            color: Theme.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

            }

            mask: Region {
            }

        }

    }

}
