# Phase 6 — external-call and capability audit

Every external binary the Frost runtime invokes, where it comes from, and how it
is guaranteed present. The rule from the master plan: the inventory of runtime
dependencies is the program itself — `frost doctor` checks each fixed executable
by name — not a document that drifts. This table is the once-per-phase snapshot.

## Hard dependencies — called unconditionally

| Command | Called by | Package | `frost` dep | `frost doctor` |
|---|---|---|---|---|
| Hyprland, hyprctl | session, `frost-capture`, `close-all-windows` | hyprland | ✓ | ✓ |
| uwsm, uwsm-app | keybinds, session | uwsm | ✓ | ✓ |
| quickshell | `frost-osd`, `frost-capture`, IPC | quickshell | ✓ | ✓ |
| ghostty | terminal keybind | ghostty | ✓ | ✓ |
| mako, makoctl | notifications, CLI verbs | mako | ✓ | ✓ |
| hyprlock | lock service | hyprlock | ✓ | ✓ |
| hypridle | idle service | hypridle | ✓ | ✓ |
| hyprpolkitagent | polkit service | hyprpolkitagent | ✓ | ✓ |
| hyprpicker | `Super+Print` colour picker | hyprpicker | ✓ | ✓ |
| hyprsunset | `frost-nightlight.service` | hyprsunset | ✓ | ✓ |
| grim, slurp | `frost-capture` | grim, slurp | ✓ | ✓ |
| wpctl | `frost-osd` | wireplumber | ✓ | ✓ |
| brightnessctl | `frost-osd` | brightnessctl | ✓ | ✓ |
| wl-copy, wl-paste | shell, `frost-capture` | wl-clipboard | ✓ | ✓ |
| cliphist | clipboard history | cliphist | ✓ | ✓ |
| notify-send | `frost-capture` | libnotify | ✓ | ✓ |
| curl | weather | curl | ✓ | ✓ |
| jq | CLI, `frost-capture` | jq | ✓ | ✓ |
| awk | CLI parsing | gawk | ✓ | ✓ |
| nmcli | network | networkmanager | ✓ | ✓ |
| powerprofilesctl | power profiles | power-profiles-daemon | ✓ | ✓ |
| rfkill | bluetooth radio | util-linux | ✓ | ✓ |
| upower | battery | upower | ✓ | ✓ |
| busctl, systemctl, systemd-inhibit, systemd-run | session, CLI | systemd | ✓ | ✓ |
| start-hyprland | session wrapper | uwsm | ✓ | ✓ |

## Optional — guarded, degrade cleanly when absent

| Command | Called by | Package | Behaviour when missing |
|---|---|---|---|
| tesseract | `frost-capture text` | tesseract | prints "OCR unavailable" |
| gpu-screen-recorder | `frost-capture record` | gpu-screen-recorder | prints "recording unavailable" |
| git | `frost packages plan --lockfile` only | git | the `--lockfile` flag is a no-op for that entry |

`tesseract` and `gpu-screen-recorder` are `DESKTOP` optional in the inventory and
are selected in the `this-machine` manifest; they are not `frost` package
dependencies because `frost-capture` checks `-x` before calling them.

## frost-settings helpers

`frost-firstboot` calls `snapper` and `ufw`, both `frost-settings` dependencies,
each guarded (`command -v`, `findmnt` for a Btrfs root) so the script no-ops on a
base that lacks them. `bootstrap-cachyos` calls only `pacman`, `pacman-key`,
`systemctl` and `mkinitcpio` — enforced by `frost-pkgs/test/install-contract`.

## Result

No unlisted external call, no privileged call outside the two narrow helpers the
sudoers file names, and `frost verify` reports every fixed executable and path
`ok` in the live session on `0.2.0-34`.
