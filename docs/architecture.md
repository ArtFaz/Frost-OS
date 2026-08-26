# Frost Arch foundation

Frost is split into a coexistable user/session package and a later privileged settings package. The runtime repository owns the CLI, static shell, data-only defaults, themes, user services, and migrations. The sibling package repository owns PKGBUILDs, signing and local pacman repository tooling.

The initial public paths are `/usr/share/frost`, `/usr/bin/frost`, `/etc/frost`, `~/.config/frost`, `~/.local/state/frost`, `${XDG_RUNTIME_DIR}/frost`, and `/var/lib/frost`.

The session architecture is UWSM → Hyprland → `frost-session.target`. Mako, Hyprlock and hyprpolkitagent retain exclusive ownership of notifications, lock/PAM and Polkit. Quickshell is statically composed and has no plugin registry or user QML loading.

Phase 1 intentionally contains no live session entry, global settings, package choice, updater, migration runner, or privileged helper. Those enter only in their gated phases.

