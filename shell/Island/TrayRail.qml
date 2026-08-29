import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.Core

// Background applications: the StatusNotifierItem hosts, drawn as bare icons
// beside the island with no surface of their own.
Row {
    id: root

    property real fade: 1

    signal menuRequested(var item, real anchorX)
    readonly property int iconSize: 15
    readonly property int maxItems: 6
    readonly property var items: (SystemTray.items?.values ?? []).slice(0, root.maxItems)

    spacing: 8
    opacity: root.fade

    Behavior on opacity {
        NumberAnimation { duration: 160 }
    }

    Repeater {
        model: root.items

        Item {
            id: entry

            required property var modelData

            width: root.iconSize
            height: root.iconSize

            Image {
                anchors.fill: parent
                source: entry.modelData?.icon ?? ""
                sourceSize.width: root.iconSize * 2
                sourceSize.height: root.iconSize * 2
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                visible: status === Image.Ready
                opacity: entryMouse.containsMouse ? 1 : 0.85
                scale: entryMouse.containsMouse ? 1.15 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 140 }
                }

                Behavior on scale {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: entryMouse

                anchors.fill: parent
                anchors.margins: -3
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (!entry.modelData)
                        return;
                    if (mouse.button === Qt.RightButton && entry.modelData.hasMenu)
                        root.menuRequested(entry.modelData, entry.x + entry.width / 2);
                    else
                        entry.modelData.activate();
                }
            }
        }
    }
}
