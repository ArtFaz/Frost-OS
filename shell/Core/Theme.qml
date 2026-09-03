import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    // Neutral greyscale placeholders only. The real palette arrives from the
    // runtime file (or the on-disk fallback) the instant the shell starts, so
    // no theme's identity is spelled out in the component code.
    property string name: "Neutral"
    property string mode: "dark"
    property color background: "#1c1c1c"
    property color foreground: "#d6d6d6"
    property color mutedBase: "#8a8a8a"
    property color accent: "#9e9e9e"
    property color urgent: "#b4b4b4"
    property color highlight: "#bcbcbc"
    property color success: "#a6a6a6"
    property color warning: "#b0b0b0"
    property bool runtimeLoaded: false
    readonly property string sourceRoot: Quickshell.env("FROST_PREVIEW") === "1" ? Quickshell.env("FROST_SOURCE_ROOT") : ""

    readonly property bool light: mode === "light"
    readonly property color surface: background
    readonly property real glassOpacity: 0.78
    readonly property int barHeight: Style.barHeight
    readonly property int radius: Style.radius
    readonly property int rowRadius: Style.rowRadius
    readonly property int controlRadius: Style.controlRadius
    readonly property int barHoverRadius: Style.barHoverRadius
    readonly property int spacing: Style.space(1)
    readonly property int horizontalPadding: Style.space(2)
    readonly property int panelPadding: Style.panelPadding
    readonly property int panelWidth: Style.panelWidth
    readonly property int widePanelWidth: Style.installerWidth
    readonly property int panelMaxHeight: Style.installerHeight
    readonly property int rowHeight: Style.rowHeight
    readonly property int borderWidth: Style.borderWidth
    readonly property int focusWidth: Style.focusWidth

    readonly property color barBackground: surfaceColor("bar")
    readonly property color cardBackground: surfaceColor("panel")
    readonly property color border: alpha(foreground, light ? 0.14 : 0.20)
    readonly property color focus: accent
    readonly property color muted: mutedBase
    // Secondary text is derived from the text colour rather than painted with
    // the theme's muted role. A palette is free to put muted anywhere — gruvbox
    // lands at 2.26:1 against its own background and matte-black at 1.48:1,
    // which is not readable at any size — while a fixed fraction of the
    // foreground keeps the same relationship in every theme. 0.62 is the
    // fraction the reference session uses for inactive text.
    readonly property color secondaryText: alpha(foreground, 0.62)
    readonly property color controlNormal: alpha(foreground, 0.04)
    readonly property color controlHover: alpha(foreground, 0.08)
    readonly property color controlPressed: alpha(foreground, 0.18)
    readonly property color selected: alpha(accent, 0.14)
    readonly property color scrim: alpha(background, light ? 0.05 : 0.10)

    readonly property string runtimePath: Quickshell.env("XDG_RUNTIME_DIR") + "/frost/theme/theme.toml"

    function alpha(colorValue, opacity) {
        const color = typeof colorValue === "string" ? Qt.color(colorValue) : colorValue;
        return Qt.rgba(color.r, color.g, color.b, Math.max(0, Math.min(1, opacity)));
    }

    function luminance(colorValue) {
        const color = typeof colorValue === "string" ? Qt.color(colorValue) : colorValue;
        return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
    }

    function surfaceOpacity(role) {
        const dark = {
            "bar": 0.68,
            "panel": 0.76,
            "menu": 0.80,
            "notification": 0.80,
            "osd": 0.76,
            "tooltip": 0.90,
            "lock": 0.84
        };
        const lightValues = {
            "bar": 0.76,
            "panel": 0.84,
            "menu": 0.87,
            "notification": 0.88,
            "osd": 0.84,
            "tooltip": 0.94,
            "lock": 0.90
        };
        const values = light ? lightValues : dark;
        return values[role] === undefined ? values.panel : values[role];
    }

    function surfaceColor(role) {
        return alpha(background, surfaceOpacity(role));
    }

    function radiusForRole(role) {
        if (role === "bar")
            return 0;
        if (role === "tooltip")
            return controlRadius;
        return radius;
    }

    function parseTheme(raw) {
        const next = {};
        let section = "";
        const lines = String(raw || "").split("\n");
        for (let index = 0; index < lines.length; index++) {
            const line = lines[index].trim();
            if (line === "" || line.startsWith("#"))
                continue;
            const sectionMatch = line.match(/^\[([A-Za-z0-9_-]+)\]$/);
            if (sectionMatch) {
                section = sectionMatch[1];
                continue;
            }
            const valueMatch = line.match(/^([A-Za-z0-9_-]+)\s*=\s*"([^"\r\n]*)"\s*$/);
            if (valueMatch)
                next[(section === "" ? "root" : section) + "." + valueMatch[1]] = valueMatch[2];
            else {
                const integerMatch = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(\d+)\s*$/);
                if (integerMatch)
                    next[(section === "" ? "root" : section) + "." + integerMatch[1]] = Number(integerMatch[2]);
            }
        }
        return next;
    }

    function applyTheme(raw) {
        const next = parseTheme(raw);
        const required = ["background", "foreground", "muted", "accent", "urgent", "highlight", "success", "warning"];
        if (next["root.schemaVersion"] !== 1 || (next["root.mode"] !== "dark" && next["root.mode"] !== "light"))
            return false;
        for (let index = 0; index < required.length; index++) {
            if (!/^#[0-9A-Fa-f]{6}$/.test(next["colors." + required[index]] || ""))
                return false;
        }
        name = next["root.name"] || "Frost";
        mode = next["root.mode"];
        background = next["colors.background"];
        foreground = next["colors.foreground"];
        mutedBase = next["colors.muted"];
        accent = next["colors.accent"];
        urgent = next["colors.urgent"];
        highlight = next["colors.highlight"];
        success = next["colors.success"];
        warning = next["colors.warning"];
        return true;
    }

    property FileView fallbackFile: FileView {
        path: root.sourceRoot !== "" ? root.sourceRoot + "/themes/gruvbox/theme.toml" : "/usr/share/frost/themes/gruvbox/theme.toml"
        watchChanges: false
        printErrors: false
        onLoaded: {
            if (!root.runtimeLoaded)
                root.applyTheme(text());
        }
    }

    property FileView runtimeFile: FileView {
        path: root.runtimePath
        watchChanges: true
        printErrors: false
        onLoaded: root.runtimeLoaded = root.applyTheme(text())
        onFileChanged: reload()
    }
}
