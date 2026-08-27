import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    signal backRequested()

    function iconFor(code, day) {
        const value = Number(code);
        if (value === 0)
            return day === 0 ? "󰖔" : "󰖙";
        if (value <= 3)
            return "󰖕";
        if (value <= 48)
            return "󰖑";
        if (value <= 67 || value >= 80 && value <= 82)
            return "󰖗";
        if (value <= 77 || value >= 85 && value <= 86)
            return "󰼶";
        if (value >= 95)
            return "󰙾";
        return "󰖐";
    }

    Column {
        anchors.fill: parent
        anchors.margins: Style.panelPadding
        spacing: Style.space(2)

        PanelHeader {
            width: parent.width
            title: WeatherState.city || "Weather"
            subtitle: WeatherState.failed ? "Forecast unavailable" : "Open-Meteo forecast"
            showBack: true
            actionText: WeatherState.loading ? "Loading" : "Refresh"
            onBack: root.backRequested()
            onAction: WeatherState.refresh()
        }

        Rectangle {
            width: parent.width
            height: 154
            radius: Style.rowRadius
            color: Theme.controlNormal

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Style.panelPadding
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconFor(WeatherState.current ? WeatherState.current.code : -1, WeatherState.current ? WeatherState.current.isDay : 1)
                color: Theme.highlight
                font.family: Style.iconFontFamily
                font.pixelSize: 52
            }

            Column {
                anchors.right: parent.right
                anchors.rightMargin: Style.panelPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(1)

                Text {
                    anchors.right: parent.right
                    text: WeatherState.current && Number.isFinite(Number(WeatherState.current.temperature)) ? Math.round(Number(WeatherState.current.temperature)) + "°" : "--°"
                    color: Theme.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Style.displayLarge
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    text: WeatherState.current ? "Feels " + Math.round(Number(WeatherState.current.apparent)) + "° · " + Math.round(Number(WeatherState.current.humidity)) + "% humidity" : "No current conditions"
                    color: Theme.muted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.bodySmall
                }
            }
        }

        Text {
            text: "5-DAY FORECAST"
            color: Theme.muted
            font.family: Style.fontFamily
            font.pixelSize: Style.caption
            font.bold: true
        }

        Repeater {
            model: WeatherState.daily

            SurfaceButton {
                required property var modelData
                width: parent.width
                iconText: root.iconFor(modelData.code, 1)
                title: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "dddd")
                subtitle: Number.isFinite(Number(modelData.precipitation)) ? Math.round(Number(modelData.precipitation)) + "% precipitation" : ""
                trailingText: Math.round(Number(modelData.minimum)) + "°  " + Math.round(Number(modelData.maximum)) + "°"
            }
        }
    }
}
