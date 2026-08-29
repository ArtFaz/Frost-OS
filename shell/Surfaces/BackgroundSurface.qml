import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core

// The wallpaper is drawn by the shell rather than a separate daemon, which is
// how the reference session does it and is why Frost needs no swaybg/hyprpaper
// dependency. Two layers cross-fade so a change never flashes the desktop.
Scope {
    id: root

    property string currentPath: ""
    property string incomingPath: ""
    property real reveal: 1

    function apply(path) {
        const next = String(path || "");
        if (next === "" || next === root.currentPath)
            return;

        if (root.currentPath === "") {
            root.currentPath = next;
            root.reveal = 1;
            return;
        }

        root.incomingPath = next;
        root.reveal = 0;
        revealAnimation.restart();
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: 420
        easing.type: Easing.InOutCubic

        onFinished: {
            root.currentPath = root.incomingPath;
            root.incomingPath = "";
        }
    }

    FileView {
        id: selectionFile

        path: Quickshell.env("HOME") + "/.local/state/frost/background.json"
        preload: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(selectionFile.text());
                root.apply(String(parsed.path || ""));
            } catch (error) {
                // No selection yet, or the file was hand-edited into something
                // unparseable. The solid theme background stays.
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            // Only present once a wallpaper is actually selected. An always-on
            // opaque layer would paint over whatever else is drawing the desktop.
            visible: root.currentPath !== ""
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "frost-background"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            mask: Region {}

            Rectangle {
                anchors.fill: parent
                color: Theme.background
            }

            Image {
                anchors.fill: parent
                source: root.currentPath !== "" ? "file://" + root.currentPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                visible: status === Image.Ready
            }

            Image {
                anchors.fill: parent
                source: root.incomingPath !== "" ? "file://" + root.incomingPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                opacity: root.reveal
                visible: root.incomingPath !== "" && status === Image.Ready
            }
        }
    }
}
