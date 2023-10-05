#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

REPO_URL='https://github.com/eza-community/eza'

install_eza() {
  run_own_shell cargo install --all-features --git "$REPO_URL"
}

# if has_pacman; then # eza is in extra repo on arch
#   log_and_run "Installing eza using pacman" pacman -S eza
if has_cmd cargo; then # only with cargo installed
  log_and_run "Installing eza using cargo" install_eza
fi
