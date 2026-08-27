import QtQuick
pragma Singleton

QtObject {
    readonly property string fontFamily: "JetBrains Mono"
    readonly property string iconFontFamily: "Symbols Nerd Font Mono"
    readonly property string emojiFontFamily: "Noto Color Emoji"

    readonly property int barHeight: 30
    readonly property int radius: 14
    readonly property int rowRadius: 8
    readonly property int controlRadius: 6
    readonly property int barHoverRadius: 4
    readonly property int borderWidth: 1
    readonly property int focusWidth: 1

    readonly property int contentMargin: 24
    readonly property int panelPadding: 18
    readonly property int popupPadding: 14
    readonly property int rowHeight: 56
    readonly property int detailRowHeight: 64
    readonly property int headerHeight: 46
    readonly property int compactHeaderHeight: 34
    readonly property int footerHeight: 48

    readonly property int menuWidth: 448
    readonly property int menuMaxHeight: 448
    readonly property int panelWidth: 420
    readonly property int notificationWidth: 420
    readonly property int notificationHeight: 620
    readonly property int clipboardWidth: 875
    readonly property int clipboardHeight: 600
    readonly property int emojiWidth: 400
    readonly property int emojiHeight: 500
    readonly property int imageWidth: 720
    readonly property int imageHeight: 450
    readonly property int installerWidth: 720
    readonly property int installerHeight: 600

    readonly property int caption: 10
    readonly property int bodySmall: 11
    readonly property int body: 12
    readonly property int subtitle: 13
    readonly property int title: 14
    readonly property int heading: 16
    readonly property int display: 24
    readonly property int displayLarge: 28
    readonly property int brandIcon: 42
    readonly property int icon: 14
    readonly property int iconLarge: 18

    function space(units) {
        return Math.max(0, Math.round(units * 6));
    }
}
