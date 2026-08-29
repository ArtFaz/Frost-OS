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
            natural_scroll = true,
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
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false })

hl.window_rule({
    name = "frost-apps-no-blur",
    match = { class = ".*" },
    no_blur = true,
})

hl.layer_rule({
    name = "frost-island-blur",
    match = { namespace = "^frost-island$" },
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

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start --no-block frost-session.target")
end)

local main_mod = "SUPER"

hl.bind(main_mod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc --path /usr/share/frost/shell call frost toggle launcher"))
hl.bind(main_mod .. " + V", hl.dsp.exec_cmd("quickshell ipc --path /usr/share/frost/shell call frost toggle clipboard"))
hl.bind(main_mod .. " + PERIOD", hl.dsp.exec_cmd("quickshell ipc --path /usr/share/frost/shell call frost toggle emoji"))
hl.bind(main_mod .. " + RETURN", hl.dsp.exec_cmd("uwsm-app -- /usr/lib/frost/frost-terminal"))
hl.bind(main_mod .. " + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + L", hl.dsp.exec_cmd("systemctl --user start frost-lock.service"))
hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(main_mod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))

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
