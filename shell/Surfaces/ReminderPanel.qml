import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    signal backRequested()

    Column {
        anchors.fill: parent
        anchors.margins: Style.panelPadding
        spacing: Style.space(2)

        PanelHeader {
            width: parent.width
            title: "Reminder"
            subtitle: IndicatorState.reminder ? "A Frost reminder is scheduled" : "Choose a delay"
            showBack: true
            actionText: IndicatorState.reminder ? "Cancel" : ""
            onBack: root.backRequested()
            onAction: ShellBackend.action("reminder-clear")
        }

        Repeater {
            model: [{"label": "15 minutes", "minutes": 15}, {"label": "30 minutes", "minutes": 30}, {"label": "1 hour", "minutes": 60}, {"label": "2 hours", "minutes": 120}]

            SurfaceButton {
                required property var modelData
                width: parent.width
                iconText: "󰢌"
                title: modelData.label
                subtitle: "Show a Mako notification"
                trailingText: "Set"
                onActivated: ShellBackend.action("reminder-set", modelData.minutes)
            }
        }
    }
}
