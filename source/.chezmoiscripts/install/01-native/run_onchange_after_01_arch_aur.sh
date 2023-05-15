#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

REPO=https://aur.archlinux.org/zeal.git

# Defined in utils.sh
if [ -z "$PACMAN" ]; then
  exit 0 # Assume already knows
elif command -v zeal &>/dev/null; then
  abort 'Zeal is already installed' 0
fi

# Dependancy that's no longer supplied by pacman
pacman -U https://archive.archlinux.org/packages/q/qt5-webkit/qt5-webkit-5.212.0alpha4-18-x86_64.pkg.tar.zst

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
git clone "$REPO" "$tmpdir"
cd "$tmpdir"
(export -n SHELLOPTS && makepkg -sirc)
rm -rf "$tmpdir" && trap '' EXIT
