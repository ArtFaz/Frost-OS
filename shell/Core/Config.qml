import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    readonly property string configHome: {
        const explicitHome = Quickshell.env("XDG_CONFIG_HOME");
        return explicitHome ? explicitHome : Quickshell.env("HOME") + "/.config";
    }
    readonly property string defaultsPath: "/usr/share/frost/config/shell.json"
    readonly property string userPath: configHome + "/frost/shell.json"
    readonly property var fallback: ({
        "schemaVersion": 1,
        "bar": {
            "enabled": true,
            "position": "top"
        },
        "osd": {
            "enabled": true
        },
        "surfaces": {
            "commandCenter": true,
            "notificationCenter": true
        }
    })
    property var value: fallback
    readonly property bool barEnabled: value.bar.enabled
    readonly property string barPosition: value.bar.position
    readonly property bool osdEnabled: value.osd.enabled
    property FileView defaultsFile

    defaultsFile: FileView {
        path: root.defaultsPath
        watchChanges: false
        printErrors: false
        onLoaded: root.reloadConfig()
        onLoadFailed: root.reloadConfig()
    }

    property FileView userFile

    userFile: FileView {
        path: root.userPath
        watchChanges: true
        printErrors: false
        onLoaded: root.reloadConfig()
        onLoadFailed: root.reloadConfig()
        onFileChanged: reload()
    }

    function exactKeys(object, expected) {
        if (object === null || typeof object !== "object" || Array.isArray(object))
            return false;

        const actual = Object.keys(object).sort();
        const wanted = expected.slice().sort();
        return JSON.stringify(actual) === JSON.stringify(wanted);
    }

    function validated(candidate) {
        if (!exactKeys(candidate, ["schemaVersion", "bar", "osd", "surfaces"]))
            return null;

        if (candidate.schemaVersion !== 1)
            return null;

        if (!exactKeys(candidate.bar, ["enabled", "position"]))
            return null;

        if (typeof candidate.bar.enabled !== "boolean")
            return null;

        if (candidate.bar.position !== "top" && candidate.bar.position !== "bottom")
            return null;

        if (!exactKeys(candidate.osd, ["enabled"]) || typeof candidate.osd.enabled !== "boolean")
            return null;

        if (!exactKeys(candidate.surfaces, ["commandCenter", "notificationCenter"]))
            return null;

        if (typeof candidate.surfaces.commandCenter !== "boolean")
            return null;

        if (typeof candidate.surfaces.notificationCenter !== "boolean")
            return null;

        return candidate;
    }

    function parse(raw) {
        try {
            return validated(JSON.parse(String(raw || "")));
        } catch (error) {
            return null;
        }
    }

    function reloadConfig() {
        const defaults = parse(defaultsFile.text()) || fallback;
        const userRaw = String(userFile.text() || "").trim();
        const user = userRaw ? parse(userRaw) : null;
        value = user || defaults;
    }

}
