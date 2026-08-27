import QtQuick
import Quickshell
import "../shell/Core" as Core

ShellRoot {
    property var configState: Core.Config
    property var indicatorState: Core.IndicatorState
    property var systemState: Core.SystemState
    property var themeState: Core.Theme
    property var weatherState: Core.WeatherState
}
