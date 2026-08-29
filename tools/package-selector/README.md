# Package selector

An offline, single-purpose tool for one human decision: **what does the Frost
system ship?** It imports and exports JSON and does nothing else — no pacman, no
network, no telemetry, no PKGBUILD.

## Files

| File | Purpose |
|---|---|
| `inventory.json` | Audited data source. Hand-curated and version-controlled. |
| `schema/inventory.schema.json` | Human reference for the inventory shape. `test/inventory-contract` is what a machine enforces. |
| `schema/frost-packages.schema.json` | Shape of the exported manifest (`frost-packages.json`). Mirrored by `frost packages validate`. |
| `index.html`, `app.js`, `style.css` | The selector UI. Open `index.html` directly in a browser. |
| `build-standalone` | Writes `package-selector.html` with the inventory inlined, for use with no checkout. |
| `build-inventory` | Read-only reconciliation aid. Prints draft records to classify; never writes the inventory. |

## Flow

```
index.html  --export-->  frost-packages.json  --frost packages validate-->  frost packages plan
                                                                                     |
                                                          reviewable plan + aur.lock.json + diff
                                                                                     |
                                                                          human approval (Gate 5)
                                                                                     |
                                                             frost-meta manifest  (Phase 6, not here)
```

## Categories

`BOOTSTRAP` boot, kernel, filesystem, pacman, install · `CORE` session, audio,
network, security, recovery · `DESKTOP` the default application experience ·
`HARDWARE` drivers and workarounds, gated by detected hardware · `OPTIONAL`
useful but not needed · `DEVELOPMENT` languages and dev tooling · `DROP`
explicitly rejected, with a reason.

AUR is allowed for `DESKTOP`/`HARDWARE`/`OPTIONAL`/`DEVELOPMENT` only, never for
`BOOTSTRAP` or `CORE`. Essential items (`required`) are locked in the UI and
explain why; changing one means editing and re-reviewing the inventory.

## Updating the inventory

1. `./build-inventory > /tmp/draft.json` to see what the donor lists and the
   local system currently hold.
2. Edit `inventory.json` by hand. Bump `inventoryVersion` (`YYYY-MM-DD.N`).
3. `../../test/inventory-contract` must pass.
