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

function install_bitwarden_cli() (
  local DESTINATION=/usr/local/bin/bw temp_dir
  # shellcheck disable=SC2206 # ik it splits. that's the point
  local zip_file
  zip_file=$(download_file 'https://vault.bitwarden.com/download/?app=cli&platform=linux')
  rm_exit "$zip_file"
  temp_dir=$(mktemp -d)
  rm_exit "$temp_dir"
  unzip -qq "$zip_file" -d "$temp_dir"
  sudo_cmd mkdir -p "$(dirname "$DESTINATION")"
  sudo_cmd install "$temp_dir/bw" "$DESTINATION"
  sudo_cmd chmod +x "$DESTINATION"
  rm_exit_cleanup "$temp_dir"
)

## Ignore if already installed, updates itself -- not when permissions don't work for it.
# if ! has_cmd bitwarden; then
log_and_run "Installing bitwarden desktop" install_bitwarden_desktop
# fi

if ! has_cmd unzip; then
  abort "unzip is required to install bitwarden cli" 2
fi

log_and_run "Installing bitwarden CLI" install_bitwarden_cli
