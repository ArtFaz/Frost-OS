-- Package-owned Frost session. User and administrator overlays enter only
-- through the versioned Frost configuration contract in a later phase.

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.config({
    input = {
        -- One keyboard, always ABNT2. Read from the system only if Frost ever
        -- ships on another machine; kb_options is empty (no compose remap).
        kb_layout = "br",
        kb_options = "",
        follow_mouse = 1,
        sensitivity = 0,
        repeat_rate = 40,
        repeat_delay = 250,
        numlock_by_default = true,
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
            clickfinger_behavior = true,
            scroll_factor = 0.4,
        },
    },
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 0,
        col = {
            active_border = "rgba(00000000)",
            inactive_border = "rgba(00000000)",
        },
        resize_on_border = false,
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
    cursor = {
        hide_on_key_press = true,
        warp_on_change_workspace = 1,
    },
    binds = {
        hide_special_on_workspace_change = true,
    },
    group = {
        col = {
            border_active = "rgba(00000000)",
            border_inactive = "rgba(00000000)",
            border_locked_active = "rgba(00000000)",
            border_locked_inactive = "rgba(00000000)",
        },
        groupbar = {
            enabled = true,
            font_family = "monospace",
            font_size = 11,
            font_weight_active = "semibold",
            font_weight_inactive = "normal",
            gradients = true,
            height = 24,
            indicator_gap = 0,
            indicator_height = 0,
            text_padding = 8,
            rounding = 6,
            rounding_power = 2.0,
            gradient_rounding = 6,
            gradient_rounding_power = 2.0,
            -- Colours are overwritten at runtime by the generated
            -- hyprland-colors.conf; these are the pre-theme fallback.
            text_color = "rgba(d4be98ff)",
            text_color_inactive = "rgba(d4be989e)",
            gaps_in = 4,
            gaps_out = 4,
            keep_upper_gap = true,
            blur = true,
            col = {
                active = "rgba(d4be981f)",
                inactive = "rgba(d4be980a)",
                locked_active = "rgba(d4be981f)",
                locked_inactive = "rgba(d4be980a)",
            },
        },
    },
    decoration = {
        rounding = 12,
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            new_optimizations = true,
            noise = 0.008,
            contrast = 0.98,
            brightness = 0.96,
            vibrancy = 0.12,
            vibrancy_darkness = 0.25,
        },
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            sharp = false,
            color = "rgba(0000003d)",
            color_inactive = "rgba(0000001f)",
            scale = 1.0,
        },
    },
    animations = {
        enabled = true,
    },
    misc = {
        disable_hyprland_logo = true,
        -- uwsm sets XDG_CURRENT_DESKTOP to "Frost:Hyprland" on purpose, so the
        -- session is identifiable as Frost to portals and desktop files. Hyprland
        -- warns on every login that the value is not plain "Hyprland"; the value
        -- is deliberate, so the check is off rather than the identity changed.
        disable_xdg_env_checks = true,
        disable_splash_rendering = true,
        -- The configuration is package-owned and only ever changes through a
        -- pacman transaction, which replaces the file rather than editing it.
        -- With the watcher on, Hyprland reloads during the instant the old file
        -- is gone and the new one is not yet in place, and reports a missing
        -- config every single upgrade. Reloading after an upgrade is an explicit
        -- hyprctl reload instead.
        disable_autoreload = true,
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
        focus_on_activate = true,
        disable_scale_notification = true,
    },
    xwayland = {
        -- Without this every XWayland client renders blurry on a scaled output.
        force_zero_scaling = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("motionSmooth", { type = "bezier", points = { { 0.22, 0.65 }, { 0.25, 1.00 } } })
hl.curve("motionOut", { type = "bezier", points = { { 0.20, 0.85 }, { 0.25, 1.00 } } })

-- One curve family at one speed, so nothing in the session moves at a rate the
-- rest does not share.
hl.animation({ leaf = "global", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "border", enabled = true, speed = 1.5, bezier = "motionOut" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "motionSmooth", style = "popin 95%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "motionSmooth", style = "popin 97%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.0, bezier = "motionSmooth" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "motionSmooth", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.5, bezier = "motionSmooth", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.5, bezier = "motionSmooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.0, bezier = "motionSmooth", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.0, bezier = "motionSmooth", style = "slidefadevert 12%" })

-- Three-finger horizontal swipe changes workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.window_rule({
    name = "frost-apps-no-blur",
    match = { class = ".*" },
    no_blur = true,
})

-- Nothing forces itself to maximize.
hl.window_rule({
    name = "frost-no-forced-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- A focused window is fully solid; only an unfocused one carries the faint
-- translucency that ties the material together. Applications whose own content
-- is the subject opt out entirely below.
hl.window_rule({
    name = "frost-default-opacity-tag",
    match = { class = ".*" },
    tag = "+default-opacity",
})

hl.window_rule({
    name = "frost-default-opacity",
    match = { tag = "default-opacity" },
    opacity = "1.0 0.96",
})

-- One definition of what counts as a terminal, so the universal clipboard
-- bindings below can send the chord a terminal actually understands.
hl.window_rule({
    name = "frost-terminal-tag",
    match = { class = "^(Alacritty|kitty|com\\.mitchellh\\.ghostty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm|org\\.frost\\..*)$" },
    tag = "+terminal",
})

hl.window_rule({
    name = "frost-opaque-content",
    match = { class = "^(chromium|firefox|zen|mpv|vlc|obs|steam|steam_app_.*|Pinta|imv|kdenlive)$" },
    tag = "-default-opacity",
    opacity = "1.0 1.0",
})

-- Behavioural window rules. Every one is data: a class or title match and named
-- properties, never a command.

-- One centred card for anything tagged as a floating window.
hl.window_rule({
    name = "frost-floating-window",
    match = { tag = "floating-window" },
    float = true,
    center = true,
    size = { 875, 600 },
})

-- The GTK portal only ever draws dialogs — file pickers, screen-share prompts,
-- permission requests — so all of them float, whatever the requesting app is.
hl.window_rule({
    name = "frost-portal-dialog",
    match = { class = "^xdg-desktop-portal-gtk$" },
    tag = "+floating-window",
})

-- Open/Save dialogs some apps draw themselves.
hl.window_rule({
    name = "frost-file-dialog",
    match = { title = "^(Open.*|Save.*|Save|All Files|.* wants to (open|save).*|Choose.*)" },
    tag = "+floating-window",
})

-- Small viewers and settings dialogs that belong floating.
hl.window_rule({
    name = "frost-floating-apps",
    match = { class = "^(org\\.gnome\\.Evince|org\\.gnome\\.NautilusPreviewer|imv|nm-connection-editor|blueman-manager|org\\.pulseaudio\\.pavucontrol|org\\.gnome\\.DiskUtility)$" },
    tag = "+floating-window",
})

-- Password managers float and are kept out of screen shares and captures.
hl.window_rule({
    name = "frost-password-manager",
    match = { class = "^(1Password|Bitwarden|KeePassXC|org\\.keepassxc\\.KeePassXC|Proton Pass|Passwords)$" },
    tag = "+floating-window",
    no_screen_share = true,
})

-- Picture-in-picture: a small pinned always-solid overlay.
hl.window_rule({
    name = "frost-pip-tag",
    match = { title = "[Pp]icture.?[Ii]n.?.?[Pp]icture" },
    tag = "+pip",
})
hl.window_rule({
    name = "frost-pip",
    match = { tag = "pip" },
    tag = "-default-opacity",
    float = true,
    pin = true,
    size = { 600, 338 },
    keep_aspect_ratio = true,
    border_size = 0,
    opacity = "1.0 1.0",
})

-- Fullscreen games and streams keep the screen awake.
hl.window_rule({
    name = "frost-fullscreen-idle-inhibit",
    match = { class = "^(com\\.moonlight_stream\\.Moonlight|steam_app_.*|com\\.libretro\\.RetroArch)$" },
    idle_inhibit = "fullscreen",
})
hl.window_rule({
    name = "frost-noidle-tag",
    match = { tag = "noidle" },
    idle_inhibit = "always",
})

-- Scroll the terminal at a comfortable rate on the touchpad.
hl.window_rule({
    name = "frost-terminal-scroll",
    match = { class = "^com\\.mitchellh\\.ghostty$" },
    scroll_touchpad = 0.2,
})

hl.layer_rule({
    name = "frost-selection-noanim",
    match = { namespace = "^selection$" },
    no_anim = true,
    animation = "none",
})

hl.layer_rule({
    name = "frost-island-blur",
    match = { namespace = "^frost-island$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.12,
    animation = "layers",
})

-- The event OSD is its own surface, so it needs the rule as much as the island
-- and the overlay do; without it the card was the only Frost glass on screen
-- with nothing behind it.
hl.layer_rule({
    name = "frost-osd-blur",
    match = { namespace = "^frost-osd$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.12,
    animation = "layers",
})

hl.layer_rule({
    name = "frost-surfaces-blur",
    match = { namespace = "^frost-surfaces$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.12,
    animation = "layers",
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")

local function theme_foreground()
    local runtime = os.getenv("XDG_RUNTIME_DIR")
    if not runtime then
        return nil
    end
    local handle = io.open(runtime .. "/frost/theme/theme.toml", "r")
    if not handle then
        return nil
    end
    local value = nil
    for line in handle:lines() do
        local hex = line:match('^%s*foreground%s*=%s*"(#%x%x%x%x%x%x)"%s*$')
        if hex then
            value = hex:sub(2)
            break
        end
    end
    handle:close()
    return value
end

-- The group colours track the active theme instead of freezing one palette
-- while the shell follows another.
local foreground = theme_foreground()
if foreground then
    hl.config({
        group = {
            groupbar = {
                text_color = "rgba(" .. foreground .. "ff)",
                text_color_inactive = "rgba(" .. foreground .. "9e)",
                col = {
                    active = "rgba(" .. foreground .. "1f)",
                    inactive = "rgba(" .. foreground .. "0a)",
                    locked_active = "rgba(" .. foreground .. "1f)",
                    locked_inactive = "rgba(" .. foreground .. "0a)",
                },
            },
        },
    })
end

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start --no-block frost-session.target")
end)

local main_mod = "SUPER"

-- Send the chord with explicit modifiers to the focused surface, with no window
-- target, so it reaches layer-shell surfaces as well as ordinary windows. A
-- virtual keyboard will not do: the SUPER the user is physically holding merges
-- into the injected chord at the seat. The down/up split works around Hyprland
-- leaving synthetic key state stuck.
local function send_chord(mods, key)
    return function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
        hl.timer(function()
            hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
        end, { timeout = 50, type = "oneshot" })
    end
end

local function active_window_is_terminal()
    local window = hl.get_active_window()
    if not window then
        return false
    end

    for _, tag in ipairs(window.tags or {}) do
        if tag:gsub("%*$", "") == "terminal" then
            return true
        end
    end

    return false
end

-- A terminal reads Ctrl+C as an interrupt, so it gets the Insert pair instead.
local function universal_clipboard(default_mods, default_key, terminal_mods, terminal_key)
    return function()
        if active_window_is_terminal() then
            send_chord(terminal_mods, terminal_key)()
        else
            send_chord(default_mods, default_key)()
        end
    end
end

-- Every action here is a native dispatcher or a fixed executable with data-only
-- arguments. No shell interpretation, no command assembled from configuration.
-- Shell state is reached through the single `frost` IPC target with `toggle`.

local FROST_IPC = "quickshell ipc --path /usr/share/frost/shell call frost "

local function ipc(rest)
    return hl.dsp.exec_cmd(FROST_IPC .. rest)
end

local function app(command)
    return hl.dsp.exec_cmd("uwsm-app -- " .. command)
end

local function term(command)
    return app("/usr/lib/frost/frost-terminal -e " .. command)
end

local function osd(action)
    return hl.dsp.exec_cmd("/usr/lib/frost/frost-osd " .. action)
end

local function capture(action)
    return hl.dsp.exec_cmd("/usr/lib/frost/frost-capture " .. action)
end

local function shell_action(action)
    return hl.dsp.exec_cmd("frost shell-action " .. action)
end

-- Universal clipboard: a terminal reads Ctrl+C as an interrupt, so it gets the
-- Insert pair instead.
hl.bind(main_mod .. " + C", universal_clipboard("CTRL", "C", "CTRL", "Insert"))
hl.bind(main_mod .. " + V", universal_clipboard("CTRL", "V", "SHIFT", "Insert"))
hl.bind(main_mod .. " + X", send_chord("CTRL", "X"))
hl.bind(main_mod .. " + CTRL + V", ipc("toggle clipboard"))

-- Shell surfaces.
hl.bind(main_mod .. " + SPACE", ipc("toggle launcher"))
hl.bind(main_mod .. " + ALT + SPACE", ipc("toggle launcher"))
hl.bind(main_mod .. " + CTRL + E", ipc("toggle emoji"))
hl.bind(main_mod .. " + CTRL + SPACE", ipc("toggle wallpaper"))
hl.bind(main_mod .. " + SHIFT + SPACE", ipc("toggle island"))

-- Applications. Targets are fixed binaries; the set matches the package
-- manifest, and a key whose app is not installed simply does nothing.
hl.bind(main_mod .. " + RETURN", app("/usr/lib/frost/frost-terminal"))
hl.bind(main_mod .. " + SHIFT + RETURN", app("brave"))
hl.bind(main_mod .. " + SHIFT + B", app("brave"))
hl.bind(main_mod .. " + SHIFT + ALT + B", app("brave --incognito"))
hl.bind(main_mod .. " + SHIFT + F", app("nautilus"))
hl.bind(main_mod .. " + SHIFT + N", app("code"))
hl.bind(main_mod .. " + SHIFT + M", app("spotify-launcher"))
hl.bind(main_mod .. " + SHIFT + ALT + M", term("cliamp"))
hl.bind(main_mod .. " + SHIFT + O", app("obsidian"))
hl.bind(main_mod .. " + SHIFT + D", term("lazydocker"))
hl.bind(main_mod .. " + CTRL + T", term("btop"))

-- Session.
hl.bind(main_mod .. " + CTRL + L", hl.dsp.exec_cmd("systemctl --user start frost-lock.service"))
hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))
hl.bind("CTRL + ALT + DELETE", shell_action("close-all-windows"))

-- Window management.
hl.bind(main_mod .. " + W", hl.dsp.window.close())
hl.bind(main_mod .. " + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(main_mod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(main_mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())
-- Super + L is left free: the donor's per-workspace master/dwindle swap is a
-- donor script and Frost only ships the dwindle layout. Lock moved to
-- Super + Ctrl + L (the donor's own lock key).
hl.bind(main_mod .. " + G", hl.dsp.group.toggle())
hl.bind(main_mod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }))

hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(main_mod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(main_mod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(main_mod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(main_mod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "d" }))

hl.bind(main_mod .. " + ALT + left", hl.dsp.window.move({ into_group = "l" }))
hl.bind(main_mod .. " + ALT + right", hl.dsp.window.move({ into_group = "r" }))
hl.bind(main_mod .. " + ALT + up", hl.dsp.window.move({ into_group = "u" }))
hl.bind(main_mod .. " + ALT + down", hl.dsp.window.move({ into_group = "d" }))

hl.bind(main_mod .. " + CTRL + left", hl.dsp.group.prev())
hl.bind(main_mod .. " + CTRL + right", hl.dsp.group.next())

-- Ten workspaces, on the number row (layout-independent keycodes).
for workspace = 1, 10 do
    local key = main_mod .. " + code:" .. tostring(workspace + 9)
    hl.bind(key, hl.dsp.focus({ workspace = tostring(workspace) }))
    hl.bind(main_mod .. " + SHIFT + code:" .. tostring(workspace + 9),
        hl.dsp.window.move({ workspace = tostring(workspace) }))
    hl.bind(main_mod .. " + SHIFT + ALT + code:" .. tostring(workspace + 9),
        hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

hl.bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(main_mod .. " + grave", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(main_mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
hl.bind(main_mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

hl.bind(main_mod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }))

hl.bind(main_mod .. " + SHIFT + ALT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(main_mod .. " + SHIFT + ALT + right", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(main_mod .. " + SHIFT + ALT + up", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(main_mod .. " + SHIFT + ALT + down", hl.dsp.workspace.move({ monitor = "d" }))

hl.bind("ALT + TAB", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))
hl.bind("ALT + TAB", hl.dsp.window.bring_to_top())
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.bring_to_top())

hl.bind("CTRL + ALT + TAB", hl.dsp.focus({ monitor = "+1" }))
hl.bind("CTRL + ALT + SHIFT + TAB", hl.dsp.focus({ monitor = "-1" }))

hl.bind(main_mod .. " + ALT + TAB", hl.dsp.group.next())
hl.bind(main_mod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev())
for index = 1, 5 do
    hl.bind(main_mod .. " + ALT + code:" .. tostring(index + 9), hl.dsp.group.active({ index = index }))
end

-- Resize the active window. code:20/21 are the two keys left of Backspace,
-- chosen by physical position so they work on any layout.
hl.bind(main_mod .. " + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(main_mod .. " + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind(main_mod .. " + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(main_mod .. " + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
hl.bind(main_mod .. " + ALT + code:20", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
hl.bind(main_mod .. " + ALT + code:21", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
hl.bind(main_mod .. " + CTRL + code:20", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
hl.bind(main_mod .. " + CTRL + code:21", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))

hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Cursor zoom (native config, no external call).
hl.bind(main_mod .. " + CTRL + Z", function()
    local zoom = hl.get_config("cursor.zoom_factor") or 1
    hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
hl.bind(main_mod .. " + CTRL + ALT + Z", function()
    hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Island panels by keyboard.
hl.bind(main_mod .. " + CTRL + A", ipc("toggle audio"))
hl.bind(main_mod .. " + CTRL + B", ipc("toggle bluetooth"))
hl.bind(main_mod .. " + CTRL + W", ipc("toggle wifi"))
hl.bind(main_mod .. " + CTRL + P", ipc("toggle battery"))

-- Notifications.
hl.bind(main_mod .. " + comma", shell_action("notification-dismiss-latest"))
hl.bind(main_mod .. " + ALT + comma", shell_action("notification-invoke-latest"))
hl.bind(main_mod .. " + SHIFT + comma", shell_action("notification-clear"))
hl.bind(main_mod .. " + SHIFT + ALT + comma", ipc("toggle notifications"))
hl.bind(main_mod .. " + CTRL + comma", shell_action("notification-dnd toggle"))

-- Session toggles.
hl.bind(main_mod .. " + CTRL + I", shell_action("stay-awake-toggle"))
hl.bind(main_mod .. " + CTRL + N", shell_action("nightlight-toggle"))

-- Capture.
hl.bind("PRINT", capture("screen"))
hl.bind("ALT + PRINT", capture("record"))
hl.bind(main_mod .. " + CTRL + C", capture("region"))
hl.bind(main_mod .. " + CTRL + PRINT", capture("text"))
hl.bind(main_mod .. " + PRINT", hl.dsp.exec_cmd("hyprpicker -a"))

-- Media, brightness, audio.
hl.bind("XF86AudioRaiseVolume", osd("volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", osd("volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", osd("volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", osd("mic-mute"), { locked = true })
hl.bind("ALT + XF86AudioRaiseVolume", osd("volume-up-fine"), { locked = true, repeating = true })
hl.bind("ALT + XF86AudioLowerVolume", osd("volume-down-fine"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", osd("brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", osd("brightness-down"), { locked = true, repeating = true })
hl.bind("ALT + XF86MonBrightnessUp", osd("brightness-up-fine"), { locked = true, repeating = true })
hl.bind("ALT + XF86MonBrightnessDown", osd("brightness-down-fine"), { locked = true, repeating = true })
hl.bind("SHIFT + XF86MonBrightnessUp", osd("brightness-max"), { locked = true })
hl.bind("SHIFT + XF86MonBrightnessDown", osd("brightness-min"), { locked = true })
hl.bind("XF86KbdBrightnessUp", osd("kbd-up"), { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessDown", osd("kbd-down"), { locked = true, repeating = true })
hl.bind("XF86KbdLightOnOff", osd("kbd-toggle"), { locked = true })

hl.bind("XF86AudioNext", ipc("media next"), { locked = true })
hl.bind("XF86AudioPrev", ipc("media previous"), { locked = true })
hl.bind("XF86AudioPlay", ipc("media playPause"), { locked = true })
hl.bind("XF86AudioPause", ipc("media playPause"), { locked = true })
hl.bind("ALT + XF86AudioPlay", ipc("media next"), { locked = true })
hl.bind("ALT + SHIFT + XF86AudioPlay", ipc("media previous"), { locked = true })
