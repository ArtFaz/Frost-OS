# Phase 5.2 — input, layout and window rules

How the keyboard, the pointer and the windows behave by default. Not keybinds
(that was 5.1). All of it is data in the package-owned `default/hypr/hyprland.lua`
— a class or title match and named properties, never a command. It does not
touch the inventory, `frost-meta` or Gate 5.

## Decisions taken

| # | Decision |
|---|---|
| 1 | **Keyboard layout stays `br`, fixed.** Frost is single-user on ABNT2; the donor's read-from-`/etc/vconsole.conf` with a `us,` prefix for non-Latin layouts is not ported. Recorded, not a defect. |
| 2 | **`kb_options` empty.** Compose is not used, so CapsLock stays CapsLock and the `shift:both_capslock_cancel` remap (which only existed to free the key for Compose) is dropped. |
| 3 | Focused window opacity → **`1.0`** (fully solid). Unfocused stays `0.96`. The always-opaque app list (mpv, obs, …) is unchanged. |
| 4 | Three-finger horizontal touchpad swipe = **switch workspace** (the donor ships this commented out; here it is on). |

## Input block — ported

`repeat_rate = 40`, `repeat_delay = 250`, `numlock_by_default = true`,
`sensitivity = 0`; touchpad `clickfinger_behavior = true` (two-finger tap is
right-click) and `scroll_factor = 0.4`; `misc.key_press_enables_dpms` and
`mouse_move_enables_dpms` (screen wakes on input); a per-window
`scroll_touchpad = 0.2` for `com.mitchellh.ghostty`.

## Compositor behaviour — ported

`dwindle.preserve_split`, `dwindle.force_split = 2`, `misc.focus_on_activate`,
`misc.disable_scale_notification`, `cursor.hide_on_key_press`,
`cursor.warp_on_change_workspace`, `binds.hide_special_on_workspace_change`.

## Window rules

**Ported**

- `suppress_event = maximize` on every window.
- **Dialogs float.** `xdg-desktop-portal-gtk` (every file picker / screen-share
  prompt / permission dialog), self-drawn Open/Save dialogs by title, and a set
  of small viewers/settings windows (`Evince`, `NautilusPreviewer`, `imv`,
  `nm-connection-editor`, `blueman-manager`, `pavucontrol`, `gnome-disk-utility`)
  all get the `floating-window` tag → float, centre, 875×600.
- **Password managers** (`1Password`, `Bitwarden`, `KeePassXC`, `Proton Pass`)
  float and carry `no_screen_share = true` — excluded from captures and shares.
  The classes are matched whether or not the app is installed.
- **Picture-in-picture**: `title ~ Picture-in-Picture` → pinned floating overlay,
  600×338, aspect kept, no border, always solid.
- **Fullscreen idle inhibit** for `Moonlight`, `steam_app_*`, `RetroArch`; a
  `noidle` tag → `idle_inhibit = always`.
- `selection` layer (slurp's region picker) → no animation, matching the
  screenshot flow from 5.1.

**Not ported** (by decision)

- Per-app opacity opt-outs for zoom / telegram / qemu — Frost's existing
  opaque-content list already covers the ones that matter.
- Separate chromium/firefox browser tagging with different opacity, and the
  "X is sharing your screen" window sent to a silent workspace.
- Per-app focus-stealing rules (`focus_on_activate = false` for Telegram,
  `no_follow_mouse` for JetBrains).
- Every donor-app-specific rule: Battle.net, DaVinci Resolve, the omarchy-shell
  dev gallery, the webcam overlay, `dev.tensaku.Tensaku`, `omacalc`, the
  omarchy screensaver.

## Gate 5.2

- [x] every reference input/rule entry classified; each not-ported item has a reason (this file);
- [x] no window rule executes a command or depends on a donor path (`session-contract` enforces the no-shell-interpretation rule over `hyprland.lua`);
- [x] `Hyprland --verify-config` accepts the full config (Hyprland 0.56.2);
- [x] `session-contract` covers the session assets;
- [ ] the ABNT2 layout item is a recorded decision, not a live test — the non-Latin-layout criterion does not apply to this machine.
