# Frost security boundaries

Status: initial Phase 0 threat model and implementation contract.

## Trust zones

| Zone | Trusted inputs | Permitted effects | Forbidden behavior |
|---|---|---|---|
| Static Quickshell process | Package defaults plus schema-validated admin/user data | Read session state; invoke named, non-privileged actions through fixed argv or typed IPC | Loading user QML, owning PAM/Polkit/notifications, shell interpolation, arbitrary commands |
| Mako | Notification D-Bus traffic and its own data-only config | Own notification service, dismiss/mode/history/actions defined by notification protocol | Executing Frost-specific privileged actions from untrusted hints |
| Hyprlock | Package-owned visual config and PAM stack | Lock/authenticate the session | Loading shell plugins or treating shell survival as authentication state |
| hyprpolkitagent | Polkit requests | Authenticate policy requests | Sharing an agent implementation with Quickshell |
| Frost user CLI | Validated Frost config/state and fixed subcommands | User-scoped inspection and actions; call narrow privileged helpers | Elevating the whole CLI, arbitrary package installation, arbitrary shell execution |
| Privileged helpers | Exact versioned request schema and canonicalized paths | One documented machine action per helper | Generic command execution, broad path writes, caller-supplied shell or executable paths |
| Package transaction | Arch and Frost signed repositories | Modify package-owned paths and create `.pacnew` where applicable | Fetch donor code, overwrite foreign package files, execute user migrations as root |
| Update orchestrator | Package plan, Snapper health, migration manifests | Snapshot, pacman transaction, idempotent migration, verify | Starting a transaction without a valid snapshot or continuing after incompatible failure |
| Theme/config loader | Regular files below permitted roots | Parse data matching a versioned schema; materialize private runtime configs for the external UI authorities | Symlinks, executable bits, QML/JS/hooks, path escape, unknown fields, theme-controlled geometry or commands |
| ISO installer | Local signed media/repositories and validated installer model | Partition/mount/install only the explicitly selected target | Network donor fallback, ambiguous disk target, silent destructive default |

## Security authorities

- Notifications: Mako only. Frost's viewer is a makoctl client behind the typed CLI boundary; it never registers `org.freedesktop.Notifications` and never acts on a notification hint, only on an id the user selected.
- Lock and PAM: Hyprlock only.
- Polkit: hyprpolkitagent only.
- Session lifecycle: UWSM plus `frost-session.target`.
- Package ownership: pacman with Arch and Frost keys.
- Machine rollback: Btrfs, Snapper and Limine.
- Shell UI: one statically composed first-party Quickshell process.

No fallback may create a second owner inside the Frost session. A fallback can be installed for recovery but must be inactive while the primary authority is active.

### Coexistence transition quarantine

UWSM environment fragments are global rather than desktop-entry scoped. During
the coexistence preview, the Frost compositor wrapper removes the single legacy
session-root variable from both the systemd user manager and its own process
before `graphical-session.target` is reached. This is a negative boundary only:
the value is never read, resolved, executed, or used as a path. Source and
session contracts allow the foreign identifier in exactly one declaration and
require its only two uses to be fixed `unset` operations. A subsequent login to
the normal session sources its own UWSM environment again.

## Initial threats and required controls

| Threat | Donor evidence | Frost control | Verification |
|---|---|---|---|
| User or downloaded QML executes code in the shell | Dynamic plugin registry/manifests | No directory scan or external QML import; source-contract allowlist | Static source test and malicious fixture |
| Config/theme injects a command | QML process arrays and shell-oriented theme/plugin hooks | Versioned data-only schemas; fixed argv; reject executable/symlink content | Schema and filesystem tests |
| Notification hint triggers arbitrary action | Donor shell owns notifications/actions | Mako owns D-Bus; Frost actions are named and allowlisted | Forged notification test |
| Shell crash compromises lock | Earlier Quickshell lock shared the shell process | Hyprlock owns PAM and session lock independently | Crash shell while locked |
| Duplicate Polkit/notification owners | Donor shell and external services can overlap | `frost-session.target` starts one owner and doctor checks D-Bus/process state | Session integration test |
| Broad passwordless privilege | Donor sudoers grants full `asdcontrol` and regex/timezone helpers | No broad executable grants; exact helper and exact schema, preferably Polkit | Negative argument tests |
| Package scriptlet overwrites foreign `/etc` files | `omarchy-settings.install` uses destructive `cp -f` | Package-owned drop-ins, `backup=()`, `.pacnew`, or explicit consented migration | Ownership and upgrade tests |
| Direct pacman bypasses migration | Donor blocks pacman globally | Pacman stays available; hook only marks pending; doctor/login notify | Direct pacman integration fixture |
| Update proceeds without recovery | Best-effort or coupled update flows | Snapshot is mandatory and recorded before transaction | Injected Snapper failure |
| Donor supply-chain dependency returns | PKGBUILDs and ISO reference donor Git/repos/mirrors | Source-contract rejects donor endpoints outside notices; builds run with donors unavailable | Offline build and forbidden-string tests |
| AUR code enters trusted base or runs with privilege | Donor helper installs AUR | Bootstrap/core remain Arch/Frost; optional AUR is explicit, pinned and later built unprivileged in isolation | Dependency/source/lock audit |
| Path traversal or symlink escape | Donor refresh helper accepts `..`; themes are mutable trees | Canonicalize, constrain roots, use no-follow checks | Traversal/symlink tests |
| Root hook executes user action | Donor package hooks and scriptlets mix lifecycle work | Root hooks only mark machine state; user migrations run as the user | Hook fixture and UID assertions |
| ISO destroys wrong disk | Installer has full partition/mount authority | Explicit resolved target, protected-mode verification, displayed plan and confirmation | Disposable-disk tests only |

## Privileged path policy

`frost-settings` may own only paths listed in its package manifest. Prefer a Frost-specific file under a supported drop-in directory. It may not replace `/etc/os-release`, PAM package files, `/etc/nsswitch.conf`, `/etc/skel/.bashrc`, or another package's configuration with a scriptlet copy.

PAM changes must use a dedicated Hyprlock service with no `nullok`, empty-password bypass, or user-controlled module path. Sudoers is permitted only when a command cannot be safely expressed with existing system policy, and every entry must bind an immutable helper to exact accepted operations. Regular-expression sudoers arguments are not considered sufficient input validation for a generic helper.

## IPC and process execution contract

- Public shell IPC target is `frost`.
- Methods are named and schema-specific; there is no generic `exec` method.
- Unknown fields that influence execution are rejected.
- Configuration never becomes a shell command string.
- Commands use a fixed executable plus an argv array. User-controlled values are validated as data, not escaped for a shell.
- QML process ownership is restricted to `qs.Core.ShellBackend`: exactly two serialized processes, both entering only `/usr/bin/frost shell-data` or `/usr/bin/frost shell-action`.
- Rust validates the action/data allowlist again, uses absolute executable paths, canonicalizes image roots and caps output/file sizes.
- URLs are parsed and restricted before a fixed browser launcher receives them.
- Privileged operations leave QML and cross a typed CLI/helper boundary.
- `--json` stdout remains strictly machine-readable; diagnostics go to stderr.

## Configuration and theme contract

- Defaults: `/usr/share/frost` (package-owned and immutable outside pacman).
- Administrative config: `/etc/frost`.
- User config: `~/.config/frost`.
- Generated state: `~/.local/state/frost`.
- Runtime state: `${XDG_RUNTIME_DIR}/frost`.
- Machine state: `/var/lib/frost`.
- Logs: journal or `/var/log/frost`, never persistent state in `/tmp`.

Every config includes `schemaVersion`. A theme contains exactly a name, dark/light mode and eight semantic colors. It cannot control geometry, opacity, blur, fonts, motion or commands. User, administrator and package themes are validated by the Rust boundary and normalized to mode-0600 runtime files. Mako and Hyprlock launch through fixed Frost subcommands that consume those files when safe and fall back to immutable package configs otherwise. Themes may contain only regular, non-executable files of explicitly allowed media/data types. Symlinks, FIFOs, device nodes, sockets, QML, JavaScript, shell, binaries and hooks are rejected.

## Update and rollback invariants

1. Acquire the Frost update lock.
2. Validate Btrfs, Snapper and free space.
3. Create and verify the mandatory pre-update snapshot.
4. Record the snapshot ID and proposed transaction.
5. Inhibit suspend.
6. Run the pacman transaction.
7. Run only compatible machine migrations, then user migrations in user context.
8. Run `frost verify` and report restart/reboot state.
9. Preserve logs and a tested rollback path.

A failed snapshot aborts before pacman. A failed pacman transaction does not run migrations for the new version. A direct `pacman -Syu` is never blocked, but it can leave a pending marker that `frost doctor` and login notification expose.

## Phase gates

- Phase 1 must add executable source-contract tests for donor endpoints, dynamic QML, executable themes, process execution outside the typed Frost backend and unsafe path/config handling.
- Phase 2 must prove the session does not share notification, lock or Polkit ownership with Omarchy.
- Phases 3–4 must inventory every runtime command and package consumer as surfaces are ported.
- Phase 6 must prove package ownership, PAM and least privilege.
- Phase 7 must inject failures across update and rollback.
- No live system change is authorized by this document.
