import QtQuick
pragma Singleton

QtObject {
    id: root

    property bool reminder: false
    property bool stayAwake: false
    property bool loading: false
    property Connections backendConnections
    property Timer refreshTimer
    property Timer retryTimer

    function refresh() {
        if (loading)
            return;
        if (ShellBackend.query("indicators")) {
            loading = true;
            return;
        }
        retryTimer.restart();
    }

    Component.onCompleted: refresh()

    backendConnections: Connections {
        function onDataReady(kind, payload) {
            if (kind !== "indicators")
                return;
            root.loading = false;
            if (payload && payload.schemaVersion === 1) {
                root.reminder = payload.reminder === true;
                root.stayAwake = payload.stayAwake === true;
            }
        }

        function onActionFinished(action) {
            if (["reminder-set", "reminder-clear", "stay-awake-toggle"].indexOf(action) >= 0)
                root.retryTimer.restart();
        }
        target: ShellBackend
    }

    refreshTimer: Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    retryTimer: Timer {
        interval: 350
        onTriggered: root.refresh()
    }
}
