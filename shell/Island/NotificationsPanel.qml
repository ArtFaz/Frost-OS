import QtQuick
import QtQuick.Layouts
import qs.Core

// A viewer onto Mako, never a notification server. Mako keeps the D-Bus name,
// the popups and the action protocol; this panel only lists what makoctl
// reports and asks makoctl to dismiss or invoke.
Item {
    id: root

    property var entries: []
    property bool dnd: false
    property bool busy: false
    property string statusText: ""
    property string fontFamily: Style.fontFamily
    property real morph: 0
    property int maxPanelHeight: 440

    readonly property color primaryText: Theme.foreground
    readonly property int panelPadding: 16
    readonly property int headerHeight: 32
    readonly property int sectionSpacing: 12
    readonly property int rowHeight: 52
    readonly property int rowSpacing: 6
    readonly property int placeholderHeight: 58
    readonly property int visibleRows: Math.min(5, root.entries.length)
    readonly property real bodyHeight: root.entries.length > 0
        ? root.visibleRows * root.rowHeight + Math.max(0, root.visibleRows - 1) * root.rowSpacing
        : root.placeholderHeight
    readonly property real contentHeight: Math.min(root.maxPanelHeight, root.panelPadding * 2 + root.headerHeight + root.sectionSpacing + root.bodyHeight)
    readonly property real panelProgress: Math.max(0, Math.min(1, (root.morph - 0.22) / 0.78))

    signal closeRequested
    signal clearRequested
    signal dndRequested
    signal dismissRequested(int id)
    signal invokeRequested(int id)

    opacity: root.panelProgress
    visible: opacity > 0.001
    scale: 0.94 + 0.06 * root.panelProgress
    transformOrigin: Item.Top

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: root.sectionSpacing

        PanelHeader {
            Layout.preferredHeight: root.headerHeight
            icon: root.dnd ? "notifications_off" : "notifications"
            iconDimmed: root.dnd
            title: "Notificações"
            statusText: root.statusText
            fontFamily: root.fontFamily
            onCloseRequested: root.closeRequested()

            Text {
                text: "DND"
                color: root.dnd ? Theme.accent : Theme.secondaryText
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            PanelSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: root.dnd
                busy: root.busy
                onToggled: root.dndRequested()
            }

            Rectangle {
                Layout.preferredWidth: clearLabel.width + 14
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                radius: Style.controlRadius
                visible: root.entries.length > 0
                color: clearMouse.containsMouse ? Theme.controlHover : Theme.controlNormal
                border.width: 1
                border.color: Theme.border

                Text {
                    id: clearLabel

                    anchors.centerIn: parent
                    text: "Limpar"
                    color: clearMouse.containsMouse ? Theme.foreground : Theme.secondaryText
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearRequested()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.rowSpacing

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: root.placeholderHeight
                visible: root.entries.length === 0
                text: root.dnd ? "Não perturbe está ativo." : "Nada por aqui."
                color: Theme.secondaryText
                verticalAlignment: Text.AlignVCenter
                font.family: root.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Repeater {
                model: root.entries.slice(0, root.visibleRows)

                Rectangle {
                    id: row

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.rowHeight
                    radius: Style.rowRadius
                    color: rowMouse.containsMouse ? Theme.controlHover : Theme.controlNormal
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.summary !== "" ? row.modelData.summary : row.modelData.appName
                                color: root.primaryText
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.body !== "" ? row.modelData.body : row.modelData.appName
                                color: Theme.secondaryText
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.family: root.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: Style.controlRadius
                            color: dismissMouse.containsMouse ? Theme.controlHover : "transparent"

                            MIcon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 11
                                color: Theme.secondaryText
                            }

                            MouseArea {
                                id: dismissMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dismissRequested(row.modelData.id)
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        anchors.rightMargin: 30
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.invokeRequested(row.modelData.id)
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
