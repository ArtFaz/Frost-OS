# Frost

Frost is an independent Arch Linux desktop built around UWSM, Hyprland, a statically composed Quickshell interface, Mako, Hyprlock, hyprpolkitagent, and a Btrfs/Snapper/Limine recovery stack.

This repository is the Frost runtime and user-facing CLI. It has a new history and no operational dependency on any donor distribution or repository.

Current status: private implementation, Phase 1 foundation. Publication is blocked until every reused source and asset has complete provenance and redistribution terms.

## Repository boundaries

- Immutable packaged data belongs below `/usr/share/frost`.
- Administrative configuration belongs below `/etc/frost`.
- User configuration belongs below `~/.config/frost`.
- Generated user state belongs below `~/.local/state/frost`.
- Runtime state belongs below `${XDG_RUNTIME_DIR}/frost`.
- Machine state belongs below `/var/lib/frost`.

Donor checkouts are audit references only. They are never build inputs, submodules, remotes, update channels, or runtime fallbacks.

