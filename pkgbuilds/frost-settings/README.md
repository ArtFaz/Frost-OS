# Frost settings package

`frost-settings` carries the privileged and global configuration for a Frost
system. It **builds** in Phase 6 from the `frost` repo archive; it is
**installed** only by the clean install (`bootstrap-cachyos`), never enabled by
a pacman transaction.

Contents (source under `frost/default/` and `frost/bin/frost-firstboot`):

- `usr/share/sddm/themes/frost/` — the greeter theme.
- `/etc` drop-ins Frost owns: `sddm.conf.d/10-frost.conf`,
  `sysctl.d/10-frost.conf`, `systemd/zram-generator.conf`, `sudoers.d/frost`.
- `usr/lib/frost/frost-firstboot` + `frost-firstboot.service` — a
  marker-guarded oneshot that reconciles the hardened `/etc/pam.d/hyprlock`,
  the snapper root config and timers, and the firewall. Files owned by another
  package (the hyprlock PAM stack, `/etc/conf.d/snapper`) are edited here rather
  than shipped, so there is no file conflict.

Checked by `../../test/settings-contract` and `../../test/signatures`.
