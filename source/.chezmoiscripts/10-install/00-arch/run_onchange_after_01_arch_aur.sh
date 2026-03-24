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
  local deps=(git base-devel)
  pacman_is_installed "${deps[@]}" || pacman_install "${deps[@]}"
}

aur_install() {
  pacman_install_aur_deps # should already be installed if yay is.
  local cmd=yay_install
  has_cmd yay || cmd=aur_install_makepkg
  local p && for p; do "$cmd" "$p"; done
}

aur_install_makepkg() {
  local tmpdir REPO="https://aur.archlinux.org/$1.git"
  tmpdir="$(mktemp -d)" && rm_exit "$tmpdir"
  git_clone "$REPO" "$tmpdir"
  (cd "$tmpdir" && export -n SHELLOPTS && makepkg -sirc)
  rm_exit_cleanup "$tmpdir"
}

# Note: this should be done before installing other packages
if ! has_cmd yay; then
  aur_install yay-bin
  yay -Y --gendb # Check the cache on first install
fi

packages=(
  # google-chrome      # Replaced with vivaldi
  consolation                    # cursor in tty
  dashbinsh                      # Use dash as /bin/sh
  downgrade                      # downgrades packages
  informant                      # arch news through pacman
  isomaster                      # unpack/edit .isos
  ripdrag-git                    # Drag and drop from terminal
  simplescreenrecorder           # screen recording
  yaru-gtk-theme yaru-icon-theme # Yaru themeing
)
for p in "${packages[@]}"; do
  ! pacman_is_installed "$p" || continue
  aur_install "$p"
done

if pacman_is_installed "consolation"; then
  sudo_cmd systemctl enable consolation.service # This is not enabled by default
fi
