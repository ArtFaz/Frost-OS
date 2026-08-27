import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
pragma Singleton

QtObject {
    id: root

    readonly property bool audioAvailable: Pipewire.ready && audioSink !== null
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property real volume: audioSink && audioSink.audio ? audioSink.audio.volume : 0
    readonly property bool muted: !audioSink || !audioSink.audio || audioSink.audio.muted
    readonly property real microphoneVolume: audioSource && audioSource.audio ? audioSource.audio.volume : 0
    readonly property bool microphoneMuted: !audioSource || !audioSource.audio || audioSource.audio.muted
    readonly property var audioNodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var activePlayer: choosePlayer()
    readonly property bool networkAvailable: Networking.backend === NetworkBackendType.NetworkManager
    readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: findNetworkDevice(DeviceType.Wifi)
    readonly property var wiredDevice: findNetworkDevice(DeviceType.Wired)
    readonly property var wifiNetworks: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    readonly property var connectedWifi: findConnectedWifi()
    readonly property bool wiredConnected: wiredDevice !== null && wiredDevice.connected
    readonly property string networkName: wiredConnected ? "Ethernet" : connectedWifi ? connectedWifi.name : "Offline"
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: bluetoothAdapter !== null
    readonly property var bluetoothDevices: Bluetooth.devices ? Bluetooth.devices.values : []
    readonly property int bluetoothConnectedCount: countConnectedBluetooth()
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: battery !== null && battery.isPresent
    readonly property int batteryPercent: batteryAvailable ? Math.round(battery.percentage * 100) : 0
    property PwObjectTracker pipewireTracker

    function choosePlayer() {
        let fallback = null;
        for (let index = 0; index < players.length; index++) {
            const player = players[index];
            if (!fallback && (player.trackTitle || player.trackArtist))
                fallback = player;

            if (player.isPlaying)
                return player;

        }
        return fallback;
    }

    function findNetworkDevice(type) {
        for (let index = 0; index < networkDevices.length; index++) {
            if (networkDevices[index].type === type)
                return networkDevices[index];

        }
        return null;
    }

    function findConnectedWifi() {
        for (let index = 0; index < wifiNetworks.length; index++) {
            if (wifiNetworks[index].connected)
                return wifiNetworks[index];

        }
        return null;
    }

    function countConnectedBluetooth() {
        let count = 0;
        for (let index = 0; index < bluetoothDevices.length; index++) {
            if (bluetoothDevices[index].connected)
                count++;

        }
        return count;
    }

    function setVolume(value) {
        if (audioSink && audioSink.audio)
            audioSink.audio.volume = Math.max(0, Math.min(1.5, Number(value)));

    }

    function toggleMute() {
        if (audioSink && audioSink.audio)
            audioSink.audio.muted = !audioSink.audio.muted;

    }

    function setMicrophoneVolume(value) {
        if (audioSource && audioSource.audio)
            audioSource.audio.volume = Math.max(0, Math.min(1.5, Number(value)));

    }

    function toggleMicrophoneMute() {
        if (audioSource && audioSource.audio)
            audioSource.audio.muted = !audioSource.audio.muted;

    }

    function toggleWifi() {
        if (networkAvailable && Networking.wifiHardwareEnabled)
            Networking.wifiEnabled = !Networking.wifiEnabled;

    }

    function toggleBluetooth() {
        if (bluetoothAdapter)
            bluetoothAdapter.enabled = !bluetoothAdapter.enabled;

    }

    pipewireTracker: PwObjectTracker {
        objects: {
            const tracked = [];
            if (root.audioSink)
                tracked.push(root.audioSink);

            if (root.audioSource)
                tracked.push(root.audioSource);

            return tracked;
        }
    }

}
