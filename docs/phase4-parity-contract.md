# Frost Island parity contract

The active shell is based on DynamicGlacier commit 70824af6350927c429ed57fb83d89ed843e6cd84, adapted under the MIT license. The exact per-file origins and transformations are recorded in docs/provenance/ports.json. The former Phase 4 bar, OSD and surface host are intentionally removed rather than kept as a second UI authority.

## Fixed identity

- One top-centre frost-island layer surface owns the shell UI.
- FrostGlassSurface.qml is the only glass material. Liquid Glass settings and variants are absent.
- Frost semantic theme colors, JetBrains Mono text and Nerd Font glyphs replace donor material/font choices.
- Hyprland supplies blur only to the exact frost-island namespace with size 5 and ignore-alpha 0.12.
- Handle style and bounded idle width/height remain schema-version-3 data in `config/shell.json`. The island exposes no UI to change them.

## Active modes

| Mode | State and actions |
|---|---|
| idle | clock, battery state and percentage, volume with scroll and mute, Wi-Fi and Bluetooth status, idle-inhibitor toggle, media-activity indicator and privacy indicators |
| media | becomes the default open face while a player is active: cover art, track, transport and progress, with a chevron back to the idle face |
| Wi-Fi | radio, rescan, connect and disconnect through the typed Frost boundary |
| Bluetooth | native Quickshell adapter discovery and device operations |
| battery | UPower telemetry, charging state, power profile and supported charge threshold |
| audio | native PipeWire master and input levels, mute, output selection and a per-application mixer |
| notifications | a viewer onto Mako: lists what makoctl reports, dismisses one or all, invokes the default action and toggles the dnd mode. It registers no notification server and holds no notification state of its own |
| volume/brightness | hardware-key and reactive OSD morphs; brightness is polled from sysfs so any tool that changes it is reflected |

The launcher, clipboard and emoji surfaces are visually held to the frozen `staging` tree, which `staging/docs/VISION.md` names the visual authority; their per-file records in `docs/provenance/ports.json` are `adapted` rather than `rewritten-from-concept` because the reproduction is deliberate and close. Frost's own JetBrains Mono and its accent-based selection fill are retained over the donor's font and highlight-based fill.

Mako remains the sole notification server; the island reads and acts on notifications only through the typed `frost shell-data notifications` / `frost shell-action notification-*` boundary, which calls fixed `makoctl` arguments. Hyprlock/PAM and hyprpolkitagent remain separate authorities. The public frost IPC target exposes only bounded single-argument methods for show, toggle, hide and hardware OSD data.

## Action boundary

QML never constructs or invokes a shell. Core/ShellBackend.qml owns exactly two serialized Process objects and dispatches only allowlisted frost shell-data and frost shell-action calls. The Rust CLI validates every action again and calls fixed absolute clients. Wi-Fi passwords are bounded printable data sent over stdin, never process arguments.

tools/preview-shell runs the Frost worktree directly with isolated XDG state and preview-only source/CLI overrides. It temporarily hides the Omarchy bar and installs a namespace-scoped blur rule; cleanup restores the bar and releases the rule handle. Upstream comparison mode copies an explicitly supplied DynamicGlacier checkout and never runs its installer.
