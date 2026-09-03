# Third-party material

The Frost Island is substantially adapted from DynamicGlacier commit `70824af6350927c429ed57fb83d89ed843e6cd84`, copyright 2026 mavxa, under the MIT License. The preserved notice is in `docs/licenses/DynamicGlacier-MIT.txt` and every derived QML destination is recorded in `docs/provenance/ports.json`.

Earlier Phase 3 shell files were original rewrites from frozen architectural or visual concepts; their per-file records remain stored in `docs/provenance/ports.json`.

`default/bash/inputrc` and the tool-integration lines in `default/bash/bashrc` (the eza, zoxide, fzf and bat blocks) are Frost-authored, written against the behaviour of the Omarchy reference bash configuration (MIT). The readline `set`/binding directives an inputrc contains are configuration facts, not copied code; the selection and wording are Frost's.

The Phase 0 donor and provenance audit is stored under `docs/`. Any future port must add a per-file ledger entry and preserve the applicable notice before the implementation enters this repository.

Publication remains blocked while the gaps in `docs/provenance.md` are open.
