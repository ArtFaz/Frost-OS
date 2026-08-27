# Frost provenance and publication status

Status: sufficient for the currently authorized private implementation; insufficient for publication.

## Rules

- Every port must record the exact source repository, commit, original path, Frost destination, transformation type, and applicable license/permission.
- A directory-level statement is not enough for copied or substantially adapted code.
- Donor Git histories are never reused as Frost histories.
- Donor remotes and paths are evidence only and are forbidden as Frost build/runtime inputs.
- Copyright notices and license texts must remain with copied or substantially adapted third-party material.
- Absence of a license file is not interpreted as permission to redistribute.
- The private permission recorded by earlier Frost work does not assert public redistribution rights.

## Source ledger

| Source | Audited commit/state | Declared or observed license | Authorized use now | Publication status |
|---|---|---|---|---|
| `Definitive Frost-OS/omarchy` | `0ae1694830b6` | MIT, copyright David Heinemeier Hansson | Reference and selective MIT-licensed ports with notice | Allowed only for traced files with preserved MIT notice |
| Omarchy stable source used by donor PKGBUILDs | `13f18b2cb7286fb54f87daf571a031aa6af3d8f0`, tag `v4.0.1` | MIT | Reference and selective traced ports | Allowed only for traced files with preserved MIT notice |
| `Definitive Frost-OS/omarchy-pkgs` | `5a73fd899940` | Repository MIT; individual built software has its own licenses | Packaging/ownership reference | Recipe reuse requires trace; built packages require upstream review |
| `Definitive Frost-OS/omarchy-iso` | `268bac16d351` | MIT, copyright Anton Hvornum | Installer/test reference; Phase 9 selective ports | Allowed only for traced files with preserved MIT notice |
| `staging` | `824831e75171` | No standalone license file found | Private functional/visual authority | Blocked until ownership and donor-derived file notices are resolved |
| `Frost-OS` | `f4a8cc9cd413` | No root license file found; `docs/attribution.md` records private donor permission | Private architectural authority and Frost-owned ports | Blocked until file ownership and redistribution rights are resolved |
| `omanix` | `4af5e88b6346` | No standalone license file found; private permission recorded in Frost docs | Private architectural reference | Blocked |
| `nixarchy` | `74802f4aa707` | README reportedly describes MIT packaging, but no standalone license file exists | Architectural reference only | Blocked for copied code |
| `frosted-os` | filesystem snapshot | Root MIT license for ArtFaz plus a third-party notice for selected Omarchy files | Attribution/reference evidence | Does not cure missing provenance in other trees |

## Known reusable sets

| Intended Frost set | Authority | Current decision | Required record before commit |
|---|---|---|---|
| Rust CLI foundation | `Frost-OS/cli` | Selective port or rewrite | Establish Frost ownership and note Omanix-derived portions file by file |
| Static shell primitives and minimal bar/OSD | `Frost-OS/shell` | Selective port | Record which files are Frost-owned versus adapted; exclude plugin runtime |
| Full Frosted Glass surfaces | `staging/config/omarchy/plugins/art.*` | Selective static port | Trace each destination to staging path and any `manifest.json` `clonedFrom` donor lineage |
| SDDM/greeter patterns | Omarchy and earlier `frosted-os` extraction | Rewrite or selectively port | Preserve the Omarchy MIT text for adapted source/assets |
| Session and service architecture | `Frost-OS` plus donor concepts | Rewrite | Architecture facts do not require copying code; record any copied fragments |
| Arch packaging and ISO | Omarchy package/ISO donors | Rewrite/port selectively | Preserve relevant MIT notices and upstream package licenses |
| Themes and assets | Staging/Omarchy/Frost trees | Data-only selective port | Verify creator/license per asset; no executable or symlink content |

## Per-file port ledger schema

The active machine-readable ledger is `docs/provenance/ports.json`. The Phase 3 entries point only to the frozen `Frost-OS` and `staging` commits recorded above and classify every QML/JavaScript implementation file as a private `rewritten-from-concept` port. The test suite rejects unfrozen commits, missing destinations, duplicate destinations and unledgered shell implementation files.

Phase 1 creates `THIRD_PARTY.md` and a machine-readable ledger using these fields:

```json
{
  "destination": "shell/Commons/Color.qml",
  "originRepository": "Frost-OS",
  "originCommit": "f4a8cc9cd413...",
  "originPath": "shell/Commons/Color.qml",
  "transformation": "adapted",
  "license": "pending-confirmation",
  "notice": "docs/licenses/..."
}
```

Allowed transformation values are `original`, `adapted`, `rewritten-from-concept`, and `generated`. `rewritten-from-concept` means no copyrightable implementation was copied; it still records why the design exists.

## Publication blockers

1. Confirm the copyright ownership and redistribution license of every reused file from `Frost-OS` and `staging`.
2. Resolve the Omanix permission into a publication-compatible written license before any Omanix-derived implementation is published.
3. Do not copy Nixarchy code based solely on a README license statement; obtain the authoritative license or rewrite from generic concepts.
4. Audit each selected third-party package's upstream license and redistribution terms after Gate 5.
5. Audit every wallpaper, icon, font, sound and other binary asset independently.

Private development may proceed because it is the explicitly authorized scope. No repository push, public release, package publication, ISO distribution, or public mirror is authorized by this record.
