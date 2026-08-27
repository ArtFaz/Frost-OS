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

                Row {
                    anchors.centerIn: parent
                    spacing: 2

                    InteractiveSurface {
                        width: 28
                        height: Theme.barHeight - 8
                        radius: Theme.barHoverRadius
                        selected: IndicatorState.reminder
                        onActivated: root.surfaceRequested("reminders")

                        Text {
                            anchors.centerIn: parent
                            text: "󰢌"
                            color: IndicatorState.reminder ? Theme.accent : Theme.foreground
                            font.family: Style.iconFontFamily
                            font.pixelSize: Style.icon
                        }
                    }

                    InteractiveSurface {
                        width: 28
                        height: Theme.barHeight - 8
                        radius: Theme.barHoverRadius
                        selected: IndicatorState.stayAwake
                        onActivated: ShellBackend.action("stay-awake-toggle")

                        Text {
                            anchors.centerIn: parent
                            text: "󰅶"
                            color: IndicatorState.stayAwake ? Theme.accent : Theme.foreground
                            font.family: Style.iconFontFamily
                            font.pixelSize: Style.icon
                        }
                    }

                    Clock {
                        anchors.verticalCenter: parent.verticalCenter
                        onActivated: root.surfaceRequested("calendar")
                    }

                    InteractiveSurface {
                        width: 28
                        height: Theme.barHeight - 8
                        radius: Theme.barHoverRadius
                        onActivated: root.surfaceRequested("notifications")

                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            color: Theme.foreground
                            font.family: Style.iconFontFamily
                            font.pixelSize: Style.icon
                        }
                    }

                    InteractiveSurface {
                        visible: WeatherState.configured
                        width: visible ? weatherRow.implicitWidth + 12 : 0
                        height: Theme.barHeight - 8
                        radius: Theme.barHoverRadius
                        onActivated: root.surfaceRequested("weather")

                        Row {
                            id: weatherRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰖕"
                                color: Theme.highlight
                                font.family: Style.iconFontFamily
                                font.pixelSize: Style.icon
                            }

                            Text {
                                text: WeatherState.current && Number.isFinite(Number(WeatherState.current.temperature)) ? Math.round(Number(WeatherState.current.temperature)) + "°" : "--°"
                                color: Theme.foreground
                                font.family: Style.fontFamily
                                font.pixelSize: Style.caption
                            }
                        }
                    }
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
