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
        border_size = 2,
        col = {
            active_border = "rgba(9ed8ffff)",
            inactive_border = "rgba(334155aa)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 12,
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
            new_optimizations = true,
        },
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = "rgba(08111ccc)",
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

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 4,
    bezier = "default",
})

hl.layer_rule({
    name = "frost-bar-blur",
    match = { namespace = "^frost-bar$" },
    blur = true,
    ignore_alpha = 0.08,
})

hl.layer_rule({
    name = "frost-osd-blur",
    match = { namespace = "^frost-osd$" },
    blur = true,
    ignore_alpha = 0.08,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start --no-block frost-session.target")
end)

local main_mod = "SUPER"

hl.bind(main_mod .. " + RETURN", hl.dsp.exec_cmd("uwsm-app -- /usr/lib/frost/frost-terminal"))
hl.bind(main_mod .. " + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + L", hl.dsp.exec_cmd("systemctl --user start frost-lock.service"))
hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

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
