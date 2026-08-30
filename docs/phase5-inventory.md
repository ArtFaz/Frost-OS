# Phase 5 — package inventory and the Gate 5 decision

Phase 5 decides the system bundle before any pruning. Nothing is removed here.
The deliverables are an audited inventory, an offline selector that exports a
manifest, a resolver that turns that manifest into a reviewable plan, and the
human approval of the manifest (Gate 5). The graphical installer frontend was
dropped by decision on 2026-08-29; subsequent installs go through the terminal.

## Where the pieces live

| Piece | Path |
|---|---|
| Inventory | `frost-pkgs/tools/package-selector/inventory.json` |
| Selector | `frost-pkgs/tools/package-selector/{index.html,app.js,style.css}` |
| Standalone build | `frost-pkgs/tools/package-selector/build-standalone` → `package-selector.html` |
| Reconciliation aid | `frost-pkgs/tools/package-selector/build-inventory` (read-only) |
| Schemas | `frost-pkgs/tools/package-selector/schema/*.json` |
| Resolver | `frost/cli/src/packages.rs` — `frost packages validate|plan` |
| Inventory contract | `frost-pkgs/test/inventory-contract` |
| Selector contract | `frost-pkgs/test/selector-static` |
| Resolver contract | `frost/test/packages-contract` + `cargo test` (`packages::tests`) |

## Reconciliation

`inventory.json` (version `2026-08-29.4`, 286 packages) was built from:

- `Definitive Frost-OS/omarchy/install/omarchy-base.packages` — `0ae1694830b6`
- `Definitive Frost-OS/omarchy/install/omarchy-other.packages` — `0ae1694830b6`
- `Definitive Frost-OS/omarchy-iso/builder/archinstall.packages` — `268bac16d351`
- `frost-pkgs/pkgbuilds/frost/PKGBUILD` `depends()` — the executables the shell
  and CLI actually call
- the local `pacman` database, for installed size and comparison only

The donor lists are evidence, never a build input. Provenance is recorded in
`docs/provenance.md`, "Phase 5 package inventory", and in the file's own
`generatedFrom` field.

## Classification

Seven decision categories (`inventory.json` `.categories`): `BOOTSTRAP` `CORE`
`DESKTOP` `HARDWARE` `OPTIONAL` `DEVELOPMENT` `DROP`. Each package carries a
`source` (`arch|frost|aur`), a `default` (`required|recommended|optional`) and a
`reason`. Rules the contract enforces:

- AUR is barred from `BOOTSTRAP` and `CORE`.
- No `BOOTSTRAP`/`CORE` package may be `optional` — an essential package the user
  can silently drop is the Gate 5 failure mode.
- Every `feature` a package names is defined; every `dependsOn`/`conflictsWith`
  target and every profile/feature package list resolves to a real entry.

`DROP` records nine packages that came from the donor lists without a
justification Frost shares: `omarchy-keyring` (replaced by `frost-keyring`),
`omarchy-nvim`, `omacut`, `omacalc`, `omawrite`, `herdr`, `ttfx` (donor-authored),
`aether` (a second theming engine), `yay-debug` (debug symbols).

The terminal package browsers `pacsea-bin` and `parui`, with `paru` as their
backend, enter as `aur` `OPTIONAL` under the `aur` feature. The hardened AUR
build flow is Phase 6; Phase 5 only lists the tools.

### Editors, Spotify and the microcode fix (`2026-08-29.4`)

Added by request: `visual-studio-code-bin` and `zed` (both in the `development`
feature and the `this-machine` profile), `spotify-launcher` (the official Arch
launcher, in `this-machine`).

Fixed: a `hardware`-tagged package no longer rides a profile category, so
`intel-ucode` stops being pulled onto an AMD machine (and vice versa). Every
profile now lists the microcode it wants explicitly — `minimal`/`desktop`/
`developer` carry both, `this-machine` carries `amd-ucode`. The rule is in
`baseSelected` and `base_selected`, and the CLI now reads the `hardware` field.

### This-machine preset (`2026-08-29.3`)

A fourth profile, `this-machine`, seeded from `pacman -Qe` on the Vaio FE16
(Ryzen 5 5825U, all-AMD): the desktop set, the eight features actually in use
(`aur`, `bluetooth`, `development`, `gaming`, `input-method`,
`media-production`, `printing`, `tailscale`), the AMD graphics stack
(`vulkan-radeon`, `lib32-vulkan-radeon`, `bolt`, `ddcutil`,
`kernel-modules-hook`), and seven AUR apps carried over from Omarchy
(`brave-bin`, `vesktop-bin`, `anydesk-bin`, `parsec-bin`,
`beekeeper-studio-bin`, `jetbrains-toolbox`, `hyprmon-bin`). The inventory's
new `defaultProfile` field makes the selector open with it already applied, so
nothing has to be re-picked by hand. It is a starting point; the donor tools
(`omarchy-nvim`, `omacut`, …) stay `DROP`.

Fixed alongside: feature membership. A package listed in a feature's `packages`
is now pulled in when that feature is on, even if the package does not name the
feature in its own `feature` field. `base_selected` in `packages.rs` and
`baseSelected` in the selector were changed together and cross-checked to
resolve the same 216 packages for this profile.

### Compatibility pass (`2026-08-29.2`)

Frost is built for one machine but should install cleanly on others. This pass
added, with every name verified against the live pacman database:

- graphics: explicit `mesa` and `vulkan-icd-loader` in `CORE`; `vulkan-nouveau`,
  `vulkan-swrast`, `vulkan-virtio`, `lib32-mesa`/`lib32-vulkan-*` in `HARDWARE`;
  `libva-utils` and `vulkan-mesa-layers` in `DESKTOP`. (`mesa` now carries the
  AMD/Intel VA-API drivers itself, so no separate `libva-mesa-driver`.)
- base system: `sudo`, `xdg-desktop-portal`, `xdg-user-dirs`, `xdg-utils`,
  `fwupd`, `rsync`, `reflector`, `zram-generator`, `nvme-cli`, `alsa-ucm-conf`.
- laptop hardware (`HARDWARE`, off by default): `modemmanager`,
  `iio-sensor-proxy`, `fprintd`/`libfprint`, `sbctl`, `tlp`, `acpid`.
- new features: `virtualisation-guest` (QEMU/SPICE/VMware/VirtualBox guest
  agents), `scanning` (`sane`, `sane-airscan`).
- fonts: `ttf-liberation`, `ttf-dejavu`, `noto-fonts-extra`; plus `pavucontrol`,
  `ntfs-3g`, `smartmontools`, `wireguard-tools`.

## Resolver

`frost packages validate --inventory PATH MANIFEST` checks an exported
`frost-packages.json` against the inventory: schema shape, matching
`inventoryVersion`, bare package names only (no executable content), names known
to the inventory, no `include`/`exclude` overlap, no `DROP` in `include`, and no
non-AUR name in `aur[]`. Exit `2` on any problem.

`frost packages plan --inventory PATH MANIFEST [--donor-base PATH] [--lockfile PATH]`
resolves the manifest with the same base-membership logic as the selector and
prints: features on, the resolved list, auto-added dependencies, excludes kept
because required, the install/remove diff against the live system, the diff
against the donor base list, the AUR selections, and the risks. It never calls
pacman to change anything and never runs a recipe. With `--lockfile` it writes
`aur.lock.json` pinning each AUR selection's `pkgbase` and, via `git ls-remote`,
its current commit — the recipe is still never fetched or executed.

## Gate 5

Not yet closed. Gate 5 closes when:

- [ ] `frost-packages.json` is exported and `frost packages validate` passes;
- [ ] every exclusion has a known effect (the `plan` output explains each);
- [ ] no essential package was dropped by accident; real hardware stays supported;
- [ ] optional features are coherent with the shell components;
- [ ] each AUR selection is explicit in the JSON with a resolvable pkgbase;
- [ ] the user approves the manifest explicitly.

Only after that may `frost-meta` be generated or changed (Phase 6).

### Record

_(to be filled when Gate 5 closes: manifest hash, plan summary, approval)_
