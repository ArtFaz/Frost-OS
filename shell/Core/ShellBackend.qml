import QtQuick
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property string pendingDataKind: ""
    property string pendingAction: ""
    property Process dataProcess
    property Process actionProcess

    signal dataReady(string kind, var payload)
    signal actionFinished(string action, bool succeeded)

    function query(kind) {
        const allowed = ["brightness", "clipboard", "images", "indicators", "notifications", "weather"];
        if (allowed.indexOf(kind) < 0 || dataProcess.running)
            return false;

        pendingDataKind = kind;
        dataProcess.command = ["/usr/bin/frost", "shell-data", kind];
        dataProcess.running = true;
        return true;
    }

    function action(name, argument) {
        if (actionProcess.running)
            return false;

        const noArgument = ["brightness-down", "brightness-up", "lock", "logout", "notification-clear", "poweroff", "reboot", "reminder-clear", "stay-awake-toggle", "suspend"];
        const numericArgument = ["brightness-set", "clipboard-copy", "notification-invoke", "reminder-set"];
        const pathArgument = ["image-copy"];
        const tokenArgument = ["theme-set"];
        let command = [];
        if (noArgument.indexOf(name) >= 0 && (argument === undefined || argument === null || argument === ""))
            command = ["/usr/bin/frost", "shell-action", name];
        else if (numericArgument.indexOf(name) >= 0 && /^\d{1,10}$/.test(argument === undefined || argument === null ? "" : String(argument)))
            command = ["/usr/bin/frost", "shell-action", name, String(argument)];
        else if ((pathArgument.indexOf(name) >= 0 && String(argument || "").indexOf("\n") < 0) || (tokenArgument.indexOf(name) >= 0 && /^[A-Za-z0-9_-]{1,64}$/.test(String(argument || ""))))
            command = ["/usr/bin/frost", "shell-action", name, String(argument)];
        else
            return false;
        pendingAction = name;
        actionProcess.command = command;
        actionProcess.running = true;
        return true;
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
        onExited: (exitCode) => {
            const action = root.pendingAction;
            root.pendingAction = "";
            root.actionFinished(action, exitCode === 0);
        }
    }

}
