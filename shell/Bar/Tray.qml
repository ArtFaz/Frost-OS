import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Core

Row {
    id: root

    spacing: 4

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem

            required property var modelData
            readonly property bool passive: modelData.status === Status.Passive

            visible: !passive
            width: visible ? 24 : 0
            height: 24

            IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: trayItem.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate();
                        return ;
                    }
                    if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && trayItem.modelData.onlyMenu)) {
                        if (!trayItem.modelData.hasMenu)
                            return ;

                        const point = trayItem.QsWindow.contentItem.mapFromItem(trayItem, mouse.x, mouse.y);
                        trayItem.modelData.display(trayItem.QsWindow.window, point.x, point.y);
                        return ;
                    }
                    trayItem.modelData.activate();
                }
            }

        }

    }

}
