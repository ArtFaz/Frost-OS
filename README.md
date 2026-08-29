# Frost

Frost is an independent Arch Linux desktop built around UWSM, Hyprland, a statically composed Quickshell interface, Mako, Hyprlock, hyprpolkitagent, and a Btrfs/Snapper/Limine recovery stack.

This repository is the Frost runtime and user-facing CLI. It has a new history and no operational dependency on any donor distribution or repository.

Current status: private implementation, Phase 4 shell development. Gate 2 is closed after two consecutive graphical Frost cycles, and Gate 3 has been validated from an installed, signed package in a live session. The island, its surfaces, the theme system and the session dialogs are implemented; Phase 6 (the privileged settings package) and the bootstrap have not started. Publication is blocked until every reused source and asset has complete provenance and redistribution terms.

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
