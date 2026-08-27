import QtQuick
import Quickshell.Services.Pipewire
import qs.Core
import qs.Primitives

Item {
    id: root

    signal backRequested()

    function sinks() {
        const output = [];
        for (let index = 0; index < SystemState.audioNodes.length; index++) {
            const node = SystemState.audioNodes[index];
            if (node && node.ready && node.audio && node.isSink && !node.isStream)
                output.push(node);

        }
        return output;
    }

    function sources() {
        const output = [];
        for (let index = 0; index < SystemState.audioNodes.length; index++) {
            const node = SystemState.audioNodes[index];
            if (node && node.ready && node.audio && !node.isSink && !node.isStream)
                output.push(node);

        }
        return output;
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 12

        PanelHeader {
            width: parent.width
            title: "Audio"
            subtitle: SystemState.audioAvailable ? "PipeWire controls" : "Audio service unavailable"
            showBack: true
            onBack: root.backRequested()
        }

        Rectangle {
            width: parent.width
            height: 82
            radius: Theme.rowRadius
            color: Theme.controlNormal

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Row {
                    width: parent.width

                    Text {
                        width: parent.width - outputMute.width
                        text: "Output · " + Math.round(SystemState.volume * 100) + "%"
                        color: Theme.foreground
                        font.family: Style.fontFamily
                        font.pixelSize: Style.body
                        font.bold: true
                    }

                    SurfaceButton {
                        id: outputMute

                        width: 58
                        height: 26
                        compact: true
                        title: SystemState.muted ? "Unmute" : "Mute"
                        onActivated: SystemState.toggleMute()
                    }

                }

                ValueSlider {
                    width: parent.width
                    value: Math.min(1, SystemState.volume)
                    enabled: SystemState.audioAvailable
                    onMoved: (value) => {
                        return SystemState.setVolume(value);
                    }
                }

            }

        }

        Rectangle {
            width: parent.width
            height: 82
            radius: Theme.rowRadius
            color: Theme.controlNormal

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Row {
                    width: parent.width

                    Text {
                        width: parent.width - inputMute.width
                        text: "Microphone · " + Math.round(SystemState.microphoneVolume * 100) + "%"
                        color: Theme.foreground
                        font.family: Style.fontFamily
                        font.pixelSize: Style.body
                        font.bold: true
                    }

                    SurfaceButton {
                        id: inputMute

                        width: 58
                        height: 26
                        compact: true
                        title: SystemState.microphoneMuted ? "Unmute" : "Mute"
                        onActivated: SystemState.toggleMicrophoneMute()
                    }

                }

                ValueSlider {
                    width: parent.width
                    value: Math.min(1, SystemState.microphoneVolume)
                    enabled: SystemState.audioSource !== null
                    onMoved: (value) => {
                        return SystemState.setMicrophoneVolume(value);
                    }
                }

            }

        }

        Text {
            text: "Outputs"
            color: Theme.muted
            font.family: Style.fontFamily
            font.pixelSize: Style.bodySmall
            font.bold: true
        }

        Repeater {
            model: root.sinks()

            SurfaceButton {
                required property var modelData

                width: parent.width
                title: modelData.description || modelData.nickname || modelData.name
                subtitle: "Audio output"
                selected: modelData === SystemState.audioSink
                trailingText: selected ? "Default" : "Select"
                onActivated: Pipewire.preferredDefaultAudioSink = modelData
            }

        }

        Text {
            text: "Inputs"
            color: Theme.muted
            font.family: Style.fontFamily
            font.pixelSize: Style.bodySmall
            font.bold: true
        }

        Repeater {
            model: root.sources()

            SurfaceButton {
                required property var modelData

                width: parent.width
                title: modelData.description || modelData.nickname || modelData.name
                subtitle: "Audio input"
                selected: modelData === SystemState.audioSource
                trailingText: selected ? "Default" : "Select"
                onActivated: Pipewire.preferredDefaultAudioSource = modelData
            }

        }

    }

}
