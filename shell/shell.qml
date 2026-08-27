//@ pragma UseQApplication
import "Bar" as BarComponents
import "Osd" as OsdComponents
import QtQuick
import Quickshell
import Quickshell.Io
import "Surfaces" as SurfaceComponents
import qs.Core

ShellRoot {
    id: root

    property bool barRuntimeVisible: true
    property string activeSurface: ""

    function surfaceEnabled(surface) {
        const direct = {
            "launcher": Config.surfaces.launcher,
            "control-center": Config.surfaces.commandCenter,
            "notifications": Config.surfaces.notificationCenter,
            "clipboard": Config.surfaces.clipboard,
            "emoji": Config.surfaces.emojiPicker,
            "images": Config.surfaces.imagePicker,
            "app-installer": Config.surfaces.appInstaller,
            "tailscale": Config.surfaces.tailscale,
            "agents": Config.surfaces.agents
        };
        if (direct[surface] !== undefined)
            return direct[surface];

        return ["audio", "bluetooth", "calendar", "display-power", "network", "reminders", "weather"].indexOf(surface) >= 0 && Config.surfaces.commandCenter;
    }

    function openSurface(surface) {
        if (!surfaceEnabled(surface))
            return "error:disabled-or-unsupported-surface";

        activeSurface = surface;
        return "ok";
    }

    BarComponents.Bar {
        enabled: Config.barEnabled && root.barRuntimeVisible
        position: Config.barPosition
        onSurfaceRequested: (surface) => {
            return root.openSurface(surface);
        }
    }

    SurfaceComponents.SurfaceHost {
        activeSurface: root.activeSurface
        onCloseRequested: root.activeSurface = ""
        onSurfaceRequested: (surface) => {
            return root.openSurface(surface);
        }
    }

    OsdComponents.Osd {
        id: osd

        enabled: Config.osdEnabled
    }

    IpcHandler {
        function ping() : string {
            return "ok";
        }

        function status() : string {
            return JSON.stringify({
                "schemaVersion": 1,
                "bar": Config.barEnabled && root.barRuntimeVisible,
                "osd": Config.osdEnabled,
                "osdVisible": osd.opened,
                "activeSurface": root.activeSurface
            });
        }

        function show(surface: string) : string {
            if (surface === "bar") {
                root.barRuntimeVisible = true;
                return "ok";
            }
            return root.openSurface(surface);
        }

        function showOsd(payload: string) : string {
            return osd.showPayload(payload);
        }

        function hide(surface: string) : string {
            if (surface === "bar") {
                root.barRuntimeVisible = false;
                return "ok";
            }
            if (surface === "osd") {
                osd.close();
                return "ok";
            }
            if (surface === root.activeSurface || surface === "surfaces") {
                root.activeSurface = "";
                return "ok";
            }
            return "error:unsupported-surface";
        }

        function toggle(surface: string) : string {
            if (surface === "bar") {
                root.barRuntimeVisible = !root.barRuntimeVisible;
                return "ok";
            }
            if (root.activeSurface === surface) {
                root.activeSurface = "";
                return "ok";
            }
            return root.openSurface(surface);
        }

        target: "frost"
    }

}
