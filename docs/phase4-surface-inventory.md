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
| images | frost shell-data images over ~/Pictures and ~/Imagens, copied with shell-action image-copy | the card stays hidden while nothing resolves |
| wallpaper | frost shell-data wallpapers over the package background root, applied with shell-action wallpaper-set; the selection is a validated JSON pointer in ~/.local/state/frost/background.json | the background layer is absent until a wallpaper is selected, so nothing paints over whatever else owns the desktop; the carousel is empty while no packaged wallpaper is installed |
| themes | frost shell-data themes enumerating every validated palette below the theme roots, applied with shell-action theme-set | the appearance route lists nothing when no palette validates; the shell keeps the last materialised palette |
| tray menu | the item's own DBus menu, opened through QsMenuOpener inside the island window | items without a menu are activated instead; a Hyprland focus grab held only while the menu is open dismisses it on click-away |
| session confirmation | presentation only, inside the launcher card; poweroff, reboot and logout require it, lock does not | cancelling is the default path; no process is started by the card itself |
| event OSD | messages emitted by the shell for logout, reboot, shutdown and microphone mute | the window carries an empty input region and no keyboard focus, so a stuck OSD can never capture the pointer; session actions are scheduled with a two-second delay so the message is drawn before the action lands |
| lock and Polkit | Hyprlock/PAM and hyprpolkitagent | no shell fallback or duplicated authority |

## Runtime dependency inventory

Every executable the shell can reach is fixed and absolute, and `frost doctor`
checks each one by name, so the inventory is the program rather than this table.

| Executable | Owning package | Reached by |
|---|---|---|
| Hyprland, start-hyprland | hyprland | session wrapper |
| uwsm | uwsm | session lifecycle and application launch |
| quickshell | quickshell | the shell itself |
| mako, makoctl | mako | notification authority and its typed viewer |
| hyprlock | hyprlock | lock authority |
| hypridle | hypridle | idle authority |
| hyprpolkitagent | hyprpolkitagent | Polkit authority |
| ghostty | ghostty | terminal launch |
| wpctl | wireplumber | audio device fallbacks |
| brightnessctl | brightnessctl | backlight |
| nmcli | networkmanager | Wi-Fi data and actions |
| powerprofilesctl | power-profiles-daemon | power profile |
| upower | upower | battery data |
| rfkill | util-linux | radio state |
| cliphist, wl-copy, wl-paste | cliphist, wl-clipboard | clipboard history and copy |
| curl, jq | curl, jq | weather |
| notify-send | libnotify | user-visible failures |
| busctl, systemctl, systemd-run, systemd-inhibit | systemd | services, scheduled session actions, idle inhibition |
| awk | gawk | wrapper scripts |
| sleep | coreutils | wrapper scripts |

Bluetooth, MPRIS, PipeWire, the system tray, UPower's live properties and
Hyprland workspaces are native Quickshell integrations and cross no process
boundary at all.

qs.Core.ShellBackend is the only QML component allowed to instantiate processes. It owns two serialized processes, a bounded action queue and one stdin channel reserved for a validated Wi-Fi password. Installed execution remains fixed to /usr/bin/frost; worktree path overrides are accepted only while FROST_PREVIEW=1.
