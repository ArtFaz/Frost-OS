import QtQuick
pragma Singleton

QtObject {
    readonly property bool reduced: false
    readonly property int fast: reduced ? 0 : 120
    readonly property int standard: reduced ? 0 : 160
    readonly property int deliberate: reduced ? 0 : 180
    readonly property int easing: Easing.OutCubic
}
