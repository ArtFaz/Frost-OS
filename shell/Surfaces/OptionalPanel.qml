import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property string feature: ""

    signal backRequested()

    Column {
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 12

        PanelHeader {
            width: parent.width
            title: root.feature === "agents" ? "Agents" : "Tailscale"
            subtitle: "Optional Frost feature"
            showBack: true
            onBack: root.backRequested()
        }

        Rectangle {
            width: parent.width
            height: 150
            radius: Theme.radius
            color: Theme.controlNormal
            border.color: Theme.border
            border.width: Theme.borderWidth

            Column {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Feature unavailable"
                    color: Theme.foreground
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: "This optional surface is disabled until its package is explicitly selected in Gate 5."
                    color: Theme.muted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

            }

        }

    }

}
