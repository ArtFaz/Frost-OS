import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Core

// One overlay window per screen, shown only on the focused monitor, hosting
// whichever full-screen surface is open. A single window keeps one keyboard-focus
// lifecycle and one compositor blur rule for every surface.
Scope {
    id: root

    function focusedScreen(screen) {
        const focused = Hyprland.focusedMonitor;
        return focused === null || !focused.name || screen.name === focused.name;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData

            readonly property bool showScrim: Surfaces.active !== "launcher"

            screen: modelData
            visible: Surfaces.active !== "" && root.focusedScreen(modelData)
            color: "transparent"
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

            // The launcher deliberately floats over an undimmed desktop; the
            // clipboard and emoji surfaces dim behind their card.
            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                visible: panel.showScrim
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Surfaces.close()
            }

            LauncherSurface {
                anchors.centerIn: parent
                hostWidth: panel.width
                hostHeight: panel.height
                active: Surfaces.active === "launcher"
            }

            ClipboardSurface {
                anchors.centerIn: parent
                hostWidth: panel.width
                hostHeight: panel.height
                active: Surfaces.active === "clipboard"
            }

            ImagePickerSurface {
                anchors.centerIn: parent
                hostWidth: panel.width
                hostHeight: panel.height
                active: Surfaces.active === "images" || Surfaces.active === "wallpaper"
                wallpaperMode: Surfaces.active === "wallpaper"
            }

            EmojiSurface {
                anchors.centerIn: parent
                hostWidth: panel.width
                hostHeight: panel.height
                active: Surfaces.active === "emoji"
            }
        }
    }
}
