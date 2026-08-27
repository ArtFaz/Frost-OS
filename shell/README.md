# Static Frost shell

The Phase 3 Quickshell composition is first-party, package-owned and static. `shell.qml` composes one bar per screen, fixed workspaces, the system tray, the clock and the Frost OSD. The only IPC target is `frost`, with allowlisted surfaces and strictly validated OSD payload fields.

This directory may not contain a plugin registry, manifests, directory discovery, runtime QML construction, imports outside this tree, a notification server, a PAM lock implementation, a Polkit agent or generic process execution. Per-file source authority and transformation records live in `docs/provenance/ports.json`.
