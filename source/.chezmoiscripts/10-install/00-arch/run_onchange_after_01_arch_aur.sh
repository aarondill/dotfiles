#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if ! has_pacman; then
  exit 0 # Assume already knows
fi

pacman_install_aur_deps() {
  # check first to avoid message every time
  if ! pacman_is_installed git base-devl; then pacman_install git base-devel; fi
}

aur_install() {
  if has_cmd yay; then
    yay_install "$1"
  else
    pacman_install_aur_deps # should already be installed if yay is.
    aur_install_makepkg "$1"
  fi
}

aur_install_makepkg() {
  local tmpdir REPO="https://aur.archlinux.org/$1.git"
  tmpdir="$(mktemp -d)"
  rm_exit "$tmpdir"
  git_clone "$REPO" "$tmpdir"
  pushd "$tmpdir" >/dev/null
  (export -n SHELLOPTS && makepkg -sirc)
  popd >/dev/null
  rm_exit_cleanup "$tmpdir"
}

if ! has_cmd yay; then
  aur_install yay-bin
  yay -Y --gendb # Check the cache on first install
else err "yay is already installed, skipping installation"; fi

## Zeal -- I don't like the qt5-webkit package. It's too big.
# if ! has_cmd zeal; then
#   # Dependancy that's no longer supplied by pacman
#   sudo_cmd pacman -U https://archive.archlinux.org/packages/q/qt5-webkit/qt5-webkit-5.212.0alpha4-18-x86_64.pkg.tar.zst
#   aur_install "zeal"
# else err "Zeal is already installed, skipping installation"; fi

## Google chrome -- Replaced with vivaldi
# if ! has_cmd google-chrome-stable; then
#   aur_install "google-chrome"
# else err "google-chrome is already installed, skipping installation"; fi

# grub-editor
if ! [ -x /opt/grub-editor/grub-editor.py ]; then
  aur_install "grub-editor"
else err "grub-editor is already installed, skipping installation"; fi

# informant for pacman/yay
if ! has_cmd informant; then
  aur_install "informant"
else err "informant is already installed, skipping installation"; fi

# consolation for a cursor in the tty!
if ! has_cmd consolation; then
  aur_install "consolation"
  sudo_cmd systemctl enable consolation.service # This is not enabled by default
else err "consolation is already installed, skipping installation"; fi
