# Phase 5.1 — core keybinds

Frost carried 33 binds; the donor Omarchy config carries ~182 after its loops
expand. This phase ports the daily vocabulary. Every bind is a native
dispatcher or a fixed executable with data-only arguments — no shell
interpretation, no command assembled from configuration. Shell state is reached
through the single `frost` IPC target with `toggle`. It does not touch the
inventory, `frost-meta` or Gate 5.

All binds live in the package-owned `default/hypr/hyprland.lua`.

## Decisions taken

| # | Decision |
|---|---|
| 1 | `Super + L` collision. The donor's action is a per-workspace master/dwindle swap (a donor script); Frost ships only dwindle. `Super + L` is **left free**; **lock moved to `Super + Ctrl + L`** (the donor's own lock key). |
| 2 | `Super + Shift + N` opens `code` (`visual-studio-code-bin`). |
| 3 | All browser binds are fixed to `brave` (`--incognito` for the private one). |
| 4 | ADAPTAR scope: A + B + C + D + E + F all in, minus create-reminder, minus show/clear-reminder (no keyboard way to set one), minus the calendar and display panels (they do not exist in the Frost island). |
| 5 | Web-app binds (`Super+Shift+A/C/E/Y/P/S/X`, …) dropped entirely. |

## Ported (PORTAR) — native dispatchers, no new code

Close (`Super+W`, `Super+Q`), maximize (`Super+Alt+F`), fullscreen, float toggle,
`togglesplit` (`Super+J`), pseudo (`Super+P`), group toggle / move-out
(`Super+G`, `Super+Alt+G`). Directional focus (arrows), swap (`Super+Shift+`
arrows), move-into-group (`Super+Alt+`arrows), grouped focus (`Super+Ctrl+`
Left/Right). Ten workspaces on the number row (`code:10..19`): switch, move,
silent move. Scratchpad (`Super+S`, `Super+grave`, `Super+Alt+S`,
`Super+Shift+grave`). Workspace cycle (`Super+Tab`, `+Shift`, `+Ctrl` former).
Move workspace to monitor (`Super+Shift+Alt+`arrows). `Alt+Tab` / `Alt+Shift+Tab`
cycle + raise. Focus monitor (`Ctrl+Alt+Tab` / `+Shift`). In-group cycle
(`Super+Alt+Tab` / `+Shift`) and focus group window N (`Super+Alt+1..5`).
Resize in four step sizes (`Super+code:20/21` with `Shift`/`Alt`/`Ctrl`).
Scroll workspaces (`Super+mouse_up/down`), drag/resize with mouse. Cursor zoom
(`Super+Ctrl+Z`, `+Alt+Z`) — native config, no external call. Terminal, brave,
nautilus, code, spotify-launcher, obsidian, cliamp/lazydocker/btop in a
terminal. Universal clipboard, launcher, emoji, clipboard manager, wallpaper
switcher (`Super+Ctrl+Space`), island toggle (`Super+Shift+Space`), lock,
logout (`Super+Shift+E`), colour picker (`Super+Print` → `hyprpicker -a`).

## Adapted (ADAPTAR) — a small bounded Frost hook each

| Cluster | Binds | Hook |
|---|---|---|
| A `frost-osd` extensions | mic-mute, brightness min/max, ±1 fine steps, keyboard backlight | new actions in `bin/frost-osd` |
| B media transport | `XF86Audio Next/Prev/Play/Pause` (+`Alt` variants) | new `media` function on the shell's `frost` IPC handler → MPRIS |
| C capture | `Print` (screen), `Super+Ctrl+C` (region), `Super+Ctrl+Print` (OCR→clipboard), `Alt+Print` (record toggle) | new `bin/frost-capture` helper (grim/slurp/tesseract/gpu-screen-recorder) |
| D island panels | `Super+Ctrl+A/B/W/P` → audio/bluetooth/wifi/battery | none — the `frost` IPC `toggle` already accepts these modes |
| E notifications | `Super+comma` dismiss latest, `Super+Alt+comma` invoke latest, `Super+Shift+comma` clear, `Super+Shift+Alt+comma` history panel, `Super+Ctrl+comma` DND toggle | new `frost shell-action` verbs (`notification-dismiss-latest`, `notification-invoke-latest`, `notification-dnd toggle`) wrapping `makoctl`; history reuses the IPC panel toggle |
| F one-offs | `Super+Ctrl+N` nightlight, `Ctrl+Alt+Delete` close-all-windows, `Super+Ctrl+I` stay-awake | `frost-nightlight.service` + `frost shell-action nightlight-toggle`; `frost shell-action close-all-windows` (reads `hyprctl -j clients`, closes each) |

New package dependencies: `grim`, `slurp`, `hyprsunset`.

## Discarded (DESCARTAR) — logged reasons

- **All `omarchy-menu` variants** (`Super+Ctrl+O/H`, `Super+Escape`, `XF86PowerOff`, `Super+Shift+code:201`, background/theme menus except the wallpaper switcher): Frost has no radial menu system.
- **All web-app binds**: donor `webapp` launcher (chromium `--app`); dropped by decision 5.
- **Runtime config-mutation scripts** (`Super+Backspace` transparency/gaps/aspect, `Super+/` monitor scaling, `Super+Ctrl+F` tiled-fullscreen, `Super+Alt+Home`/`Home` window-width save/restore, `Super+Ctrl+Delete` laptop-display toggle/mirror): they rewrite the compositor config at runtime, which the package-owned config forbids.
- **Donor apps/tools** (`Super+Alt+Return` tmux — excluded in the manifest; `Super+Ctrl+Return` herdr, `Super+Shift+W` omawrite, `Super+Ctrl+Q` omacalc — `DROP`; `Super+Shift+G` signal, `Super+Shift+/` 1Password — not in the manifest; `Super+Ctrl+S` share, `Super+Ctrl+Period` transcode, `Super+Shift+Ctrl+A` agent, voxtype dictation): no Frost equivalent.
- **`Super+Alt+Shift+F`** file-manager-at-terminal-cwd: cwd comes from a donor script; plain nautilus is on `Super+Shift+F`.
- **`Super+K` / `+Alt+K` / `+Ctrl+K`** keybinding cheatsheets: a `frost keys` cheatsheet is a possible later add.
- **`Super+Ctrl+1..9`** bar-panel focus, **`Super+Ctrl+Alt+T/B/W`** time/battery/weather notifications, **audio-device switch** keys, **webcam overlay resize**, **`XF86Eject`**: donor shell/notification plumbing without a Frost target.
- **Reminders** (`Super+Ctrl+R/Alt+R/Shift+Ctrl+R`): no keyboard way to set one, so viewing and clearing by key were dropped too. `frost shell-action reminder-set/clear` remains a terminal command.
- **`switch:Lid Switch`**: session/input config, moves to Phase 5.2.

## Gate 5.1

- [x] every donor bind classified; each `DESCARTAR` has a reason (this file);
- [x] the `Super+L` collision decided and recorded;
- [x] no bind executes interpreted shell or a command built by concatenation (`session-contract` enforces this over `hyprland.lua`);
- [x] `session-contract` covers the new helper and unit;
- [ ] **the live session comes up with the full config and no Hyprland API error** — needs a Frost login; `Hyprland --verify-config` was not available in the build environment.
