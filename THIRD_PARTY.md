# Third-party material

The Frost Island is substantially adapted from DynamicGlacier commit `70824af6350927c429ed57fb83d89ed843e6cd84`, copyright 2026 mavxa, under the MIT License. The preserved notice is in `docs/licenses/DynamicGlacier-MIT.txt` and every derived QML destination is recorded in `docs/provenance/ports.json`.

Earlier Phase 3 shell files were original rewrites from frozen architectural or visual concepts; their per-file records remain stored in `docs/provenance/ports.json`.

`default/bash/inputrc` and the tool-integration lines in `default/bash/bashrc` (the `PATH`, mise, eza, zoxide, fzf, bat and less blocks) are Frost-authored, written against the behaviour of the Omarchy reference bash configuration (MIT). The readline `set`/binding directives an inputrc contains, and the environment variables these blocks set, are configuration facts, not copied code; the selection and wording are Frost's.

`default/starship/starship.toml` is original Frost work — authored from scratch in Frost's idiom, with no Omarchy or other reference config consulted.

The Phase 0 donor and provenance audit is stored under `docs/`. Any future port must add a per-file ledger entry and preserve the applicable notice before the implementation enters this repository.

Publication remains blocked while the gaps in `docs/provenance.md` are open.
