import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property string sourceRoot: Quickshell.env("FROST_PREVIEW") === "1" ? Quickshell.env("FROST_SOURCE_ROOT") : ""
    readonly property string defaultsPath: sourceRoot !== "" ? sourceRoot + "/config/shell.json" : "/usr/share/frost/config/shell.json"
    readonly property string userPath: configHome + "/frost/shell.json"
    readonly property var fallback: ({
        "schemaVersion": 3,
        "island": { "enabled": true, "handleStyle": "bump", "idleWidth": 380, "idleHeight": 148 }
    })
    property var value: fallback
    readonly property var island: value.island
    property FileView defaultsFile
    property FileView userFile

    function validated(candidate) {
        if (!candidate || candidate.schemaVersion !== 3 || !candidate.island)
            return null;
        const island = candidate.island;
        if (typeof island.enabled !== "boolean" || ["bump", "strip"].indexOf(island.handleStyle) < 0)
            return null;
        if (!Number.isInteger(island.idleWidth) || island.idleWidth < 300 || island.idleWidth > 520)
            return null;
        if (!Number.isInteger(island.idleHeight) || island.idleHeight < 112 || island.idleHeight > 180)
            return null;
        if (JSON.stringify(Object.keys(candidate).sort()) !== JSON.stringify(["island", "schemaVersion"]) ||
            JSON.stringify(Object.keys(island).sort()) !== JSON.stringify(["enabled", "handleStyle", "idleHeight", "idleWidth"]))
            return null;
        return candidate;
    }

    function parse(raw) {
        try { return validated(JSON.parse(String(raw || ""))); }
        catch (error) { return null; }
    }

    function reloadConfig() {
        const defaults = parse(defaultsFile.text()) || fallback;
        const userRaw = String(userFile.text() || "").trim();
        value = (userRaw ? parse(userRaw) : null) || defaults;
    }

    defaultsFile: FileView { path: root.defaultsPath; printErrors: false; onLoaded: root.reloadConfig(); onLoadFailed: root.reloadConfig() }
    userFile: FileView { path: root.userPath; watchChanges: true; printErrors: false; onLoaded: root.reloadConfig(); onLoadFailed: root.reloadConfig(); onFileChanged: reload() }
}
