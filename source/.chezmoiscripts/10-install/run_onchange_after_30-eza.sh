#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

install_eza() {
  # REPO_URL='https://github.com/eza-community/eza'
  # cargo install --all-features --git "$REPO_URL"
  cargo install --all-features eza
}

if has_cmd eza; then
  log "eza is already installed"
  return 0
fi
if ! has_cmd cargo; then
  err "cargo isn't available! Can't install eza!"
  return 1
fi
log_and_run "Installing eza" install_eza
