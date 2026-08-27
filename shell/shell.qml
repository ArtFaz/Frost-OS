import "Bar" as BarComponents
import "Osd" as OsdComponents
import QtQuick
import Quickshell
import qs.Core

ShellRoot {
    id: root

    property bool barRuntimeVisible: true

    BarComponents.Bar {
        enabled: Config.barEnabled && root.barRuntimeVisible
        position: Config.barPosition
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
                "osdVisible": osd.opened
            });
        }

        function show(surface: string, payload: string) : string {
            if (surface === "bar") {
                root.barRuntimeVisible = true;
                return "ok";
            }
            if (surface === "osd")
                return osd.showPayload(payload);

            return "error:unsupported-surface";
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
            return "error:unsupported-surface";
        }

        function toggle(surface: string) : string {
            if (surface !== "bar")
                return "error:unsupported-surface";

            root.barRuntimeVisible = !root.barRuntimeVisible;
            return "ok";
        }

        target: "frost"
    }

}
