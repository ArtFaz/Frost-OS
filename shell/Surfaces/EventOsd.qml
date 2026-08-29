import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core

// Message-only OSD for system events. The island's volume morph already covers
// the donor's progress mode, so this deliberately carries only icon plus text —
// see docs/phase4-parity-contract.md for why Frost has two OSD surfaces.
Scope {
    id: root

    property bool opened: false
    property bool surfaceVisible: false
    property string glyph: ""
    property string message: ""
    property int duration: 1200

    readonly property int pad: 16
    readonly property int messageGap: 11

    function show(iconGlyph, text, milliseconds) {
        root.glyph = iconGlyph;
        root.message = text;
        root.duration = milliseconds > 0 ? milliseconds : 1200;

        exitTimer.stop();
        const wasOpen = root.opened;
        root.surfaceVisible = true;
        // One event-loop turn at opacity 0 so the layer surface exists before the
        // entrance runs; skipped when already open so a re-show only re-times.
        if (wasOpen)
            hideTimer.restart();
        else
            enterTimer.restart();
    }

    function close() {
        root.opened = false;
        hideTimer.stop();
        exitTimer.restart();
    }

    Connections {
        target: Surfaces

        function onOsdRequested(glyph, message, duration) {
            root.show(glyph, message, duration);
        }
    }

    Timer {
        id: enterTimer

        interval: 0
        onTriggered: {
            root.opened = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer

        interval: root.duration
        onTriggered: root.close()
    }

    Timer {
        id: exitTimer

        // One beat past the longest exit animation.
        interval: 190
        onTriggered: root.surfaceVisible = false
    }

    PanelWindow {
        id: panel

        visible: root.surfaceVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "frost-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }

        // Never intercept the pointer.
        mask: Region {}

        Rectangle {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 67
            width: Style.borderWidth * 2 + root.pad * 2 + iconLabel.inkWidth + root.messageGap + messageLabel.width
            height: Style.borderWidth * 2 + root.pad * 2 + Style.displayLarge
            radius: Style.radius
            color: Theme.surfaceColor("osd")
            border.width: Style.borderWidth
            border.color: Theme.border
            opacity: root.opened ? 1 : 0
            scale: root.opened ? 1 : 0.97

            Behavior on opacity {
                NumberAnimation { duration: root.opened ? 180 : 160; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: root.opened ? 200 : 170; easing.type: Easing.OutCubic }
            }

            transform: Translate {
                y: root.opened ? 0 : 6

                Behavior on y {
                    NumberAnimation { duration: root.opened ? 200 : 170; easing.type: Easing.OutCubic }
                }
            }

            Text {
                id: iconLabel

                // Nerd Font glyphs overflow their cell, so the column is measured
                // by ink rather than advance and the glyph re-offset into it.
                readonly property real inkWidth: Math.ceil(iconMetrics.tightBoundingRect.width)

                anchors.left: parent.left
                anchors.leftMargin: Style.borderWidth + root.pad - iconMetrics.tightBoundingRect.x
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                color: Theme.foreground
                font.family: Style.iconFontFamily
                font.pixelSize: Style.displayLarge
            }

            TextMetrics {
                id: iconMetrics

                font.family: Style.iconFontFamily
                font.pixelSize: Style.displayLarge
                text: root.glyph
            }

            Text {
                id: messageLabel

                anchors.left: parent.left
                anchors.leftMargin: Style.borderWidth + root.pad + iconLabel.inkWidth + root.messageGap
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(Math.ceil(messageMetrics.advanceWidth), 190)
                text: root.message
                color: Theme.foreground
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: Style.fontFamily
                font.pixelSize: Style.title
                font.bold: true
            }

            TextMetrics {
                id: messageMetrics

                font.family: Style.fontFamily
                font.pixelSize: Style.title
                font.bold: true
                text: root.message
            }
        }
    }
}
