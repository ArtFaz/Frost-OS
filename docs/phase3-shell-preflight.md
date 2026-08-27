# Phase 3 static shell preflight

Status: Gate 2 closed; the static source composition is implemented and validated. Packaging and live Gate 3 activation remain pending.

## Dependency decision

The Phase 3 package target is the official Arch `extra/quickshell` package. The synchronized repository currently exposes `quickshell 0.3.1-1`, signed by Arch, under `LGPL-3.0-only`.

The host's pre-existing `quickshell-git` installation is a test-environment fact, not a Frost dependency or build input. Frost will not copy its donor PKGBUILD, hook, distributor identity, configuration or runtime tree. Replacing that package on the live host, if still necessary when Phase 3 is activated, requires a separate reviewed pacman transaction.

## Static composition boundary

The first shell increment will be an original, package-owned composition rooted at `/usr/share/frost/shell/shell.qml`:

```text
ShellRoot
├── one bar surface per Quickshell screen
│   ├── fixed workspace component
│   ├── fixed system tray component
│   └── clock
└── one OSD controller with per-screen visual surfaces
```

The composition may use Qt, Quickshell and modules shipped inside the same Frost shell tree. It may not discover QML directories, load plugin manifests, construct QML from runtime strings, follow shell symlinks, import a quoted path outside the Frost shell tree, provide notifications, authenticate PAM/Polkit, or execute a configurable process.

Mako, Hyprlock and hyprpolkitagent remain the exclusive notification, lock and Polkit authorities. The session target will eventually supervise exactly one `frost-shell.service`; no generic Quickshell service will be enabled globally.

## Source authority and provenance plan

The frozen `Frost-OS` shell at commit `f4a8cc9cd4137469393f815ccef08a849ce9005d` is the architectural reference for a minimal static composition. The frozen `staging` shell at commit `824831e75171dc4c87c8d53dfd22e3e07de7f6a6` is the functional and visual reference for the Frosted Glass bar, workspace behavior, tray and OSD.

Neither source tree will be copied recursively. Phase 3 will implement a smaller first-party tree and add a per-file provenance ledger before each implementation commit. Visual behavior or architecture reproduced without copying implementation is recorded as `rewritten-from-concept`; any substantially adapted file is recorded as `adapted` and remains blocked from publication until its rights are resolved.

The Phase 3 source set is limited to:

- semantic color, spacing, typography and glass primitives;
- `ShellRoot` with strict schema-versioned data-only configuration;
- bar surfaces, fixed workspaces, fixed tray and clock;
- OSD model and surfaces for volume and brightness;
- the narrow `frost` IPC target with allowlisted surface names and payload fields;
- `frost-shell.service`, lifecycle diagnostics and package ownership.

Menu, notification center, command center, audio/network/Bluetooth/display/power panels, media, clipboard, emoji, image picker, Tailscale and agents remain Phase 4 work. Notification-server and Quickshell lock implementations are permanently excluded.

## Activation and test boundary

Source validation will use the Frost source contract, `qmllint`, deterministic JavaScript model tests and package inspection. Real surface, multi-monitor, hotplug, exclusive-zone, OSD and crash/restart tests belong to Gate 3 and require explicit live-session authorization.

The Phase 3 package and shell process remain inactive until the signed package is reviewed and live Gate 3 activation is explicitly authorized.
