#!/bin/bash
# Install Frost on a fresh CachyOS Minimal.
#
# While the repository is private, clone it with credentials and run this from
# the clone — raw.githubusercontent.com serves nothing without a token:
#
#   gh auth login
#   git clone https://github.com/ArtFaz/Frost-OS.git frost && ./frost/install.sh
#
# Once it is public, the same thing is one command:
#
#   curl -fsSL https://raw.githubusercontent.com/ArtFaz/Frost-OS/main/install.sh | bash
#
# It clones the repository, builds the Frost packages on this machine and hands
# off to packaging/install/bootstrap-cachyos, which does the actual install. The
# clone it leaves behind is the source tree: build new packages from it.
#
# Re-running this is the update path — it pulls, rebuilds and re-runs the
# bootstrap, all of which are idempotent.
#
# Nothing here needs a signing key or a prebuilt artifact. The Frost CLI has no
# crate dependencies, so it compiles anywhere rust is installed.

set -euo pipefail
export LC_ALL=C

readonly REPO_URL=${FROST_REPO_URL:-https://github.com/ArtFaz/Frost-OS.git}
readonly SRC=${FROST_SRC:-$HOME/frost}
readonly BUILD_DEPS=(base-devel git rust)

dry_run=0
case ${1:-} in
  --dry-run) dry_run=1 ;;
  -h | --help) sed -n '2,18p' "${BASH_SOURCE[0]}"; exit 0 ;;
  '') ;;
  *) printf 'usage: install.sh [--dry-run]\n' >&2; exit 2 ;;
esac

step() { printf '\n== %s\n' "$1"; }
note() { printf '   %s\n' "$1"; }
die() { printf 'install: %s\n' "$1" >&2; exit 1; }

run() {
  if ((dry_run)); then
    printf '   would run: %s\n' "$*"
    return 0
  fi
  "$@"
}

if [[ $EUID -eq 0 ]]; then
  die 'run this as your own user, not root — it uses sudo only where it must'
fi

step 'checking this machine'
command -v pacman >/dev/null || die 'this is not an Arch or CachyOS system'
command -v pacman-conf >/dev/null || die 'pacman-conf not found'
[[ $(uname -m) == x86_64 ]] || die "Frost is x86_64 only (this is $(uname -m))"
pacman-conf --repo-list | grep -qx multilib \
  || die 'the [multilib] repository is disabled — enable it in /etc/pacman.conf, then run this again'
note "$(. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-unknown}"), $(uname -m), multilib on"

step 'installing what the build needs'
run sudo pacman -S --needed --noconfirm "${BUILD_DEPS[@]}"

# Run from a checkout, use that checkout. Piped from curl, there is none, so the
# repository is cloned to $SRC.
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || printf '')
if [[ -n $here && -f $here/packaging/install/bootstrap-cachyos ]]; then
  src=$here
  step "using the checkout at $src"
else
  src=$SRC
  step "getting the source into $src"
  if [[ -d $src/.git ]]; then
    run git -C "$src" pull --ff-only
    note 'updated an existing clone'
  else
    run git clone "$REPO_URL" "$src"
    note 'cloned'
  fi
fi

step 'building the Frost packages here'
note 'the CLI has no dependencies, so this is a short compile'
run "$src/packaging/tools/build-local-repo"

step 'installing'
staging=$(mktemp -d)
trap 'rm -rf -- "$staging"' EXIT
run "$src/packaging/tools/build-install-bundle" --stage "$staging/frost-install-bundle"
run sudo "$staging/frost-install-bundle/bootstrap-cachyos"

step 'done'
note "the source is at $src — rebuild any time with packaging/tools/build-local-repo"
note 'reboot into Frost'
