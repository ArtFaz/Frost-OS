import QtQuick
import qs.Core

Text {
    id: root

    property string name: ""
    property real size: Style.icon
    property bool filled: false

    readonly property var glyphs: ({
        "add": "󰐕", "apps": "󰀻", "battery": "󰁹", "battery_alert": "󰂃",
        "battery_charging_full": "󰂄", "battery_full": "󰁹", "bluetooth": "󰂯",
        "bluetooth_disabled": "󰂲", "bluetooth_searching": "󰂰",
        "bolt": "󰂄", "brightness_high": "󰃠", "brightness_low": "󰃞",
        "cached": "󰑓", "check": "󰄬", "close": "󰅖",
        "electric_bolt": "󰂄", "favorite": "󰋑", "lock": "󰌾",
        "expand_less": "󰅃", "expand_more": "󰅀", "headphones": "󰋋",
        "chevron_left": "󰅁", "chevron_right": "󰅂",
        "notifications": "󰂚", "notifications_off": "󰂛",
        "hourglass_top": "󰔛", "keyboard": "󰌌", "link": "󰌷",
        "link_off": "󰌸", "mic": "󰍬", "mouse": "󰍽", "pause": "󰏤",
        "play_arrow": "󰐊", "refresh": "󰑐", "search": "󰍉",
        "repeat": "󰑖", "repeat_one": "󰑘", "settings": "󰒓", "shuffle": "󰒟",
        "skip_next": "󰒭", "skip_previous": "󰒮", "smartphone": "󰏲",
        "battery_5_bar": "󰁼", "battery_saver": "󰂃", "speed": "󰓅", "star": "󰓎",
        "terminal": "󰆍", "volume_down": "󰕿", "volume_mute": "󰖁",
        "volume_off": "󰖁", "volume_up": "󰕾", "water_drop": "󰖌",
        "wifi": "󰖩", "wifi_1_bar": "󰤟", "wifi_2_bar": "󰤢", "wifi_off": "󰖪"
    })

    text: glyphs[name] || "󰘥"
    color: Theme.foreground
    font.family: Style.iconFontFamily
    font.pixelSize: size
    font.weight: filled ? Font.Bold : Font.Medium
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
    antialiasing: true
}
