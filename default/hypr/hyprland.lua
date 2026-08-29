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
        kb_layout = "br",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
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
        disable_splash_rendering = true,
        -- The configuration is package-owned and only ever changes through a
        -- pacman transaction, which replaces the file rather than editing it.
        -- With the watcher on, Hyprland reloads during the instant the old file
        -- is gone and the new one is not yet in place, and reports a missing
        -- config every single upgrade. Reloading after an upgrade is an explicit
        -- hyprctl reload instead.
        disable_autoreload = true,
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

hl.window_rule({
    name = "frost-apps-no-blur",
    match = { class = ".*" },
    no_blur = true,
})

-- Windows are very slightly translucent so the material reads as one surface.
-- Applications whose own content is the subject opt out below.
hl.window_rule({
    name = "frost-default-opacity-tag",
    match = { class = ".*" },
    tag = "+default-opacity",
})

hl.window_rule({
    name = "frost-default-opacity",
    match = { tag = "default-opacity" },
    opacity = "0.985 0.96",
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

hl.bind(main_mod .. " + C", universal_clipboard("CTRL", "C", "CTRL", "Insert"))
hl.bind(main_mod .. " + V", universal_clipboard("CTRL", "V", "SHIFT", "Insert"))
hl.bind(main_mod .. " + X", send_chord("CTRL", "X"))

hl.bind(main_mod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc --path /usr/share/frost/shell call frost toggle launcher"))
hl.bind(main_mod .. " + CTRL + V", hl.dsp.exec_cmd("quickshell ipc --path /usr/share/frost/shell call frost toggle clipboard"))
hl.bind(main_mod .. " + CTRL + E", hl.dsp.exec_cmd("quickshell ipc --path /usr/share/frost/shell call frost toggle emoji"))
hl.bind(main_mod .. " + RETURN", hl.dsp.exec_cmd("uwsm-app -- /usr/lib/frost/frost-terminal"))
hl.bind(main_mod .. " + W", hl.dsp.window.close())
hl.bind(main_mod .. " + L", hl.dsp.exec_cmd("systemctl --user start frost-lock.service"))
hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(main_mod .. " + T", hl.dsp.window.float({ action = "toggle" }))

hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 5 do
    hl.bind(main_mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind(main_mod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("/usr/lib/frost/frost-osd volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("/usr/lib/frost/frost-osd volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("/usr/lib/frost/frost-osd volume-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("/usr/lib/frost/frost-osd brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("/usr/lib/frost/frost-osd brightness-down"), { locked = true, repeating = true })
