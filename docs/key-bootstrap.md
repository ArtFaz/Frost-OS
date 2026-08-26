# Frost local repository key bootstrap

The Frost v1 repository is local and signed. The private signing key never enters Git, a package, the repository directory, or an ISO. Only the exported public keyring files belong under `pkgbuilds/frost-keyring`.

## Active private trust root

- Identity: `Frost Local Repository <packages@frost.local>`
- Full fingerprint: `9F8D 6316 5ACC 27A4 FDCC ED02 FD40 A388 11ED D104`
- Algorithm/capability: Ed25519 signing key
- Created: 2026-08-26
- Expires: 2028-08-25
- Private GnuPG home: `~/.local/share/frost/repository-gnupg`, mode `0700`
- Protection: no passphrase, so local builds can sign non-interactively

The lack of a passphrase makes filesystem and backup access control essential. Back up the dedicated GnuPG home to encrypted offline storage before the machine trusts Frost packages for daily operation. The automatically generated revocation certificate is inside that private home and must be included in the backup.

Only these public files are tracked:

- `pkgbuilds/frost-keyring/frost.gpg`
- `pkgbuilds/frost-keyring/frost-trusted`
- `pkgbuilds/frost-keyring/frost-revoked`

## Build and verify

With the dedicated `GNUPGHOME` and full fingerprint:

```bash
export GNUPGHOME="$HOME/.local/share/frost/repository-gnupg"
./tools/build-local-repo --key FINGERPRINT
```

The tool builds from the committed sibling Frost repository, signs every package and the repository database, and verifies the detached signatures. It never downloads a donor source.

## Initial trust bootstrap

Before `frost-keyring` can maintain pacman trust, manually verify the public fingerprint and the package signature using the dedicated GnuPG home. Installing the first keyring package or modifying pacman configuration is a live privileged action and requires separate approval. Subsequent keyring upgrades are verified through the already-installed Frost trust root.

An independent public-key-only check is:

```bash
gpgv --keyring pkgbuilds/frost-keyring/frost.gpg PACKAGE.sig PACKAGE
gpgv --keyring pkgbuilds/frost-keyring/frost.gpg frost.db.tar.gz.sig frost.db.tar.gz
```
