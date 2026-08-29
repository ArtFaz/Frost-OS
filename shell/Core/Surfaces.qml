import QtQuick
pragma Singleton

// Which full-screen surface is open, if any. The island and the surfaces are
// siblings under ShellRoot and the shell is allowed exactly one IPC target, so
// routing goes through this singleton rather than a second IpcHandler or a
// cross-tree object reference.
QtObject {
    id: root

    readonly property var known: ["launcher", "clipboard", "emoji", "images"]

    property string active: ""

    // The launcher can send the user into an island panel. The island listens;
    // routing through here avoids a cross-tree object reference.
    signal islandModeRequested(string mode)

    function show(name) {
        if (root.known.indexOf(name) < 0)
            return false;

        root.active = name;
        return true;
    }

    function toggle(name) {
        if (root.active === name) {
            root.close();
            return true;
        }

        return root.show(name);
    }

    function close() {
        root.active = "";
    }
}
