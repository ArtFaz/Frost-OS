# Static Frost shell

The Phase 4 Quickshell composition is first-party, package-owned and static. `shell.qml` composes one 30 px bar per screen, fixed workspaces, media, system tray, status controls, Frost OSD and one keyboard-interactive host containing every detailed surface. `Style.qml` freezes geometry and typography; `Theme.qml` applies a strict semantic palette without allowing themes to mutate material. The only IPC target is `frost`, with allowlisted surfaces and strictly validated OSD payload fields.

This directory may not contain a plugin registry, manifests, directory discovery, runtime QML construction, imports outside this tree, a notification server, a PAM lock implementation, a Polkit agent or process execution outside `Core/ShellBackend.qml`. That singleton owns two serialized processes whose only entrypoint is the doubly allowlisted Frost CLI. Per-file source authority and transformation records live in `docs/provenance/ports.json`.
