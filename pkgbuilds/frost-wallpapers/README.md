# frost-wallpapers

Optional package carrying the theme wallpapers installed under
`/usr/share/frost/backgrounds/<theme>/`. The runtime reads that tree through
`frost shell-data wallpapers` and sets a selection with
`frost shell-action wallpaper-set`.

## Why this package ships no images yet

`docs/provenance.md` publication blocker 5 requires every wallpaper, icon, font
and sound to be audited independently before redistribution. The donor trees
carry roughly 96 images with no per-asset licence record, so copying them here
would create redistribution debt on binary assets that nobody has cleared — the
one category of debt the project has never taken on.

The mechanism is complete and the package builds; populating it is a matter of
dropping cleared images into `backgrounds/<theme>/` in the runtime repository
and adding the per-asset records. Until then a user points the picker at their
own files, which need no clearance because they are never redistributed.
