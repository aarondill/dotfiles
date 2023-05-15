#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if ! is_accessible_cmd apt; then
  abort0 "Apt not installed, skipping ppa setup"
fi

function setup_ppa_spotify() {
  sudo -v
  curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
}
function setup_ppa_vscode() {
  sudo -v
  curl -sS https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
}
function setup_ppa_google-chrome() {
  sudo -v
  curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/google-chrome.gpg
  echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
}

# Run setup_ppa_* first!
function install_proprietary_software() {
  sudo "$APT" update >/dev/null
  sudo "$APT" install -y -- "$@"
  sudo "$APT" install -f
}

# Should already be installed, sanity check
is_accessible_cmd gpg curl
log_and_run 'installing spotify ppa' setup_ppa_spotify
log_and_run 'installing vscode ppa' setup_ppa_vscode
log_and_run 'installing google chrome ppa' setup_ppa_google-chrome
log_and_run 'installing proprietary packages' install_proprietary_software spotify-client code google-chrome-stable
