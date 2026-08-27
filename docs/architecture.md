# Frost Arch foundation

Frost is split into a coexistable user/session package and a later privileged settings package. The runtime repository owns the CLI, static shell, data-only defaults, themes, user services, and migrations. The sibling package repository owns PKGBUILDs, signing and local pacman repository tooling.

The initial public paths are `/usr/share/frost`, `/usr/bin/frost`, `/etc/frost`, `~/.config/frost`, `~/.local/state/frost`, `${XDG_RUNTIME_DIR}/frost`, and `/var/lib/frost`.

The session architecture is UWSM → Hyprland → `frost-session.target`. Mako, Hyprlock and hyprpolkitagent retain exclusive ownership of notifications, lock/PAM and Polkit. Quickshell is statically composed and has no plugin registry or user QML loading.

The Phase 2 session is entered only through `/usr/share/wayland-sessions/frost.desktop`, which gives UWSM the desktop identity `Frost:Hyprland` and asks it to launch `/usr/lib/frost/frost-hyprland`. That wrapper uses upstream `start-hyprland` with the package-owned `/usr/share/frost/default/hypr/hyprland.lua`; it never loads `~/.config/hypr` or a donor runtime tree. The Lua configuration starts `frost-session.target`; no Frost unit is enabled in `default.target` or `graphical-session.target`.

`frost-session.target` is bound to `graphical-session.target` and owns only `frost-*` user units. The notification, Polkit and idle services conflict with their upstream generic unit names so a pre-enabled upstream unit cannot become a second authority inside Frost. Hyprlock is an on-demand `frost-lock.service`; it is never treated as a shell component.

Phase 2 intentionally contains no global settings package, final package selection, updater, migration runner, privileged helper, or static shell. Those enter only in their gated phases.
