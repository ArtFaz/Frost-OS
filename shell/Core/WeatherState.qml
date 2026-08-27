import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    property string city: ""
    property var current: null
    property var daily: []
    property bool loading: false
    property bool failed: false
    readonly property bool configured: city !== ""
    property FileView configFile
    property Timer refreshTimer
    property Timer retryTimer

    function loadConfig(raw) {
        try {
            const value = JSON.parse(String(raw || ""));
            city = value && value.schemaVersion === 1 && typeof value.city === "string" && value.city.length >= 2 && value.city.length <= 80 ? value.city : "";
        } catch (error) {
            city = "";
        }
        current = null;
        daily = [];
        failed = false;
        if (configured)
            refresh();
    }

    function refresh() {
        if (!configured || loading)
            return;
        if (ShellBackend.query("weather")) {
            loading = true;
            return;
        }
        retryTimer.restart();
    }

    Component.onCompleted: refresh()

    Connections {
        function onDataReady(kind, payload) {
            if (kind !== "weather")
                return;
            root.loading = false;
            if (payload && payload.schemaVersion === 1 && payload.configured === true && payload.city === root.city && payload.current && Array.isArray(payload.daily)) {
                root.current = payload.current;
                root.daily = payload.daily.slice(0, 5);
                root.failed = false;
            } else {
                root.failed = true;
            }
        }
        target: ShellBackend
    }

    configFile: FileView {
        path: root.configHome + "/frost/weather.json"
        watchChanges: true
        printErrors: false
        onLoaded: root.loadConfig(text())
        onLoadFailed: root.loadConfig("")
        onFileChanged: reload()
    }

    refreshTimer: Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.configured
        onTriggered: root.refresh()
    }

    retryTimer: Timer {
        interval: 2000
        onTriggered: root.refresh()
    }
}
