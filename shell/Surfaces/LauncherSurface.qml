import QtQuick
import Quickshell
import qs.Core

// The Frost launcher. Its navigation and every leaf action are first-party — the
// donor menu drives each leaf through `bash -lc`, which this shell forbids — but
// the card chrome, fold behaviour and motion follow the donor exactly.
Item {
    id: root

    property bool active: false
    property int hostWidth: 0
    property int hostHeight: 0

    property string route: "root"
    property string filterText: ""
    property int selectedIndex: 0
    // The card centres on open, then pins its top on the first keystroke or
    // submenu move so it grows downward instead of re-centring under the pointer.
    property int frozenTop: -1
    property int navigationDirection: 1
    property bool confirmOpen: false
    property string confirmAction: ""
    property string confirmLabel: ""
    property string confirmGlyph: ""

    readonly property int cardPadding: Style.contentMargin
    readonly property int headerHeight: Style.headerHeight
    readonly property int contentSpacing: 12
    readonly property int rowSpacing: 3
    readonly property int rowPeek: Math.round(Style.rowHeight * 0.55)
    readonly property int footerHeight: Style.footerHeight

    readonly property bool appsRoute: root.route === "apps"
    readonly property var rows: root.appsRoute ? root.applicationRows() : root.menuRows()
    readonly property int rowUnit: root.appsRoute ? Style.detailRowHeight : Style.rowHeight

    // Never end on a row boundary: fit whole rows, then add one spacing plus a
    // peek so the next row is visibly cut and the list reads as scrollable.
    readonly property int listHeight: {
        const budget = Math.min(Style.menuMaxHeight, root.hostHeight - 10 - root.cardPadding * 2
                                - root.headerHeight - root.contentSpacing * 2 - root.footerHeight);
        const unit = root.rowUnit + root.rowSpacing;
        const total = root.rows.length * unit - root.rowSpacing;
        if (total <= budget)
            return Math.max(root.rowUnit, total);

        const whole = Math.max(1, Math.floor((budget - root.rowSpacing - root.rowPeek) / unit));
        return whole * unit - root.rowSpacing + root.rowSpacing + root.rowPeek;
    }

    function menuRows() {
        const query = root.filterText.trim().toLowerCase();
        const all = root.routeItems(root.route);
        if (query === "")
            return all;

        const matched = [];
        for (let i = 0; i < all.length; i += 1) {
            if ((all[i].label + " " + all[i].detail).toLowerCase().indexOf(query) >= 0)
                matched.push(all[i]);
        }
        return matched;
    }

    function applicationRows() {
        const query = root.filterText.trim().toLowerCase();
        const source = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        const matched = [];

        for (let i = 0; i < source.length; i += 1) {
            const entry = source[i];
            if (!entry || entry.noDisplay)
                continue;
            const haystack = (entry.name + " " + entry.genericName + " " + entry.comment).toLowerCase();
            if (query === "" || haystack.indexOf(query) >= 0)
                matched.push({"entry": entry, "label": entry.name, "detail": entry.comment || entry.genericName || "", "kind": "app"});
        }

        matched.sort((left, right) => String(left.label).localeCompare(String(right.label)));
        return matched.slice(0, 120);
    }

    function routeItems(value) {
        if (value === "trigger")
            return [{"icon": "󰅌", "label": "Clipboard", "detail": "Histórico de texto", "surface": "clipboard", "kind": "menu"},
                    {"icon": "󰞅", "label": "Emoji", "detail": "Buscar e copiar", "surface": "emoji", "kind": "menu"},
                    {"icon": "󰋩", "label": "Imagens", "detail": "Copiar de ~/Pictures", "surface": "images", "kind": "menu"},
                    {"icon": "󰸉", "label": "Papel de parede", "detail": "Trocar o fundo", "surface": "wallpaper", "kind": "menu"}];
        if (value === "setup")
            return [{"icon": "󰖩", "label": "Wi-Fi", "detail": "Redes e conexões", "island": "wifi", "kind": "menu"},
                    {"icon": "󰂯", "label": "Bluetooth", "detail": "Dispositivos", "island": "bluetooth", "kind": "menu"},
                    {"icon": "󰕾", "label": "Áudio", "detail": "Volume e saída", "island": "audio", "kind": "menu"},
                    {"icon": "󰂚", "label": "Notificações", "detail": "Histórico do Mako", "island": "notifications", "kind": "menu"},
                    {"icon": "󰁹", "label": "Bateria", "detail": "Energia e limite de carga", "island": "battery", "kind": "menu"}];
        if (value === "system")
            return [{"icon": "󰌾", "label": "Bloquear", "detail": "Proteger esta sessão", "action": "lock", "kind": "action"},
                    {"icon": "󰒲", "label": "Suspender", "detail": "Dormir até retomar", "action": "suspend", "kind": "action"},
                    {"icon": "󰍃", "label": "Encerrar sessão", "detail": "Sair do Frost", "action": "logout", "kind": "action"},
                    {"icon": "󰜉", "label": "Reiniciar", "detail": "Reiniciar a máquina", "action": "reboot", "kind": "action"},
                    {"icon": "󰐥", "label": "Desligar", "detail": "Encerrar a máquina", "action": "poweroff", "kind": "action"}];
        if (value === "style")
            return [{"icon": "󰏘", "label": "Frost Dark", "detail": "Paleta escura fria", "theme": "frost", "kind": "action"},
                    {"icon": "󰏘", "label": "Frost Light", "detail": "Paleta clara neutra", "theme": "frost-light", "kind": "action"},
                    {"icon": "󰏘", "label": "Gruvbox", "detail": "Paleta escura padrão", "theme": "gruvbox", "kind": "action"}];
        return [{"icon": "󰀻", "label": "Aplicativos", "detail": "Buscar e abrir", "route": "apps", "kind": "menu"},
                {"icon": "󱓥", "label": "Atalhos", "detail": "Área de transferência e emoji", "route": "trigger", "kind": "menu"},
                {"icon": "󰏘", "label": "Aparência", "detail": "Paleta semântica", "route": "style", "kind": "menu"},
                {"icon": "󰒓", "label": "Ajustes", "detail": "Rede, áudio e energia", "route": "setup", "kind": "menu"},
                {"icon": "󰐥", "label": "Sistema", "detail": "Sessão e energia", "route": "system", "kind": "menu"}];
    }

    function routeTitle() {
        if (root.route === "apps") return "Aplicativos";
        if (root.route === "trigger") return "Atalhos";
        if (root.route === "style") return "Aparência";
        if (root.route === "setup") return "Ajustes";
        if (root.route === "system") return "Sistema";
        return "";
    }

    function enterRoute(value, direction) {
        root.navigationDirection = direction;
        root.route = value;
        root.filterText = "";
        root.selectedIndex = 0;
        root.freezeTop();
        listMotion.restart();
    }

    function goBack() {
        if (root.route === "root") {
            Surfaces.close();
            return;
        }
        root.enterRoute("root", -1);
    }

    function freezeTop() {
        if (root.frozenTop < 0)
            root.frozenTop = root.y;
    }

    readonly property var sessionNotices: ({
        "poweroff": {"glyph": "󰐥", "message": "Desligando"},
        "reboot": {"glyph": "󰜉", "message": "Reiniciando"},
        "logout": {"glyph": "󰍃", "message": "Encerrando sessão"}
    })

    function requestSessionAction(action, label, glyph) {
        if (action === "lock") {
            root.runSessionAction(action);
            return;
        }

        root.confirmAction = action;
        root.confirmLabel = label;
        root.confirmGlyph = glyph;
        root.confirmOpen = true;
    }

    function runSessionAction(action) {
        const notice = root.sessionNotices[action];
        if (notice)
            Surfaces.notify(notice.glyph, notice.message, 5000);

        ShellBackend.action(action);
        Surfaces.close();
    }

    function cancelConfirm() {
        root.confirmOpen = false;
        root.confirmAction = "";
    }

    function activate(item) {
        if (!item)
            return;

        if (item.kind === "app") {
            item.entry.execute();
            Surfaces.close();
            return;
        }
        if (item.route) {
            root.enterRoute(item.route, 1);
            return;
        }
        if (item.surface) {
            Surfaces.show(item.surface);
            return;
        }
        if (item.island) {
            Surfaces.close();
            Surfaces.islandModeRequested(item.island);
            return;
        }
        if (item.action) {
            root.requestSessionAction(item.action, item.label, item.icon);
            return;
        }
        if (item.theme)
            ShellBackend.action("theme-set", item.theme);
    }

    function select(delta) {
        const count = root.rows.length;
        if (count === 0)
            return;

        root.selectedIndex = ((root.selectedIndex + delta) % count + count) % count;
        rowList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function editFilter(mode) {
        if (root.filterText === "") {
            root.goBack();
            return;
        }

        if (mode === "clear")
            root.filterText = "";
        else if (mode === "word")
            root.filterText = root.filterText.replace(/\s*\S+\s*$/, "");
        else
            root.filterText = root.filterText.slice(0, -1);

        root.selectedIndex = 0;
    }

    width: Math.min(Style.menuWidth, root.hostWidth - 10)
    height: Math.min(root.cardPadding * 2 + root.headerHeight + root.contentSpacing * 2 + root.listHeight + root.footerHeight,
                     root.hostHeight - 10)
    visible: root.active
    opacity: root.active ? 1 : 0
    scale: root.active ? 1 : 0.98

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Behavior on height {
        enabled: root.active
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    transform: Translate {
        y: root.active ? 0 : 6

        Behavior on y {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
    }

    onActiveChanged: {
        if (!root.active) {
            root.frozenTop = -1;
            return;
        }

        root.route = "root";
        root.filterText = "";
        root.selectedIndex = 0;
        keyCatcher.forceActiveFocus();
    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: root.active
        Keys.priority: Keys.BeforeItem

        Keys.onPressed: event => {
            if (root.confirmOpen) {
                event.accepted = confirmCard.handleKey(event);
                return;
            }
            if (event.key === Qt.Key_Escape) {
                if (root.filterText !== "")
                    root.filterText = "";
                else
                    Surfaces.close();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Backspace) {
                root.editFilter(event.modifiers & Qt.ControlModifier ? "word" : "character");
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
                root.editFilter("clear");
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Left) {
                root.goBack();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Up) {
                root.select(-1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Down) {
                root.select(1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageUp) {
                root.select(-6);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_PageDown) {
                root.select(6);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) {
                root.activate(root.rows[root.selectedIndex]);
                event.accepted = true;
                return;
            }
            if (event.text.length === 1 && event.text.charCodeAt(0) >= 0x20 && event.text.charCodeAt(0) !== 0x7f
                && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                root.filterText += event.text;
                root.selectedIndex = 0;
                root.freezeTop();
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Theme.surfaceColor("menu")
            border.width: Style.borderWidth
            border.color: Theme.border

            Column {
                anchors.fill: parent
                anchors.margins: root.cardPadding
                spacing: root.contentSpacing

                // The launcher's field is not the one the other surfaces use: the
                // donor gives it a fainter fill and border, a taller box and a back
                // chevron that replaces the search glyph inside a submenu.
                SurfaceSearchField {
                    width: parent.width
                    height: root.headerHeight
                    text: root.filterText
                    placeholder: root.route === "root" ? "Buscar no Frost…" : "Buscar em " + root.routeTitle() + "…"
                    glyph: root.route !== "root" && root.filterText === "" ? "󰅁" : "󰍉"
                    glyphOpacity: 0.78
                    placeholderOpacity: 0.62
                    textSize: Style.body
                    fillAlpha: 0.035
                    borderAlpha: 0.17
                    glyphLeftMargin: 10
                    textLeftMargin: 6
                    textRightMargin: 14

                    MouseArea {
                        width: 48
                        height: parent.height
                        enabled: root.route !== "root" && root.filterText === ""
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.goBack()
                    }
                }

                Item {
                    width: parent.width
                    height: root.listHeight
                    clip: true

                    ListView {
                        id: rowList

                        anchors.fill: parent
                        spacing: root.rowSpacing
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.rows

                        transform: Translate {
                            id: listTranslate
                        }

                        delegate: Rectangle {
                            id: rowItem

                            required property var modelData
                            required property int index

                            readonly property bool current: root.selectedIndex === rowItem.index

                            width: ListView.view.width
                            height: root.rowUnit
                            radius: Style.rowRadius
                            color: rowItem.current ? Theme.selected : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: root.rowUnit - 14
                                radius: 2
                                color: Theme.accent
                                visible: rowItem.current
                            }

                            Item {
                                id: rowIcon

                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                height: 36

                                Text {
                                    anchors.centerIn: parent
                                    text: rowItem.modelData.icon || ""
                                    visible: rowItem.modelData.kind !== "app"
                                    color: Theme.foreground
                                    font.family: Style.iconFontFamily
                                    font.pixelSize: Style.iconLarge
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    visible: rowItem.modelData.kind === "app"
                                    source: rowItem.modelData.kind === "app"
                                            ? Quickshell.iconPath(rowItem.modelData.entry.icon, true) : ""
                                    sourceSize.width: 36
                                    sourceSize.height: 36
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                            }

                            Column {
                                anchors.left: rowIcon.right
                                anchors.leftMargin: 6
                                anchors.right: rowTrail.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: rowItem.modelData.label || ""
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.heading
                                    font.weight: Font.Medium
                                }

                                Text {
                                    width: parent.width
                                    text: rowItem.modelData.detail || ""
                                    visible: text !== ""
                                    color: Theme.foreground
                                    opacity: 0.52
                                    elide: Text.ElideRight
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.bodySmall
                                }
                            }

                            Text {
                                id: rowTrail

                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                text: "›"
                                color: Theme.foreground
                                opacity: rowItem.modelData.kind === "menu" ? 0.36 : 0
                                horizontalAlignment: Text.AlignHCenter
                                font.family: Style.fontFamily
                                font.pixelSize: Style.heading
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = rowItem.index
                                onClicked: root.activate(rowItem.modelData)
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: root.rows.length === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰈉"
                            color: Theme.foreground
                            opacity: 0.8
                            font.family: Style.iconFontFamily
                            font.pixelSize: Style.displayLarge
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.filterText !== "" ? "No matches for “" + root.filterText + "”" : "Nothing here yet"
                            color: Theme.foreground
                            opacity: 0.7
                            font.family: Style.fontFamily
                            font.pixelSize: Style.title
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: root.footerHeight

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: Style.borderWidth
                        color: Theme.alpha(Theme.foreground, 0.17)
                    }

                    Row {
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [{"action": "poweroff", "glyph": "󰐥", "size": 20, "label": "Desligar"},
                                    {"action": "lock", "glyph": "󰌾", "size": 16, "label": "Bloquear"},
                                    {"action": "reboot", "glyph": "󰜉", "size": 18, "label": "Reiniciar"},
                                    {"action": "logout", "glyph": "󰍃", "size": 18, "label": "Encerrar sessão"}]

                            Rectangle {
                                id: footerButton

                                required property var modelData

                                width: (parent.width - 18) / 4
                                height: parent.parent.height - 6
                                radius: Style.controlRadius
                                color: footerMouse.pressed ? Theme.controlPressed
                                                           : (footerMouse.containsMouse ? Theme.controlHover : "transparent")

                                Behavior on color {
                                    ColorAnimation { duration: 130; easing.type: Easing.OutCubic }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: footerButton.modelData.glyph
                                    color: Theme.foreground
                                    opacity: footerMouse.containsMouse ? 1 : 0.78
                                    font.family: Style.iconFontFamily
                                    font.pixelSize: footerButton.modelData.size

                                    Behavior on opacity {
                                        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                                    }
                                }

                                MouseArea {
                                    id: footerMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.requestSessionAction(footerButton.modelData.action,
                                                                        footerButton.modelData.label,
                                                                        footerButton.modelData.glyph)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        z: 40
        visible: root.confirmOpen || confirmCard.opacity > 0

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancelConfirm()
        }

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Theme.scrim
            opacity: root.confirmOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }

        ConfirmCard {
            id: confirmCard

            x: (parent.width - width) / 2
            y: parent.height + 12
            width: Math.max(240, Math.min(parent.width, 370))
            opened: root.confirmOpen
            message: "Deseja " + root.confirmLabel.toLowerCase() + "?"
            confirmLabel: root.confirmLabel
            onConfirmed: {
                const action = root.confirmAction;
                root.cancelConfirm();
                root.runSessionAction(action);
            }
            onCanceled: root.cancelConfirm()
        }
    }

    // Submenu navigation slides the whole list as one block; the donor has no
    // per-row stagger anywhere.
    ParallelAnimation {
        id: listMotion

        NumberAnimation {
            target: listTranslate
            property: "x"
            from: root.navigationDirection * 10
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: rowList
            property: "opacity"
            from: 0.62
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
}
