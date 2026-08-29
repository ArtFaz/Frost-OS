import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.Core

Scope {
    id: root

    property string mode: "idle"
    property bool runtimeVisible: Config.island.enabled
    property string appName: "Dynamic Glacier"
    property string title: "Ready"
    property string body: "Waiting for a signal"
    property string artist: ""
    property string artUrl: ""
    property int volume: 42
    property bool muted: false
    property bool volumeIndicatorVisible: false
    // "audio" or "brightness" — the HUD is the same pill, only the glyph differs.
    property string volumeKind: "audio"
    property bool playing: true
    property bool demoRunning: false
    property bool pointerInside: false
    property bool pinnedOpen: false
    // Which face the open peek shows while something is playing. The arrow in
    // each face flips it; it resets to "media" as soon as playback ends, so the
    // next track opens on the media face again.
    property string peekFace: "media"
    property bool liveLinksEnabled: true
    property bool liveLinksPrimed: false
    property bool privacyDebugEnabled: false
    property bool debugMicrophoneActive: false
    property bool debugCameraActive: false
    property bool polledCameraActive: false
    // Empty when the machine has no backlight, which disables the poll.
    property string backlightPath: ""
    property int backlightMaxRaw: 0
    property date currentDateTime: new Date()
    property string handleStyle: Config.island.handleStyle
    property int peekWidth: Config.island.idleWidth
    property int peekHeight: Config.island.idleHeight
    property bool exitPreviewActive: false
    property int exitPreviewWidth: 340
    property var activePlayer: null
    property string lastTrackKey: ""
    property real lastSinkVolume: -1
    property bool lastSinkMuted: false
    property int lastBatteryLevel: -1
    property bool lastBatteryPluggedIn: false
    property int lastBrightnessLevel: -1
    property int demoStep: 0
    property var trayMenuItem: null
    property var notificationEntries: []
    property bool notificationsDnd: false
    property bool notificationsBusy: false
    property string notificationsStatusText: ""
    property bool stayAwakeActive: false
    property bool stayAwakeBusy: false

    readonly property bool interactionOpen: root.mode === "idle" && (root.pointerInside || root.pinnedOpen || root.exitPreviewActive)
    readonly property int mediaPlayerCount: root.mediaPlayerList().length
    readonly property int mediaPlayerIndex: root.mediaPlayerList().indexOf(root.activePlayer)
    readonly property bool mediaFaceAvailable: root.liveLinksEnabled && root.hasActiveMedia()
    readonly property bool hoverMediaMode: root.mediaFaceAvailable && root.peekFace === "media" && root.mode === "idle" && root.interactionOpen && !root.exitPreviewActive
    // The volume HUD is a transient morph, so it only takes over the idle shape —
    // a notification, the media card or an open panel all outrank it.
    readonly property bool volumeHudMode: root.volumeIndicatorVisible && root.mode === "idle" && !root.interactionOpen
    readonly property string visualMode: root.volumeHudMode ? "volume" : (root.hoverMediaMode ? "media" : root.mode)
    readonly property int idleTopMargin: 0
    readonly property int expandedTopMargin: 0
    readonly property int reservedZone: root.handleStyle === "strip" ? 0 : 24
    readonly property int windowHeight: 136
    readonly property int bumpWidth: 104
    readonly property int handleWidth: root.handleStyle === "strip" ? root.stripWidth : root.bumpWidth
    readonly property int bumpHeight: 24
    readonly property int stripWidth: 98
    readonly property int stripHeight: 4
    // Media is a face of the open peek, not a separate shape, so it tracks the
    // pill geometry with enough headroom for its own header row.
    readonly property int mediaWidth: root.peekWidth
    readonly property int mediaHeight: root.peekHeight
    readonly property int volumeWidth: 244
    readonly property int volumeHeight: 48
    readonly property int wifiWidth: 500
    // Floor for the Wi-Fi panel; the island grows past it to fit the network list,
    // up to wifiMaxPanelHeight.
    readonly property int wifiMinHeight: 132
    readonly property int wifiMaxPanelHeight: 440
    readonly property int btWidth: 500
    readonly property int btMinHeight: 132
    readonly property int btMaxPanelHeight: 440
    readonly property int batteryWidth: 500
    readonly property int batteryMinHeight: 132
    readonly property int notificationsWidth: 500
    readonly property int notificationsMinHeight: 132
    readonly property int notificationsMaxPanelHeight: 440
    readonly property int audioWidth: 500
    readonly property int audioMinHeight: 132
    readonly property int audioMaxPanelHeight: 440
    readonly property string fontFamily: Style.fontFamily
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property var audioSinkNodes: root.collectAudioNodes(true)
    readonly property int audioVolume: root.sinkVolumePercent()
    readonly property bool audioMuted: root.sinkMuted()
    readonly property int audioInputVolume: root.sourceVolumePercent()
    readonly property bool audioInputMuted: root.sourceMuted()
    readonly property string audioActiveSinkName: root.audioSink?.name ?? ""
    readonly property var audioStreamNodes: root.collectPlaybackStreams()
    property real wheelRemainder: 0
    readonly property bool mediaCanGoPrevious: root.activePlayer?.canGoPrevious ?? false
    readonly property bool mediaCanTogglePlaying: (root.activePlayer?.canTogglePlaying ?? false) || (root.activePlayer?.canPause ?? false) || (root.activePlayer?.canPlay ?? false)
    readonly property bool mediaCanGoNext: root.activePlayer?.canGoNext ?? false
    readonly property real mediaPosition: Math.max(0, root.activePlayer?.position ?? 0)
    readonly property real mediaLength: Math.max(0, root.activePlayer?.length ?? 0)
    readonly property bool mediaShuffleSupported: root.activePlayer?.shuffleSupported ?? false
    readonly property bool mediaShuffleActive: root.activePlayer?.shuffle ?? false
    readonly property bool mediaLoopSupported: root.activePlayer?.loopSupported ?? false
    readonly property var mediaLoopState: root.activePlayer?.loopState ?? MprisLoopState.None
    readonly property bool mediaLoopActive: root.mediaLoopState !== MprisLoopState.None
    readonly property string mediaLoopStateText: root.mediaLoopState === MprisLoopState.Track ? "ONE" : (root.mediaLoopState === MprisLoopState.Playlist ? "ALL" : "RPT")
    readonly property bool microphoneActive: root.privacyDebugEnabled ? root.debugMicrophoneActive : root.liveLinksEnabled && root.detectMicrophoneActivity()
    readonly property bool cameraActive: root.privacyDebugEnabled ? root.debugCameraActive : root.liveLinksEnabled && (root.detectVideoActivity() || root.polledCameraActive)
    readonly property bool privacyActive: root.microphoneActive || root.cameraActive
    // The side rails ride outside the glass. They stay out of the way whenever a
    // full panel owns the island.
    readonly property bool railsVisible: root.visualMode === "idle" && !root.interactionOpen
    readonly property bool compactPrivacyIndicators: root.handleStyle === "strip" && root.visualMode === "idle" && !root.interactionOpen
    readonly property color microphoneIndicatorColor: Theme.warning
    readonly property color cameraIndicatorColor: Theme.success
    readonly property string batteryHoverText: root.batteryAvailable() ? (root.batteryPluggedIn() ? "CHG " : "BAT ") + root.batteryLevel() + "%" : ""
    readonly property string hoverTimeText: root.formatClockTime(root.currentDateTime)
    readonly property string hoverDateText: root.formatClockDate(root.currentDateTime)
    readonly property bool mediaAvailable: root.liveLinksEnabled && root.hasActiveMedia()
    readonly property bool mediaCanSeek: (root.activePlayer?.canSeek ?? false) && (root.activePlayer?.positionSupported ?? false) && root.mediaLength > 0

    // WiFi
    property string wifiSsid: ""
    property int wifiSignal: 0
    readonly property bool wifiConnected: root.wifiSsid !== ""

    // WiFi manager panel (morphs the island into mode "wifi")
    property bool wifiRadioEnabled: true
    property var wifiNetworks: []
    property var savedWifiProfiles: []
    property string wifiExpandedSsid: ""
    property string wifiPasswordDraft: ""
    property string pendingWifiPassword: ""
    property string pendingWifiSsid: ""
    property bool pendingWifiSecured: false
    property bool pendingWifiUsedPassword: false
    property string wifiStatusText: ""
    property bool wifiConnecting: false
    property double lastWifiScanAt: 0

    // Bluetooth manager. Quickshell talks to BlueZ directly, so the panel and
    // compact status stay reactive without polling bluetoothctl through a shell.
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property var btDevices: root.sortedBluetoothDevices()
    readonly property var btConnectedDevice: root.btDevices.find(device => device.connected) ?? null
    readonly property bool btEnabled: root.btAdapter?.enabled ?? false
    readonly property bool btConnected: root.btConnectedDevice !== null
    readonly property string btDeviceName: root.btConnectedDevice?.name || root.btConnectedDevice?.deviceName || ""
    readonly property int btBattery: root.btConnectedDevice?.batteryAvailable ? Math.round(root.btConnectedDevice.battery * 100) : -1
    readonly property bool btDiscovering: root.btAdapter?.discovering ?? false
    property string btStatusText: ""
    property bool pendingBluetoothEnabled: false

    // Detailed battery telemetry combines reactive UPower state with values that
    // are only exposed by the kernel power_supply interface on this machine.
    readonly property var batteryDevice: UPower.devices.values.find(device => device.isLaptopBattery && (device.nativePath ?? "") !== "") ?? UPower.displayDevice
    readonly property string batterySysfsPath: (root.batteryDevice?.nativePath ?? "") !== "" ? "/sys/class/power_supply/" + root.batteryDevice.nativePath : ""
    readonly property int batteryCycles: root.fileNumber(batteryCycleFile, -1)
    readonly property real batteryFullCharge: root.fileNumber(batteryFullFile, -1)
    readonly property real batteryDesignCharge: root.fileNumber(batteryDesignFile, -1)
    readonly property real batteryFullEnergy: root.fileNumber(batteryFullEnergyFile, -1)
    readonly property real batteryDesignEnergy: root.fileNumber(batteryDesignEnergyFile, -1)
    readonly property real batteryDesignVoltage: root.fileNumber(batteryDesignVoltageFile, -1)
    readonly property real batteryVoltage: root.fileNumber(batteryVoltageFile, -1) / 1000000
    readonly property real batteryCurrent: root.fileNumber(batteryCurrentFile, -1) / 1000000
    readonly property real batteryPowerNow: root.fileNumber(batteryPowerFile, -1) / 1000000
    readonly property real batteryFullCapacityWh: root.batteryFullEnergy >= 0 ? root.batteryFullEnergy / 1000000
                                                     : (root.batteryFullCharge >= 0 && root.batteryDesignVoltage > 0 ? root.batteryFullCharge * root.batteryDesignVoltage / 1000000000000 : -1)
    readonly property real batteryDesignCapacityWh: root.batteryDesignEnergy >= 0 ? root.batteryDesignEnergy / 1000000
                                                       : (root.batteryDesignCharge >= 0 && root.batteryDesignVoltage > 0 ? root.batteryDesignCharge * root.batteryDesignVoltage / 1000000000000 : -1)
    readonly property real batteryHealth: root.batteryFullCapacityWh >= 0 && root.batteryDesignCapacityWh > 0 ? Math.min(100, root.batteryFullCapacityWh / root.batteryDesignCapacityWh * 100)
                                                : (root.batteryDevice?.healthSupported ? Math.min(100, Number(root.batteryDevice.healthPercentage || 0) * 100) : -1)
    readonly property real batteryPower: root.batteryPowerNow >= 0 ? root.batteryPowerNow
                                               : (root.batteryVoltage >= 0 && root.batteryCurrent >= 0 ? Math.abs(root.batteryVoltage * root.batteryCurrent) : -1)
    readonly property string batteryStatus: root.fileText(batteryStatusFile, "")
    readonly property string batteryModel: root.fileText(batteryModelFile, "")
    readonly property string batteryDbusPath: (root.batteryDevice?.nativePath ?? "") !== "" ? "/org/freedesktop/UPower/devices/battery_" + root.batteryDevice.nativePath.replace(/[^A-Za-z0-9_]/g, "_") : ""
    property bool batteryThresholdSupported: false
    property bool batteryThresholdEnabled: false
    property bool batteryThresholdBusy: false
    property bool pendingBatteryThresholdEnabled: false
    property int batteryThresholdStart: -1
    property int batteryThresholdEnd: -1
    property string batteryThresholdStatusText: ""
    property bool powerProfilesAvailable: false
    property var availablePowerProfiles: []
    property string activePowerProfile: ""
    property bool powerProfileBusy: false
    property string pendingPowerProfile: ""
    property string powerProfileStatusText: ""
    property string performanceDegraded: ""
    property string performanceInhibited: ""

    function targetWidth() {
        switch (root.visualMode) {
        case "media":
            return root.mediaWidth;
        case "volume":
            return root.volumeWidth;
        case "wifi":
            return root.wifiWidth;
        case "bluetooth":
            return root.btWidth;
        case "battery":
            return root.batteryWidth;
        case "audio":
            return root.audioWidth;
        case "notifications":
            return root.notificationsWidth;
        default:
            if (root.interactionOpen)
                return root.exitPreviewActive ? Math.max(root.peekWidth, root.exitPreviewWidth) : root.peekWidth;
            return root.handleStyle === "strip" ? root.stripWidth : root.bumpWidth;
        }
    }

    function targetHeight() {
        switch (root.visualMode) {
        case "media":
            return root.mediaHeight;
        case "volume":
            return root.volumeHeight;
        case "wifi":
            return root.wifiMinHeight;
        case "bluetooth":
            return root.btMinHeight;
        case "battery":
            return root.batteryMinHeight;
        case "audio":
            return root.audioMinHeight;
        case "notifications":
            return root.notificationsMinHeight;
        default:
            if (root.interactionOpen)
                return root.peekHeight;
            return root.handleStyle === "strip" ? root.stripHeight : root.bumpHeight;
        }
    }

    // Single source of truth for "a full panel owns the island right now".
    // Previously this was seven hand-synchronised string-literal lists.
    readonly property var panelModes: ["wifi", "bluetooth", "battery", "audio", "notifications"]

    function isPanelMode(name) {
        return root.panelModes.indexOf(name) !== -1;
    }

    function targetY() {
        return root.visualMode === "idle" && !root.interactionOpen ? root.idleTopMargin : root.expandedTopMargin;
    }

    function hold(milliseconds) {
        collapseTimer.interval = milliseconds;
        collapseTimer.restart();
    }

    // makoctl serialises D-Bus variants as { "type": "s", "data": ... }, and wraps
    // the array one or two levels deep depending on the call. Both shapes are
    // unwrapped defensively so a format change degrades to an empty list rather
    // than throwing inside a binding.
    function makoValue(field, fallback) {
        if (field === null || field === undefined)
            return fallback;
        if (typeof field === "object" && !Array.isArray(field) && field.data !== undefined)
            return field.data === null || field.data === undefined ? fallback : field.data;
        return field;
    }

    function normalizeNotifications(raw) {
        let list = raw;

        if (list && !Array.isArray(list) && list.data !== undefined)
            list = list.data;
        while (Array.isArray(list) && list.length === 1 && Array.isArray(list[0]))
            list = list[0];
        if (!Array.isArray(list))
            return [];

        const entries = [];

        for (let i = 0; i < list.length && entries.length < 50; i += 1) {
            const item = list[i];
            if (!item || typeof item !== "object")
                continue;

            const id = Number(root.makoValue(item.id, 0));
            if (!isFinite(id) || id < 0)
                continue;

            entries.push({
                id: Math.round(id),
                appName: String(root.makoValue(item["app-name"], "")),
                summary: String(root.makoValue(item.summary, "")),
                body: String(root.makoValue(item.body, "")).replace(/\s+/g, " ").trim()
            });
        }

        return entries;
    }

    function refreshNotifications() {
        ShellBackend.query("notifications");
    }

    function toggleNotificationsPanel() {
        if (root.mode === "notifications") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "notifications";
        root.refreshNotifications();
    }

    function toggleNotificationsDnd() {
        if (root.notificationsBusy)
            return;

        root.notificationsBusy = true;
        ShellBackend.action("notification-dnd", root.notificationsDnd ? "off" : "on");
    }

    function dismissNotification(id) {
        ShellBackend.action("notification-dismiss", String(id));
    }

    function invokeNotification(id) {
        ShellBackend.action("notification-invoke", String(id));
    }

    function clearNotifications() {
        ShellBackend.action("notification-clear");
    }

    function refreshIndicators() {
        ShellBackend.query("indicators");
    }

    function toggleStayAwake() {
        if (root.stayAwakeBusy)
            return;

        root.stayAwakeBusy = true;
        ShellBackend.action("stay-awake-toggle");
    }

    function keepInteractionOpen(prepareMedia) {
        hoverLeaveTimer.stop();
        root.pointerInside = true;
        // The query is a process round trip, so it is refreshed when the island
        // opens rather than polled.
        root.refreshIndicators();
        root.refreshNotifications();

        if (prepareMedia)
            root.prepareHoverMedia();
    }

    function scheduleInteractionClose() {
        // Detail panels are hover-owned even when the idle island was pinned.
        // Keeping the pinned state only applies to the compact idle peek.
        if (root.isPanelMode(root.mode) || !root.pinnedOpen)
            hoverLeaveTimer.restart();
    }

    function boolFromIpc(value) {
        return value === true || value === "true" || value === "1" || value === "on" || value === "yes";
    }

    function fileText(fileView, fallback) {
        if (!fileView?.loaded)
            return fallback;

        const value = fileView.text().trim();
        return value !== "" ? value : fallback;
    }

    function fileNumber(fileView, fallback) {
        const text = root.fileText(fileView, "");

        if (text === "")
            return fallback;

        const value = Number(text);
        return isFinite(value) ? value : fallback;
    }

    function pad2(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function formatClockTime(value) {
        const date = new Date(value);

        return root.pad2(date.getHours()) + ":" + root.pad2(date.getMinutes());
    }

    function formatClockDate(value) {
        const date = new Date(value);
        const shortDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        const day = date.getDay();

        return root.pad2(date.getDate()) + "." + root.pad2(date.getMonth() + 1) + "." + date.getFullYear() + ", " + shortDays[day];
    }

    function showIdle(preserveExitPreview) {
        const keepExitPreview = preserveExitPreview === true;

        root.trayMenuItem = null;

        if (root.mode === "bluetooth" && root.btAdapter?.discovering)
            root.btAdapter.discovering = false;

        collapseTimer.stop();
        root.mode = "idle";
        root.pinnedOpen = false;
        if (!keepExitPreview)
            root.exitPreviewActive = false;
        root.title = "Ready";
        root.body = "Waiting for a signal";
        root.wifiExpandedSsid = "";
        root.wifiPasswordDraft = "";
        root.wifiStatusText = "";
        root.btStatusText = "";

        if (root.liveLinksEnabled) {
            root.chooseActivePlayer(null);
            if (root.hasActiveMedia())
                root.syncMediaFields(root.activePlayer);
        }
    }

    function closePanelToWideIdle(panelWidth) {
        root.exitPreviewWidth = Math.max(root.peekWidth, panelWidth);
        root.exitPreviewActive = true;
        root.pointerInside = true;
        root.showIdle(true);
    }

    function maybeFinishExitPreview(localX, areaWidth) {
        if (!root.exitPreviewActive)
            return;

        const normalWidth = Math.min(root.peekWidth, areaWidth);
        const normalLeft = (areaWidth - normalWidth) / 2;

        if (localX >= normalLeft && localX <= normalLeft + normalWidth) {
            root.exitPreviewActive = false;
            root.pointerInside = true;
        }
    }

    function showMedia(trackTitle, trackArtist, isPlaying, trackArtUrl) {
        root.title = trackTitle || "Unknown track";
        root.artist = trackArtist || "Unknown artist";
        root.artUrl = trackArtUrl || "";
        root.playing = isPlaying;
        root.mode = "media";
        root.hold(6200);
    }

    // The HUD no longer borrows `title` — it morphs into its own pill, and writing
    // the title here would have leaked "Volume" into a notification sitting behind it.
    function showVolume(level, isMuted) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = isMuted;
        root.volumeKind = "audio";
        root.volumeIndicatorVisible = true;
        volumeIndicatorTimer.restart();
    }

    function showBrightness(level) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = false;
        root.volumeKind = "brightness";
        root.volumeIndicatorVisible = true;
        volumeIndicatorTimer.restart();
    }

    function trackTitle(player) {
        return player?.trackTitle || "Unknown track";
    }

    function trackArtist(player) {
        return player?.trackArtist || player?.identity || "Unknown artist";
    }

    function trackArtUrl(player) {
        return player?.trackArtUrl || "";
    }

    function trackKey(player) {
        if (!player)
            return "";

        return [player.uniqueId || player.dbusName || "", root.trackTitle(player), root.trackArtist(player), player.isPlaying ? "playing" : "paused"].join("|");
    }

    function syncMediaFields(player) {
        if (!player)
            return;

        root.title = root.trackTitle(player);
        root.artist = root.trackArtist(player);
        root.artUrl = root.trackArtUrl(player);
        root.playing = player.isPlaying;
    }

    function hasActiveMedia() {
        const player = root.activePlayer;

        if (!player)
            return false;

        return player.isPlaying || root.trackTitle(player) !== "Unknown track";
    }

    // Every player worth cycling through: one that is playing, or one that at
    // least reports a track. A player sitting on "Unknown track" is not a
    // destination the user asked for.
    function mediaPlayerList() {
        const players = Mpris.players.values;
        const usable = [];

        for (let i = 0; i < players.length; i += 1) {
            const player = players[i];
            if (player.isPlaying || root.trackTitle(player) !== "Unknown track")
                usable.push(player);
        }

        return usable;
    }

    function selectMediaPlayer(index) {
        const players = root.mediaPlayerList();

        if (index < 0 || index >= players.length)
            return;

        const next = players[index];
        if (next === root.activePlayer)
            return;

        root.activePlayer = next;
        root.syncMediaFields(next);
        root.lastTrackKey = root.trackKey(next);
        root.keepInteractionOpen(false);
    }

    function cycleMediaPlayer() {
        const players = root.mediaPlayerList();

        if (players.length < 2)
            return;

        let index = players.indexOf(root.activePlayer);
        if (index < 0)
            index = 0;

        const next = players[(index + 1) % players.length];

        root.activePlayer = next;
        root.syncMediaFields(next);
        root.lastTrackKey = root.trackKey(next);
        // Staying on the media face is the point of the gesture, so the hover
        // close timer is pushed back the way any other interaction does.
        root.keepInteractionOpen(false);
    }

    function chooseActivePlayer(preferredPlayer) {
        const players = Mpris.players.values;

        if (preferredPlayer) {
            root.activePlayer = preferredPlayer;
            return;
        }

        for (let i = 0; i < players.length; i += 1) {
            if (players[i].isPlaying) {
                root.activePlayer = players[i];
                return;
            }
        }

        root.activePlayer = players.length > 0 ? players[0] : null;
    }

    function prepareHoverMedia() {
        if (!root.liveLinksEnabled)
            return;

        root.chooseActivePlayer(null);
        root.syncMediaFields(root.activePlayer);
    }

    function mediaPrevious() {
        if (root.activePlayer?.canGoPrevious)
            root.activePlayer.previous();
    }

    function mediaTogglePlaying() {
        const player = root.activePlayer;

        if (!player)
            return;

        if (player.canTogglePlaying) {
            player.togglePlaying();
        } else if (player.isPlaying && player.canPause) {
            player.pause();
        } else if (!player.isPlaying && player.canPlay) {
            player.play();
        }
    }

    function mediaNext() {
        if (root.activePlayer?.canGoNext)
            root.activePlayer.next();
    }

    function mediaToggleShuffle() {
        const player = root.activePlayer;

        if (!player || !player.shuffleSupported)
            return;

        player.shuffle = !player.shuffle;
    }

    function mediaCycleLoop() {
        const player = root.activePlayer;

        if (!player || !player.loopSupported)
            return;

        if (player.loopState === MprisLoopState.None) {
            player.loopState = MprisLoopState.Track;
        } else if (player.loopState === MprisLoopState.Track) {
            player.loopState = MprisLoopState.Playlist;
        } else {
            player.loopState = MprisLoopState.None;
        }
    }

    function maybeShowMediaFromPlayer(preferredPlayer, force) {
        if (!root.liveLinksEnabled)
            return;

        root.chooseActivePlayer(preferredPlayer);
        const player = root.activePlayer;
        const key = root.trackKey(player);

        if (!player || !key)
            return;

        const keepMediaFieldsFresh = root.mode === "idle" || root.hoverMediaMode;

        if (keepMediaFieldsFresh)
            root.syncMediaFields(player);

        if (!root.liveLinksPrimed) {
            root.lastTrackKey = key;
            return;
        }

        if (force || key !== root.lastTrackKey) {
            root.lastTrackKey = key;
            if (keepMediaFieldsFresh)
                root.syncMediaFields(player);
        }
    }

    function mediaSeek(position) {
        const player = root.activePlayer;

        if (!player || !root.mediaCanSeek)
            return;

        player.position = Math.max(0, Math.min(root.mediaLength, Number(position)));
    }

    function sinkVolumePercent() {
        const rawVolume = root.audioSink?.audio?.volume ?? 0;
        return Math.max(0, Math.min(100, Math.round(rawVolume * 100)));
    }

    function sinkMuted() {
        return root.audioSink?.audio?.muted ?? false;
    }

    function clampVolume(value) {
        const numeric = Number(value);
        return isFinite(numeric) ? Math.max(0, Math.min(1, numeric)) : 0;
    }

    function setSinkVolume(percent) {
        const audio = root.audioSink?.audio ?? null;
        if (!audio)
            return;

        audio.volume = root.clampVolume(Number(percent) / 100);
        if (audio.muted && audio.volume > 0)
            audio.muted = false;
    }

    // Wheel events arrive as sub-notch deltas on a touchpad, so the remainder is
    // carried across events instead of being rounded away to nothing.
    function stepSinkVolume(delta) {
        const bounded = Math.max(-120, Math.min(120, Number(delta) || 0));
        const accumulated = root.wheelRemainder + bounded;
        const steps = (accumulated - accumulated % 120) / 120;

        root.wheelRemainder = accumulated % 120;
        if (steps === 0)
            return;

        root.setSinkVolume(root.sinkVolumePercent() + steps * 5);
    }

    function toggleSinkMute() {
        const audio = root.audioSink?.audio ?? null;
        if (audio)
            audio.muted = !audio.muted;
    }

    function sourceVolumePercent() {
        const rawVolume = root.audioSource?.audio?.volume ?? 0;
        return Math.max(0, Math.min(100, Math.round(rawVolume * 100)));
    }

    function sourceMuted() {
        return root.audioSource?.audio?.muted ?? false;
    }

    function setSourceVolume(percent) {
        const audio = root.audioSource?.audio ?? null;
        if (!audio)
            return;

        audio.volume = root.clampVolume(Number(percent) / 100);
        if (audio.muted && audio.volume > 0)
            audio.muted = false;
    }

    function toggleSourceMute() {
        const audio = root.audioSource?.audio ?? null;
        if (!audio)
            return;

        audio.muted = !audio.muted;
        Surfaces.notify(audio.muted ? "󰍭" : "󰍬", audio.muted ? "Microfone mudo" : "Microfone ligado", 1200);
    }

    function setPreferredSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setStreamVolume(node, percent) {
        const audio = node?.audio ?? null;
        if (!audio)
            return;

        audio.volume = root.clampVolume(Number(percent) / 100);
        if (audio.muted && audio.volume > 0)
            audio.muted = false;
    }

    function toggleStreamMute(node) {
        const audio = node?.audio ?? null;
        if (audio)
            audio.muted = !audio.muted;
    }

    function nodeLabel(node) {
        const properties = node?.properties ?? {};
        return properties["application.name"] || properties["media.name"] || node?.description || node?.name || "Audio";
    }

    function collectAudioNodes(wantSinks) {
        const nodes = Pipewire.nodes?.values ?? [];
        const collected = [];

        for (let i = 0; i < nodes.length; i += 1) {
            const node = nodes[i];
            if (!node?.audio || node.isStream)
                continue;
            if (node.isSink !== wantSinks)
                continue;
            collected.push(node);
        }

        return collected;
    }

    function collectPlaybackStreams() {
        const nodes = Pipewire.nodes?.values ?? [];
        const collected = [];

        for (let i = 0; i < nodes.length; i += 1) {
            const node = nodes[i];
            if (!node?.audio || !node.isStream || node.isSink)
                continue;
            collected.push(node);
        }

        return collected;
    }

    function pipewireLinkGroups() {
        return Pipewire.linkGroups?.values ?? [];
    }

    function nodeHasType(node, type) {
        return node && node.type !== undefined && (node.type === type || (node.type & type) === type);
    }

    function nodePropertyText(node) {
        const properties = node?.properties ?? {};

        return [properties["media.class"] ?? "", properties["node.name"] ?? "", properties["node.description"] ?? "", properties["node.nick"] ?? "", properties["application.name"] ?? "", node?.name ?? "", node?.description ?? "", node?.nickname ?? ""].join(" ").toLowerCase();
    }

    function textHasAny(text, needles) {
        for (let i = 0; i < needles.length; i += 1) {
            if (text.indexOf(needles[i]) !== -1)
                return true;
        }

        return false;
    }

    function nodeLooksLikeVideoSource(node) {
        const text = root.nodePropertyText(node);

        return root.nodeHasType(node, PwNodeType.VideoSource) || (root.nodeHasType(node, PwNodeType.Video) && root.nodeHasType(node, PwNodeType.Source)) || text.indexOf("video/source") !== -1 || text.indexOf("video source") !== -1 || text.indexOf("v4l2") !== -1 || text.indexOf("camera") !== -1;
    }

    function nodeLooksLikeMicrophoneSource(node) {
        const text = root.nodePropertyText(node);

        return root.nodeHasType(node, PwNodeType.AudioSource) || (root.nodeHasType(node, PwNodeType.Audio) && root.nodeHasType(node, PwNodeType.Source)) || text.indexOf("audio/source") !== -1 || text.indexOf("audio source") !== -1 || text.indexOf("alsa_input") !== -1 || root.textHasAny(text, ["microphone", "mic", "input"]);
    }

    function nodeLooksLikeAudioInputStream(node) {
        const text = root.nodePropertyText(node);

        return root.nodeHasType(node, PwNodeType.AudioInStream) || (root.nodeHasType(node, PwNodeType.Audio) && root.nodeHasType(node, PwNodeType.Stream)) || text.indexOf("stream/input/audio") !== -1 || text.indexOf("audio/input") !== -1 || text.indexOf("input audio") !== -1 || text.indexOf("source-output") !== -1 || text.indexOf("capture") !== -1;
    }

    function updatePolledPrivacy(text) {
        root.polledCameraActive = text.trim() === "1";
    }

    // Raw sysfs value in, percentage out. The mic/max scaling the old shell
    // pipeline did with integer arithmetic now happens here.
    function updateRawBrightness(raw) {
        if (!isFinite(raw) || raw < 0 || root.backlightMaxRaw <= 0)
            return;

        root.updatePolledBrightness(raw * 100 / root.backlightMaxRaw);
    }

    function updatePolledBrightness(rawLevel) {
        if (!isFinite(rawLevel) || rawLevel < 0)
            return;

        const nextLevel = Math.max(0, Math.min(100, Math.round(rawLevel)));

        if (root.lastBrightnessLevel < 0) {
            root.lastBrightnessLevel = nextLevel;
            return;
        }

        if (nextLevel !== root.lastBrightnessLevel) {
            root.lastBrightnessLevel = nextLevel;
            root.showBrightness(nextLevel);
        }
    }

    function detectVideoActivity() {
        const groups = root.pipewireLinkGroups();

        for (let i = 0; i < groups.length; i += 1) {
            const group = groups[i];

            if (root.nodeLooksLikeVideoSource(group?.source) || root.nodeLooksLikeVideoSource(group?.target))
                return true;
        }

        return false;
    }

    function detectMicrophoneActivity() {
        const groups = root.pipewireLinkGroups();

        for (let i = 0; i < groups.length; i += 1) {
            const group = groups[i];
            const sourceIsMic = root.nodeLooksLikeMicrophoneSource(group?.source);
            const targetIsMic = root.nodeLooksLikeMicrophoneSource(group?.target);
            const sourceIsStream = root.nodeLooksLikeAudioInputStream(group?.source);
            const targetIsStream = root.nodeLooksLikeAudioInputStream(group?.target);

            if ((sourceIsMic && (targetIsStream || !targetIsMic)) || (targetIsMic && (sourceIsStream || !sourceIsMic)))
                return true;
        }

        return false;
    }

    function maybeShowVolumeFromSink() {
        if (!root.liveLinksEnabled)
            return;

        const nextVolume = root.sinkVolumePercent();
        const nextMuted = root.sinkMuted();

        if (!root.liveLinksPrimed) {
            root.lastSinkVolume = nextVolume;
            root.lastSinkMuted = nextMuted;
            return;
        }

        if (nextVolume !== root.lastSinkVolume || nextMuted !== root.lastSinkMuted) {
            root.lastSinkVolume = nextVolume;
            root.lastSinkMuted = nextMuted;
            root.showVolume(nextVolume, nextMuted);
        }
    }

    function batteryAvailable() {
        return (root.batteryDevice?.isLaptopBattery ?? false) && (root.batteryDevice?.isPresent ?? true);
    }

    function batteryLevel() {
        return Math.max(0, Math.min(100, Math.round((root.batteryDevice?.percentage ?? 0) * 100)));
    }

    function batteryPluggedIn() {
        return !UPower.onBattery;
    }

    function batteryCharging() {
        const chargeState = root.batteryDevice?.state;
        return chargeState === UPowerDeviceState.Charging || chargeState === UPowerDeviceState.PendingCharge;
    }

    function maybeShowBattery(forceStateEvent) {
        if (!root.liveLinksEnabled || !root.batteryAvailable())
            return;

        const nextLevel = root.batteryLevel();
        const nextPluggedIn = root.batteryPluggedIn();

        if (!root.liveLinksPrimed) {
            root.lastBatteryLevel = nextLevel;
            root.lastBatteryPluggedIn = nextPluggedIn;
            return;
        }

        if (forceStateEvent && nextPluggedIn !== root.lastBatteryPluggedIn) {
        }

        root.lastBatteryLevel = nextLevel;
        root.lastBatteryPluggedIn = nextPluggedIn;
    }

    onMediaFaceAvailableChanged: {
        if (!root.mediaFaceAvailable)
            root.peekFace = "media";
    }

    function primeLiveLinks() {
        root.chooseActivePlayer(null);
        root.syncMediaFields(root.activePlayer);
        root.lastTrackKey = root.trackKey(root.activePlayer);
        root.lastSinkVolume = root.sinkVolumePercent();
        root.lastSinkMuted = root.sinkMuted();

        if (root.batteryAvailable()) {
            root.lastBatteryLevel = root.batteryLevel();
            root.lastBatteryPluggedIn = root.batteryPluggedIn();
        }

        // One shot: the sysfs poll cannot glob for the backlight device, so the
        // typed CLI boundary resolves it.
        if (root.backlightPath === "")
            ShellBackend.query("brightness");

        root.liveLinksPrimed = true;
    }

    function demo() {
        const step = root.demoStep % 4;
        root.demoStep += 1;

        if (step === 0) {
            root.toggleAudioPanel();
        } else if (step === 1) {
            root.showMedia("Subzero Signal", "Glacier FM", true);
        } else if (step === 2) {
            root.showVolume(68, false);
        } else {
            root.showIdle();
        }
    }

    function focusedScreen() {
        const focusedMonitor = Hyprland.focusedMonitor;

        if (focusedMonitor) {
            for (let i = 0; i < Quickshell.screens.length; i += 1) {
                if (Quickshell.screens[i].name === focusedMonitor.name)
                    return Quickshell.screens[i];
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    // Morphs the island into the Wi-Fi manager, or collapses it back to
    // idle if it is already showing.
    function toggleWifiPanel() {
        if (root.mode === "wifi") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "wifi";
        root.wifiExpandedSsid = "";
        root.wifiPasswordDraft = "";
        root.wifiStatusText = "";
        root.refreshWifiRadioState();
        root.scanWifiNetworks();
    }

    function refreshWifiRadioState() {
        ShellBackend.query("wifi");
    }

    function scanWifiNetworks() {
        root.lastWifiScanAt = Date.now();
        ShellBackend.query("wifi-scan");
    }

    // Warms the network list while the island is merely open, so the Wi-Fi panel
    // has something to show — and can size itself correctly — the instant it opens.
    function prewarmWifiNetworks() {
        if (Date.now() - root.lastWifiScanAt < 10000)
            return;

        root.refreshWifiRadioState();
        root.scanWifiNetworks();
    }

    function splitNmcliLine(line) {
        const parts = [];
        let current = "";
        let i = 0;

        while (i < line.length) {
            const ch = line[i];

            if (ch === "\\" && i + 1 < line.length) {
                current += line[i + 1];
                i += 2;
                continue;
            }

            if (ch === ":") {
                parts.push(current);
                current = "";
                i += 1;
                continue;
            }

            current += ch;
            i += 1;
        }

        parts.push(current);
        return parts;
    }

    function parseWifiNetworks(text) {
        const lines = text.split("\n").filter(line => line.trim() !== "");
        const parsed = [];
        const seen = {};

        for (let i = 0; i < lines.length; i += 1) {
            const parts = root.splitNmcliLine(lines[i]);

            if (parts.length < 4)
                continue;

            const active = parts[0] === "yes";
            const ssid = parts[1];
            const signal = parseInt(parts[2]) || 0;
            const security = parts.slice(3).join(":");
            const secured = security !== "" && security !== "--";
            const saved = root.savedWifiProfiles.indexOf(ssid) !== -1;

            if (ssid === "" || seen[ssid])
                continue;

            seen[ssid] = true;
            parsed.push({
                ssid: ssid,
                signal: signal,
                secured: secured,
                active: active,
                saved: saved
            });
        }

        parsed.sort((a, b) => b.signal - a.signal);
        root.wifiNetworks = parsed;
    }

    function toggleWifiRadio() {
        const nextState = !root.wifiRadioEnabled;

        root.wifiRadioEnabled = nextState;
        if (!ShellBackend.action("wifi-radio", nextState ? "on" : "off"))
            root.wifiRadioEnabled = !nextState;
    }

    function requestWifiExpand(ssid) {
        root.wifiExpandedSsid = root.wifiExpandedSsid === ssid ? "" : ssid;
        root.wifiPasswordDraft = "";
        root.wifiStatusText = "";
    }

    function connectToWifiNetwork(ssid, secured) {
        if (root.wifiConnecting)
            return;

        root.wifiConnecting = true;
        root.wifiStatusText = "";
        root.pendingWifiSsid = ssid;
        root.pendingWifiSecured = secured;
        root.pendingWifiUsedPassword = root.wifiPasswordDraft !== "";

        root.pendingWifiPassword = root.wifiPasswordDraft;
        if (!ShellBackend.action("wifi-connect", {"ssid": ssid, "password": root.pendingWifiPassword})) {
            root.wifiConnecting = false;
            root.wifiStatusText = "Invalid network request";
        }
        root.pendingWifiPassword = "";
        root.wifiPasswordDraft = "";
    }

    function forgetWifiNetwork(ssid) {
        root.wifiStatusText = "";
        ShellBackend.action("wifi-forget", ssid);
    }

    function disconnectFromWifiNetwork(ssid) {
        root.wifiConnecting = true;
        root.wifiStatusText = "";
        if (!ShellBackend.action("wifi-disconnect", ssid)) {
            root.wifiConnecting = false;
            root.wifiStatusText = "Invalid network request";
        }
    }

    function parseActiveWifi(text) {
        const lines = text.split("\n");

        for (let i = 0; i < lines.length; i += 1) {
            if (lines[i] === "")
                continue;

            const parts = root.splitNmcliLine(lines[i]);

            if (parts.length >= 3 && parts[0] === "yes") {
                root.wifiSsid = parts[1] === "--" ? "" : parts[1];
                root.wifiSignal = parseInt(parts[2]) || 0;
                return;
            }
        }

        root.wifiSsid = "";
        root.wifiSignal = 0;
    }

    function bluetoothDeviceName(device) {
        return device?.name || device?.deviceName || device?.address || "Unknown device";
    }

    function sortedBluetoothDevices() {
        const devices = root.btAdapter?.devices.values ?? [];

        return devices.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;

            return root.bluetoothDeviceName(a).localeCompare(root.bluetoothDeviceName(b));
        });
    }

    function toggleBluetoothPanel() {
        if (root.mode === "bluetooth") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "bluetooth";
        root.btStatusText = root.btAdapter ? "" : "No Bluetooth adapter";

        if (root.btEnabled)
            root.btAdapter.discovering = true;
    }

    function toggleBluetoothRadio() {
        if (!root.btAdapter) {
            root.btStatusText = "No Bluetooth adapter";
            return;
        }

        const nextState = !root.btAdapter.enabled;
        root.pendingBluetoothEnabled = nextState;
        root.btStatusText = nextState ? "Turning on…" : "Turning off…";
        if (!ShellBackend.action("bluetooth-radio", nextState ? "on" : "off"))
            root.btStatusText = "Could not change Bluetooth";
    }

    function refreshBluetoothDevices() {
        if (!root.btAdapter || !root.btAdapter.enabled)
            return;

        root.btStatusText = "";
        root.btAdapter.discovering = true;
    }

    function toggleBluetoothDevice(device) {
        if (!device)
            return;

        root.btStatusText = "";

        if (device.pairing) {
            device.cancelPair();
            root.btStatusText = "Pairing cancelled";
            return;
        }

        if (device.connected) {
            device.disconnect();
            return;
        }

        // BlueZ pairs and connects as separate operations. Calling connect() on a
        // device that was never bonded silently does the wrong thing on anything
        // that needs a passkey, so an unpaired device is paired explicitly.
        if (device.paired || device.bonded)
            device.connect();
        else
            device.pair();
    }

    function forgetBluetoothDevice(device) {
        if (!device)
            return;

        root.btStatusText = "";
        device.forget();
    }

    function refreshBatteryTelemetry() {
        if (root.batterySysfsPath === "")
            return;

        batteryCycleFile.reload();
        batteryFullFile.reload();
        batteryDesignFile.reload();
        batteryFullEnergyFile.reload();
        batteryDesignEnergyFile.reload();
        batteryDesignVoltageFile.reload();
        batteryVoltageFile.reload();
        batteryCurrentFile.reload();
        batteryPowerFile.reload();
        batteryStatusFile.reload();
        batteryModelFile.reload();
        batteryThresholdFile.reload();
    }

    function parseBusctlValue(line) {
        const separator = line.indexOf(" ");
        return separator >= 0 ? line.slice(separator + 1).trim() : "";
    }

    function parseBatteryThresholdState(text) {
        const lines = text.trim().split("\n").filter(line => line.trim() !== "");

        if (lines.length < 4)
            return;

        const start = Number(root.parseBusctlValue(lines[0]));
        const end = Number(root.parseBusctlValue(lines[1]));

        root.batteryThresholdStart = isFinite(start) ? start : -1;
        root.batteryThresholdEnd = isFinite(end) ? end : -1;
        root.batteryThresholdEnabled = root.parseBusctlValue(lines[2]) === "true";
        root.batteryThresholdSupported = root.parseBusctlValue(lines[3]) === "true";
    }

    function refreshBatteryThresholdState() {
        ShellBackend.query("battery-threshold");
    }

    function setBatteryThreshold(enabled) {
        if (!root.batteryThresholdSupported || root.batteryThresholdBusy || root.batteryDbusPath === "")
            return;

        root.pendingBatteryThresholdEnabled = enabled;
        root.batteryThresholdBusy = true;
        root.batteryThresholdStatusText = "";
        if (!ShellBackend.action("battery-threshold", root.pendingBatteryThresholdEnabled ? "on" : "off")) {
            root.batteryThresholdBusy = false;
            root.batteryThresholdStatusText = "Could not change charge limit";
        }
    }

    function toggleBatteryThreshold() {
        root.setBatteryThreshold(!root.batteryThresholdEnabled);
    }

    function parseBusctlString(line) {
        const value = root.parseBusctlValue(line);

        if (value.length >= 2 && value.charAt(0) === "\"" && value.charAt(value.length - 1) === "\"")
            return value.slice(1, -1);

        return value;
    }

    function parsePowerProfileState(text) {
        const lines = text.trim().split("\n").filter(line => line.trim() !== "");

        if (lines.length < 4)
            return;

        const profilesLine = lines[1];
        const knownProfiles = ["power-saver", "balanced", "performance"];
        const profiles = knownProfiles.filter(profile => profilesLine.indexOf("\"" + profile + "\"") !== -1);
        const active = root.parseBusctlString(lines[0]);

        root.availablePowerProfiles = profiles;
        root.activePowerProfile = active;
        root.performanceDegraded = root.parseBusctlString(lines[2]);
        root.performanceInhibited = root.parseBusctlString(lines[3]);
        root.powerProfilesAvailable = profiles.length > 0 && profiles.indexOf(active) !== -1;
    }

    function refreshPowerProfileState() {
        ShellBackend.query("power");
    }

    function setPowerProfile(profile) {
        if (!root.powerProfilesAvailable || root.powerProfileBusy || root.availablePowerProfiles.indexOf(profile) === -1 || profile === root.activePowerProfile)
            return;

        root.pendingPowerProfile = profile;
        root.powerProfileBusy = true;
        root.powerProfileStatusText = "";
        if (!ShellBackend.action("power-profile", profile)) {
            root.powerProfileBusy = false;
            root.pendingPowerProfile = "";
            root.powerProfileStatusText = "Could not change power mode";
        }
    }

    function toggleBatteryPanel() {
        if (root.mode === "battery") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "battery";
        root.refreshBatteryTelemetry();
        root.refreshBatteryThresholdState();
        root.refreshPowerProfileState();
    }

    // Morphs the island into the audio mixer, or collapses it back to idle if it
    // is already showing.
    function toggleAudioPanel() {
        if (root.mode === "audio") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "audio";
    }

    Timer {
        id: collapseTimer
        repeat: false
        onTriggered: root.showIdle()
    }

    Timer {
        id: hoverLeaveTimer
        interval: 140
        repeat: false
        onTriggered: {
            root.pointerInside = false;

            if (root.exitPreviewActive || root.isPanelMode(root.mode))
                root.showIdle();
        }
    }

    Timer {
        id: demoLoopTimer
        interval: 2600
        repeat: true
        running: root.demoRunning
        onTriggered: root.demo()
    }

    Timer {
        id: volumeIndicatorTimer
        interval: 1800
        repeat: false
        onTriggered: root.volumeIndicatorVisible = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.currentDateTime = new Date()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visualMode === "media" && root.activePlayer !== null
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged();
            root.syncMediaFields(root.activePlayer);
        }
    }

    Timer {
        id: liveLinkPrimeTimer
        interval: 900
        repeat: false
        running: true
        onTriggered: root.primeLiveLinks()
    }

    // Camera only. The microphone half of this poll used to shell out to
    // `pactl list source-outputs` on the same tick, which is redundant —
    // detectMicrophoneActivity() already derives that from the Pipewire graph
    // for free, and microphoneActive ORs the two together anyway. Cameras still
    // need the fallback because an app that opens /dev/video0 directly, rather
    // than through the portal, never shows up as a Pipewire node.
    Timer {
        interval: 3000
        repeat: true
        running: root.liveLinksEnabled && !root.privacyDebugEnabled
        triggeredOnStart: true
        onTriggered: {
            ShellBackend.query("privacy");
        }
    }

    // backlightPath is resolved once through `frost shell-data brightness`.
    // Machines without a backlight (desktops) leave it empty, which switches this
    // poll off entirely. sysfs supports poll(2)/sysfs_notify but not inotify, so
    // a timer is the mechanism here; each tick is a read(2), with no process spawn.
    Timer {
        interval: 700
        repeat: true
        running: root.liveLinksEnabled && root.backlightPath !== ""
        triggeredOnStart: true
        onTriggered: {
            backlightMaxFile.reload();
            backlightFile.reload();
        }
    }

    FileView {
        id: backlightMaxFile

        path: root.backlightPath === "" ? "" : root.backlightPath + "/max_brightness"
        printErrors: false
        onLoaded: root.backlightMaxRaw = Number(backlightMaxFile.text().trim())
    }

    FileView {
        id: backlightFile

        path: root.backlightPath === "" ? "" : root.backlightPath + "/brightness"
        printErrors: false
        onLoaded: root.updateRawBrightness(Number(backlightFile.text().trim()))
    }

    FileView {
        id: batteryCycleFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/cycle_count" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryFullFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/charge_full" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryDesignFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/charge_full_design" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryFullEnergyFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/energy_full" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryDesignEnergyFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/energy_full_design" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryDesignVoltageFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/voltage_min_design" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryVoltageFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/voltage_now" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryCurrentFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/current_now" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryPowerFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/power_now" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryStatusFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/status" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryModelFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/model_name" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryThresholdFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/charge_control_end_threshold" : ""
        preload: true
        printErrors: false
        onLoaded: {
            if (root.batteryThresholdEnd < 0)
                root.batteryThresholdEnd = root.fileNumber(batteryThresholdFile, -1);
        }
    }

    Timer {
        id: batteryThresholdStatusTimer

        interval: 2600
        repeat: false
        onTriggered: root.batteryThresholdStatusText = ""
    }

    Timer {
        id: powerProfileStatusTimer

        interval: 2600
        repeat: false
        onTriggered: root.powerProfileStatusText = ""
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.mode === "battery" && root.powerProfilesAvailable
        onTriggered: root.refreshPowerProfileState()
    }

    Timer {
        interval: 6000
        repeat: true
        running: root.mode === "wifi"
        onTriggered: root.scanWifiNetworks()
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.liveLinksEnabled
        triggeredOnStart: true
        onTriggered: {
            ShellBackend.query("wifi");
        }
    }

    PwObjectTracker {
        objects: [root.audioSink, root.audioSource].concat(root.audioSinkNodes).concat(root.audioStreamNodes)
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                root.maybeShowMediaFromPlayer(modelData, false);
            }

            function onPlaybackStateChanged() {
                root.maybeShowMediaFromPlayer(modelData, false);
            }

            function onPostTrackChanged() {
                root.maybeShowMediaFromPlayer(modelData, true);
            }
        }
    }

    Connections {
        target: root.audioSink?.audio ?? null

        function onVolumeChanged() {
            root.maybeShowVolumeFromSink();
        }

        function onMutedChanged() {
            root.maybeShowVolumeFromSink();
        }
    }

    Connections {
        target: root.batteryDevice ?? null

        function onPercentageChanged() {
            root.maybeShowBattery(false);
        }

        function onStateChanged() {
            root.maybeShowBattery(true);
        }
    }

    Connections {
        target: Surfaces

        function onIslandModeRequested(mode) {
            if (mode === "wifi") root.toggleWifiPanel();
            else if (mode === "bluetooth") root.toggleBluetoothPanel();
            else if (mode === "battery") root.toggleBatteryPanel();
            else if (mode === "audio") root.toggleAudioPanel();
            else if (mode === "notifications") root.toggleNotificationsPanel();
        }
    }

    Connections {
        target: ShellBackend

        function onDataReady(kind, payload) {
            if (!payload || payload.schemaVersion !== 1)
                return;

            if (kind === "wifi" || kind === "wifi-scan") {
                root.wifiRadioEnabled = payload.radioEnabled === true;
                root.wifiSsid = String(payload.activeSsid || "");
                root.wifiSignal = Number(payload.activeSignal || 0);
                const networks = Array.isArray(payload.networks) ? payload.networks.slice() : [];
                root.savedWifiProfiles = networks.filter(network => network.saved === true).map(network => String(network.ssid));
                root.wifiNetworks = networks.sort((a, b) => Number(b.signal || 0) - Number(a.signal || 0));
            } else if (kind === "power") {
                root.powerProfilesAvailable = payload.available === true;
                root.availablePowerProfiles = Array.isArray(payload.profiles) ? payload.profiles : [];
                root.activePowerProfile = String(payload.activeProfile || "");
                root.performanceDegraded = "";
                root.performanceInhibited = "";
            } else if (kind === "battery-threshold") {
                root.batteryThresholdSupported = payload.supported === true;
                root.batteryThresholdEnabled = payload.enabled === true;
                root.batteryThresholdStart = Number(payload.start ?? -1);
                root.batteryThresholdEnd = Number(payload.end ?? -1);
            } else if (kind === "privacy") {
                root.polledCameraActive = payload.camera === true;
            } else if (kind === "notifications") {
                root.notificationEntries = root.normalizeNotifications(payload.active);
                root.notificationsDnd = payload.dnd === true;
                root.notificationsStatusText = "";
            } else if (kind === "indicators") {
                root.stayAwakeActive = payload.stayAwake === true;
            } else if (kind === "brightness") {
                // Only the device path is taken from the CLI. The percentage the
                // poll reads from sysfs is what drives the OSD, so brightness
                // reacts to any tool that changes it, not just frost-osd.
                root.backlightPath = payload.available === true ? String(payload.devicePath || "") : "";
            }
        }

        function onActionFinished(action, succeeded) {
            if (action === "notification-dnd") {
                root.notificationsBusy = false;
                root.refreshNotifications();
            }
            if (action === "notification-dismiss" || action === "notification-invoke" || action === "notification-clear") {
                if (!succeeded)
                    root.notificationsStatusText = "Mako não respondeu";
                root.refreshNotifications();
            }
            if (action === "stay-awake-toggle") {
                root.stayAwakeBusy = false;
                root.refreshIndicators();
            }

            if (action === "wifi-forget") {
                root.wifiExpandedSsid = "";
                root.wifiStatusText = succeeded ? "" : "Could not forget network";
                root.scanWifiNetworks();
            } else if (action === "wifi-connect" || action === "wifi-disconnect") {
                const secured = root.pendingWifiSecured;
                const usedPassword = root.pendingWifiUsedPassword;
                const attemptedSsid = root.pendingWifiSsid;
                root.wifiConnecting = false;
                root.pendingWifiSsid = "";
                root.pendingWifiSecured = false;
                root.pendingWifiUsedPassword = false;
                if (succeeded) {
                    root.wifiExpandedSsid = "";
                    root.wifiStatusText = "";
                } else if (action === "wifi-connect" && secured && !usedPassword) {
                    root.wifiExpandedSsid = attemptedSsid;
                    root.wifiStatusText = "Password required";
                } else {
                    root.wifiStatusText = action === "wifi-connect" ? "Connection failed" : "Disconnect failed";
                }
                root.scanWifiNetworks();
            } else if (action === "wifi-radio") {
                root.refreshWifiRadioState();
            } else if (action === "bluetooth-radio") {
                if (succeeded && root.btAdapter) {
                    root.btAdapter.enabled = root.pendingBluetoothEnabled;
                    root.btAdapter.discovering = root.pendingBluetoothEnabled;
                    root.btStatusText = "";
                } else {
                    root.btStatusText = "Could not change Bluetooth";
                }
            } else if (action === "battery-threshold") {
                root.batteryThresholdBusy = false;
                root.batteryThresholdStatusText = succeeded ? (root.pendingBatteryThresholdEnabled ? "Charge limit enabled" : "Charge limit disabled") : "Could not change charge limit";
                root.refreshBatteryThresholdState();
                batteryThresholdStatusTimer.restart();
            } else if (action === "power-profile") {
                const requested = root.pendingPowerProfile;
                root.powerProfileBusy = false;
                root.pendingPowerProfile = "";
                if (succeeded)
                    root.activePowerProfile = requested;
                root.powerProfileStatusText = succeeded ? "Power mode changed" : "Could not change power mode";
                root.refreshPowerProfileState();
                powerProfileStatusTimer.restart();
            }
        }
    }

    onInteractionOpenChanged: {
        if (root.interactionOpen)
            root.prewarmWifiNetworks();
    }


    PanelWindow {
        id: islandWindow

        screen: root.focusedScreen()
        color: "transparent"
        exclusiveZone: root.reservedZone
        exclusionMode: ExclusionMode.Normal
        // Tall enough for the tallest expanded panel so the morph never clips.
        // The surface is transparent and input is limited to `mask`, so the extra
        // room costs nothing.
        implicitHeight: Math.max(root.windowHeight, root.wifiMaxPanelHeight + 32, root.btMaxPanelHeight + 32, root.audioMaxPanelHeight + 32)
        visible: root.runtimeVisible

        // end-4 already enables compositor blur for `quickshell:*` surfaces.
        // Other Hyprland setups can target this stable namespace explicitly.
        WlrLayershell.namespace: "frost-island"
        WlrLayershell.layer: WlrLayer.Top
        // Layer surfaces get no keyboard by default, so every TextInput in here
        // was inert: forceActiveFocus() moved Qt's internal focus (which is why
        // the field highlighted) but the compositor never routed a single key
        // press to the surface. OnDemand hands us the keyboard while the pointer
        // has clicked into the island and gives it straight back on click-away —
        // Exclusive would hold it for as long as the bar is mapped, i.e. always.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
            item: interactionMask
        }

        Item {
            anchors.fill: parent

            Item {
                id: interactionMask

                readonly property real maskPadding: 8
                readonly property bool privacyVisible: root.privacyActive && !root.interactionOpen
                readonly property real islandRightEdge: island.x + island.width
                readonly property real islandBottomEdge: island.y + island.height
                readonly property real privacyRightEdge: privacyVisible ? privacyIndicators.x + privacyIndicators.width : islandRightEdge
                readonly property real privacyBottomEdge: privacyVisible ? privacyIndicators.y + privacyIndicators.height : islandBottomEdge
                readonly property bool railsVisible: root.railsVisible && workspaceRail.opacity > 0
                readonly property real workspaceRailEdge: railsVisible && workspaceRail.width > 0 ? workspaceRail.x : island.x
                readonly property real trayRailEdge: railsVisible && trayRail.width > 0 ? trayRail.x + trayRail.width : islandRightEdge
                readonly property bool trayMenuVisible: trayMenu.visible
                readonly property real trayMenuRightEdge: trayMenuVisible ? trayMenu.x + trayMenu.width : islandRightEdge
                readonly property real trayMenuBottomEdge: trayMenuVisible ? trayMenu.y + trayMenu.height : islandBottomEdge
                readonly property real leftEdge: Math.min(island.x, workspaceRailEdge, privacyVisible ? privacyIndicators.x : island.x)
                readonly property real rightEdge: Math.max(islandRightEdge, privacyRightEdge, trayRailEdge, trayMenuRightEdge)
                readonly property real bottomEdge: Math.max(islandBottomEdge, privacyBottomEdge, trayMenuBottomEdge)

                x: Math.max(0, leftEdge - maskPadding)
                y: Math.max(0, island.y - maskPadding)
                width: Math.min(parent.width - x, rightEdge - x + maskPadding)
                height: Math.min(parent.height - y, bottomEdge - y + maskPadding)
            }

            WorkspaceRail {
                id: workspaceRail

                readonly property int gap: 14

                hostScreen: islandWindow.screen
                fade: root.railsVisible ? 1 : 0
                visible: opacity > 0.001
                // Pinned to the open-pill footprint rather than to the island's
                // animated width, so the rail stays put while the island morphs.
                x: (parent.width - root.handleWidth) / 2 - width - gap
                y: Math.max(0, (root.bumpHeight - height) / 2)
                z: 25
            }

            TrayRail {
                id: trayRail

                readonly property int gap: 14

                fade: root.railsVisible ? 1 : 0
                visible: opacity > 0.001
                onMenuRequested: (item, anchorX) => root.trayMenuItem = item
                x: (parent.width + root.handleWidth) / 2 + gap
                y: Math.max(0, (root.bumpHeight - height) / 2)
                z: 25
            }

            TrayMenu {
                id: trayMenu

                trayItem: root.trayMenuItem
                x: Math.min(parent.width - width - 8, trayRail.x)
                y: trayRail.y + trayRail.height + 8
                z: 40
                onDismissed: root.trayMenuItem = null
            }

            // The island's input mask covers only the island itself, so a click
            // anywhere else never reached this process and the menu stayed up
            // until something inside it was pressed. While the grab is active
            // input is routed to this window alone and the click-away is
            // reported instead of being swallowed by whatever is underneath.
            HyprlandFocusGrab {
                active: trayMenu.visible
                windows: [islandWindow]
                onCleared: root.trayMenuItem = null
            }

            IslandSurface {
                id: island

                anchors.horizontalCenter: parent.horizontalCenter
                y: root.targetY()
                targetW: root.targetWidth()
                targetH: root.targetHeight()
                wifiMaxPanelHeight: root.wifiMaxPanelHeight
                btMaxPanelHeight: root.btMaxPanelHeight
                mode: root.visualMode
                handleStyle: root.handleStyle
                idleWidth: root.peekWidth
                idleHeight: root.peekHeight
                forceExpanded: root.interactionOpen
                appName: root.appName
                title: root.title
                body: root.body
                artist: root.artist
                artUrl: root.artUrl
                volume: root.volume
                muted: root.muted
                volumeKind: root.volumeKind
                playing: root.playing
                canGoPrevious: root.mediaCanGoPrevious
                canTogglePlaying: root.mediaCanTogglePlaying
                canGoNext: root.mediaCanGoNext
                canSeek: root.mediaCanSeek
                shuffleActive: root.mediaShuffleActive
                shuffleSupported: root.mediaShuffleSupported
                loopStateText: root.mediaLoopStateText
                loopActive: root.mediaLoopActive
                loopSupported: root.mediaLoopSupported
                mediaPosition: root.mediaPosition
                mediaLength: root.mediaLength
                mediaAvailable: root.mediaAvailable
                mediaFaceAvailable: root.mediaFaceAvailable
                mediaPlayerCount: root.mediaPlayerCount
                mediaPlayerIndex: root.mediaPlayerIndex
                notificationEntries: root.notificationEntries
                notificationsDnd: root.notificationsDnd
                microphoneMuted: root.audioInputMuted
                microphoneActive: root.microphoneActive
                notificationsBusy: root.notificationsBusy
                notificationsStatusText: root.notificationsStatusText
                notificationsMaxPanelHeight: root.notificationsMaxPanelHeight
                stayAwakeActive: root.stayAwakeActive
                stayAwakeBusy: root.stayAwakeBusy
                fontFamily: root.fontFamily
                batteryHoverText: root.batteryHoverText
                batteryCharging: root.batteryCharging()
                batteryLevel: root.batteryLevel()
                batteryAvailable: root.batteryAvailable()
                batteryHealth: root.batteryHealth
                batteryCycles: root.batteryCycles
                batteryFullCapacityWh: root.batteryFullCapacityWh
                batteryDesignCapacityWh: root.batteryDesignCapacityWh
                batteryVoltage: root.batteryVoltage
                batteryPower: root.batteryPower
                batteryStatus: root.batteryStatus
                batteryModel: root.batteryModel
                batteryThresholdSupported: root.batteryThresholdSupported
                batteryThresholdEnabled: root.batteryThresholdEnabled
                batteryThresholdBusy: root.batteryThresholdBusy
                batteryThresholdStart: root.batteryThresholdStart
                batteryThresholdEnd: root.batteryThresholdEnd
                batteryThresholdStatusText: root.batteryThresholdStatusText
                powerProfilesAvailable: root.powerProfilesAvailable
                availablePowerProfiles: root.availablePowerProfiles
                activePowerProfile: root.activePowerProfile
                powerProfileBusy: root.powerProfileBusy
                powerProfileStatusText: root.powerProfileStatusText
                performanceDegraded: root.performanceDegraded
                performanceInhibited: root.performanceInhibited
                wifiConnected: root.wifiConnected
                wifiSsid: root.wifiSsid
                wifiSignal: root.wifiSignal
                btEnabled: root.btEnabled
                btConnected: root.btConnected
                btDeviceName: root.btDeviceName
                btBattery: root.btBattery
                btDiscovering: root.btDiscovering
                btDevices: root.btDevices
                btStatusText: root.btStatusText
                timeText: root.hoverTimeText
                dateText: root.hoverDateText
                wifiRadioEnabled: root.wifiRadioEnabled
                wifiNetworks: root.wifiNetworks
                wifiExpandedSsid: root.wifiExpandedSsid
                wifiPasswordDraft: root.wifiPasswordDraft
                wifiStatusText: root.wifiStatusText
                wifiConnecting: root.wifiConnecting
                onPreviousRequested: root.mediaPrevious()
                onPlayPauseRequested: root.mediaTogglePlaying()
                onNextRequested: root.mediaNext()
                onShuffleRequested: root.mediaToggleShuffle()
                onLoopRequested: root.mediaCycleLoop()
                onDismissRequested: root.peekFace = "normal"
                onMediaFaceRequested: root.peekFace = "media"
                onNextPlayerRequested: root.cycleMediaPlayer()
                onPlayerRequested: index => root.selectMediaPlayer(index)
                onWifiSettingsRequested: root.toggleWifiPanel()
                onWifiCloseRequested: root.closePanelToWideIdle(root.wifiWidth)
                onWifiToggleRadioRequested: root.toggleWifiRadio()
                onWifiRowRequested: ssid => root.requestWifiExpand(ssid)
                onWifiConnectRequested: (ssid, secured) => root.connectToWifiNetwork(ssid, secured)
                onWifiDisconnectRequested: ssid => root.disconnectFromWifiNetwork(ssid)
                onWifiForgetRequested: ssid => root.forgetWifiNetwork(ssid)
                onWifiPasswordChanged: text => root.wifiPasswordDraft = text
                onBtCloseRequested: root.closePanelToWideIdle(root.btWidth)
                onBtToggleRadioRequested: root.toggleBluetoothRadio()
                onBtRefreshRequested: root.refreshBluetoothDevices()
                onBtDeviceRequested: device => root.toggleBluetoothDevice(device)
                onBtDeviceForgetRequested: device => root.forgetBluetoothDevice(device)
                onBatteryRequested: root.toggleBatteryPanel()
                onBatteryCloseRequested: root.closePanelToWideIdle(root.batteryWidth)
                onBatteryToggleThresholdRequested: root.toggleBatteryThreshold()
                onPowerProfileRequested: profile => root.setPowerProfile(profile)
                audioMaxPanelHeight: root.audioMaxPanelHeight
                audioVolume: root.audioVolume
                audioMuted: root.audioMuted
                audioInputVolume: root.audioInputVolume
                audioInputMuted: root.audioInputMuted
                audioSinkNodes: root.audioSinkNodes
                audioStreamNodes: root.audioStreamNodes
                audioActiveSinkName: root.audioActiveSinkName
                onAudioCloseRequested: root.closePanelToWideIdle(root.audioWidth)
                onAudioPanelRequested: root.toggleAudioPanel()
                onStayAwakeRequested: root.toggleStayAwake()
                onNotificationsRequested: root.toggleNotificationsPanel()
                onMicrophoneMuteRequested: root.toggleSourceMute()
                onNotificationsCloseRequested: root.closePanelToWideIdle(root.notificationsWidth)
                onNotificationsClearRequested: root.clearNotifications()
                onNotificationsDndRequested: root.toggleNotificationsDnd()
                onNotificationDismissRequested: id => root.dismissNotification(id)
                onNotificationInvokeRequested: id => root.invokeNotification(id)
                onAudioVolumeRequested: level => root.setSinkVolume(level)
                onAudioMuteRequested: root.toggleSinkMute()
                onAudioStepRequested: steps => root.stepSinkVolume(steps)
                onAudioInputVolumeRequested: level => root.setSourceVolume(level)
                onAudioInputMuteRequested: root.toggleSourceMute()
                onAudioSinkRequested: node => root.setPreferredSink(node)
                onAudioStreamVolumeRequested: (node, level) => root.setStreamVolume(node, level)
                onAudioStreamMuteRequested: node => root.toggleStreamMute(node)
                onBtSettingsRequested: root.toggleBluetoothPanel()
                onSeekRequested: position => root.mediaSeek(position)
            }

            Item {
                id: privacyIndicators

                readonly property int dotSize: root.compactPrivacyIndicators ? 4 : 9
                readonly property int itemSize: root.compactPrivacyIndicators ? dotSize : 16
                readonly property int dotSpacing: root.compactPrivacyIndicators ? 3 : 5
                readonly property int haloSize: root.compactPrivacyIndicators ? 0 : 16
                readonly property int islandGap: root.compactPrivacyIndicators ? 4 : 8
                readonly property real anchorX: island.x + island.width + privacyIndicators.islandGap

                z: 35
                x: privacyIndicators.anchorX
                y: island.y + Math.max(0, island.height / 2 - height / 2)
                width: (root.microphoneActive ? privacyIndicators.itemSize : 0) + (root.cameraActive ? privacyIndicators.itemSize : 0) + (root.microphoneActive && root.cameraActive ? privacyIndicators.dotSpacing : 0)
                height: privacyIndicators.itemSize
                opacity: visible ? 1 : 0
                visible: root.privacyActive && !root.interactionOpen
                transformOrigin: Item.Center

                Row {
                    anchors.centerIn: parent
                    spacing: privacyIndicators.dotSpacing

                    Item {
                        width: root.microphoneActive ? privacyIndicators.itemSize : 0
                        height: privacyIndicators.itemSize
                        visible: root.microphoneActive

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.haloSize
                            height: privacyIndicators.haloSize
                            radius: width / 2
                            color: root.microphoneIndicatorColor
                            opacity: 0.2
                            visible: privacyIndicators.haloSize > 0
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.dotSize
                            height: privacyIndicators.dotSize
                            radius: width / 2
                            color: root.microphoneIndicatorColor
                            border.width: root.compactPrivacyIndicators ? 0 : 1
                            border.color: Theme.background
                        }
                    }

                    Item {
                        width: root.cameraActive ? privacyIndicators.itemSize : 0
                        height: privacyIndicators.itemSize
                        visible: root.cameraActive

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.haloSize
                            height: privacyIndicators.haloSize
                            radius: width / 2
                            color: root.cameraIndicatorColor
                            opacity: 0.18
                            visible: privacyIndicators.haloSize > 0
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.dotSize
                            height: privacyIndicators.dotSize
                            radius: width / 2
                            color: root.cameraIndicatorColor
                            border.width: root.compactPrivacyIndicators ? 0 : 1
                            border.color: Theme.background
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: islandHitbox

                readonly property bool wholeIslandClickable: !(root.visualMode === "media" || root.isPanelMode(root.visualMode) || root.interactionOpen)

                z: 20
                anchors.horizontalCenter: island.horizontalCenter
                y: island.y
                width: island.width
                height: root.mode === "idle" && !root.interactionOpen ? Math.max(root.reservedZone, island.height) : island.height
                hoverEnabled: true
                acceptedButtons: islandHitbox.wholeIslandClickable ? Qt.LeftButton : Qt.NoButton
                // The pointing hand belongs to the states where a click on the
                // island itself does something. Once it opens into media or a
                // panel the clickable things are the controls inside it, and a
                // hand over the whole surface points at nothing.
                cursorShape: islandHitbox.wholeIslandClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: root.keepInteractionOpen(true)
                onWheel: wheel => {
                    if (root.visualMode === "volume" && root.volumeKind === "audio")
                        root.stepSinkVolume(wheel.angleDelta.y);
                    else
                        wheel.accepted = false;
                }
                onPositionChanged: mouse => root.maybeFinishExitPreview(mouse.x, width)
                onExited: root.scheduleInteractionClose()
                onClicked: {
                    if (root.mode === "idle")
                        root.pinnedOpen = !root.pinnedOpen;
                    else
                        root.showIdle();
                }
            }
        }
    }

    IpcHandler {
        target: "frost"

        function ping(): string {
            return "ok";
        }

        function status(): string {
            return JSON.stringify({
                "schemaVersion": 2,
                "visible": root.runtimeVisible,
                "mode": root.visualMode,
                "handleStyle": root.handleStyle,
                "idleWidth": root.peekWidth,
                "idleHeight": root.peekHeight
            });
        }

        function show(mode: string): string {
            root.runtimeVisible = true;
            if (mode === "idle" || mode === "island") {
                root.showIdle();
                return "ok";
            }
            // Full-screen surfaces are siblings of the island, routed through the
            // Surfaces singleton so the shell keeps exactly one IPC target.
            if (Surfaces.known.indexOf(mode) >= 0) {
                Surfaces.show(mode);
                return "ok";
            }
            if (mode === "wifi") root.toggleWifiPanel();
            else if (mode === "notifications") root.toggleNotificationsPanel();
            else if (mode === "bluetooth") root.toggleBluetoothPanel();
            else if (mode === "battery") root.toggleBatteryPanel();
            else if (mode === "audio") root.toggleAudioPanel();
            else if (mode === "media" && root.hasActiveMedia()) root.showMedia(root.title, root.artist, root.playing, root.artUrl);
            else return "error:unsupported-mode";
            return "ok";
        }

        function toggle(mode: string): string {
            if (mode === "island") {
                root.runtimeVisible = !root.runtimeVisible;
                return "ok";
            }
            if (Surfaces.known.indexOf(mode) >= 0) {
                Surfaces.toggle(mode);
                return "ok";
            }
            if (root.mode === mode) {
                root.showIdle();
                return "ok";
            }
            return show(mode);
        }

        function hide(surface: string): string {
            if (surface !== "island")
                return "error:unsupported-surface";
            root.runtimeVisible = false;
            root.showIdle();
            return "ok";
        }

        function showOsd(payload: string): string {
            try {
                const parsed = JSON.parse(payload);
                const value = Math.max(0, Math.min(100, Number(parsed.value || 0)));
                if (parsed.icon === "brightness")
                    root.showBrightness(value);
                else
                    root.showVolume(value, parsed.icon === "volume-muted");
                return "ok";
            } catch (error) {
                return "error:invalid-payload";
            }
        }

        function demo(): string {
            root.demo();
            return "ok";
        }
    }
}
