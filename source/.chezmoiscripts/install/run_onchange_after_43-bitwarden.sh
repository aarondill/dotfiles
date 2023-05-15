#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_bitwarden_desktop() {
  declare DESTINATION=/usr/local/bin/bitwarden
  sudo curl -sSL 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=appimage' -o "$DESTINATION"
  sudo chown root "$DESTINATION"
  sudo chmod +x "$DESTINATION"
}

function install_bitwarden_cli() (
  local DESTINATION=/usr/local/bin/bw temp_dir
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT
  curl -sSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o "$temp_dir/bw.zip"
  unzip -qq "$temp_dir/bw.zip" -d "$temp_dir"
  sudo mv -f "$temp_dir/bw" "$DESTINATION"
  sudo chmod +x "$DESTINATION"
  rm -rf "$temp_dir" && trap '' EXIT # cleanup
)

# Ignore if already installed, updates itself
if ! is_accessible_cmd bitwarden; then
  log_and_run "Installing bitwarden desktop" install_bitwarden_desktop
fi

if ! is_accessible_cmd unzip; then
  abort "unzip is required to install bitwarden cli" 2
fi

log_and_run "Installing bitwarden CLI" install_bitwarden_cli
