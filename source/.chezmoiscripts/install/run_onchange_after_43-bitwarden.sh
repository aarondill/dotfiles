#! /usr/bin/env bash
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

function install_bitwarden_cli() {
  declare temp_dir
  temp_dir=$(mktemp -d) && (
    # Executed in a subshell, so this will run on end of block
    trap 'rm -rf $temp_dir' EXIT
    set -e

    curl -sSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o "$temp_dir/bw.zip"
    unzip -qq "$temp_dir/bw.zip" -d "$temp_dir"
    sudo mv -f "$temp_dir/bw" /usr/local/bin/bw
    sudo chmod +x /usr/local/bin/bw
  )
}

# Ignore if already installed, updates itself
is_accessible_cmd bitwarden ||
  log_and_run "Installing bitwarden desktop" install_bitwarden_desktop

log_and_run "Installing bitwarden CLI" install_bitwarden_cli
