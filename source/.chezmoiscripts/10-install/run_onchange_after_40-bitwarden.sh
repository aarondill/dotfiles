#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_bitwarden_desktop() {
  declare DESTINATION=/usr/local/bin/bitwarden
  download_file 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=appimage' "$DESTINATION" "+x"
}

if has_pacman; then
  pacman_install 'bitwarden'
else
  log_and_run "Installing bitwarden desktop" install_bitwarden_desktop
fi
