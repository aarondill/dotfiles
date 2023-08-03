#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if ! has_apt; then
  abort "Apt not installed, skipping ppa setup" 0
fi

function setup_ppa_spotify() {
  sudo -v
  sudo mkdir -p /etc/apt/trusted.gpg.d/
  download https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  sudo mkdir -p /etc/apt/sources.list.d
  printf '%s\n' "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
}
function setup_ppa_vscode() {
  sudo -v
  sudo mkdir -p /etc/apt/keyrings
  download https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
  sudo mkdir -p /etc/apt/sources.list.d
  printf '%s\n' "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
}
function setup_ppa_google-chrome() {
  sudo -v
  sudo mkdir -p /etc/apt/trusted.gpg.d/
  download https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/google-chrome.gpg
  sudo mkdir -p /etc/apt/sources.list.d
  printf '%s\n' "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
}

# Run setup_ppa_* first!
function install_proprietary_software() {
  apt_update
  local update=()
  for package; do if ! apt_is_held "$package"; then update+=("$package"); fi; done
  if [ "${#update[@]}" -gt 0 ]; then
    apt_install "${update[@]}"
  fi
}

# Should already be installed, sanity check
has_cmd gpg curl
log_and_run 'installing spotify ppa' setup_ppa_spotify
log_and_run 'installing vscode ppa' setup_ppa_vscode
log_and_run 'installing google chrome ppa' setup_ppa_google-chrome
log_and_run 'installing proprietary packages' install_proprietary_software spotify-client code google-chrome-stable
