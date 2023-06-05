#!/usr/bin/env bash
# Installs the latest version of wezterm. Only works on Ubuntu for now
# This is handled by pacman on arch because it's more recently updated

set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if ! is_accessible_cmd apt || is_available_apt wezterm; then
  abort "wezterm is already installed" 0
fi

log 'installing wezterm'

# Check first to save download time for version
if [ "$OS" != "Ubuntu" ] && [ "$OS" != "Debian" ]; then
  abort 'This script currently only supports Ubuntu and Debian. More support comming soon. (Hopefully)' 0
fi

REPO=wez/wezterm
VERSION=$(get_latest_version_github "$REPO") # v1.0.0
case "$OS" in
Ubuntu)
  ASSET=wezterm-${VERSION}.Ubuntu22.04.deb # hard coding to Ubuntu22.04.deb for now
  ;;
Debian)
  ASSET=wezterm-${VERSION}.Debian10.deb # hard coding to Ubuntu22.04.deb for now
  ;;
*)
  abort "this is a bug!" 3
  ;;
esac

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
if [ -z "$wez" ]; then abort "Something went wrong setting wezterm as default term" 0; fi

sudo update-alternatives --install "$x_term" x-terminal-emulator "$wez" 50
sudo update-alternatives --set x-terminal-emulator "$wez"
