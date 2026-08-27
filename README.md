# Frost

Frost is an independent Arch Linux desktop built around UWSM, Hyprland, a statically composed Quickshell interface, Mako, Hyprlock, hyprpolkitagent, and a Btrfs/Snapper/Limine recovery stack.

This repository is the Frost runtime and user-facing CLI. It has a new history and no operational dependency on any donor distribution or repository.

Current status: private implementation, Phase 2 parallel-session preview. The isolated preview is installed locally; the Phase 2 compatibility fix is implemented in source and awaits its final graphical acceptance test. Publication is blocked until every reused source and asset has complete provenance and redistribution terms.

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
- [ ] Confirm the three startup warnings are absent in a fresh graphical Frost login.

Acceptance requires a clean graphical startup without the deprecated `.conf`, direct-`Hyprland`, or unintended `XDG_CURRENT_DESKTOP` warnings, while `frost-session.target` and all `frost-*` ownership boundaries remain unchanged.
