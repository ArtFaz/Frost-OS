import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property string pendingDataKind: ""
    property string pendingAction: ""
    property string pendingInput: ""
    property var actionQueue: []
    property Process dataProcess
    property Process actionProcess
    readonly property string frostExecutable: Quickshell.env("FROST_PREVIEW") === "1" && Quickshell.env("FROST_CLI") !== ""
                                              ? Quickshell.env("FROST_CLI") : "/usr/bin/frost"

    signal dataReady(string kind, var payload)
    signal actionFinished(string action, bool succeeded)
    signal actionRejected(string action)

    function query(kind) {
        const allowed = ["battery-threshold", "brightness", "indicators", "notifications", "power", "privacy", "wifi", "wifi-scan"];
        if (allowed.indexOf(kind) < 0 || dataProcess.running)
            return false;

        pendingDataKind = kind;
        dataProcess.command = [root.frostExecutable, "shell-data", kind];
        dataProcess.running = true;
        return true;
    }

    function action(name, argument) {
        const noArgument = ["brightness-down", "brightness-up", "lock", "logout", "notification-clear", "open-terminal", "poweroff", "reboot", "stay-awake-toggle", "suspend"];
        const numericArgument = ["brightness-set", "clipboard-copy", "notification-dismiss", "notification-invoke"];
        const pathArgument = ["image-copy"];
        const tokenArgument = ["theme-set"];
        let argumentsList = [];
        if (noArgument.indexOf(name) >= 0 && (argument === undefined || argument === null || argument === ""))
            argumentsList = [];
        else if (numericArgument.indexOf(name) >= 0 && /^\d{1,10}$/.test(argument === undefined || argument === null ? "" : String(argument)))
            argumentsList = [String(argument)];
        else if ((pathArgument.indexOf(name) >= 0 && String(argument || "").indexOf("\n") < 0) || (tokenArgument.indexOf(name) >= 0 && /^[A-Za-z0-9_-]{1,64}$/.test(String(argument || ""))))
            argumentsList = [String(argument)];
        else if (["wifi-radio", "notification-dnd"].indexOf(name) >= 0 && ["on", "off"].indexOf(String(argument || "")) >= 0)
            argumentsList = [String(argument)];
        else if (name === "bluetooth-radio" && ["on", "off"].indexOf(String(argument || "")) >= 0)
            argumentsList = [String(argument)];
        else if (name === "wifi-disconnect" && /^[^\u0000-\u001f\u007f]{1,32}$/.test(String(argument || "")))
            argumentsList = [String(argument)];
        else if (name === "power-profile" && ["power-saver", "balanced", "performance"].indexOf(String(argument || "")) >= 0)
            argumentsList = [String(argument)];
        else if (name === "battery-threshold" && ["on", "off"].indexOf(String(argument || "")) >= 0)
            argumentsList = [String(argument)];
        else if (name === "wifi-connect" && argument && /^[^\u0000-\u001f\u007f]{1,32}$/.test(String(argument.ssid || "")) && (/^$/.test(String(argument.password || "")) || /^[\x20-\x7e]{8,63}$/.test(String(argument.password || ""))))
            argumentsList = [String(argument.ssid)];
        else {
            actionRejected(name);
            return false;
        }
        if (actionQueue.length >= 16) {
            actionRejected(name);
            return false;
        }
        const nextQueue = actionQueue.slice();
        nextQueue.push({"name": name, "command": [root.frostExecutable, "shell-action", name].concat(argumentsList), "input": name === "wifi-connect" ? String(argument.password || "") + "\n" : ""});
        actionQueue = nextQueue;
        startNextAction();
        return true;
    }

    function startNextAction() {
        if (actionProcess.running || actionQueue.length === 0)
            return;
        const nextQueue = actionQueue.slice();
        const next = nextQueue.shift();
        actionQueue = nextQueue;
        pendingAction = next.name;
        pendingInput = next.input;
        actionProcess.command = next.command;
        actionProcess.running = true;
    }

    dataProcess: Process {
        onExited: (exitCode) => {
            const kind = root.pendingDataKind;
            root.pendingDataKind = "";
            let payload = null;
            if (exitCode === 0) {
                try {
                    payload = JSON.parse(dataCollector.text || "null");
                } catch (error) {
                    payload = null;
                }
            }
            root.dataReady(kind, payload);
        }

        stdout: StdioCollector {
            id: dataCollector

            waitForEnd: true
        }

    }

    actionProcess: Process {
        stdinEnabled: true

        onStarted: {
            if (root.pendingInput !== "")
                write(root.pendingInput);
            root.pendingInput = "";
        }

        onExited: (exitCode) => {
            const action = root.pendingAction;
            root.pendingAction = "";
            root.actionFinished(action, exitCode === 0);
            Qt.callLater(root.startNextAction);
        }
    }

}
