# Third-party material

No donor PKGBUILD has been copied into this repository. Frost recipes are new implementations informed by the ownership audit in the sibling `frost` repository.

Every future third-party package must identify its direct upstream, pinned source, checksums, license, and reason for inclusion. Inclusion remains subject to the Gate 5 package decision.

## Package selector

`tools/package-selector/inventory.json` reconciles the donor package lists (`omarchy` `0ae1694830b6`, `omarchy-iso` `268bac16d351`) and the `frost` package's own dependencies. The donor lists are evidence only; no donor file is copied. The reconciliation and classification are Frost-authored. See `frost/docs/provenance.md`, "Phase 5 package inventory". The AUR entries (`paru`, `pacsea-bin`, `parui`) and every other third-party selection still owe an upstream-license audit before any publication.
