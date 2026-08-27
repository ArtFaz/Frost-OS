import QtQuick
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property color background: "#0f1724"
    property color foreground: "#eef6ff"
    property color accent: "#8ed8ff"
    property color surface: "#1a2738"
    property color urgent: "#ff6b7a"
    property real glassOpacity: 0.78
    readonly property int barHeight: 36
    readonly property int radius: 14
    readonly property int rowRadius: 8
    readonly property int controlRadius: 6
    readonly property int barHoverRadius: 4
    readonly property int spacing: 6
    readonly property int horizontalPadding: 10
    readonly property int borderWidth: 1
    readonly property int focusWidth: 1
    readonly property bool light: luminance(background) >= 0.56
    readonly property color barBackground: surfaceColor("bar")
    readonly property color cardBackground: surfaceColor("panel")
    readonly property color border: alpha(foreground, light ? 0.14 : 0.2)
    readonly property color focus: accent
    readonly property color muted: alpha(foreground, 0.58)
    readonly property color controlNormal: alpha(foreground, 0.04)
    readonly property color controlHover: alpha(foreground, 0.08)
    readonly property color controlPressed: alpha(foreground, 0.18)
    readonly property color selected: alpha(accent, 0.14)
    property FileView themeFile

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
            "menu": 0.8,
            "notification": 0.8,
            "osd": 0.76,
            "tooltip": 0.9,
            "lock": 0.84
        };
        const lightValues = {
            "bar": 0.76,
            "panel": 0.84,
            "menu": 0.87,
            "notification": 0.88,
            "osd": 0.84,
            "tooltip": 0.94,
            "lock": 0.9
        };
        const values = light ? lightValues : dark;
        const baseOpacity = values[role] === undefined ? 0.78 : values[role];
        return Math.max(0, Math.min(1, baseOpacity * glassOpacity / 0.78));
    }

    function surfaceColor(role) {
        return alpha(surface, surfaceOpacity(role));
    }

    function radiusForRole(role) {
        if (role === "bar")
            return 0;

        if (role === "tooltip")
            return controlRadius;

        return radius;
    }

    function loadTheme(raw) {
        const next = ({
        });
        let section = "";
        const lines = String(raw || "").split("\n");
        for (let index = 0; index < lines.length; index++) {
            const line = lines[index].trim();
            const sectionMatch = line.match(/^\[([A-Za-z0-9_-]+)\]$/);
            if (sectionMatch) {
                section = sectionMatch[1];
                continue;
            }
            const valueMatch = line.match(/^([A-Za-z0-9_-]+)\s*=\s*"?([^"#][^"#]*|#[0-9A-Fa-f]{6})"?\s*$/);
            if (valueMatch)
                next[section + "." + valueMatch[1]] = valueMatch[2].trim();

        }
        if (/^#[0-9A-Fa-f]{6}$/.test(next["colors.background"] || ""))
            background = next["colors.background"];

        if (/^#[0-9A-Fa-f]{6}$/.test(next["colors.foreground"] || ""))
            foreground = next["colors.foreground"];

        if (/^#[0-9A-Fa-f]{6}$/.test(next["colors.accent"] || ""))
            accent = next["colors.accent"];

        if (/^#[0-9A-Fa-f]{6}$/.test(next["colors.surface"] || ""))
            surface = next["colors.surface"];

        if (/^#[0-9A-Fa-f]{6}$/.test(next["colors.urgent"] || ""))
            urgent = next["colors.urgent"];

        const opacity = Number(next["glass.opacity"]);
        if (isFinite(opacity))
            glassOpacity = Math.max(0, Math.min(1, opacity));

    }

    themeFile: FileView {
        path: "/usr/share/frost/themes/frost/theme.toml"
        watchChanges: false
        printErrors: false
        onLoaded: root.loadTheme(text())
    }

}
