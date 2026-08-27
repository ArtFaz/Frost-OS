# Frost Arch foundation

Frost is split into a coexistable user/session package and a later privileged settings package. The runtime repository owns the CLI, static shell, data-only defaults, themes, user services, and migrations. The sibling package repository owns PKGBUILDs, signing and local pacman repository tooling.

The initial public paths are `/usr/share/frost`, `/usr/bin/frost`, `/etc/frost`, `~/.config/frost`, `~/.local/state/frost`, `${XDG_RUNTIME_DIR}/frost`, and `/var/lib/frost`.

The session architecture is UWSM → Hyprland → `frost-session.target`. Mako, Hyprlock and hyprpolkitagent retain exclusive ownership of notifications, lock/PAM and Polkit. Quickshell is statically composed and has no plugin registry or user QML loading.

The Phase 2 session is entered only through `/usr/share/wayland-sessions/frost.desktop`, which gives UWSM the desktop identity `Frost:Hyprland` and asks it to launch `/usr/lib/frost/frost-hyprland`. That wrapper uses upstream `start-hyprland` with the package-owned `/usr/share/frost/default/hypr/hyprland.lua`; it never loads `~/.config/hypr` or a donor runtime tree. The Lua configuration starts `frost-session.target`; no Frost unit is enabled in `default.target` or `graphical-session.target`.

`frost-session.target` is bound to `graphical-session.target` and owns only `frost-*` user units. The notification, Polkit and idle services conflict with their upstream generic unit names so a pre-enabled upstream unit cannot become a second authority inside Frost. Hyprlock is an on-demand `frost-lock.service`; it is never treated as a shell component.

Beginning in Phase 3, `frost-shell.service` is supervised by the Frost target and starts exactly `/usr/bin/quickshell --path /usr/share/frost/shell/shell.qml`. The package-owned tree contains a statically composed bar per monitor and an OSD. It exposes only the `frost` IPC target and does not load manifests, external QML or a user shell tree. User settings are read only as schema-versioned data from `~/.config/frost`.

The bar owns workspace presentation, the system tray and the clock. The OSD accepts only bounded JSON fields and is triggered by `/usr/lib/frost/frost-osd`, whose fixed action allowlist controls volume or brightness before sending display state to the shell. Mako, Hyprlock and hyprpolkitagent remain separate authorities.

Phase 3 still contains no global settings package, final package selection, updater, migration runner or privileged helper. Those enter only in their gated phases.
