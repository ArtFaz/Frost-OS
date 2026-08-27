import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core

Item {
    id: root

    property string position: "top"

    Variants {
        model: root.enabled ? Quickshell.screens : []

        delegate: PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            color: "transparent"
            implicitHeight: Theme.barHeight
            exclusiveZone: Theme.barHeight
            focusable: false
            WlrLayershell.namespace: "frost-bar"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: root.position === "top"
                bottom: root.position === "bottom"
                left: true
                right: true
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.barBackground
                border.color: Theme.border
                border.width: 1

                Workspaces {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.horizontalPadding
                    anchors.verticalCenter: parent.verticalCenter
                    screen: panel.screen
                }

                Clock {
                    anchors.centerIn: parent
                }

                Tray {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPadding
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

        }

    }

}
