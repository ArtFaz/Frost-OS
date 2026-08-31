# frost-wallpapers

Optional package carrying the theme wallpapers installed under
`/usr/share/frost/backgrounds/<theme>/`. The runtime reads that tree through
`frost shell-data wallpapers` and sets a selection with
`frost shell-action wallpaper-set`.

## Why publication is blocked

`docs/provenance.md` publication blocker 5 requires every wallpaper, icon, font
and sound to be audited independently before redistribution. The donor trees
carry the images with no per-asset licence record, so distributing them would
create redistribution debt on binary assets that nobody has cleared — the one
category of debt the project has never taken on.

Installing them on the machine of the person who already has the donor checkout
is not distribution, so the images are carried for private use and the package
is not published. Clearing an image means establishing its creator and terms,
then flipping its `redistribution` field to `cleared`.

## Status

The images are present, for private use only. They were copied verbatim from the
frozen Omarchy donor checkout, and `docs/provenance/wallpapers.json` in the
runtime repository records for each file its origin repository, frozen commit,
origin path and SHA-256, with `license: unresolved` and `redistribution:
blocked`. The `provenance-contract` enforces the bijection, so an image cannot
enter the tree without a record and a record cannot outlive its image.

The donor-branded wallpaper shipped in most donor themes is excluded. Frost is
an independent desktop and does not carry another project's branding.

Publication of this package remains blocked. That is a redistribution limit, not
a usage limit: nothing prevents the owner of the machine from installing it.
