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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
git clone "$REPO" "$tmpdir"
cd "$tmpdir"
makepkg -sirc
rm -rf "$tmpdir" && trap '' EXIT
