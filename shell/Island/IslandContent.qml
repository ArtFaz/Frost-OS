import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Core

Item {
    id: root

    property string mode: "idle"
    property string appName: ""
    property string title: ""
    property string body: ""
    property string artist: ""
    property string artUrl: ""
    property int volume: 0
    property bool muted: false
    property bool playing: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canSeek: false
    property bool shuffleActive: false
    property bool shuffleSupported: false
    property string loopStateText: "OFF"
    property bool loopActive: false
    property bool loopSupported: false
    property real mediaPosition: 0
    property real mediaLength: 0
    property bool forceExpanded: false
    property bool mediaAvailable: false
    property bool mediaFaceAvailable: false
    property int mediaPlayerCount: 0
    property int mediaPlayerIndex: -1
    property bool stayAwakeActive: false
    property bool stayAwakeBusy: false
    property string handleStyle: "bump"
    property int idleWidth: 340
    property int idleHeight: 132
    property string batteryHoverText: ""
    property bool batteryCharging: false
    property int batteryLevel: 0
    property bool batteryAvailable: false
    property real batteryHealth: -1
    property int batteryCycles: -1
    property real batteryFullCapacityWh: -1
    property real batteryDesignCapacityWh: -1
    property real batteryVoltage: -1
    property real batteryPower: -1
    property string batteryStatus: ""
    property string batteryModel: ""
    property bool batteryThresholdSupported: false
    property bool batteryThresholdEnabled: false
    property bool batteryThresholdBusy: false
    property int batteryThresholdStart: -1
    property int batteryThresholdEnd: -1
    property string batteryThresholdStatusText: ""
    property bool powerProfilesAvailable: false
    property var availablePowerProfiles: []
    property string activePowerProfile: ""
    property bool powerProfileBusy: false
    property string powerProfileStatusText: ""
    property string performanceDegraded: ""
    property string performanceInhibited: ""
    property bool wifiConnected: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool btEnabled: false
    property bool btConnected: false
    property string btDeviceName: ""
    property int btBattery: -1
    property bool btDiscovering: false
    property var btDevices: []
    property string btStatusText: ""
    property string timeText: ""
    property string dateText: ""
    property string fontFamily: Style.fontFamily
    readonly property color primaryText: Theme.foreground
    readonly property color secondaryText: Theme.secondaryText
    readonly property color accent: Theme.accent
    readonly property int mediaHorizontalPadding: 24
    readonly property real normalizedMediaPosition: root.normalizedSeconds(mediaPosition)
    readonly property real normalizedMediaLength: root.normalizedSeconds(mediaLength)
    readonly property real mediaProgress: normalizedMediaLength > 0 ? Math.max(0, Math.min(1, normalizedMediaPosition / normalizedMediaLength)) : 0

    property bool wifiRadioEnabled: true
    property var wifiNetworks: []
    property string wifiExpandedSsid: ""
    property string wifiPasswordDraft: ""
    property string wifiStatusText: ""
    property bool wifiConnecting: false

    // 0 = island surface content, 1 = Wi-Fi manager. Driven by the surface morph transition.
    property real wifiMorph: 0
    property int wifiMaxPanelHeight: 420

    // Wi-Fi panel metrics — kept as tokens so the surface can size itself to the list.
    readonly property int wifiPanelPadding: 16
    readonly property int wifiHeaderHeight: 32
    readonly property int wifiSectionSpacing: 12
    readonly property int wifiRowHeight: 42
    readonly property int wifiRowSpacing: 6
    readonly property int wifiPlaceholderHeight: 58
    readonly property real wifiBodyHeight: root.wifiRadioEnabled && root.wifiNetworks.length > 0 ? wifiNetworkColumn.implicitHeight : root.wifiPlaceholderHeight
    readonly property real wifiContentHeight: Math.min(root.wifiMaxPanelHeight, root.wifiPanelPadding * 2 + root.wifiHeaderHeight + root.wifiSectionSpacing + root.wifiBodyHeight)

    // Bluetooth uses the same surface morph as the other control panels, while
    // its layout stays isolated in BluetoothPanel.qml.
    property real btMorph: 0
    property int btMaxPanelHeight: 420
    readonly property real btContentHeight: btContent.contentHeight

    property real batteryMorph: 0
    readonly property real batteryContentHeight: batteryContent.contentHeight

    // 0 = island surface content, 1 = notification viewer. Driven by the surface morph.
    property real notificationsMorph: 0
    property int notificationsMaxPanelHeight: 440
    property var notificationEntries: []
    property bool notificationsDnd: false
    property bool microphoneMuted: false
    property bool microphoneActive: false
    property bool notificationsBusy: false
    property string notificationsStatusText: ""
    readonly property real notificationsContentHeight: notificationsContent.contentHeight

    // 0 = island surface content, 1 = audio mixer. Driven by the surface morph transition.
    property real audioMorph: 0
    property int audioMaxPanelHeight: 440
    readonly property real audioContentHeight: audioContent.contentHeight

    // Audio state, mirrored from the PipeWire-backed island root.
    property int audioVolume: 0
    property bool audioMuted: false
    property int audioInputVolume: 0
    property bool audioInputMuted: false
    property var audioSinkNodes: []
    property var audioStreamNodes: []
    property string audioActiveSinkName: ""

    // 0 = island surface content, 1 = volume HUD. Driven by the surface morph transition.
    property real volumeMorph: 0
    property string volumeKind: "audio"

    readonly property real volumeProgress: root.muted ? 0 : Math.max(0, Math.min(1, root.volume / 100))
    readonly property real volumeHudProgress: Math.max(0, Math.min(1, (root.volumeMorph - 0.15) / 0.85))
    readonly property string volumeGlyph: {
        if (root.volumeKind === "brightness")
            return root.volume >= 50 ? "brightness_high" : "brightness_low";

        if (root.muted)
            return "volume_off";

        if (root.volume <= 0)
            return "volume_mute";

        return root.volume < 50 ? "volume_down" : "volume_up";
    }

    // Only one panel morph is ever non-zero, so the peek can react to whichever is running.
    readonly property real panelMorph: Math.max(root.wifiMorph, root.btMorph, root.batteryMorph, root.audioMorph, root.notificationsMorph)

    // The peek stays mounted through the morph so it can fade/shrink into the panel.
    readonly property bool peekVisible: (root.mode === "idle" && root.forceExpanded) || root.mode === "wifi" || root.mode === "bluetooth" || root.mode === "battery" || root.mode === "audio" || root.mode === "notifications"
    // The two peek faces share one shape, so flipping between them slides rather
    // than cross-fades in place: media leaves to the left, the normal face
    // arrives from the right, matching the chevron that triggers it.
    readonly property bool mediaFaceActive: root.mode === "media"
    readonly property real faceSlide: 28
    readonly property real peekMorphOpacity: 1 - Math.min(1, root.panelMorph / 0.45)
    readonly property real wifiPanelProgress: Math.max(0, Math.min(1, (root.wifiMorph - 0.22) / 0.78))

    signal previousRequested
    signal playPauseRequested
    signal nextRequested
    signal shuffleRequested
    signal loopRequested
    signal dismissRequested
    signal mediaFaceRequested
    signal nextPlayerRequested
    signal playerRequested(int index)
    signal stayAwakeRequested
    signal notificationsRequested
    signal microphoneMuteRequested
    signal notificationsCloseRequested
    signal notificationsClearRequested
    signal notificationsDndRequested
    signal notificationDismissRequested(int id)
    signal notificationInvokeRequested(int id)
    signal wifiSettingsRequested
    signal wifiCloseRequested
    signal wifiToggleRadioRequested
    signal wifiRowRequested(string ssid)
    signal wifiConnectRequested(string ssid, bool secured)
    signal wifiDisconnectRequested(string ssid)
    signal wifiForgetRequested(string ssid)
    signal wifiPasswordChanged(string text)
    signal btCloseRequested
    signal btToggleRadioRequested
    signal btRefreshRequested
    signal btDeviceRequested(var device)
    signal btDeviceForgetRequested(var device)
    signal batteryRequested
    signal batteryCloseRequested
    signal batteryToggleThresholdRequested
    signal powerProfileRequested(string profile)
    signal audioCloseRequested
    signal idleWidthRequested(int width)
    signal idleHeightRequested(int height)
    signal audioPanelRequested
    signal audioVolumeRequested(int level)
    signal audioMuteRequested
    signal audioStepRequested(int steps)
    signal audioInputVolumeRequested(int level)
    signal audioInputMuteRequested
    signal audioSinkRequested(var node)
    signal audioStreamVolumeRequested(var node, int level)
    signal audioStreamMuteRequested(var node)
    signal btSettingsRequested
    signal seekRequested(real position)

    function normalizedSeconds(value) {
        if (!isFinite(value) || value <= 0)
            return 0;

        return value > 86400 ? value / 1000000 : value;
    }

    function formatTime(seconds) {
        const normalized = root.normalizedSeconds(seconds);

        if (normalized <= 0)
            return "0:00";

        const safeSeconds = Math.floor(normalized);
        const minutes = Math.floor(safeSeconds / 60);
        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;
        const remainingSeconds = safeSeconds % 60;
        const secondText = remainingSeconds < 10 ? "0" + remainingSeconds : String(remainingSeconds);

        if (hours > 0) {
            const minuteText = remainingMinutes < 10 ? "0" + remainingMinutes : String(remainingMinutes);

            return hours + ":" + minuteText + ":" + secondText;
        }

        return minutes + ":" + secondText;
    }

    Item {
        id: collapsedBumpMedia

        anchors.fill: parent
        opacity: root.mode === "idle" && !root.forceExpanded && root.handleStyle === "bump" ? 1 : 0
        visible: opacity > 0

        Rectangle {
            id: collapsedCover

            x: 9
            y: 4
            width: 14
            height: 14
            radius: 5
            color: Theme.controlNormal
            border.width: 1
            border.color: Theme.border
            clip: true
            visible: root.mediaAvailable

            Image {
                id: collapsedCoverSource

                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: collapsedCoverSource
                visible: root.artUrl !== "" && collapsedCoverSource.status === Image.Ready

                maskSource: Rectangle {
                    width: collapsedCover.width
                    height: collapsedCover.height
                    radius: collapsedCover.radius
                }
            }

            Row {
                id: collapsedEqualizer

                anchors.centerIn: parent
                spacing: 1
                visible: root.artUrl === "" || collapsedCoverSource.status !== Image.Ready

                Repeater {
                    model: 3

                    Rectangle {
                        width: 2
                        height: root.playing ? (5 + index * 2) : 4
                        radius: 1
                        color: root.playing ? Theme.foreground : Theme.secondaryText

                        // Gate on the bars' own effective visibility, not just the
                        // container's. `visible` folds in every ancestor, so this
                        // also covers collapsedCover (visible: mediaAvailable).
                        //
                        // This used to be `collapsedBumpMedia.visible && root.playing`,
                        // and `playing` defaults to true and is never cleared when
                        // there is no player — syncMediaFields() returns early on a
                        // null player. So with no media at all, three infinite
                        // animations ran from startup on invisible bars, which keeps
                        // Qt's animation driver ticking and the render thread waking
                        // at the refresh rate for as long as the shell is up.
                        SequentialAnimation on height {
                            running: collapsedEqualizer.visible && root.playing
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 4 + index
                                duration: 280 + index * 70
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 8 - index
                                duration: 320 + index * 70
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            x: collapsedCover.x - 1
            y: collapsedCover.y + collapsedCover.height + 1
            width: collapsedCover.width + 2
            height: 2
            radius: 1
            color: Theme.controlHover
            visible: root.mediaAvailable

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: root.playing ? parent.width : 6
                height: parent.height
                radius: parent.radius
                color: root.playing ? Theme.foreground : Theme.secondaryText

                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // Playback activity on the resting handle. The equalizer inside the cover
        // only shows when there is no artwork, so this is the tell that survives
        // a player that does publish cover art.
        AudioIndicator {
            id: collapsedActivity

            anchors.right: parent.right
            anchors.rightMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            active: root.mediaAvailable
            playing: root.playing
            interactive: false
            barWidth: 2
            maxBarHeight: 10
        }

        Text {
            anchors.left: root.mediaAvailable ? collapsedCover.right : parent.left
            anchors.leftMargin: root.mediaAvailable ? 9 : 0
            anchors.right: root.mediaAvailable ? collapsedActivity.left : parent.right
            anchors.rightMargin: root.mediaAvailable ? 7 : 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeText
            color: root.primaryText
            horizontalAlignment: root.mediaAvailable ? Text.AlignLeft : Text.AlignHCenter
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: idleContent

        anchors.fill: parent
        opacity: root.peekVisible ? root.peekMorphOpacity : 0
        visible: opacity > 0
        scale: 1 - 0.05 * root.panelMorph
        transformOrigin: Item.Top

        transform: Translate {
            x: root.mediaFaceActive ? root.faceSlide : 0

            Behavior on x {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 6
            anchors.bottomMargin: 7
            spacing: 2

            PeekStatusRow {
                volume: root.audioVolume
                muted: root.audioMuted
                batteryCharging: root.batteryCharging
                batteryLevel: root.batteryLevel
                fontFamily: root.fontFamily
                showBattery: true
                showNotifications: true
                showMicrophone: true
                microphoneMuted: root.microphoneMuted
                microphoneActive: root.microphoneActive
                onMicrophoneMuteRequested: root.microphoneMuteRequested()
                notificationsDnd: root.notificationsDnd
                notificationCount: root.notificationEntries.length
                onNotificationsRequested: root.notificationsRequested()
                onBatteryRequested: root.batteryRequested()
                onAudioPanelRequested: root.audioPanelRequested()
                onAudioMuteRequested: root.audioMuteRequested()
                onAudioStepRequested: steps => root.audioStepRequested(steps)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: root.timeText
                            color: root.primaryText
                            elide: Text.ElideRight
                            font.family: root.fontFamily
                            font.pixelSize: 28
                            font.weight: Font.Bold
                        }

                        // Playback activity, beside the clock. Clicking it flips
                        // the peek to the media face.
                        AudioIndicator {
                            Layout.alignment: Qt.AlignVCenter
                            active: root.mediaFaceAvailable
                            playing: root.playing
                            onClicked: root.mediaFaceRequested()
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.dateText
                        color: Theme.foreground
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 5

                    // WiFi
                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: wifiRow.width
                        Layout.preferredHeight: wifiRow.height

                        Row {
                            id: wifiRow
                            spacing: 4

                            MIcon {
                                name: root.wifiConnected ? (root.wifiSignal >= 70 ? "wifi" : root.wifiSignal >= 40 ? "wifi_2_bar" : "wifi_1_bar") : "wifi_off"
                                size: 13
                                color: root.wifiConnected ? Theme.foreground : Theme.secondaryText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.wifiConnected ? root.wifiSsid : "Off"
                                color: root.wifiConnected ? Theme.foreground : Theme.secondaryText
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wifiSettingsRequested()
                        }
                    }

                    // Bluetooth
                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: btRow.width
                        Layout.preferredHeight: btRow.height

                        Row {
                            id: btRow
                            spacing: 4

                            MIcon {
                                name: "bluetooth"
                                size: 13
                                color: root.btConnected ? Theme.accent : (root.btEnabled ? Theme.foreground : Theme.secondaryText)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.btConnected ? (root.btBattery >= 0 ? root.btDeviceName + " " + root.btBattery + "%" : root.btDeviceName) : (root.btEnabled ? "On" : "Off")
                                color: root.btConnected ? Theme.foreground : Theme.secondaryText
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.btSettingsRequested()
                        }
                    }

                    // Idle inhibitor. Backed by the typed CLI action that already
                    // existed but had never been reachable from the shell.
                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: stayAwakeRow.width
                        Layout.preferredHeight: stayAwakeRow.height

                        Row {
                            id: stayAwakeRow
                            spacing: 4

                            MIcon {
                                name: "hourglass_top"
                                size: 13
                                color: root.stayAwakeActive ? Theme.warning : Theme.secondaryText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.stayAwakeActive ? "Acordado" : "Idle"
                                color: root.stayAwakeActive ? Theme.foreground : Theme.secondaryText
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        opacity: root.stayAwakeBusy ? 0.5 : 1

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.stayAwakeRequested()
                        }
                    }

                    // Way back to the media face. Only offered while a player is
                    // active; when playback ends the island returns here on its own.
                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: mediaFaceRow.width
                        Layout.preferredHeight: mediaFaceRow.height
                        visible: root.mediaFaceAvailable

                        Row {
                            id: mediaFaceRow
                            spacing: 3

                            MIcon {
                                name: "chevron_left"
                                size: 13
                                color: mediaFaceMouse.containsMouse ? Theme.highlight : Theme.secondaryText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Tocando"
                                color: mediaFaceMouse.containsMouse ? Theme.foreground : Theme.secondaryText
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: mediaFaceMouse

                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.mediaFaceRequested()
                        }
                    }
                }
            }
        }

        // The morph drives opacity directly; only plain show/hide is eased here.
        Behavior on opacity {
            enabled: root.panelMorph <= 0.001

            NumberAnimation {
                duration: 160
            }
        }
    }

    Item {
        id: wifiContent

        anchors.fill: parent
        opacity: root.wifiPanelProgress
        visible: opacity > 0.001
        scale: 0.94 + 0.06 * root.wifiPanelProgress
        transformOrigin: Item.Top

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.wifiPanelPadding
            spacing: root.wifiSectionSpacing

            PanelHeader {
                Layout.preferredHeight: root.wifiHeaderHeight
                icon: !root.wifiRadioEnabled ? "wifi_off" : (root.wifiConnected ? (root.wifiSignal >= 70 ? "wifi" : root.wifiSignal >= 40 ? "wifi_2_bar" : "wifi_1_bar") : "wifi")
                iconDimmed: !root.wifiRadioEnabled
                title: "Wi-Fi"
                subtitle: !root.wifiRadioEnabled ? "Desligado" : (root.wifiConnected ? root.wifiSsid + "  ·  " + root.wifiSignal + "%" : "Não conectado")
                subtitleHighlighted: root.wifiConnected
                statusText: root.wifiStatusText
                fontFamily: root.fontFamily
                onCloseRequested: root.wifiCloseRequested()

                PanelSwitch {
                    Layout.alignment: Qt.AlignVCenter
                    checked: root.wifiRadioEnabled
                    busy: root.wifiConnecting
                    onToggled: root.wifiToggleRadioRequested()
                }
            }

            Flickable {
                id: wifiListFlick

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: contentHeight > height
                contentHeight: wifiNetworkColumn.height
                boundsBehavior: Flickable.StopAtBounds
                visible: root.wifiRadioEnabled && root.wifiNetworks.length > 0

                ColumnLayout {
                    id: wifiNetworkColumn

                    width: wifiListFlick.width
                    spacing: root.wifiRowSpacing

                    Repeater {
                        model: root.wifiNetworks

                        delegate: Rectangle {
                            id: wifiRowItem

                            required property var modelData
                            required property int index

                            readonly property bool expanded: root.wifiExpandedSsid === modelData.ssid
                            // Rows stagger in off the shared morph progress instead of their own
                            // timers. The delay is capped so every row still reaches full opacity
                            // at wifiMorph 1, including ones that arrive after the morph finished.
                            readonly property real appear: Math.max(0, Math.min(1, (root.wifiMorph - Math.min(index, 6) * 0.045) / 0.55))

                            Layout.fillWidth: true
                            Layout.preferredHeight: root.wifiRowHeight + (expanded ? wifiExpandedContent.implicitHeight + 10 : 0)
                            radius: Style.rowRadius
                            color: expanded ? Theme.controlNormal : (wifiRowMouse.containsMouse ? Theme.controlHover : "transparent")
                            border.width: 1
                            border.color: expanded ? Theme.border : "transparent"
                            opacity: appear

                            transform: Translate {
                                y: (1 - wifiRowItem.appear) * 12
                            }

                            Behavior on Layout.preferredHeight {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.bottomMargin: wifiRowItem.expanded ? 10 : 0
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.wifiRowHeight
                                    spacing: 8

                                    MIcon {
                                        name: wifiRowItem.modelData.signal >= 70 ? "wifi" : wifiRowItem.modelData.signal >= 40 ? "wifi_2_bar" : "wifi_1_bar"
                                        size: 13
                                        color: wifiRowItem.modelData.active ? root.primaryText : Theme.foreground
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: wifiRowItem.modelData.ssid
                                        color: root.primaryText
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    // Fixed slots so the trailing column stays aligned
                                    // whether or not a row is secured or active.
                                    Item {
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12

                                        MIcon {
                                            anchors.centerIn: parent
                                            name: "lock"
                                            size: 11
                                            color: Theme.secondaryText
                                            visible: wifiRowItem.modelData.secured
                                        }
                                    }

                                    Item {
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14

                                        MIcon {
                                            anchors.centerIn: parent
                                            name: "check"
                                            size: 13
                                            color: Theme.accent
                                            visible: wifiRowItem.modelData.active
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: wifiExpandedContent

                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: wifiRowItem.expanded

                                    Text {
                                        Layout.fillWidth: true
                                        visible: wifiRowItem.modelData.active
                                        text: "Disconnect from this network?"
                                        color: root.secondaryText
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        visible: !wifiRowItem.modelData.active && wifiRowItem.modelData.secured && !wifiRowItem.modelData.saved
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: Style.controlRadius
                                        color: Theme.controlNormal
                                        border.width: 1
                                        border.color: wifiPasswordInput.activeFocus ? Theme.focus : Theme.border

                                        TextInput {
                                            id: wifiPasswordInput

                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            verticalAlignment: Text.AlignVCenter
                                            echoMode: TextInput.Password
                                            color: root.primaryText
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            clip: true
                                            text: root.wifiPasswordDraft
                                            onTextChanged: root.wifiPasswordChanged(text)
                                            onAccepted: root.wifiConnectRequested(wifiRowItem.modelData.ssid, wifiRowItem.modelData.secured)

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Password"
                                                color: Theme.secondaryText
                                                visible: wifiPasswordInput.text === ""
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: root.wifiStatusText !== ""
                                        text: root.wifiStatusText
                                        color: Theme.urgent
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 30
                                            radius: Style.controlRadius
                                            color: wifiCancelMouse.containsMouse ? Theme.controlHover : Theme.controlNormal
                                            border.width: 1
                                            border.color: Theme.border

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Cancel"
                                                color: Theme.foreground
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                id: wifiCancelMouse

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.wifiRowRequested(wifiRowItem.modelData.ssid)
                                            }
                                        }

                                        // Only offered for a network NetworkManager
                                        // actually holds a profile for.
                                        Rectangle {
                                            Layout.preferredWidth: wifiForgetLabel.width + 18
                                            Layout.preferredHeight: 30
                                            radius: Style.controlRadius
                                            visible: wifiRowItem.modelData.saved === true
                                            color: wifiForgetMouse.containsMouse ? Theme.alpha(Theme.urgent, 0.14) : Theme.controlNormal
                                            border.width: 1
                                            border.color: wifiForgetMouse.containsMouse ? Theme.urgent : Theme.border

                                            Text {
                                                id: wifiForgetLabel

                                                anchors.centerIn: parent
                                                text: "Esquecer"
                                                color: wifiForgetMouse.containsMouse ? Theme.urgent : Theme.secondaryText
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                id: wifiForgetMouse

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: !root.wifiConnecting
                                                onClicked: root.wifiForgetRequested(wifiRowItem.modelData.ssid)
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 30
                                            radius: Style.controlRadius
                                            color: wifiRowItem.modelData.active ? Theme.alpha(Theme.urgent, 0.14) : (root.wifiConnecting ? Theme.controlNormal : Theme.selected)
                                            border.width: 1
                                            border.color: wifiRowItem.modelData.active ? Theme.urgent : Theme.accent

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.wifiConnecting ? "..." : (wifiRowItem.modelData.active ? "Disconnect" : "Connect")
                                                color: wifiRowItem.modelData.active ? Theme.urgent : Theme.foreground
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: !root.wifiConnecting
                                                onClicked: {
                                                    if (wifiRowItem.modelData.active)
                                                        root.wifiDisconnectRequested(wifiRowItem.modelData.ssid);
                                                    else
                                                        root.wifiConnectRequested(wifiRowItem.modelData.ssid, wifiRowItem.modelData.secured);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: wifiRowMouse

                                anchors.fill: parent
                                anchors.bottomMargin: wifiRowItem.expanded ? parent.height - root.wifiRowHeight : 0
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // A secured network NetworkManager has no profile
                                    // for needs its password before the attempt, not
                                    // after a deliberate failure.
                                    const needsPassword = wifiRowItem.modelData.secured && !wifiRowItem.modelData.saved;
                                    if (wifiRowItem.modelData.active || wifiRowItem.expanded || needsPassword)
                                        root.wifiRowRequested(wifiRowItem.modelData.ssid);
                                    else
                                        root.wifiConnectRequested(wifiRowItem.modelData.ssid, wifiRowItem.modelData.secured);
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !wifiListFlick.visible

                Text {
                    anchors.centerIn: parent
                    text: root.wifiRadioEnabled ? "No networks found" : "Wi-Fi is off"
                    color: root.secondaryText
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    BluetoothPanel {
        id: btContent

        anchors.fill: parent
        radioEnabled: root.btEnabled
        discovering: root.btDiscovering
        devices: root.btDevices
        connectedDeviceName: root.btDeviceName
        statusText: root.btStatusText
        fontFamily: root.fontFamily
        morph: root.btMorph
        maxPanelHeight: root.btMaxPanelHeight
        onCloseRequested: root.btCloseRequested()
        onToggleRadioRequested: root.btToggleRadioRequested()
        onRefreshRequested: root.btRefreshRequested()
        onDeviceRequested: device => root.btDeviceRequested(device)
        onDeviceForgetRequested: device => root.btDeviceForgetRequested(device)
    }

    BatteryPanel {
        id: batteryContent

        anchors.fill: parent
        available: root.batteryAvailable
        level: root.batteryLevel
        charging: root.batteryCharging
        health: root.batteryHealth
        cycles: root.batteryCycles
        fullCapacityWh: root.batteryFullCapacityWh
        designCapacityWh: root.batteryDesignCapacityWh
        voltage: root.batteryVoltage
        power: root.batteryPower
        status: root.batteryStatus
        model: root.batteryModel
        thresholdSupported: root.batteryThresholdSupported
        thresholdEnabled: root.batteryThresholdEnabled
        thresholdBusy: root.batteryThresholdBusy
        thresholdStart: root.batteryThresholdStart
        thresholdEnd: root.batteryThresholdEnd
        thresholdStatusText: root.batteryThresholdStatusText
        profilesAvailable: root.powerProfilesAvailable
        availableProfiles: root.availablePowerProfiles
        activeProfile: root.activePowerProfile
        profileBusy: root.powerProfileBusy
        profileStatusText: root.powerProfileStatusText
        performanceDegraded: root.performanceDegraded
        performanceInhibited: root.performanceInhibited
        fontFamily: root.fontFamily
        morph: root.batteryMorph
        onCloseRequested: root.batteryCloseRequested()
        onToggleThresholdRequested: root.batteryToggleThresholdRequested()
        onPowerProfileRequested: profile => root.powerProfileRequested(profile)
    }

    NotificationsPanel {
        id: notificationsContent

        anchors.fill: parent
        fontFamily: root.fontFamily
        morph: root.notificationsMorph
        maxPanelHeight: root.notificationsMaxPanelHeight
        entries: root.notificationEntries
        dnd: root.notificationsDnd
        busy: root.notificationsBusy
        statusText: root.notificationsStatusText
        onCloseRequested: root.notificationsCloseRequested()
        onClearRequested: root.notificationsClearRequested()
        onDndRequested: root.notificationsDndRequested()
        onDismissRequested: id => root.notificationDismissRequested(id)
        onInvokeRequested: id => root.notificationInvokeRequested(id)
    }

    AudioPanel {
        id: audioContent

        anchors.fill: parent
        fontFamily: root.fontFamily
        morph: root.audioMorph
        maxPanelHeight: root.audioMaxPanelHeight
        outputVolume: root.audioVolume
        outputMuted: root.audioMuted
        inputVolume: root.audioInputVolume
        inputMuted: root.audioInputMuted
        sinkNodes: root.audioSinkNodes
        activeSinkName: root.audioActiveSinkName
        streamNodes: root.audioStreamNodes
        onCloseRequested: root.audioCloseRequested()
        onStepRequested: steps => root.audioStepRequested(steps)
        onVolumeRequested: level => root.audioVolumeRequested(level)
        onMuteRequested: root.audioMuteRequested()
        onInputVolumeRequested: level => root.audioInputVolumeRequested(level)
        onInputMuteRequested: root.audioInputMuteRequested()
        onSinkRequested: node => root.audioSinkRequested(node)
        onStreamVolumeRequested: (node, level) => root.audioStreamVolumeRequested(node, level)
        onStreamMuteRequested: node => root.audioStreamMuteRequested(node)
    }

    // Volume / brightness HUD. One capsule that fills from the left with the glyph
    // riding inside it, iOS-style: the glyph is drawn twice and the bright copy is
    // clipped to the fill, so it inverts as the level sweeps past it.
    Item {
        id: volumeContent

        anchors.fill: parent
        opacity: root.volumeHudProgress
        visible: opacity > 0.001
        scale: 0.92 + 0.08 * root.volumeHudProgress

        Item {
            id: volumeBar

            anchors.centerIn: parent
            width: Math.max(0, parent.width - 32)
            height: Math.min(26, Math.max(10, parent.height - 16))

            readonly property real glyphLeft: 9
            readonly property real fillWidth: volumeBar.width * root.volumeProgress

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.controlPressed
            }

            // Dim glyph sits on the empty track; the fill paints straight over it
            // and the bright copy inside the fill takes its place.
            MIcon {
                x: volumeBar.glyphLeft
                anchors.verticalCenter: parent.verticalCenter
                name: root.volumeGlyph
                size: 15
                filled: true
                color: Theme.secondaryText
            }

            // Clip container, so the fill keeps the capsule's rounded caps instead
            // of ending in a square edge as it grows.
            Item {
                width: volumeBar.fillWidth
                height: parent.height
                clip: true

                Rectangle {
                    width: volumeBar.width
                    height: volumeBar.height
                    radius: height / 2
                    color: Theme.foreground
                }

                MIcon {
                    x: volumeBar.glyphLeft
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.volumeGlyph
                    size: 15
                    filled: true
                    color: Theme.background
                }

                // Level changes slide the fill instead of snapping, so holding a
                // volume key reads as one continuous sweep.
                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

            }
        }
    }

    ColumnLayout {
        id: mediaContent

        anchors.fill: parent
        anchors.leftMargin: root.mediaHorizontalPadding
        anchors.rightMargin: root.mediaHorizontalPadding
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        spacing: 6
        opacity: root.mediaFaceActive ? 1 : 0
        visible: opacity > 0

        transform: Translate {
            x: root.mediaFaceActive ? 0 : -root.faceSlide

            Behavior on x {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }
        }

        // Header spans the full face, so the volume sits the same distance from
        // the left edge as the back chevron does from the right.
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PeekStatusRow {
                volume: root.audioVolume
                muted: root.audioMuted
                fontFamily: root.fontFamily
                compact: true
                showBattery: false
                expandStatus: false
                onAudioPanelRequested: root.audioPanelRequested()
                onAudioMuteRequested: root.audioMuteRequested()
                onAudioStepRequested: steps => root.audioStepRequested(steps)
            }

            // One dot per active player, in the workspace rail's language.
            // Clicking a dot switches to that player; only shown when there is
            // somewhere else to go.
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                spacing: 5
                visible: root.mediaPlayerCount > 1

                Repeater {
                    model: root.mediaPlayerCount

                    Item {
                        id: playerDot

                        required property int index

                        readonly property bool current: playerDot.index === root.mediaPlayerIndex

                        width: 8
                        height: 8

                        Rectangle {
                            anchors.centerIn: parent
                            width: playerDot.current ? 7 : 5
                            height: width
                            radius: width / 2
                            color: playerDot.current ? Theme.accent : Theme.secondaryText
                            opacity: playerDot.current ? 1 : 0.5
                            scale: playerDotMouse.containsMouse ? 1.25 : 1

                            Behavior on width {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }

                            Behavior on scale {
                                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: playerDotMouse

                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playerRequested(playerDot.index)
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                radius: Style.controlRadius
                color: dismissMouse.containsMouse ? Theme.controlHover : "transparent"

                MIcon {
                    anchors.centerIn: parent
                    name: "chevron_right"
                    size: 12
                    color: dismissMouse.containsMouse ? Theme.foreground : Theme.secondaryText
                }

                MouseArea {
                    id: dismissMouse

                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissRequested()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            Rectangle {
                id: mediaArtwork

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                radius: Style.radius
                color: Theme.controlNormal
                border.width: 1
                border.color: root.playing ? Theme.border : Theme.border
                clip: true

                Image {
                    id: mediaCoverSource

                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: mediaCoverSource
                    visible: root.artUrl !== "" && mediaCoverSource.status === Image.Ready

                    maskSource: Rectangle {
                        width: mediaArtwork.width
                        height: mediaArtwork.height
                        radius: mediaArtwork.radius
                    }
                }

                Row {
                    id: mediaEqualizer

                    anchors.centerIn: parent
                    spacing: 3
                    visible: root.artUrl === "" || mediaCoverSource.status !== Image.Ready

                    Repeater {
                        model: 3

                        Rectangle {
                            width: 4
                            height: root.playing ? (12 + index * 5) : 10
                            radius: 2
                            color: root.playing ? root.accent : Theme.secondaryText

                            // Same reasoning as the collapsed equalizer: these bars are
                            // hidden whenever there is cover art to show, so keying off
                            // the mode alone kept them animating behind the artwork.
                            SequentialAnimation on height {
                                running: mediaEqualizer.visible && root.playing
                                loops: Animation.Infinite

                                NumberAnimation {
                                    to: 10 + index * 4
                                    duration: 360 + index * 80
                                    easing.type: Easing.InOutSine
                                }

                                NumberAnimation {
                                    to: 23 - index * 3
                                    duration: 420 + index * 80
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    text: root.title
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.artist
                    color: root.secondaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 13
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7
                    visible: root.mediaLength > 0

                    Text {
                        text: root.formatTime(root.mediaPosition)
                        color: Theme.secondaryText
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        id: mediaProgressTrack

                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: height / 2
                        color: Theme.controlHover

                        Rectangle {
                            width: parent.width * root.mediaProgress
                            height: parent.height
                            radius: parent.radius
                            color: Theme.foreground

                            Behavior on width {
                                NumberAnimation {
                                    duration: 260
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            enabled: root.canSeek
                            hoverEnabled: true
                            cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

                            function seekToX(x) {
                                const progress = Math.max(0, Math.min(1, x / Math.max(1, mediaProgressTrack.width)));
                                root.seekRequested(root.mediaLength * progress);
                            }

                            onPressed: event => seekToX(event.x)
                            onPositionChanged: event => {
                                if (pressed)
                                    seekToX(event.x);
                            }
                        }
                    }

                    Text {
                        text: root.formatTime(root.mediaLength)
                        color: Theme.secondaryText
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 1
                    spacing: 7

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: Style.controlRadius
                        color: shuffleMouse.containsMouse && root.shuffleSupported ? Theme.controlHover : (root.shuffleActive ? Theme.selected : Theme.controlNormal)
                        border.width: 1
                        border.color: root.shuffleActive ? Theme.accent : Theme.border
                        opacity: root.shuffleSupported ? 1 : 0.35

                        MIcon {
                            anchors.centerIn: parent
                            name: "shuffle"
                            size: 14
                            color: root.shuffleActive ? Theme.foreground : root.primaryText
                        }

                        MouseArea {
                            id: shuffleMouse

                            anchors.fill: parent
                            enabled: root.shuffleSupported
                            hoverEnabled: true
                            cursorShape: root.shuffleSupported ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.shuffleRequested()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: Style.controlRadius
                        color: previousMouse.containsMouse && root.canGoPrevious ? Theme.controlHover : Theme.controlNormal
                        border.width: 1
                        border.color: root.canGoPrevious ? Theme.border : Theme.border
                        opacity: root.canGoPrevious ? 1 : 0.35

                        MIcon {
                            anchors.centerIn: parent
                            name: "skip_previous"
                            size: 16
                            color: root.primaryText
                        }

                        MouseArea {
                            id: previousMouse

                            anchors.fill: parent
                            enabled: root.canGoPrevious
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.previousRequested()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: Style.controlRadius
                        color: playPauseMouse.containsMouse && root.canTogglePlaying ? Theme.border : Theme.controlNormal
                        border.width: 1
                        border.color: root.canTogglePlaying ? Theme.border : Theme.border
                        opacity: root.canTogglePlaying ? 1 : 0.35

                        MIcon {
                            anchors.centerIn: parent
                            name: root.playing ? "pause" : "play_arrow"
                            size: 18
                            color: root.primaryText
                            filled: true
                        }

                        MouseArea {
                            id: playPauseMouse

                            anchors.fill: parent
                            enabled: root.canTogglePlaying
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playPauseRequested()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: Style.controlRadius
                        color: nextMouse.containsMouse && root.canGoNext ? Theme.controlHover : Theme.controlNormal
                        border.width: 1
                        border.color: root.canGoNext ? Theme.border : Theme.border
                        opacity: root.canGoNext ? 1 : 0.35

                        MIcon {
                            anchors.centerIn: parent
                            name: "skip_next"
                            size: 16
                            color: root.primaryText
                        }

                        MouseArea {
                            id: nextMouse

                            anchors.fill: parent
                            enabled: root.canGoNext
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextRequested()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: Style.controlRadius
                        color: loopMouse.containsMouse && root.loopSupported ? Theme.controlHover : (root.loopActive ? Theme.selected : Theme.controlNormal)
                        border.width: 1
                        border.color: root.loopActive ? Theme.accent : Theme.border
                        opacity: root.loopSupported ? 1 : 0.35

                        MIcon {
                            anchors.centerIn: parent
                            name: root.loopStateText === "ONE" ? "repeat_one" : "repeat"
                            size: 14
                            color: root.loopActive ? Theme.foreground : root.primaryText
                        }

                        MouseArea {
                            id: loopMouse

                            anchors.fill: parent
                            enabled: root.loopSupported
                            hoverEnabled: true
                            cursorShape: root.loopSupported ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.loopRequested()
                        }
                    }

                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 210
            }
        }
    }
}
