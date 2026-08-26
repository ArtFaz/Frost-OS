# Frost local repository key bootstrap

The Frost v1 repository is local and signed. The private signing key never enters Git, a package, the repository directory, or an ISO. Only the exported public keyring files belong under `pkgbuilds/frost-keyring`.

Creating the real key is a gated action. Do not run the commands below until the owner explicitly authorizes key creation and chooses the identity and expiration.

## Proposed private-key location

Use a dedicated GnuPG home outside both repositories, for example `~/.local/share/frost/repository-gnupg`, mode `0700`. Back it up separately and never point build logs at its private material.

## Proposed creation and export flow

```bash
export GNUPGHOME="$HOME/.local/share/frost/repository-gnupg"
install -d -m 0700 "$GNUPGHOME"
gpg --quick-generate-key 'Frost Local Repository <packages@frost.local>' ed25519 sign 2y
gpg --list-secret-keys --with-colons
gpg --export FINGERPRINT > pkgbuilds/frost-keyring/frost.gpg
printf '%s:4:\n' FINGERPRINT > pkgbuilds/frost-keyring/frost-trusted
: > pkgbuilds/frost-keyring/frost-revoked
```

The final identity, expiration and fingerprint must be recorded in the master plan after approval. The private key must be backed up before any live system trusts it.

## Build and verify

With the same dedicated `GNUPGHOME` and the approved full fingerprint:

```bash
./tools/build-local-repo --key FINGERPRINT
```

The tool builds from the committed sibling Frost repository, signs every package and the repository database, and verifies the detached signatures. It never downloads a donor source.

## Initial trust bootstrap

Before `frost-keyring` can maintain pacman trust, manually verify the public fingerprint and the package signature using the dedicated GnuPG home. Installing the first keyring package or modifying pacman configuration is a live privileged action and requires separate approval. Subsequent keyring upgrades are verified through the already-installed Frost trust root.

