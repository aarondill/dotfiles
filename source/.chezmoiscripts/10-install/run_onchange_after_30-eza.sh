#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"
! has_cmd eza || exit 0

install_eza() {
  # REPO_URL='https://github.com/eza-community/eza'
  # cargo install --all-features --git "$REPO_URL"
  cargo install --all-features eza
}

if has_pacman; then
  pacman_install eza
else
  if ! has_cmd cargo; then
    err "cargo isn't available! Can't install eza!"
    exit 1
  fi
  log_and_run "Installing eza" install_eza
fi
