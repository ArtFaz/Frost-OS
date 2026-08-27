import QtQuick
import Quickshell.Hyprland
import qs.Core

Row {
    id: root

    property var screen

    function workspaceById(id) {
        const values = Hyprland.workspaces.values;
        for (let index = 0; index < values.length; index++) {
            if (values[index].id === id)
                return values[index];

        }
        return null;
    }

    spacing: 2

    Repeater {
        model: [1, 2, 3, 4, 5]

        Rectangle {
            id: workspaceButton

            required property int modelData
            readonly property var workspace: root.workspaceById(modelData)
            readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
            readonly property bool occupied: workspace !== null && workspace.toplevels !== null && workspace.toplevels.values.length > 0

            width: 26
            height: Theme.barHeight - 8
            radius: Theme.controlRadius
            color: focused ? Theme.selected : "transparent"
            opacity: occupied || focused ? 1 : 0.58

            Text {
                anchors.centerIn: parent
                text: String(workspaceButton.modelData)
                color: workspaceButton.focused ? Theme.accent : Theme.foreground
                font.family: "sans-serif"
                font.pixelSize: 13
                font.bold: workspaceButton.focused
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + workspaceButton.modelData)
            }

        }

    }

}
