# Frost Island runtime inventory

This inventory describes the single active shell composition after the DynamicGlacier migration.

| Component | Authority | Failure behavior |
|---|---|---|
| DynamicGlacier / IslandSurface | one Quickshell PanelWindow, namespace frost-island, following the focused monitor | collapses to its idle handle; no fallback shell is loaded |
| FrostGlassSurface | Frost theme plus Hyprland blur | retains the opaque Frost fallback color when compositor blur is unavailable |
| media | Quickshell MPRIS | the media face is offered only while a player is active; the island falls back to the idle face |
| audio | Quickshell PipeWire, read and written natively | sliders, mute, output selection and the per-application mixer disable when no sink or source exists |
| brightness | sysfs poll on the device path resolved once through frost shell-data | machines without a backlight leave the path empty, which disables the poll |
| background applications | Quickshell SystemTray, rendered as a bare icon rail outside the glass | absent or passive items remain hidden; the rail collapses to nothing |
| workspaces | Quickshell Hyprland, rendered as a bare dot rail outside the glass | falls back to the baseline set when no monitor can be resolved |
| Bluetooth | Quickshell Bluetooth/BlueZ, pairing and forgetting as distinct operations | reports unavailable or rfkill-blocked state; a device needing a passkey cannot complete pairing because no BlueZ agent is registered — see docs/security-boundaries.md |
| battery | Quickshell UPower plus typed threshold/profile queries | metrics and controls disable independently when unsupported |
| Wi-Fi | frost shell-data/action using fixed NetworkManager clients, including which SSIDs already hold a saved profile | unavailable state; a secured network without a profile asks for its password before attempting; enterprise authentication and hidden SSIDs are not guessed |
| privacy | Quickshell PipeWire for microphone use plus a typed bounded camera projection | indicators remain absent when state cannot be established |
| idle inhibitor | frost shell-data indicators and shell-action stay-awake-toggle | the chip reports the last known state and refuses overlapping toggles |
| notifications | Mako outside Quickshell, read and acted on through makoctl behind the typed CLI | the island never registers a notification server; when makoctl is unavailable the viewer shows an empty list and reports the failure |
| launcher | one shared overlay window, namespace frost-surfaces; desktop entries executed through the Quickshell API and typed frost shell-actions | an empty list when no entries resolve; no command discovery and no shell string is ever built |
| clipboard | frost shell-data clipboard and shell-action clipboard-copy over cliphist | empty list when cliphist is unavailable |
| emoji | package-owned catalog at config/data/emojis.json | empty grid when the catalog cannot be read |
| images | frost shell-data images over ~/Pictures and ~/Imagens, copied with shell-action image-copy | the card stays hidden while nothing resolves; Frost has no wallpaper stack, so this browses and copies rather than setting a background |
| lock and Polkit | Hyprlock/PAM and hyprpolkitagent | no shell fallback or duplicated authority |

qs.Core.ShellBackend is the only QML component allowed to instantiate processes. It owns two serialized processes, a bounded action queue and one stdin channel reserved for a validated Wi-Fi password. Installed execution remains fixed to /usr/bin/frost; worktree path overrides are accepted only while FROST_PREVIEW=1.
