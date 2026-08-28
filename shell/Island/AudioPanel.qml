import QtQuick
import QtQuick.Layouts
import qs.Core

Item {
    id: root

    property int outputVolume: 0
    property bool outputMuted: false
    property int inputVolume: 0
    property bool inputMuted: false
    property var sinkNodes: []
    property var streamNodes: []
    property string activeSinkName: ""
    property string fontFamily: Style.fontFamily
    property real morph: 0
    property int maxPanelHeight: 440

    readonly property color primaryText: Theme.foreground
    readonly property int panelPadding: 16
    readonly property int headerHeight: 32
    readonly property int sectionSpacing: 12
    readonly property int sliderRowHeight: 30
    readonly property int deviceRowHeight: 30
    readonly property int deviceRowSpacing: 4
    readonly property int labelHeight: 14
    readonly property int streamRowHeight: 30
    readonly property int visibleSinkCount: Math.min(3, root.sinkNodes.length)
    readonly property int visibleStreamCount: Math.min(3, root.streamNodes.length)
    readonly property real sinkListHeight: root.visibleSinkCount > 0 ? root.labelHeight + root.deviceRowSpacing + root.visibleSinkCount * root.deviceRowHeight + Math.max(0, root.visibleSinkCount - 1) * root.deviceRowSpacing : 0
    readonly property real streamListHeight: root.visibleStreamCount > 0 ? root.labelHeight + root.deviceRowSpacing + root.visibleStreamCount * root.streamRowHeight + Math.max(0, root.visibleStreamCount - 1) * root.deviceRowSpacing : 0
    readonly property real bodyHeight: root.sliderRowHeight * 2 + root.sectionSpacing
                                       + (root.sinkListHeight > 0 ? root.sectionSpacing + root.sinkListHeight : 0)
                                       + (root.streamListHeight > 0 ? root.sectionSpacing + root.streamListHeight : 0)
    readonly property real contentHeight: Math.min(root.maxPanelHeight, root.panelPadding * 2 + root.headerHeight + root.sectionSpacing + root.bodyHeight)
    readonly property real panelProgress: Math.max(0, Math.min(1, (root.morph - 0.22) / 0.78))

    signal closeRequested
    signal stepRequested(int steps)
    signal volumeRequested(int level)
    signal muteRequested
    signal inputVolumeRequested(int level)
    signal inputMuteRequested
    signal sinkRequested(var node)
    signal streamVolumeRequested(var node, int level)
    signal streamMuteRequested(var node)

    function nodeLabel(node) {
        const properties = node?.properties ?? {};
        return properties["application.name"] || properties["media.name"] || node?.description || node?.nickname || node?.name || "Audio";
    }

    function nodePercent(node) {
        const raw = node?.audio?.volume ?? 0;
        return Math.max(0, Math.min(100, Math.round(raw * 100)));
    }

    opacity: root.panelProgress
    visible: opacity > 0.001
    scale: 0.94 + 0.06 * root.panelProgress
    transformOrigin: Item.Top

    // A level track that reports the clicked/dragged position as a percentage.
    // Kept local so the panel owns no process and no external control style.
    component LevelSlider: Item {
        id: slider

        property int value: 0
        property bool dimmed: false

        signal moved(int level)

        implicitHeight: 18

        function report(x) {
            const ratio = slider.width <= 0 ? 0 : Math.max(0, Math.min(1, x / slider.width));
            slider.moved(Math.round(ratio * 100));
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.controlPressed

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, slider.value)) / 100
                height: parent.height
                radius: parent.radius
                color: slider.dimmed ? Theme.muted : Theme.accent

                Behavior on width {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => slider.report(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    slider.report(mouse.x);
            }
        }
    }

    // Scrolling anywhere over the mixer keeps adjusting the master level, so the
    // gesture that opened the panel does not have to be restarted.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.stepRequested(wheel.angleDelta.y)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: root.sectionSpacing

        PanelHeader {
            Layout.preferredHeight: root.headerHeight
            icon: root.outputMuted ? "volume_off" : (root.outputVolume < 50 ? "volume_down" : "volume_up")
            iconDimmed: root.outputMuted
            title: "Áudio"
            fontFamily: root.fontFamily
            onCloseRequested: root.closeRequested()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.sliderRowHeight
            spacing: 10

            MIcon {
                name: root.outputMuted ? "volume_off" : (root.outputVolume < 50 ? "volume_down" : "volume_up")
                size: 14
                color: root.outputMuted ? Theme.muted : root.primaryText

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.muteRequested()
                }
            }

            LevelSlider {
                Layout.fillWidth: true
                value: root.outputVolume
                dimmed: root.outputMuted
                onMoved: level => root.volumeRequested(level)
            }

            Text {
                Layout.preferredWidth: 34
                text: root.outputVolume + "%"
                color: root.outputMuted ? Theme.muted : root.primaryText
                horizontalAlignment: Text.AlignRight
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.sliderRowHeight
            spacing: 10

            MIcon {
                name: "mic"
                size: 14
                color: root.inputMuted ? Theme.muted : root.primaryText

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.inputMuteRequested()
                }
            }

            LevelSlider {
                Layout.fillWidth: true
                value: root.inputVolume
                dimmed: root.inputMuted
                onMoved: level => root.inputVolumeRequested(level)
            }

            Text {
                Layout.preferredWidth: 34
                text: root.inputVolume + "%"
                color: root.inputMuted ? Theme.muted : root.primaryText
                horizontalAlignment: Text.AlignRight
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.visibleSinkCount > 0
            spacing: root.deviceRowSpacing

            Text {
                text: "Saída"
                color: Theme.muted
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            Repeater {
                model: root.sinkNodes

                Rectangle {
                    required property var modelData

                    readonly property bool current: modelData?.name === root.activeSinkName

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.deviceRowHeight
                    radius: Style.rowRadius
                    color: current ? Theme.selected : (sinkMouse.containsMouse ? Theme.controlHover : Theme.controlNormal)
                    border.width: 1
                    border.color: current ? Theme.accent : Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        MIcon {
                            name: "headphones"
                            size: 12
                            color: parent.parent.current ? Theme.accent : Theme.muted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.nodeLabel(parent.parent.modelData)
                            color: root.primaryText
                            elide: Text.ElideRight
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        MIcon {
                            name: "check"
                            size: 12
                            visible: parent.parent.current
                            color: Theme.accent
                        }
                    }

                    MouseArea {
                        id: sinkMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sinkRequested(parent.modelData)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.visibleStreamCount > 0
            spacing: root.deviceRowSpacing

            Text {
                text: "Por aplicativo"
                color: Theme.muted
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            Repeater {
                model: root.streamNodes

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.streamRowHeight
                    spacing: 8

                    MIcon {
                        name: modelData?.audio?.muted ? "volume_off" : "volume_up"
                        size: 12
                        color: modelData?.audio?.muted ? Theme.muted : Theme.foreground

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.streamMuteRequested(parent.parent.modelData)
                        }
                    }

                    Text {
                        Layout.preferredWidth: 96
                        text: root.nodeLabel(parent.modelData)
                        color: root.primaryText
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    LevelSlider {
                        Layout.fillWidth: true
                        value: root.nodePercent(parent.modelData)
                        dimmed: parent.modelData?.audio?.muted ?? false
                        onMoved: level => root.streamVolumeRequested(parent.modelData, level)
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
