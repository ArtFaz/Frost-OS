# Frost parallel-session preview

Status: implementation plan only. None of these live-system actions is authorized by this document.

## Scope

The preview installs the signed `frost` package and its fixed Phase 2 dependencies. It does not install `frost-settings`, alter a donor session, write a user configuration, replace PAM files, enable a user unit globally, or change SDDM configuration. The package-owned `/usr/share/wayland-sessions/frost.desktop` entry makes the additional session visible to display managers that enumerate Wayland sessions.

Before installation, record the exact package file, signature, dependency transaction and current session entries. Abort if pacman proposes removing or replacing an installed package. The live transaction and the first SDDM login require separate explicit approval.

## Verified installation plan

Use only the five explicitly qualified Arch `extra` packages. A preflight `pacman -Sp --print-format '%r/%n %v'` must show only `extra/` for the requested packages and their missing dependencies. Do not add a Frost or donor repository stanza to `/etc/pacman.conf` for this preview.

First validate both local packages using the public-key-only keyring:

```bash
gpg --show-keys --fingerprint /home/art/Frosted-Glass/frost-pkgs/pkgbuilds/frost-keyring/frost.gpg
gpgv --keyring /home/art/Frosted-Glass/frost-pkgs/pkgbuilds/frost-keyring/frost.gpg /home/art/Frosted-Glass/frost-pkgs/repo/x86_64/frost-keyring-20260826-1-any.pkg.tar.zst.sig /home/art/Frosted-Glass/frost-pkgs/repo/x86_64/frost-keyring-20260826-1-any.pkg.tar.zst
gpgv --keyring /home/art/Frosted-Glass/frost-pkgs/pkgbuilds/frost-keyring/frost.gpg /home/art/Frosted-Glass/frost-pkgs/repo/x86_64/frost-0.2.0-5-x86_64.pkg.tar.zst.sig /home/art/Frosted-Glass/frost-pkgs/repo/x86_64/frost-0.2.0-5-x86_64.pkg.tar.zst
```

After the fingerprint has been checked against the execution journal, bootstrap only that key and install the official dependencies plus the two signed local packages:

```bash
sudo pacman-key --add /home/art/Frosted-Glass/frost-pkgs/pkgbuilds/frost-keyring/frost.gpg
sudo pacman-key --lsign-key 9F8D63165ACC27A4FDCCED02FD40A38811EDD104
sudo pacman -S --needed extra/cliphist extra/hypridle extra/hyprlock extra/hyprpolkitagent extra/mako
sudo pacman -U /home/art/Frosted-Glass/frost-pkgs/repo/x86_64/frost-keyring-20260826-1-any.pkg.tar.zst /home/art/Frosted-Glass/frost-pkgs/repo/x86_64/frost-0.2.0-5-x86_64.pkg.tar.zst
systemctl --user daemon-reload
pacman -Qkk frost frost-keyring
```

Stop immediately if pacman proposes any removal, a package outside the official Arch repositories, or a target other than these named packages and their dependencies. Do not start `frost-session.target` manually from the current desktop. The first Frost login is a separate graphical gate.

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

Then inspect ownership and remove only the two Frost packages:

```bash
pacman -Qql frost
sudo pacman -R frost
sudo pacman -R frost-keyring
sudo pacman-key --delete 9F8D63165ACC27A4FDCCED02FD40A38811EDD104
sudo pacman-key --updatedb
```

Do not use recursive orphan removal: the preview must preserve pre-existing and newly resolved dependency packages. No repository stanza is added, so there is no `pacman.conf` edit to reverse. After removal, verify that `/usr/share/wayland-sessions/frost.desktop` and every `frost-*` user unit are absent.
