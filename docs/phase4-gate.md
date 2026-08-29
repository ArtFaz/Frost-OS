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

## Only a live Frost login can establish

These need the Frost session itself, not the preview, because the preview runs
over another compositor configuration and cannot exercise session lifecycle.

1. Clean startup: no deprecated-config, direct-`Hyprland` or `XDG_CURRENT_DESKTOP` warning; `frost status` reports the Frost session and every `frost-*` unit in its expected state.
2. Compositor appearance: per-window opacity with its opt-outs, Motion v2 on windows, workspaces and layers, cursor size, and XWayland scaling.
3. Single authority under load: `frost doctor` clean, and no second notification, lock or Polkit owner while the desktop is in use.
4. Do Not Disturb: the switch must move `makoctl mode` in and out of `dnd`. This could not be exercised anywhere else — the reference session no longer runs Mako at all, so `makoctl` has no daemon to talk to there and the switch appears inert for reasons that have nothing to do with Frost.
5. Session actions: the confirmation card precedes poweroff, reboot and logout, the event OSD is drawn, and the action lands about two seconds later.
6. Multi-monitor: the island follows the focused monitor, the reserved zone is correct on each, and hotplug does not duplicate or strand a surface.
7. Wallpaper: selecting one paints it and it survives a shell restart.

## Scope decision recorded during this gate

The application installer left Phase 4. Its frontend was listed as a Phase 4
surface and its typed plan as a Phase 4 gate criterion, while the package
selection that plan describes belongs to Phase 5 — so the frontend would have
had nothing real to render. By explicit decision, Phase 4 is the shell and
nothing else, and the installer enters Phase 5 whole, frontend and backend
together. The criterion is removed from Gate 4 rather than carried as debt.
