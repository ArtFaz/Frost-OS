# Gate 4 record

Phase 4 closes when the Frost session carries the whole desktop experience with
no second owner of any authority. This records what has been established, how,
and what only a live Frost login can establish.

Package under test: `frost 0.2.0-17`, built from the Frost worktree and signed
with `9F8D63165ACC27A4FDCCED02FD40A38811EDD104`.

## Established statically

| Criterion | Evidence |
|---|---|
| No Waybar or SwayOSD owner exists | Neither name appears in any package recipe, unit, compositor config or QML file; the only OSD is the package-owned `/usr/lib/frost/frost-osd` and the shell's own event card |
| Mako and Hyprlock remain external authorities | `frost-notifications.service` and `frost-lock.service` run them as separate processes and conflict with their upstream generic unit names; the shell never registers a notification server and holds no PAM path |
| One shell process, one IPC target, one process owner | `source-contract` and `shell-contract`: exactly two `Process` objects, both in `qs.Core.ShellBackend`, both entering only `frost shell-data` or `frost shell-action`; the surfaces coordinate through the `qs.Core.Surfaces` singleton rather than a second IPC handler |
| Every runtime dependency is inventoried | `frost doctor` checks each fixed executable by name; the mapping to owning packages is in `docs/phase4-surface-inventory.md`, and every one of them is a declared dependency of the `frost` package |
| Optional surfaces fail closed | Each row of `docs/phase4-surface-inventory.md` states the behaviour when its source is unavailable; none falls back to a shell string, a second authority or a donor path |
| Themes are data | 24 palettes validate, contrast gates included; a theme cannot carry geometry, opacity, motion, commands, symlinks or executable content |
| Material and motion are frozen | `material-contract` pins the alpha ladder, the single glass implementation and the bounded motion durations; the island paints at the reference bar's transmittance in every state |

`./test/all` passes: six contracts and 16 Rust tests.

## Established in the live session

Verified from inside a running Frost session on `0.2.0-25`:

- `frost status` reports the Frost session, the package-owned Hyprland config,
  and `frost-session.target`, shell, notifications, Polkit and idle all active
  with lock correctly inactive.
- `frost doctor` reports no failing check at all: every fixed executable, path
  and authority resolves.
- Do Not Disturb works end to end. `frost shell-action notification-dnd on`
  moves `makoctl mode` to `default,dnd` and `off` moves it back, and
  `frost shell-data notifications` reports `"dnd":true` in between. The switch
  had appeared inert only where no Mako runs at all.
- Opening a window now takes the keyboard with it; the island holds the keyboard
  only while its password field is on screen.
- The wallpaper survives a shell restart: the `frost-background` layer comes back
  mapped at full size and the state pointer is unchanged.
- Terminal opacity, per-window opacity, motion, cursor size and the pointing hand
  inside the island were all confirmed by eye against the reference session.

## Gate 4 closed

The session actions were exercised by the user: the confirmation card precedes
poweroff, reboot and logout, the OSD is drawn, and the action lands after the
scheduled delay. Multi-monitor is accepted as closed by explicit decision — the
machine under test has one output and the behaviour will be checked when a
second display exists. Everything else in the matrix was verified from inside a
running Frost session.

Gate 4 is closed. Phase 4 delivered the shell, its surfaces, the theme system,
the wallpaper mechanism and the session dialogs. What was deliberately left out
is recorded below and in the master plan as Phases 5.1 and 5.2.

## Alignment audit before closing

A sweep for capability that exists on one side of the boundary and nowhere on
the other, since either direction is a defect: an unreachable feature, or an
action surface nobody uses.

Fixed here:

- The image browser hid its whole card when nothing resolved, so choosing
  "Papel de parede" with no wallpapers installed dimmed the screen and drew
  nothing. It now keeps the card and says what is empty. The same silence would
  have appeared for an empty picture directory.
- Searching from the launcher root matched only the five fixed rows. Typing now
  searches applications as well, which is what a launcher field is for; reaching
  an application required entering a submenu first.
- `open-terminal` existed as a shell action on both sides of the boundary with
  no caller: the keybind starts `/usr/lib/frost/frost-terminal` directly, and the
  action spawned Ghostty bare, skipping the theme-aware wrapper. Removed from the
  QML allowlist and from the CLI.
- `docs/security-boundaries.md` still described a theme as exactly eight colours,
  which the ANSI palette made false.

Recorded, not fixed, because each is a feature decision rather than a defect:

- `shell-action reminder-set` and `reminder-clear` are implemented and validated
  in Rust and reachable from no interface. `shell-data indicators` already
  reports the reminder timer's state.
- `shell-data weather` has no consumer either, though `frost weather` works as a
  user command.
- The wallpaper and image surfaces have no keybind; they are reached through the
  launcher. Keybinds are Phase 5.1.

## Scope decision recorded during this gate

The application installer left Phase 4. Its frontend was listed as a Phase 4
surface and its typed plan as a Phase 4 gate criterion, while the package
selection that plan describes belongs to Phase 5 — so the frontend would have
had nothing real to render. By explicit decision, Phase 4 is the shell and
nothing else, and the installer enters Phase 5 whole, frontend and backend
together. The criterion is removed from Gate 4 rather than carried as debt.
