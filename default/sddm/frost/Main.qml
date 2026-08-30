// Frost greeter. Pure QtQuick — no QtQuick.Controls, no SddmComponents, no
// process spawn. The only privileged calls are the ones SDDM injects: login()
// and the power methods. settings-contract enforces that.

import QtQuick 2.15

Rectangle {
    id: root

    readonly property color textColor: config.textColor || "#d4be98"
    readonly property color mutedColor: config.mutedColor || "#928374"
    readonly property color accentColor: config.accentColor || "#7daea3"
    readonly property color errorColor: config.errorColor || "#ea6962"
    readonly property color borderColor: config.borderColor || "#d4be98"
    readonly property color cardColor: config.cardColor || "#282828"
    readonly property real cardOpacity: parseFloat(config.cardOpacity || "0.78")
    readonly property int cardRadius: parseInt(config.radius || "14")
    readonly property string uiFont: config.fontFamily || "monospace"
    readonly property string glyphFont: config.glyphFont || uiFont

    property string errorText: ""
    property bool busy: false

    anchors.fill: parent

    gradient: Gradient {
        GradientStop { position: 0.0; color: config.backgroundTop || "#161616" }
        GradientStop { position: 1.0; color: config.backgroundBottom || "#1e1e1e" }
    }

    function attemptLogin() {
        if (root.busy || passwordInput.text.length === 0)
            return;
        root.busy = true;
        root.errorText = "";
        var index = (typeof sessionModel !== "undefined" && sessionModel.lastIndex !== undefined)
            ? sessionModel.lastIndex : 0;
        sddm.login(userInput.text, passwordInput.text, index);
    }

    Connections {
        target: sddm
        function onLoginSucceeded() { root.busy = false; }
        function onLoginFailed() {
            root.busy = false;
            root.errorText = "Authentication failed";
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
        }
    }

    // The card.
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 360
        radius: root.cardRadius
        color: Qt.rgba(root.cardColor.r, root.cardColor.g, root.cardColor.b, root.cardOpacity)
        border.width: 1
        border.color: Qt.rgba(root.borderColor.r, root.borderColor.g, root.borderColor.b, 0.20)
        height: layout.implicitHeight + 48

        Column {
            id: layout
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 16

            Text {
                text: "Frost"
                color: root.textColor
                font.family: root.uiFont
                font.pixelSize: 22
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item { width: 1; height: 4 }

            InputField {
                id: userInput
                width: parent.width
                placeholder: "username"
                text: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : ""
                onAccepted: passwordInput.forceActiveFocus()
            }

            InputField {
                id: passwordInput
                width: parent.width
                placeholder: "password"
                password: true
                enabled: !root.busy
                onAccepted: root.attemptLogin()
            }

            Text {
                text: root.errorText
                visible: root.errorText.length > 0
                color: root.errorColor
                font.family: root.uiFont
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22
                topPadding: 4

                PowerButton {
                    glyph: "2"   // pause / suspend
                    label: "suspend"
                    visible: sddm.canSuspend
                    onTriggered: sddm.suspend()
                }
                PowerButton {
                    glyph: "9"   // restart
                    label: "restart"
                    visible: sddm.canReboot
                    onTriggered: sddm.reboot()
                }
                PowerButton {
                    glyph: "5"   // power
                    label: "shut down"
                    visible: sddm.canPowerOff
                    onTriggered: sddm.powerOff()
                }
            }
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()

    // ---- small components ----

    component InputField: Rectangle {
        id: field
        property alias text: input.text
        property string placeholder: ""
        property bool password: false
        signal accepted()

        height: 38
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.25)
        border.width: input.activeFocus ? 1 : 0
        border.color: root.accentColor

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: root.textColor
            font.family: root.uiFont
            font.pixelSize: 14
            clip: true
            echoMode: field.password ? TextInput.Password : TextInput.Normal
            selectByMouse: true
            onAccepted: field.accepted()
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: field.placeholder
            visible: input.text.length === 0 && !input.activeFocus
            color: root.mutedColor
            font.family: root.uiFont
            font.pixelSize: 14
        }
    }

    component PowerButton: Column {
        id: pb
        property string glyph: ""
        property string label: ""
        signal triggered()

        spacing: 3

        Text {
            text: pb.glyph
            color: hover.containsMouse ? root.textColor : root.mutedColor
            font.family: root.glyphFont
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: pb.label
            color: root.mutedColor
            font.family: root.uiFont
            font.pixelSize: 10
            anchors.horizontalCenter: parent.horizontalCenter
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
