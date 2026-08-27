import QtQuick
import qs.Core
import qs.Primitives

Item {
    id: root

    property date shownMonth: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    readonly property date today: new Date()

    signal backRequested()

    function changeMonth(delta) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + delta, 1);
    }

    function cellDate(index) {
        const mondayOffset = (shownMonth.getDay() + 6) % 7;
        return new Date(shownMonth.getFullYear(), shownMonth.getMonth(), index - mondayOffset + 1);
    }

    onVisibleChanged: {
        if (visible)
            shownMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    }

    Column {
        anchors.fill: parent
        anchors.margins: Style.panelPadding
        spacing: Style.space(2)

        PanelHeader {
            width: parent.width
            title: Qt.formatDate(root.shownMonth, "MMMM yyyy")
            subtitle: Qt.formatDate(root.today, "dddd, d MMMM")
            actionText: "Today"
            onAction: root.shownMonth = new Date(root.today.getFullYear(), root.today.getMonth(), 1)
        }

        Row {
            width: parent.width
            height: Style.compactHeaderHeight

            SurfaceButton {
                width: 52
                height: parent.height
                compact: true
                title: "‹"
                onActivated: root.changeMonth(-1)
            }

            Item {
                width: parent.width - 104
                height: 1
            }

            SurfaceButton {
                width: 52
                height: parent.height
                compact: true
                title: "›"
                onActivated: root.changeMonth(1)
            }
        }

        Grid {
            width: parent.width
            columns: 7

            Repeater {
                model: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

                Text {
                    required property string modelData
                    width: parent.width / 7
                    height: 26
                    text: modelData
                    color: Theme.muted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.caption
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Repeater {
                model: 42

                InteractiveSurface {
                    required property int index
                    readonly property date day: root.cellDate(index)
                    readonly property bool currentMonth: day.getMonth() === root.shownMonth.getMonth()
                    readonly property bool isToday: day.getFullYear() === root.today.getFullYear() && day.getMonth() === root.today.getMonth() && day.getDate() === root.today.getDate()
                    width: parent.width / 7
                    height: 43
                    selected: isToday

                    Text {
                        anchors.centerIn: parent
                        text: parent.day.getDate()
                        color: parent.isToday ? Theme.accent : parent.currentMonth ? Theme.foreground : Theme.muted
                        opacity: parent.currentMonth || parent.isToday ? 1 : 0.46
                        font.family: Style.fontFamily
                        font.pixelSize: Style.body
                        font.bold: parent.isToday
                    }
                }
            }
        }
    }
}
