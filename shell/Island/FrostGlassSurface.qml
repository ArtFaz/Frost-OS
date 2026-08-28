import QtQuick
import qs.Core

Canvas {
    id: root

    property real bottomRadius: Style.radius
    property color fallbackColor: Theme.cardBackground
    readonly property real glassAmount: 1

    antialiasing: true

    function cssColor(value, alphaScale) {
        const alpha = Math.max(0, Math.min(1, value.a * alphaScale));
        return "rgba(" + Math.round(value.r * 255) + ", "
                       + Math.round(value.g * 255) + ", "
                       + Math.round(value.b * 255) + ", " + alpha + ")";
    }

    function traceBody(context, inset) {
        const left = inset;
        const top = inset;
        const right = Math.max(left, width - inset);
        const bottom = Math.max(top, height - inset);
        const radius = Math.max(0, Math.min(root.bottomRadius - inset,
                                            (right - left) / 2,
                                            (bottom - top) / 2));

        context.beginPath();
        context.moveTo(left, top);
        context.lineTo(right, top);
        context.lineTo(right, bottom - radius);
        context.quadraticCurveTo(right, bottom, right - radius, bottom);
        context.lineTo(left + radius, bottom);
        context.quadraticCurveTo(left, bottom, left, bottom - radius);
        context.closePath();
    }

    onPaint: {
        const context = getContext("2d");
        context.reset();
        context.clearRect(0, 0, width, height);

        // The fill itself defines the silhouette. A closed stroke would draw a
        // straight line against the display's top edge, so the island has no
        // external outline.
        traceBody(context, 0);
        context.fillStyle = cssColor(root.fallbackColor, root.glassAmount);
        context.fill();
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onBottomRadiusChanged: requestPaint()
    onFallbackColorChanged: requestPaint()
    onGlassAmountChanged: requestPaint()

    Connections {
        target: Theme
        function onBackgroundChanged() { root.requestPaint(); }
        function onForegroundChanged() { root.requestPaint(); }
        function onModeChanged() { root.requestPaint(); }
    }
}
