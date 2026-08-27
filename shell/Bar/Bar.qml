import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Primitives

Item {
    id: root

    property string position: "top"

    signal surfaceRequested(string surface)

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

            GlassSurface {
                anchors.fill: parent
                surfaceRole: "bar"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.horizontalPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    MenuButton {
                        onSurfaceRequested: (surface) => {
                            return root.surfaceRequested(surface);
                        }
                    }

                    Workspaces {
                        screen: panel.screen
                    }

                    Media {
                        onSurfaceRequested: (surface) => {
                            return root.surfaceRequested(surface);
                        }
                    }

                }

                Clock {
                    anchors.centerIn: parent
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Tray {
                    }

                    Status {
                        onSurfaceRequested: (surface) => {
                            return root.surfaceRequested(surface);
                        }
                    }

                }

            }

        }

    }

}
