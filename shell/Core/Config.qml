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
        "schemaVersion": 2,
        "bar": {
            "enabled": true,
            "position": "top"
        },
        "osd": {
            "enabled": true
        },
        "surfaces": {
            "launcher": true,
            "commandCenter": true,
            "notificationCenter": true,
            "clipboard": true,
            "emojiPicker": true,
            "imagePicker": true,
            "appInstaller": true,
            "tailscale": false,
            "agents": false
        }
    })
    property var value: fallback
    readonly property bool barEnabled: value.bar.enabled
    readonly property string barPosition: value.bar.position
    readonly property bool osdEnabled: value.osd.enabled
    readonly property var surfaces: value.surfaces
    property FileView defaultsFile
    property FileView userFile

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

        if (candidate.schemaVersion !== 2)
            return null;

        if (!exactKeys(candidate.bar, ["enabled", "position"]))
            return null;

        if (typeof candidate.bar.enabled !== "boolean")
            return null;

        if (candidate.bar.position !== "top" && candidate.bar.position !== "bottom")
            return null;

        if (!exactKeys(candidate.osd, ["enabled"]) || typeof candidate.osd.enabled !== "boolean")
            return null;

        if (!exactKeys(candidate.surfaces, ["launcher", "commandCenter", "notificationCenter", "clipboard", "emojiPicker", "imagePicker", "appInstaller", "tailscale", "agents"]))
            return null;

        const surfaceNames = ["launcher", "commandCenter", "notificationCenter", "clipboard", "emojiPicker", "imagePicker", "appInstaller", "tailscale", "agents"];
        for (let index = 0; index < surfaceNames.length; index++) {
            if (typeof candidate.surfaces[surfaceNames[index]] !== "boolean")
                return null;

        }
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

    defaultsFile: FileView {
        path: root.defaultsPath
        watchChanges: false
        printErrors: false
        onLoaded: root.reloadConfig()
        onLoadFailed: root.reloadConfig()
    }

    userFile: FileView {
        path: root.userPath
        watchChanges: true
        printErrors: false
        onLoaded: root.reloadConfig()
        onLoadFailed: root.reloadConfig()
        onFileChanged: reload()
    }

}
