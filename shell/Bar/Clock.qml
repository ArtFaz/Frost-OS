import QtQuick
import Quickshell
import qs.Core

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd, d MMM  HH:mm")
        color: Theme.foreground
        font.family: "sans-serif"
        font.pixelSize: 13
        font.bold: true
    }

}
