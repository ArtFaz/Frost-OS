// Frost greeter. Pure QtQuick — no QtQuick.Controls, no SddmComponents, no
// process spawn. The only privileged calls are the ones SDDM injects: login()
// and the power methods. settings-contract enforces that.
//
// The username is never typed. SDDM's own user model supplies it: the last user
// who logged in, or the first account on the machine when there has not been a
// login yet. The editable field only appears when the model gives neither,
// which is the one case where typing is the only way in.
//
// The look is Frost Dark: a cold ground with a faint ice bloom, and a card that
// reads as frosted glass — a translucent white wash, a top-lit rim, an inner
// highlight and a soft lift. No compositor blur is available here, so the glass
// is faked the way the shell surfaces fake it.

import QtQuick 2.15

Rectangle {
    id: root

    readonly property color bgColor: config.background || "#0f1724"
    readonly property color textColor: config.textColor || "#eef6ff"
    readonly property color mutedColor: config.mutedColor || "#93a8c0"
    readonly property color accentColor: config.accentColor || "#8ed8ff"
    readonly property color errorColor: config.errorColor || "#ff6b7a"
    readonly property color glassColor: config.cardColor || "#eef6ff"
    readonly property real glassOpacity: parseFloat(config.cardOpacity || "0.07")
    readonly property int cardRadius: parseInt(config.radius || "22")
    readonly property string uiFont: config.fontFamily || "monospace"
    readonly property string glyphFont: config.glyphFont || uiFont

    property string errorText: ""
    property bool busy: false
    property string probedUser: ""
    property date now: new Date()

    // The last user who logged in; failing that, the first account that exists.
    readonly property string resolvedUser: {
        if (typeof userModel === "undefined")
            return "";
        var last = userModel.lastUser ? String(userModel.lastUser) : "";
        return last.length > 0 ? last : root.probedUser;
    }
    readonly property bool needsUserInput: root.resolvedUser.length === 0
    readonly property string loginUser: root.needsUserInput ? userInput.text : root.resolvedUser

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    anchors.fill: parent
    color: root.bgColor

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Reading the model once, off screen, so the name is available before the
    // first paint. Repeater over SDDM's user model; index 0 is the first account.
    Item {
        visible: false

        Repeater {
            model: (typeof userModel !== "undefined") ? userModel : 0

            delegate: Item {
                required property int index
                required property string name

                Component.onCompleted: {
                    if (index === 0 && root.probedUser.length === 0)
                        root.probedUser = String(name);
                }
            }
        }
    }

    function attemptLogin() {
        if (root.busy || passwordInput.text.length === 0 || root.loginUser.length === 0)
            return;
        root.busy = true;
        root.errorText = "";
        var index = (typeof sessionModel !== "undefined" && sessionModel.lastIndex !== undefined)
            ? sessionModel.lastIndex : 0;
        sddm.login(root.loginUser, passwordInput.text, index);
    }

    Connections {
        target: sddm
        function onLoginSucceeded() { root.busy = false; }
        function onLoginFailed() {
            root.busy = false;
            root.errorText = "Wrong password";
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
        }
    }

    // ---- cold ground: an ice bloom above the card, a vignette at the edges ---

    Canvas {
        id: backdrop
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var g = ctx.createRadialGradient(width / 2, height * 0.40,
                                             Math.min(width, height) * 0.12,
                                             width / 2, height * 0.52,
                                             Math.max(width, height) * 0.80);
            g.addColorStop(0.0, root.alpha(root.accentColor, 0.07));
            g.addColorStop(0.32, "transparent");
            g.addColorStop(1.0, Qt.rgba(0, 0, 0, 0.42));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // ---- clock -------------------------------------------------------------

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 60
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            color: root.textColor
            font.family: root.uiFont
            font.pixelSize: 86
            font.weight: Font.Thin
            font.letterSpacing: 4
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
            color: root.alpha(root.mutedColor, 0.85)
            font.family: root.uiFont
            font.pixelSize: 13
            font.letterSpacing: 3
            font.capitalization: Font.AllLowercase
        }
    }

    // ---- the frosted-glass card -----------------------------------------

    Item {
        id: card

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.06
        width: 360
        height: layout.implicitHeight + 52

        opacity: 0
        transform: Translate {
            id: cardRise
            y: 12
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }

        Component.onCompleted: {
            opacity = 1;
            cardRise.y = 0;
        }
        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        // Soft lift. Two flat translucent layers stand in for a blurred shadow.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -10
            anchors.topMargin: -6
            anchors.bottomMargin: -14
            radius: root.cardRadius + 12
            color: Qt.rgba(0, 0, 0, 0.22)
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            anchors.bottomMargin: -8
            radius: root.cardRadius + 4
            color: Qt.rgba(0, 0, 0, 0.20)
        }

        // Top-lit rim: a vertical gradient sheet, 1px of which peeks past the
        // glass on every edge — bright at the top, gone by the bottom.
        Rectangle {
            anchors.fill: glass
            anchors.margins: -1
            radius: root.cardRadius + 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.alpha(root.glassColor, 0.30) }
                GradientStop { position: 0.45; color: root.alpha(root.glassColor, 0.07) }
                GradientStop { position: 1.0; color: root.alpha(root.glassColor, 0.02) }
            }
        }

        Rectangle {
            id: glass

            anchors.fill: parent
            radius: root.cardRadius
            color: root.alpha(root.glassColor, root.glassOpacity)
            clip: true

            // Frost catches the light near the top edge.
            Rectangle {
                width: parent.width
                height: parent.height * 0.42
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.alpha(root.glassColor, 0.06) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Column {
                id: layout

                anchors.centerIn: parent
                width: parent.width - 52
                spacing: 16

                // Avatar: the account's initial, not a photo. No file access,
                // no fallback icon to go missing.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 68
                    height: 68
                    radius: 34
                    color: root.alpha(root.accentColor, 0.10)
                    border.width: 1
                    border.color: root.alpha(root.accentColor, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: root.loginUser.length > 0 ? root.loginUser.charAt(0).toUpperCase() : ""
                        color: root.accentColor
                        font.family: root.loginUser.length > 0 ? root.uiFont : root.glyphFont
                        font.pixelSize: 26
                        font.weight: Font.Light
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.needsUserInput ? "Frost" : root.resolvedUser
                    color: root.textColor
                    font.family: root.uiFont
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    font.letterSpacing: 0.5
                }

                Item { width: 1; height: 2 }

                // Only when SDDM knows of no account at all.
                InputField {
                    id: userInput
                    width: parent.width
                    visible: root.needsUserInput
                    placeholder: "username"
                    glyph: "󰀄"
                    onAccepted: passwordInput.forceActiveFocus()
                }

                InputField {
                    id: passwordInput
                    width: parent.width
                    placeholder: "password"
                    glyph: "󰌾"
                    password: true
                    enabled: !root.busy
                    submit: true
                    onAccepted: root.attemptLogin()
                    onSubmitted: root.attemptLogin()
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.errorText
                    visible: root.errorText.length > 0
                    color: root.errorColor
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.letterSpacing: 0.5
                }
            }
        }
    }

    // ---- mark and power ---------------------------------------------

    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        text: ""
        color: root.mutedColor
        font.family: root.glyphFont
        font.pixelSize: 13
        opacity: 0.5
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 6

        PowerButton {
            glyph: "󰤄"
            label: "suspend"
            visible: sddm.canSuspend
            onTriggered: sddm.suspend()
        }
        PowerButton {
            glyph: "󰜉"
            label: "restart"
            visible: sddm.canReboot
            onTriggered: sddm.reboot()
        }
        PowerButton {
            glyph: "󰐥"
            label: "shut down"
            visible: sddm.canPowerOff
            onTriggered: sddm.powerOff()
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()

    // ---- small components --------------------------------------------

    component InputField: Rectangle {
        id: field

        property alias text: input.text
        property string placeholder: ""
        property string glyph: ""
        property bool password: false
        property bool submit: false
        signal accepted()
        signal submitted()

        height: 44
        radius: 11
        color: Qt.rgba(0, 0, 0, input.activeFocus ? 0.30 : 0.20)
        border.width: 1
        border.color: input.activeFocus
                      ? root.alpha(root.accentColor, 0.70)
                      : root.alpha(root.textColor, 0.10)

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }

        Text {
            id: fieldGlyph
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: field.glyph
            color: input.activeFocus ? root.accentColor : root.mutedColor
            font.family: root.glyphFont
            font.pixelSize: 15

            Behavior on color { ColorAnimation { duration: 130 } }
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: field.submit ? 40 : 14
            verticalAlignment: TextInput.AlignVCenter
            color: root.textColor
            font.family: root.uiFont
            font.pixelSize: 14
            clip: true
            echoMode: field.password ? TextInput.Password : TextInput.Normal
            passwordCharacter: "•"
            selectByMouse: true
            enabled: field.enabled
            onAccepted: field.accepted()
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 40
            anchors.verticalCenter: parent.verticalCenter
            text: field.placeholder
            visible: input.text.length === 0 && !input.activeFocus
            color: root.alpha(root.mutedColor, 0.8)
            font.family: root.uiFont
            font.pixelSize: 14
        }

        // The caret doubles as the submit button and as the busy indicator, so
        // the card needs no separate spinner. It matches the shell's prompt.
        Text {
            id: caret
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            visible: field.submit
            text: "❯"
            color: input.text.length > 0 ? root.accentColor : root.mutedColor
            font.family: root.uiFont
            font.pixelSize: 16
            opacity: root.busy ? 0.35 : 1

            Behavior on color { ColorAnimation { duration: 130 } }

            SequentialAnimation on opacity {
                running: root.busy
                loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.35; duration: 420; easing.type: Easing.InOutQuad }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                cursorShape: Qt.PointingHandCursor
                onClicked: field.submitted()
            }
        }
    }

    component PowerButton: Rectangle {
        id: pb

        property string glyph: ""
        property string label: ""
        signal triggered()

        width: 42
        height: 42
        radius: 11
        color: hover.containsMouse ? root.alpha(root.textColor, 0.09) : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: pb.glyph
            color: hover.containsMouse ? root.textColor : root.mutedColor
            font.family: root.glyphFont
            font.pixelSize: 17

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 2
            text: pb.label
            visible: hover.containsMouse
            color: root.mutedColor
            font.family: root.uiFont
            font.pixelSize: 9
            font.letterSpacing: 1
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.triggered()
        }
    }
}
