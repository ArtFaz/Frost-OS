# Frost

Frost is an independent Arch Linux desktop built around UWSM, Hyprland, a statically composed Quickshell interface, Mako, Hyprlock, hyprpolkitagent, and a Btrfs/Snapper/Limine recovery stack.

This repository is the Frost runtime and user-facing CLI. It has a new history and no operational dependency on any donor distribution or repository.

Current status: private implementation. Gate 6 is closed — `install.sh` turns a clean CachyOS Minimal into a working Frost system in one command. Publication is still blocked until every reused source and asset has complete provenance and redistribution terms.

## Install

On a fresh CachyOS Minimal, with a Btrfs root and `[multilib]` enabled:

```
curl -fsSL https://raw.githubusercontent.com/ArtFaz/Frost-OS/main/install.sh | bash
```

Or read it first, which is the same thing with one more step:

```
git clone https://github.com/ArtFaz/Frost-OS.git frost
./frost/install.sh --dry-run   # prints every step without running any of them
./frost/install.sh
```

It installs `base-devel git rust`, builds the Frost packages on the machine, and
hands off to `packaging/install/bootstrap-cachyos`. Nothing is downloaded but the
repository itself: the Frost CLI has no crate dependencies, so it compiles
anywhere `rust` is installed, and the packages are never signed because they are
built and consumed on the same machine — see `docs/security-boundaries.md`.

The clone it leaves behind is the source tree. Build new packages from it with
`packaging/tools/build-local-repo`, and re-run `install.sh` to update: it pulls,
rebuilds and re-runs the bootstrap, all of which are idempotent.

For a machine with no network, `packaging/tools/build-install-bundle` packs the
built repository and the bootstrap into one tarball to carry across.

## Base

Frost is a desktop, not a distribution. The official base is CachyOS Minimal with Btrfs, Snapper and Limine; Arch Linux becomes a secondary supported base later. The base owns the kernel, drivers, repositories, bootloader and filesystem layout; Frost installs only the desktop experience on top of it and never patches the kernel, touches the bootloader, or replaces a base repository. Frost builds no installation image — it is installed onto an already-installed base by a `bootstrap-cachyos` script whose `plan` verb writes nothing and whose `apply` verb snapshots first. See `docs/architecture.md` and the Bootstrap trust zone in `docs/security-boundaries.md`.

A base and a donor are different categories. A base is a declared, permitted upstream. A donor is an audit reference and can never become one.

## Repository boundaries

- Immutable packaged data belongs below `/usr/share/frost`.
- Administrative configuration belongs below `/etc/frost`.
- User configuration belongs below `~/.config/frost`.
- Generated user state belongs below `~/.local/state/frost`.
- Runtime state belongs below `${XDG_RUNTIME_DIR}/frost`.
- Machine state belongs below `/var/lib/frost`.

Donor checkouts are audit references only. They are never build inputs, submodules, remotes, update channels, or runtime fallbacks.

## Phase 2 — Fix

Before Phase 3 begins, the parallel-session preview must complete these compatibility fixes:

- [x] Replace the transitional `hyprland.conf` with an original Frost Lua configuration at `/usr/share/frost/default/hypr/hyprland.lua`, using the current upstream Hyprland API.
- [x] Change `/usr/lib/frost/frost-hyprland` to launch `start-hyprland -- --config /usr/share/frost/default/hypr/hyprland.lua` instead of executing the raw `Hyprland` binary.
- [x] Set the UWSM desktop identity to `Frost:Hyprland`, preserving Frost session detection while advertising Hyprland compatibility to the desktop ecosystem.
- [x] Keep the configuration package-owned and independent: it must not load donor files or anything below `~/.config/hypr`; future personal overrides remain below `~/.config/frost`.
- [x] Confirm the three startup warnings are absent in two consecutive graphical Frost login cycles.

Acceptance requires a clean graphical startup without the deprecated `.conf`, direct-`Hyprland`, or unintended `XDG_CURRENT_DESKTOP` warnings, while `frost-session.target` and all `frost-*` ownership boundaries remain unchanged.
