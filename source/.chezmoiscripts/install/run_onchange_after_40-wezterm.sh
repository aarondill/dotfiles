#!/usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if ! is_accessible_cmd apt || is_available_apt wezterm; then
  abort0 "wezterm is already installed"
fi

log 'installing wezterm'

if [ "$OS" != "Ubuntu" ]; then
  log 'This script currently only supports ubuntu. More support comming soon. (Hopefully)'
  return 0
fi
REPO=wez/wezterm
VERSION=$(get_latest_version_github "$REPO") # v1.0.0
ASSET=wezterm-${VERSION}.Ubuntu22.04.deb     # hard coding to Ubuntu22.04.deb for now

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
DESTINATION=$TMP_DIR/wezterm.deb

log_github_install "$REPO" "$VERSION" "$ASSET" "$DESTINATION"
curl -sSL "https://github.com/$REPO/releases/download/$VERSION/$ASSET" -o "$DESTINATION"
sudo "$APT" install -y "$DESTINATION"

rm -rf "$TMP_DIR" && trap '' EXIT # cleanup

# set wezterm as default term
# sudo update-alternatives --set x-terminal-emulator /usr/bin/open-wezterm-here
x_term="$(which x-terminal-emulator || printf '/usr/bin/x-terminal-emulator')"
wez="$(which wezterm-gui)"
if [ -z "$wez" ]; then abort0 "Something went wrong setting wezterm as default term"; fi

sudo update-alternatives --install "$x_term" x-terminal-emulator "$wez" 50
sudo update-alternatives --set x-terminal-emulator "$wez"
