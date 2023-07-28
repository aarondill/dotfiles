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

pacman_install_aur_deps() {
  # check first to avoid message every time
  if ! pacman -Q 'git' || ! pacman -Q 'base-devel'; then
    pacman -S --needed git base-devel
  fi
}

aur_install() {
  # shellcheck disable=SC2155 # assign and declare seperately
  local YAY="$(which yay 2>/dev/null || printf '')"
  local tmpdir REPO="https://aur.archlinux.org/$1.git"
  if [ -n "$YAY" ]; then
    (export -n SHELLOPTS && "$YAY" -S --needed -- "$1")
    return
  fi
  pacman_install_aur_deps
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  git clone "$REPO" "$tmpdir"
  cd "$tmpdir"
  (export -n SHELLOPTS && makepkg -sirc)
  cd -
  rm -rf "$tmpdir" && trap '' EXIT
}

if ! which yay &>/dev/null; then
  aur_install yay-bin
  yay -Y --gendb # Check the cache on first install
else err "yay is already installed, skipping installation"; fi

## Zeal -- I don't like the qt5-webkit package. It's too big.
# if ! which zeal &>/dev/null; then
#   # Dependancy that's no longer supplied by pacman
#   sudo pacman -U https://archive.archlinux.org/packages/q/qt5-webkit/qt5-webkit-5.212.0alpha4-18-x86_64.pkg.tar.zst
#   aur_install "zeal"
# else err "Zeal is already installed, skipping installation"; fi

# Google chrome
if ! which google-chrome-stable &>/dev/null; then
  aur_install "google-chrome"
else err "google-chrome is already installed, skipping installation"; fi

# grub-editor
if ! [ -x /opt/grub-editor/grub-editor.py ]; then
  aur_install "grub-editor"
else err "grub-editor is already installed, skipping installation"; fi

# informant for pacman/yay
if ! which informant &>/dev/null; then
  aur_install "informant"
else err "informant is already installed, skipping installation"; fi

# consolation for a cursor in the tty!
if ! which consolation &>/dev/null; then
  aur_install "consolation"
else err "consolation is already installed, skipping installation"; fi
