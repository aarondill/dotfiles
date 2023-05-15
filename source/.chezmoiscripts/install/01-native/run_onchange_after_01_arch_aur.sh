#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if [ -z "$PACMAN" ]; then
  exit 0 # Assume already knows
fi

aur_install() {
  local REPO=$1 tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  git clone "$REPO" "$tmpdir"
  cd "$tmpdir"
  (export -n SHELLOPTS && makepkg -sirc)
  cd -
  rm -rf "$tmpdir" && trap '' EXIT
}

# Zeal
if ! command -v zeal &>/dev/null; then
  # Dependancy that's no longer supplied by pacman
  pacman -U https://archive.archlinux.org/packages/q/qt5-webkit/qt5-webkit-5.212.0alpha4-18-x86_64.pkg.tar.zst
  aur_install "https://aur.archlinux.org/zeal.git"
else err "Zeal is already installed, skipping installation"; fi

# Google chrome
if ! command -v google-chrome-stable &>/dev/null; then
  aur_install "https://aur.archlinux.org/google-chrome.git"
else err "google-chrome is already installed, skipping installation"; fi

# spotify
if ! command -v spotify &>/dev/null; then
  aur_install "https://aur.archlinux.org/spotify.git"
else err "Spotify is already installed, skipping installation"; fi
