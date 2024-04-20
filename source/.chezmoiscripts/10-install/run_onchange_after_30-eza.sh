#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

install_eza() {
  # eza is in extra repo on arch
  if has_pacman; then
    pacman_install eza
  elif has_cmd cargo; then
    # REPO_URL='https://github.com/eza-community/eza'
    # cargo install --all-features --git "$REPO_URL"
    cargo install --all-features eza
  else
    err "Neither pacman nor cargo are available! Can't install eza!"
  fi
}

log_and_run "Installing eza" install_eza
