# Frost Arch donor audit

Status: Phase 0 evidence complete for private implementation. Publication remains blocked by the provenance gaps recorded in `provenance.md`.

Audit date: 2026-08-26

## Scope and method

This audit treats every donor checkout as read-only. It records the exact local commits, classifies the top-level implementation areas, maps package ownership and privileged writes, reconciles the initial package sources, inventories external commands used by the two Frost authorities, and identifies which ideas may be retained without making a donor an upstream.

The generated evidence is reproducible with:

```bash
./tools/audit/generate-phase0-evidence
```

The generator does not use the network, install packages, invoke privilege escalation, or write outside the Frost tree and an isolated `/tmp/frost-phase0.*` directory. It evaluates only the three core donor packaging functions (`omarchy`, `omarchy-settings`, and `omarchy-keyring`) against the already-frozen local source to produce exact package file lists. No donor worktree is modified.

## Frozen sources

The authoritative machine-readable record is `audit/generated/source-snapshots.tsv`.

| Source | Commit | Role | Observed state |
|---|---|---|---|
| `Frost-OS` | `f4a8cc9cd413` | Recent Frost architecture and security authority | Clean |
| `staging` | `824831e75171` | Functional and visual shell authority | Clean |
| `Definitive Frost-OS/omarchy` | `0ae1694830b6` | Arch runtime donor | Clean |
| `Definitive Frost-OS/omarchy-pkgs` | `5a73fd899940` | PKGBUILD and ownership donor | Clean; obtained for this audit |
| `Definitive Frost-OS/omarchy-iso` | `268bac16d351` | Installer and ISO donor | Clean |
| `omanix` | `4af5e88b6346` | Historical Nix structure donor | Clean |
| `nixarchy` | `74802f4aa707` | Historical extraction donor | Clean |
| `frosted-os` | filesystem snapshot, no Git history | Earlier sanitized extraction and attribution record | Reference only |

The current `omarchy-pkgs` stable package recipes pin Omarchy tag `v4.0.1` at `13f18b2cb7286fb54f87daf571a031aa6af3d8f0`, while the frozen runtime donor checkout is newer. Both facts are intentional audit inputs; Frost must not silently mix their implementations. The clone remote is retained as provenance metadata only. Builds and tests in Frost may not fetch or consult it.

The workspace root contains a non-functional `.git` directory and is not a usable Git repository. It is not a history source for either new Frost product.

## Package and install topology

The donor design has four relevant layers:

1. `omarchy-keyring` installs the donor pacman public key material and populates it through a package scriptlet.
2. `omarchy-settings` owns global drop-ins, `/etc/skel`, user defaults, SDDM assets, user units, fonts, icons, PAM-related source material, sudoers, Snapper templates, and generated defaults.
3. `omarchy` owns the runtime command farm, shell, themes, migrations, install routines, and three libalpm hooks. It depends on the settings package and the Limine/Snapper stack.
4. The ISO constructs an offline repository, lets Archinstall create or consume the target layout, then runs root and user finalizers inside `arch-chroot`.

Exact generated file counts at the audited commits:

| Package | Package-owned files/symlinks | Important note |
|---|---:|---|
| `omarchy` | 1,566 | Includes every runtime command and the full dynamic shell tree |
| `omarchy-settings` | 419 | Includes 94 paths below `/etc`; six additional live paths are overwritten by its scriptlet |
| `omarchy-keyring` | 3 | Installs public keyring, trusted and revoked lists |

The complete per-file map is `audit/generated/donor-package-paths.tsv`. Every row identifies the package, ownership type, installed path, and source mapping. The six scriptlet writes are marked `unowned-scriptlet-write` rather than pretending they are package-owned:

- `/etc/os-release`
- `/etc/security/faillock.conf`
- `/etc/nsswitch.conf`
- `/etc/cups/cups-browsed.conf` when that file already exists
- `/etc/plymouth/plymouthd.conf`
- `/etc/skel/.bashrc`

These destructive `cp -f` writes are explicitly rejected for Frost. Global Frost configuration must be package-owned, a non-conflicting drop-in, or an explicit migration with backup and consent.

Other privileged package owners found in the donor recipes are known even where their complete upstream payload is downloaded only at build time:

| Owner | Privileged paths or effects | Frost disposition |
|---|---|---|
| `limine-mkinitcpio-hook` | `/etc/boot/hooks`, `/etc/limine-entry-tool.conf`, `/usr/lib/limine`, mkinitcpio integration | `KEEP-CONCEPT`; audit the direct Arch/upstream package before Frost packaging |
| `limine-snapper-sync` | `/etc/boot/hooks`, `/etc/limine-snapper-sync.conf`, `/usr/lib/limine`, system units | `KEEP-CONCEPT`; source directly from the project, not donor builds |
| `voxtype-bin` | Scriptlet rewrites `/usr/bin/voxtype` and `/usr/lib/voxtype` links | `DROP` by default; reconsider only at Gate 5 |
| `nvidia-580xx-utils` | Enables/disables NVIDIA sleep services | `DROP` for the audited AMD-only machine |
| `intel-ipu7-camera` | Writes a system-sleep hook and changes global services | `DROP` for the audited machine |
| `dell-xps-touchpad-haptics` | Writes `/etc` state, user config, udev state and services | `DROP` for the audited machine |
| `1password*` | Creates groups and setgid binaries/directories | Optional application, Gate 5 only |
| `nordvpn-bin` | Creates/removes global library symlinks | Optional application, Gate 5 only |
| `sunshine` | Reloads and triggers udev | Optional feature, Gate 5 only |
| `asusctl`, `once-bin`, `rustdesk` | Starts/reloads system services when applicable | Hardware/optional review at Gate 5 |
| `omarchy-keyring` | Populates pacman trust | `DROP`; Frost will use its own public key and bootstrap procedure |

No unknown privileged path remains in the audited core topology. Third-party packages are not approved by being inventoried: their selection and a fresh source/license/security review remain Gate 5 work.

## Dependency map

| Donor component | Depends on or controls | Frost action |
|---|---|---|
| Runtime command farm | Bash scripts, `gum`, `jq`, Hyprland tools, pacman helpers | `REWRITE`; expose only the small typed Frost CLI contract |
| Dynamic Quickshell shell | Plugin registry, manifests, external QML, shell-owned notifications/lock/Polkit | `PORT` visual/behavioral surfaces; `DROP` runtime plugin architecture and security ownership |
| Session setup | UWSM, Hyprland, SDDM, environment and user units | `KEEP-CONCEPT`; implement isolated Frost paths and target |
| Settings package | `/etc`, `/etc/skel`, user config, units, SDDM, boot defaults | `REWRITE`; split coexistable `frost` from privileged `frost-settings` |
| Pacman update flow | Guard hook, Git/channel update, AUR and migrations | `REWRITE`; allow direct pacman and require snapshot only in `frost update` |
| Boot and recovery | Btrfs, Snapper, Limine and two helper packages | `KEEP-CONCEPT`; depend on direct upstream/Arch sources and test rollback |
| Hardware install scripts | Broad multi-vendor package and config mutations | `DROP` except detected hardware requirements |
| ISO orchestrator | Archinstall, offline repo, target finalizers, recovery | `PORT` selectively in Phase 9 only |
| Local signed repository tooling | Build, sign and repo database workflow | `KEEP-CONCEPT`; new Frost implementation and key |
| Omarchy repository/mirror/channel endpoints | Donor operational infrastructure | `DROP` absolutely |

## Top-level classification

Classification values are the plan's `KEEP-CONCEPT`, `PORT`, `REWRITE`, and `DROP`. A whole directory marked `PORT` still requires file-by-file provenance before copying.

### Runtime donor: `omarchy`

| Area | Class | Reason |
|---|---|---|
| `.github` | `DROP` | Donor CI/release coupling |
| `agents` | `KEEP-CONCEPT` | Development procedures are reference material only |
| `applications` | `PORT` | Selected desktop files/icons only after package decisions |
| `bin` | `REWRITE` | Large shell command surface and donor namespace |
| `config` | `PORT` | Behavior/default reference; no blind copy into user config |
| `default` | `PORT` | Selected data/assets/unit patterns; rewrite privileged integration |
| `docs`, `manual`, `plans` | `KEEP-CONCEPT` | Operational knowledge, not product content |
| `etc` | `REWRITE` | Privileged global policy and ownership conflicts |
| `install` | `REWRITE` | Mutating installer logic and broad package selection |
| `migrations` | `KEEP-CONCEPT` | Preserve versioned/idempotent model, not scripts |
| `shell` | `PORT` | Static surfaces only; plugin runtime, lock, notifications and Polkit excluded |
| `test` | `PORT` | Relevant unit/integration/acceptance behavior |
| `themes` | `PORT` | Data-only assets after validation and provenance |

### Package donor: `omarchy-pkgs`

| Area | Class | Reason |
|---|---|---|
| `.github` | `DROP` | Donor release/publish infrastructure |
| `bin`, `build`, `helpers`, `systemd` | `KEEP-CONCEPT` | Learn local repository mechanics; rewrite for Frost |
| `pkgbuilds/omarchy*` | `REWRITE` | Establish Frost ownership and dependencies from scratch |
| `pkgbuilds/limine-*` | `KEEP-CONCEPT` | Recovery stack; source directly and audit upstream |
| all other `pkgbuilds` | `DROP` by default | Only enter Frost after Gate 5 selection and a fresh audit |

### ISO donor: `omarchy-iso`

| Area | Class | Reason |
|---|---|---|
| `.github` | `DROP` | Donor publishing infrastructure |
| `archiso` | `KEEP-CONCEPT` | Frozen upstream integration reference |
| `bin` | `REWRITE` | Donor names, remotes and live-system assumptions |
| `builder` | `PORT` | Offline mirror and package-build concepts, Phase 9 only |
| `configs` | `PORT` | Selected Archiso and orchestrator implementation, Phase 9 only |
| `manifests` | `KEEP-CONCEPT` | Test oracle and inventory evidence |
| `plans` | `KEEP-CONCEPT` | Historical design rationale |
| `test` | `PORT` | Relevant unit/integration/acceptance coverage |

### Frost authorities and historical Nix trees

| Source/area | Class | Reason |
|---|---|---|
| `staging/config/.../plugins` | `PORT` | Visual and functional authority, flattened into static composition |
| `staging/config/.../shell.json` and manifests as runtime | `DROP` | Dynamic registry/configuration is forbidden |
| `staging/scripts/check.sh`, `staging/tests` | `PORT` | Mature static and behavioral checks |
| `staging/scripts/deploy.sh` | `DROP` | Live Omarchy deployment is not a Frost install path |
| `Frost-OS/cli`, `shell`, `config`, `docs`, `assets` | `PORT` | Current architectural authority and Frost-owned work, subject to provenance |
| `Frost-OS/modules`, `packages`, `pkgs`, `lib` | `KEEP-CONCEPT` | Nix-specific implementation is not copied as the Arch runtime |
| `Frost-OS/flake.nix`, `.github` | `DROP` | Nix build/release infrastructure does not belong in Arch products |
| `omanix` | `KEEP-CONCEPT` | Historical architecture only; no publication until permission/license is resolved |
| `nixarchy` | `KEEP-CONCEPT` | Historical extraction patterns only; no direct code copy |
| `frosted-os` | `KEEP-CONCEPT` | Earlier sanitization and attribution evidence; not a source tree for wholesale copying |

Every principal top-level implementation area now has a classification. Hidden metadata, logos, READMEs, and license files are retained only as provenance/reference material and are never runtime inputs.

## External command inventory

The machine-readable inventory is `audit/generated/external-commands.tsv`. It covers literal process entrypoints and helper calls in `staging` and the recent `Frost-OS` implementation.

Important findings:

- Staging calls more than 30 donor-namespaced helpers. Each must be replaced by a Frost CLI method or a direct stable interface; no compatibility shim may survive.
- Staging contains a `bash -c` pipeline for clipboard copying. It is rejected; Frost will pass bytes to a fixed process or typed service without shell interpolation.
- Staging invokes `pkexec tailscale set --operator=...`. This must become a narrow reviewed privileged helper or remain unavailable; QML must not construct the privileged command.
- Direct stable user-session tools include `hyprctl`, `nmcli`, `tailscale`, `wl-copy`, `wl-paste`, `systemctl --user`, and `xkbcli`. Each surface must define exact argv schemas.
- Recent Frost code calls `qs` and `systemctl` from Rust and uses `hyprctl`/`fc-match` in the minimal shell. These are candidates, not automatically approved contracts.
- Power, reboot, shutdown, lock, package, DNS and hardware actions may not be launched from arbitrary QML strings.

## Preliminary package inventory

`audit/generated/preliminary-package-inventory.json` is a deterministic union of:

- the 148-entry donor base list;
- the 60-entry donor secondary/hardware list;
- the 15-entry ISO Archinstall list;
- all package recipe directory names in the frozen package donor;
- the fixed architectural dependencies named by the master plan;
- the packages installed on the audited machine on 2026-08-26.

Every record remains `UNCLASSIFIED` with default `review`. This is deliberate: Phase 0 records evidence but does not perform the package decision reserved for Gate 5.

## Audited machine facts

Read-only local probes recorded the following facts for later hardware filtering:

- x86_64, AMD Ryzen 7 5825U with integrated AMD Barcelo graphics;
- Realtek RTL8111/8168 Ethernet and RTL8852BE Wi-Fi;
- one ADATA NVMe device;
- LUKS container with Btrfs root subvolume `@`;
- vfat ESP mounted at `/boot`;
- zram swap;
- no NVIDIA, Intel IPU7, Apple T2, Surface, Dell XPS haptics, ASUS ROG, Framework 16, or Tuxedo-specific device was detected.

This evidence may remove irrelevant hardware paths from consideration later, but it does not authorize package removal before Gate 5.

## Gaps and decisions carried forward

- Publication is blocked because `Frost-OS`, `staging`, `omanix`, and `nixarchy` do not all carry sufficient standalone license evidence for every reusable file. See `provenance.md`.
- Exact third-party package licenses and upstream source integrity must be reviewed only for packages selected at Gate 5; inventory is not approval.
- The current donor runtime checkout and the stable package-pinned commit differ. Ports must name their exact source file and commit rather than saying only “Omarchy.”
- The Limine helper recipes are donor copies of external upstream projects. Frost must prefer direct upstream or official Arch packages and preserve their licenses.
- Graphical/session behavior cannot be validated in Phase 0 and is not claimed here.

## Gate 0 result

- [x] Source commits, cleanliness and remotes recorded.
- [x] `omarchy-pkgs` available as a frozen read-only reference.
- [x] Every principal directory classified.
- [x] Core package file ownership mapped exactly.
- [x] Every identified privileged path/effect has a package, scriptlet, installer or ISO owner.
- [x] Runtime/settings/keyring/ISO dependency topology mapped.
- [x] External commands used by `staging` and `Frost-OS` inventoried.
- [x] Initial threat boundaries and gaps recorded.
- [x] Preliminary package inventory produced without making package choices.
- [x] Donor worktrees remain clean.
- [x] Publication remains explicitly blocked pending provenance closure.

Gate 0 is closed for private implementation. Phase 1 may begin without using any donor as a build or runtime dependency.
