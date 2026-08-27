# Phase 4 visual parity contract

This contract freezes the first-party Frost shell against the visual and functional authority in `staging` commit `824831e75171dc4c87c8d53dfd22e3e07de7f6a6`. The donor tree remains read-only. Every implementation is a static Frost rewrite recorded in `docs/provenance/ports.json`; no plugin registry, manifest, command guard, environment authority or runtime path is imported.

## Fixed visual language

`shell/Core/Style.qml` owns geometry, typography and density. `shell/Core/Theme.qml` owns fixed Frosted Glass material roles and consumes only the selected semantic palette. Themes may provide exactly `background`, `foreground`, `muted`, `accent`, `urgent`, `highlight`, `success` and `warning` under schema version 1. They cannot change alpha, blur, radius, spacing, fonts, motion or layout.

The frozen baseline is a 30 px bar, 14 px principal radius, 8 px row radius, 6 px control radius, 448 px menu, 420 px panels, 400 x 500 emoji picker, 720 x 450 image picker and 875 x 600 clipboard. The text face is JetBrains Mono; UI glyphs use the package-owned Nerd Font symbol face and emoji use Noto Color Emoji. Gruvbox is the default palette.

## Surface mapping

| Staging concept | Static Frost owner | Contract |
|---|---|---|
| custom bar and layout | `shell/Bar` | left menu/workspaces/media, centered reminder/stay-awake, clock, notifications and conditional weather, right tray plus conditional and system modules |
| menu | `Surfaces/Launcher.qml` | 448 px routed keyboard menu with applications, tools, style, setup, installer, about and session actions |
| command center | `Surfaces/ControlCenter.qml` | 420 px connectivity group, audio, display, media and power modules |
| clipboard | `Surfaces/ClipboardPanel.qml` | 875 x 600 history/preview split view |
| emoji picker | `Surfaces/EmojiPanel.qml` | 400 x 500 searchable 44 px grid and direct clipboard copy |
| image picker | `Surfaces/ImagePickerPanel.qml` | 720 x 450 preview carousel and typed image copy |
| calendar | `Surfaces/CalendarPanel.qml` | clock-attached 420 px month view |
| notification center | `Surfaces/NotificationPanel.qml` | 420 x 620 typed projection of Mako active/history state |
| OSD | `shell/Osd/Osd.qml` | focused-monitor Frost overlay driven by bounded IPC payloads |
| notification popups | Mako with generated Frost config | Mako remains the sole notification server |
| lock | Hyprlock with generated Frost config | Hyprlock and PAM remain the sole lock/authentication authority |
| Tailscale and agents | static conditional modules | absent by default and shown only by explicit Frost feature selection |

Weather remains absent until a city is explicitly configured with `frost weather set CITY`; Frost never infers location from an IP address. Its fixed Rust boundary uses the official Open-Meteo geocoding and forecast endpoints with response caps, a short timeout and a 15-minute normalized cache. System-update UI remains absent until the Phase 7 update authority exists. The installer is a real typed selection and review frontend, while package application remains deliberately disabled until the Phase 6 backend gate.

## Action boundary

QML never constructs a shell command. `Core/ShellBackend.qml` owns exactly two serialized processes and can call only `frost shell-data` or `frost shell-action`. Workspace activation uses the Hyprland Lua dispatcher. Theme changes, clipboard/image copy, Mako operations, brightness and session actions are validated again in the Rust CLI. Restart and poweroff require an explicit confirmation card.

Mako and Hyprlock consume materialized runtime configs. If theme materialization is unavailable, their Frost launchers fall back to immutable package configs so visual state cannot disable either authority.
