# Frost parallel-session preview

Status: implementation plan only. None of these live-system actions is authorized by this document.

## Scope

The preview installs the signed `frost` package and its fixed Phase 2 dependencies. It does not install `frost-settings`, alter a donor session, write a user configuration, replace PAM files, enable a user unit globally, or change SDDM configuration. The package-owned `/usr/share/wayland-sessions/frost.desktop` entry makes the additional session visible to display managers that enumerate Wayland sessions.

Before installation, record the exact package file, signature, dependency transaction and current session entries. Abort if pacman proposes removing or replacing an installed package. The live transaction and the first SDDM login require separate explicit approval.

## Expected ownership

- `/usr/bin/frost`
- `/usr/lib/frost/frost-hyprland`
- `/usr/lib/frost/frost-terminal`
- `/usr/share/frost/**`
- `/usr/lib/systemd/user/frost-*`
- `/usr/share/wayland-sessions/frost.desktop`

No other package path is replaced. Hyprlock continues to use the upstream package-owned `/etc/pam.d/hyprlock`; Frost does not write that PAM file.

## Removal plan

From a non-Frost session, stop any leftover preview target with:

```bash
systemctl --user stop frost-session.target
```

Then inspect ownership and remove only the Frost package:

```bash
pacman -Qql frost
sudo pacman -R frost
```

Do not use recursive orphan removal: the preview must preserve pre-existing and newly resolved dependency packages. If a temporary local repository stanza or public trust bootstrap is authorized later, its exact reversal must be added here before installation.
