# Phase 4 surface inventory

This inventory is updated with every static surface port. It records state, actions, authority and runtime package impact before a surface can enter a graphical gate.

## Material, focus and motion

| Component | State read | Actions emitted | Single authority | Runtime package impact | Failure behavior |
|---|---|---|---|---|---|
| `Theme` | Package-owned `theme.toml` colors and glass opacity | None | `qs.Core.Theme` | None beyond the existing QuickShell runtime | Invalid or absent values retain compiled Frost defaults |
| `GlassSurface` | Semantic role and tokens from `Theme` | None | `Theme`; Hyprland remains the sole blur compositor | None | Unknown roles use the bounded generic glass opacity |
| `FocusRing` | Local `activeFocus` from its owning control | None | Qt focus chain | None | Hidden when the control has no focus |
| `InteractiveSurface` | Local hover, press, selection, enablement and keyboard focus | Typed `activated` signal only | The consuming static component owns the action | None | Disabled controls cannot activate and render muted |
| `Motion` | Compiled reduced-motion boundary and bounded durations | None | `qs.Core.Motion` | None | Reduced motion resolves all durations to zero |

The first integration applies these primitives only to the already approved bar, workspace controls and OSD. Workspace activation still uses the direct typed Hyprland dispatcher. The shell does not start processes, interpret commands from configuration, or acquire notification, lock, PAM or Polkit authority.

The compositor blur contract is package-owned in `default/hypr/hyprland.lua`: size 5, two passes and an alpha threshold of 0.12 for the exact `frost-bar` and `frost-osd` namespaces. The equivalent data tokens are recorded in the Frost theme for consistency; QML does not execute or generate compositor configuration.
