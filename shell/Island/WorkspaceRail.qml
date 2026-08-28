import QtQuick
import Quickshell.Hyprland
import qs.Core

// Workspace indicator that sits outside the glass: colour only, no surface.
// Reads the workspace set of whichever monitor the island is currently on, so it
// follows the focused screen with the rest of the shell.
Row {
    id: root

    property var hostScreen: null
    property real fade: 1

    readonly property var monitor: root.hostScreen ? Hyprland.monitorFor(root.hostScreen) : null
    readonly property string monitorName: root.monitor?.name ?? ""

    // Live workspaces on this monitor, plus a baseline so the rail does not
    // collapse to nothing on an empty desktop.
    readonly property int baselineCount: 5
    readonly property var workspaceIds: {
        const ids = [];

        for (let i = 1; i <= root.baselineCount; i += 1)
            ids.push(i);

        const live = Hyprland.workspaces?.values ?? [];
        for (let i = 0; i < live.length; i += 1) {
            const workspace = live[i];
            if (workspace.id <= 0)
                continue;
            if (root.monitorName !== "" && (workspace.monitor?.name ?? "") !== root.monitorName)
                continue;
            if (ids.indexOf(workspace.id) === -1)
                ids.push(workspace.id);
        }

        return ids.sort((a, b) => a - b);
    }

    function workspaceById(id) {
        const live = Hyprland.workspaces?.values ?? [];

        for (let i = 0; i < live.length; i += 1) {
            if (live[i].id === id)
                return live[i];
        }

        return null;
    }

    function activateWorkspace(id) {
        const workspace = root.workspaceById(id);

        // Native: this crosses the Hyprland control socket, never a shell.
        if (workspace)
            workspace.activate();
    }

    spacing: 7
    opacity: root.fade

    Behavior on opacity {
        NumberAnimation { duration: 160 }
    }

    Repeater {
        model: root.workspaceIds

        Item {
            id: dot

            required property int modelData

            readonly property var workspace: root.workspaceById(dot.modelData)
            // `active` is the workspace shown on this monitor, which is what the
            // rail is about — not Hyprland.focusedWorkspace, which is global.
            readonly property bool focused: dot.workspace?.active ?? false
            readonly property bool occupied: (dot.workspace?.toplevels?.values?.length ?? 0) > 0

            width: 10
            height: 10

            Rectangle {
                id: mark

                anchors.centerIn: parent
                width: dot.focused ? 10 : 6
                height: width
                radius: width / 2
                color: dot.focused ? Theme.accent : (dot.occupied ? Theme.foreground : Theme.muted)
                opacity: dot.focused || dot.occupied ? 1 : 0.45
                scale: dotMouse.containsMouse ? 1.25 : 1

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                Behavior on scale {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: dotMouse

                anchors.fill: parent
                anchors.margins: -3
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activateWorkspace(dot.modelData)
            }
        }
    }
}
