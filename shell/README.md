# Frost Island shell

The Frost shell is a static, package-owned Quickshell composition built around one top-centre DynamicGlacier-derived island. shell.qml creates only Island/DynamicGlacier.qml; the previous bar, OSD host and Phase 4 surface tree are not part of the runtime. The island owns exactly one PanelWindow, which follows the focused monitor rather than being instantiated per screen.

The island keeps native Quickshell integrations for MPRIS, PipeWire, Bluetooth, UPower, Hyprland workspaces and the system tray. Audio is read and written directly through PipeWire, so volume, mute, output selection and the per-application mixer need no process at all. Wi-Fi, power profiles, charge thresholds, the idle inhibitor and the backlight device path cross Core/ShellBackend.qml, whose two serialized processes can call only the typed Frost CLI. Wi-Fi secrets use the process stdin channel and never enter argv.

Two rails sit outside the glass, beside the resting handle: workspaces on the left, background applications on the right. Both are colour and icon only, they hold their position while the island morphs, and they fade out whenever it opens. Workspace activation and tray activation are native calls, not shell commands.

The island carries no configuration UI and no application launcher. Geometry and handle style are data in config/shell.json; launching applications is not the shell's job.

Theme.qml, Style.qml and Motion.qml retain Frost's semantic palette, Nerd Font glyphs and bounded motion. FrostGlassSurface.qml is the only island material; there is no Liquid Glass option or runtime material switch. Mako, Hyprlock and hyprpolkitagent remain the sole notification, authentication and Polkit authorities.

For a reversible live worktree preview, run tools/preview-shell. It uses isolated config/state/cache, temporarily hides the pre-existing session bar, applies a scoped blur rule and restores the prior session state on exit.
