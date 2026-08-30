# Frost meta package

`PKGBUILD` is **generated** by `../../tools/generate-frost-meta` from the
approved `frost/frost-packages.json` (Gate 5, 2026-08-30). Do not hand-edit it —
re-run the generator after the manifest changes and commit the result.

`depends()` is the Arch/Frost half of the resolved package set. It excludes:

- **BOOTSTRAP** packages (kernel, `base`, bootloader) — the CachyOS Minimal base
  owns those; `bootstrap-cachyos` reconciles any delta.
- **AUR** packages — they stay in `frost/aur.lock.json` and are installed later
  with `paru`; a meta-package cannot make an AUR recipe pacman-resolvable.

The package installs one file, `usr/share/doc/frost-meta/manifest.txt`.
