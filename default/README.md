# Packaged defaults

Immutable templates and session assets that install below `/usr/share/frost` belong here. The tree contains the package-owned Hyprland, Hypridle, Hyprlock, Mako, Ghostty and Bash defaults, the Frost-only systemd user units, the static Quickshell lifecycle unit, and the UWSM desktop entry source.

Nothing here is copied into a donor or user configuration tree. The package installs one `/usr/share/wayland-sessions/frost.desktop` entry and user units named only `frost-*`; none of those units has an `[Install]` section or a global target.
