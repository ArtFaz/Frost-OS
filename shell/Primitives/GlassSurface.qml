import QtQuick
import qs.Core

Rectangle {
    property string surfaceRole: "panel"

    color: Theme.surfaceColor(surfaceRole)
    radius: Theme.radiusForRole(surfaceRole)
    border.color: Theme.border
    border.width: Theme.borderWidth
}
