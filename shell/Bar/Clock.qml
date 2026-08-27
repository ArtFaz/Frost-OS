import QtQuick
import Quickshell
import qs.Core

Item {
    signal activated()

    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight - 8

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm")
        color: Theme.foreground
        font.family: Style.fontFamily
        font.pixelSize: Style.bodySmall
        font.bold: true
    }

    TapHandler {
        onTapped: parent.activated()
    }

}
