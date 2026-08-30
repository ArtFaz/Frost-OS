// Frost greeter. Pure QtQuick — no QtQuick.Controls, no SddmComponents, no
// process spawn. The only privileged calls are the ones SDDM injects: login()
// and the power methods. settings-contract enforces that.
//
// The username is never typed. SDDM's own user model supplies it: the last user
// who logged in, or the first account on the machine when there has not been a
// login yet. The editable field only appears when the model gives neither,
// which is the one case where typing is the only way in.

import QtQuick 2.15

Rectangle {
    id: root

    readonly property color textColor: config.textColor || "#d4be98"
    readonly property color mutedColor: config.mutedColor || "#928374"
    readonly property color accentColor: config.accentColor || "#7daea3"
    readonly property color errorColor: config.errorColor || "#ea6962"
    readonly property color cardColor: config.cardColor || "#282828"
    readonly property real cardOpacity: parseFloat(config.cardOpacity || "0.72")
    readonly property int cardRadius: parseInt(config.radius || "18")
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

    anchors.fill: parent

    gradient: Gradient {
        GradientStop { position: 0.0; color: config.backgroundTop || "#141618" }
        GradientStop { position: 0.55; color: config.backgroundMid || "#1b1e21" }
        GradientStop { position: 1.0; color: config.backgroundBottom || "#101214" }
    }

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
            root.errorText = "Senha incorreta";
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
        }
    }

    // ---- depth ----------------------------------------------------------
    // Three very faint discs. Cheap, no shader, no extra QML module, and they
    // keep a flat gradient from looking like a broken render.

    Glow { size: root.height * 1.1; centerX: 0.18; centerY: 0.15; tint: root.accentColor; strength: 0.05 }
    Glow { size: root.height * 0.9; centerX: 0.85; centerY: 0.80; tint: root.textColor; strength: 0.03 }
    Glow { size: root.height * 0.5; centerX: 0.50; centerY: 0.50; tint: root.accentColor; strength: 0.04 }

    // ---- clock ----------------------------------------------------------

    Column {
        id: clock

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 56
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            color: root.textColor
            font.family: root.uiFont
            font.pixelSize: 76
            font.weight: Font.Light
            font.letterSpacing: 2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
            color: root.mutedColor
            font.family: root.uiFont
            font.pixelSize: 14
            font.capitalization: Font.Capitalize
        }
    }

    // ---- the card -------------------------------------------------------

    Rectangle {
        id: card

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.08
        width: 340
        height: layout.implicitHeight + 44
        radius: root.cardRadius
        color: Qt.rgba(root.cardColor.r, root.cardColor.g, root.cardColor.b, root.cardOpacity)
        border.width: 1
        border.color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)

        Column {
            id: layout

            anchors.centerIn: parent
            width: parent.width - 44
            spacing: 14

            // Avatar: the account's initial, not a photo. No file access, no
            // fallback icon to go missing.
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 66
                height: 66
                radius: 33
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)

                Text {
                    anchors.centerIn: parent
                    text: root.loginUser.length > 0 ? root.loginUser.charAt(0).toUpperCase() : "F"
                    color: root.accentColor
                    font.family: root.uiFont
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.needsUserInput ? "Frost" : root.resolvedUser
                color: root.textColor
                font.family: root.uiFont
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Item { width: 1; height: 2 }

            // Only when SDDM knows of no account at all.
            InputField {
                id: userInput
                width: parent.width
                visible: root.needsUserInput
                placeholder: "usuário"
                glyph: "󰀄"
                onAccepted: passwordInput.forceActiveFocus()
            }

            InputField {
                id: passwordInput
                width: parent.width
                placeholder: "senha"
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
            }
        }
    }

    // ---- session, host and power ---------------------------------------

    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 22
        text: "Frost"
        color: root.mutedColor
        font.family: root.uiFont
        font.pixelSize: 11
        opacity: 0.55
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 18
        spacing: 6

        PowerButton {
            glyph: "󰤄"
            label: "suspender"
            visible: sddm.canSuspend
            onTriggered: sddm.suspend()
        }
        PowerButton {
            glyph: "󰜉"
            label: "reiniciar"
            visible: sddm.canReboot
            onTriggered: sddm.reboot()
        }
        PowerButton {
            glyph: "󰐥"
            label: "desligar"
            visible: sddm.canPowerOff
            onTriggered: sddm.powerOff()
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()

    // ---- small components ----------------------------------------------

    component Glow: Rectangle {
        property real size: 400
        property real centerX: 0.5
        property real centerY: 0.5
        property color tint: "#ffffff"
        property real strength: 0.05

        width: size
        height: size
        radius: size / 2
        x: root.width * centerX - size / 2
        y: root.height * centerY - size / 2
        color: Qt.rgba(tint.r, tint.g, tint.b, strength)
        antialiasing: true
    }

    component InputField: Rectangle {
        id: field

        property alias text: input.text
        property string placeholder: ""
        property string glyph: ""
        property bool password: false
        property bool submit: false
        signal accepted()
        signal submitted()

        height: 42
        radius: 10
        color: Qt.rgba(0, 0, 0, input.activeFocus ? 0.34 : 0.24)
        border.width: 1
        border.color: input.activeFocus
                      ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.75)
                      : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.10)

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }

        Text {
            id: fieldGlyph
            anchors.left: parent.left
            anchors.leftMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            text: field.glyph
            color: input.activeFocus ? root.accentColor : root.mutedColor
            font.family: root.glyphFont
            font.pixelSize: 15
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 38
            anchors.rightMargin: field.submit ? 38 : 13
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
            anchors.leftMargin: 38
            anchors.verticalCenter: parent.verticalCenter
            text: field.placeholder
            visible: input.text.length === 0 && !input.activeFocus
            color: root.mutedColor
            font.family: root.uiFont
            font.pixelSize: 14
        }

        // The caret doubles as the submit button and as the busy indicator, so
        // the card needs no separate spinner.
        Text {
            id: caret
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: field.submit
            text: "❯"
            color: input.text.length > 0 ? root.accentColor : root.mutedColor
            font.family: root.uiFont
            font.pixelSize: 16
            opacity: root.busy ? 0.35 : 1

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

        width: 40
        height: 40
        radius: 10
        color: hover.containsMouse
               ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.10)
               : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: pb.glyph
            color: hover.containsMouse ? root.textColor : root.mutedColor
            font.family: root.glyphFont
            font.pixelSize: 17
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
