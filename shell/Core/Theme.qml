import QtQuick
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property color background: "#0f1724"
    property color foreground: "#eef6ff"
    property color accent: "#8ed8ff"
    property color surface: "#1a2738"
    property real glassOpacity: 0.78
    readonly property int barHeight: 36
    readonly property int radius: 12
    readonly property int controlRadius: 8
    readonly property int spacing: 6
    readonly property int horizontalPadding: 10
    readonly property color barBackground: alpha(surface, glassOpacity)
    readonly property color cardBackground: alpha(surface, Math.min(0.94, glassOpacity + 0.08))
    readonly property color border: alpha(foreground, 0.18)
    readonly property color muted: alpha(foreground, 0.58)
    readonly property color selected: alpha(accent, 0.22)
    property FileView themeFile

    themeFile: FileView {
        path: "/usr/share/frost/themes/frost/theme.toml"
        watchChanges: false
        printErrors: false
        onLoaded: root.loadTheme(text())
    }

    function alpha(colorValue, opacity) {
        const color = typeof colorValue === "string" ? Qt.color(colorValue) : colorValue;
        return Qt.rgba(color.r, color.g, color.b, Math.max(0, Math.min(1, opacity)));
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

        const opacity = Number(next["glass.opacity"]);
        if (isFinite(opacity))
            glassOpacity = Math.max(0, Math.min(1, opacity));

    }

}
