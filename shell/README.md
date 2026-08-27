# Static Frost shell

The Phase 4 Quickshell composition is first-party, package-owned and static. `shell.qml` composes one bar per screen, fixed workspaces, media, system tray, status controls, Frost OSD and one keyboard-interactive host containing every detailed surface. The only IPC target is `frost`, with allowlisted surfaces and strictly validated OSD payload fields.

This directory may not contain a plugin registry, manifests, directory discovery, runtime QML construction, imports outside this tree, a notification server, a PAM lock implementation, a Polkit agent or process execution outside `Core/ShellBackend.qml`. That singleton owns two serialized processes whose only entrypoint is the doubly allowlisted Frost CLI. Per-file source authority and transformation records live in `docs/provenance/ports.json`.
