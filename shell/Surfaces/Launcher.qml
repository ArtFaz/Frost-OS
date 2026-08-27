import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Core
import qs.Primitives

Item {
    id: root

    property string route: "root"
    property string filterText: ""
    readonly property var applications: filteredApplications()
    readonly property var routeItems: itemsForRoute(route).filter((item) => {
        const query = filterText.trim().toLowerCase();
        return query === "" || (item.label + " " + item.detail).toLowerCase().indexOf(query) >= 0;
    })

    signal closeRequested()
    signal surfaceRequested(string surface)

    function filteredApplications() {
        const query = filterText.trim().toLowerCase();
        const source = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        const result = [];
        for (let index = 0; index < source.length; index++) {
            const entry = source[index];
            if (!entry || entry.noDisplay)
                continue;
            const haystack = (entry.name + " " + entry.genericName + " " + entry.comment).toLowerCase();
            if (!query || haystack.indexOf(query) >= 0)
                result.push(entry);
        }
        result.sort((left, right) => String(left.name).localeCompare(String(right.name)));
        return result.slice(0, 120);
    }

    function itemsForRoute(value) {
        if (value === "trigger")
            return [{"icon": "󰅇", "label": "Clipboard", "detail": "Text history", "surface": "clipboard"}, {"icon": "󰞅", "label": "Emoji", "detail": "Search and copy", "surface": "emoji"}, {"icon": "󰋩", "label": "Images", "detail": "Recent pictures", "surface": "images"}, {"icon": "󰂚", "label": "Notifications", "detail": "Mako history", "surface": "notifications"}];
        if (value === "setup")
            return [{"icon": "󰤨", "label": "Network", "detail": SystemState.networkName, "surface": "network"}, {"icon": "󰂯", "label": "Bluetooth", "detail": SystemState.bluetoothAvailable ? "Devices" : "Unavailable", "surface": "bluetooth"}, {"icon": "󰕾", "label": "Audio", "detail": SystemState.muted ? "Muted" : Math.round(SystemState.volume * 100) + "%", "surface": "audio"}, {"icon": "󰍹", "label": "Display & power", "detail": "Brightness and session", "surface": "display-power"}];
        if (value === "system")
            return [{"icon": "󰌾", "label": "Lock", "detail": "Secure this session", "action": "lock"}, {"icon": "󰒲", "label": "Suspend", "detail": "Sleep until resumed", "action": "suspend"}, {"icon": "󰗽", "label": "Log out", "detail": "End the Frost session", "action": "logout"}, {"icon": "󰐥", "label": "Power controls", "detail": "Restart or power off", "surface": "display-power"}];
        if (value === "style")
            return [{"icon": "󰏘", "label": "Gruvbox", "detail": "Default dark palette", "theme": "gruvbox"}, {"icon": "󰏘", "label": "Frost Dark", "detail": "Cool dark palette", "theme": "frost"}, {"icon": "󰏘", "label": "Frost Light", "detail": "Neutral light palette", "theme": "frost-light"}];
        return [{"icon": "󰀻", "label": "Apps", "detail": "Browse and launch applications", "route": "apps"}, {"icon": "󱓥", "label": "Trigger", "detail": "Clipboard, emoji and captures", "route": "trigger"}, {"icon": "󰏘", "label": "Style", "detail": "Choose a semantic color palette", "route": "style"}, {"icon": "󰒓", "label": "Setup", "detail": "System settings and preferences", "route": "setup"}, {"icon": "󰏖", "label": "Install", "detail": "Applications from Arch, Frost and AUR", "surface": "app-installer"}, {"icon": "󰋼", "label": "About", "detail": "Frost 0.2.0 · independent Arch session", "route": "about"}, {"icon": "󰐥", "label": "System", "detail": "Power, session and security", "route": "system"}];
    }

    function activateItem(item) {
        if (item.surface) {
            surfaceRequested(item.surface);
            return;
        }
        if (item.action) {
            ShellBackend.action(item.action);
            closeRequested();
            return;
        }
        if (item.theme) {
            ShellBackend.action("theme-set", item.theme);
            return;
        }
        if (item.route) {
            route = item.route;
            filterText = "";
            focusTimer.restart();
        }
    }

    onVisibleChanged: {
        if (visible) {
            route = "root";
            filterText = "";
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 0
        onTriggered: search.takeFocus()
    }

    Column {
        anchors.fill: parent
        anchors.margins: Style.contentMargin
        spacing: Style.space(2)

        PanelHeader {
            width: parent.width
            title: root.route === "root" ? "Frost" : root.route === "apps" ? "Applications" : root.route.charAt(0).toUpperCase() + root.route.slice(1)
            subtitle: root.route === "about" ? "Sovereign Arch desktop" : "Type to search"
            showBack: root.route !== "root"
            actionText: root.route === "root" ? "Close" : ""
            onBack: {
                root.route = "root";
                root.filterText = "";
            }
            onAction: root.closeRequested()
        }

        SearchField {
            id: search
            width: parent.width
            visible: root.route !== "about"
            placeholderText: root.route === "apps" ? "Search applications" : "Search Frost"
            onTextChanged: root.filterText = text
            onAccepted: {
                if (root.route === "apps" && root.applications.length > 0) {
                    root.applications[0].execute();
                    root.closeRequested();
                } else if (root.routeItems.length > 0) {
                    root.activateItem(root.routeItems[0]);
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - y - footer.height - Style.space(2)

            Column {
                anchors.centerIn: parent
                visible: root.route === "about"
                spacing: Style.space(2)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰍜"
                    color: Theme.accent
                    font.family: Style.iconFontFamily
                    font.pixelSize: Style.brandIcon
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Frost 0.2.0"
                    color: Theme.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Style.heading
                    font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Theme.name + " · " + Theme.mode
                    color: Theme.muted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.bodySmall
                }
            }

            ListView {
                id: itemList
                anchors.fill: parent
                visible: root.route !== "about" && root.route !== "apps"
                clip: true
                spacing: Style.space(1)
                model: root.routeItems

                delegate: SurfaceButton {
                    required property var modelData
                    width: itemList.width
                    iconText: modelData.icon
                    title: modelData.label
                    subtitle: modelData.detail
                    trailingText: "›"
                    onActivated: root.activateItem(modelData)
                }
            }

            ListView {
                id: applicationList
                anchors.fill: parent
                visible: root.route === "apps"
                clip: true
                spacing: Style.space(1)
                model: root.applications

                delegate: SurfaceButton {
                    required property var modelData
                    width: applicationList.width
                    iconSource: Quickshell.iconPath(modelData.icon, true)
                    title: modelData.name
                    subtitle: modelData.comment || modelData.genericName
                    trailingText: "Open"
                    onActivated: {
                        modelData.execute();
                        root.closeRequested();
                    }
                }
            }
        }

        Row {
            id: footer
            width: parent.width
            height: Style.footerHeight
            spacing: Style.space(1)

            Repeater {
                model: [{"label": "Clipboard", "surface": "clipboard"}, {"label": "Emoji", "surface": "emoji"}, {"label": "Images", "surface": "images"}, {"label": "Install", "surface": "app-installer"}]

                SurfaceButton {
                    required property var modelData
                    width: (footer.width - Style.space(3)) / 4
                    height: Style.compactHeaderHeight
                    compact: true
                    title: modelData.label
                    onActivated: root.surfaceRequested(modelData.surface)
                }
            }
        }
    }
}
