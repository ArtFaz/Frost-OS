import "NotificationModel.js" as NotificationModel
import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property var items: []

    signal backRequested()

    onVisibleChanged: {
        if (visible)
            ShellBackend.query("notifications");

    }

    Connections {
        function onDataReady(kind, payload) {
            if (kind === "notifications")
                root.items = NotificationModel.normalize(payload);

        }

        function onActionFinished(action) {
            if (action === "notification-clear" && root.visible)
                refreshTimer.restart();

        }

        target: ShellBackend
    }

    Timer {
        id: refreshTimer

        interval: 180
        onTriggered: ShellBackend.query("notifications")
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 12

        PanelHeader {
            width: parent.width
            title: "Notifications"
            subtitle: "History provided by Mako"
            showBack: true
            actionText: root.items.length > 0 ? "Clear" : "Refresh"
            onBack: root.backRequested()
            onAction: root.items.length > 0 ? ShellBackend.action("notification-clear") : ShellBackend.query("notifications")
        }

        ListView {
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: 6
            model: root.items

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "No Mako notifications"
                color: Theme.muted
                font.pixelSize: 12
            }

            delegate: SurfaceButton {
                required property var modelData

                width: ListView.view.width
                height: modelData.body ? 66 : Theme.rowHeight
                title: modelData.app + " · " + modelData.summary
                subtitle: modelData.body
                trailingText: modelData.active ? "Now" : "History"
                selected: modelData.active
                enabled: modelData.id > 0
                onActivated: ShellBackend.action("notification-invoke", modelData.id)
            }

        }

    }

}
