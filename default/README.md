# Packaged defaults

Immutable templates and session assets that install below `/usr/share/frost` belong here. The tree contains the package-owned Hyprland, Hypridle, Hyprlock, Mako, Ghostty and Bash defaults (the bash tree also ships a `readline` `inputrc`), the Frost-only systemd user units, the static Quickshell lifecycle unit, and the UWSM desktop entry source.

`default/nautilus/frost-open-in-ghostty.py` is a `nautilus-python` extension installed to `/usr/share/nautilus-python/extensions/`; it adds an "Abrir no Ghostty" context entry that launches the fixed `frost-terminal` wrapper in the selected folder.

Nothing here is copied into a donor or user configuration tree. The package installs one `/usr/share/wayland-sessions/frost.desktop` entry and user units named only `frost-*`; none of those units has an `[Install]` section or a global target.
