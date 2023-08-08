#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

REPO_URL='https://github.com/eza-community/eza'

install_eza() {
  cargo install --all-features --git -- "$REPO_URL"
}

if has_cmd cargo; then # only with cargo installed
  log_and_run "Installing cargo using rustup" install_cargo
fi
