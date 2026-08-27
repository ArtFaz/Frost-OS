# Phase 4 surface inventory

This inventory is updated with every static surface port. It records state, actions, authority and runtime package impact before a surface can enter a graphical gate.

## Material, focus and motion

| Component | State read | Actions emitted | Single authority | Runtime package impact | Failure behavior |
|---|---|---|---|---|---|
| `Theme` | Package-owned `theme.toml` colors and glass opacity | None | `qs.Core.Theme` | None beyond the existing QuickShell runtime | Invalid or absent values retain compiled Frost defaults |
| `GlassSurface` | Semantic role and tokens from `Theme` | None | `Theme`; Hyprland remains the sole blur compositor | None | Unknown roles use the bounded generic glass opacity |
| `FocusRing` | Local `activeFocus` from its owning control | None | Qt focus chain | None | Hidden when the control has no focus |
| `InteractiveSurface` | Local hover, press, selection, enablement and keyboard focus | Typed `activated` signal only | The consuming static component owns the action | None | Disabled controls cannot activate and render muted |
| `Motion` | Compiled reduced-motion boundary and bounded durations | None | `qs.Core.Motion` | None | Reduced motion resolves all durations to zero |

The primitives are shared by the bar, workspace controls, OSD and every Phase 4 panel. Workspace activation still uses the direct typed Hyprland dispatcher. The shell never interprets commands from configuration and does not acquire notification, lock, PAM or Polkit authority.

The compositor blur contract is package-owned in `default/hypr/hyprland.lua`: size 5, two passes and an alpha threshold of 0.12 for the exact `frost-bar`, `frost-osd` and `frost-surfaces` namespaces. The equivalent data tokens are recorded in the Frost theme for consistency; QML does not execute or generate compositor configuration.

## Complete static composition

| Surface | State read | Actions | Authority/interface | Runtime packages | Failure behavior |
|---|---|---|---|---|---|
| Launcher/menu/workspaces | `DesktopEntries`, Hyprland workspaces | Desktop entry `execute`; typed workspace dispatch | QuickShell desktop-entry model; Hyprland | `quickshell`, `hyprland` | Empty application model renders an empty state |
| Media and tray | MPRIS players; StatusNotifier items | Play/pause/previous/next; tray activation/menu | QuickShell MPRIS and SystemTray | `quickshell` | Media hides without a player; passive tray items hide |
| Audio | PipeWire default nodes, volume and mute | Set default node, volume and mute | QuickShell PipeWire | `quickshell`, `wireplumber` | Controls disable when PipeWire is not ready |
| Network | NetworkManager devices and Wi-Fi networks | Toggle Wi-Fi, scan, connect/disconnect, PSK connect | QuickShell Networking | `quickshell`, `networkmanager` | Panel reports unavailable; unsupported enterprise secrets are not guessed |
| Bluetooth | BlueZ adapters and devices | Toggle/discover/pair/connect/disconnect | QuickShell Bluetooth | `quickshell`, `bluez` | Panel reports unavailable and emits no action without an adapter |
| Display and power | QuickShell screens, UPower, power-profiles; typed brightness query | Brightness, profile, lock/suspend/logout/reboot/poweroff | QuickShell UPower plus `frost shell-data/action` | `upower`, `power-profiles-daemon`, `brightnessctl`, `systemd`, `uwsm` | Brightness disables without a device; destructive session actions require confirmation |
| Control center | Aggregated read-only properties from the services above | Opens only statically registered panels; direct toggles | `qs.Core.SystemState` | No additional package | Missing modules render unavailable rather than loading fallbacks |
| Clipboard | Bounded text-only `cliphist list` view | Copy a numeric history id through the typed CLI | `frost shell-data/action` | `cliphist`, `wl-clipboard` | Binary rows are excluded; invalid ids are rejected twice |
| Emoji picker | Package-owned schema-versioned catalog | Assign selected Unicode text to QuickShell clipboard | QuickShell clipboard | No additional package | Invalid catalog yields an empty model |
| Image picker | Canonicalized image inventory below Pictures | Copy an allowlisted regular image through the typed CLI | `frost shell-data/action` | `wl-clipboard` | Symlinks, path escapes, unsupported formats and files over 32 MiB are rejected |
| App installer frontend | Package-owned typed application inventory | Selection and in-memory plan generation only | Static QML/JavaScript model | No additional package | Apply remains disabled; no pacman, makepkg, AUR helper or privileged helper is callable |
| Notification center | `makoctl list/history -j` normalized as inert text | Invoke numeric notification id; dismiss all | Mako remains notification owner; typed Frost CLI is only a client | `mako` | Invalid/unavailable JSON yields an empty history; no NotificationServer is created |
| Tailscale and agents | Feature flags only in this phase | None | Gate 5 feature selection | None by default | Hidden by default; explicit enablement shows a disabled informational surface |

## Typed shell backend

`qs.Core.ShellBackend` is the only QML file allowed to instantiate a process. It owns exactly two serialized processes and can invoke only `/usr/bin/frost shell-data KIND` or `/usr/bin/frost shell-action ACTION [VALUE]`. Both QML and Rust maintain independent allowlists. Numeric ids, percentages and canonical image paths are validated before any fixed executable is called; neither layer invokes a shell or accepts executable names, environment, working directories or stdin from configuration.
