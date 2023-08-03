#!/usr/bin/env bash
# Installs the latest version of wezterm. Only works on Ubuntu for now
# This is handled by pacman on arch because it's more recently updated

set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if [ -z "$APT" ]; then
  abort 'This script only supports apt. Install from your disto repos' 0
fi

# # Wezterm will inform of updates itself, only run if not already installed
# if apt_is_available wezterm; then
#   abort "wezterm is already installed" 0
# fi

log 'installing wezterm'

# Check first to save download time for version
if [ "$OS" != "Ubuntu" ] && [ "$OS" != "Debian" ]; then
  abort 'This script currently only supports Ubuntu and Debian. More support comming soon. (Hopefully)' 0
fi

REPO=wez/wezterm
version=$(get_latest_version_github "$REPO") # 20230712-072601-f4abf8fd
if has_cmd dpkg-query; then
  installed_version=$(dpkg-query --showformat='${Version}' --show wezterm)
  if [ "$installed_version" = "$version" ]; then
    abort 'Already up to date' 0
  fi
fi

# true if $1 lt $2
is_lt() { awk 'BEGIN{exit !(ARGV[1]<ARGV[2])}' "$1" "$2"; }
case "$OS" in
Ubuntu)
  ubuntu_version=$(lsb_release -sr)
  if is_lt "$ubuntu_version" "20.04"; then
    asset=wezterm-${version}.Ubuntu20.04.deb
  else
    # latest as of writing. may need to be updated
    asset=wezterm-${version}.Ubuntu22.04.deb
  fi
  ;;
Debian)
  deb_version=$(lsb_release -sr)
  if is_lt "$deb_version" 11; then
    asset=wezterm-${version}.Debian10.deb
  else
    # latest as of writing. may need to be updated
    asset=wezterm-${version}.Debian11.deb
  fi
  ;;
*)
  abort "this is a bug!" 3
  ;;
esac

log_github_install "$REPO" "$version" "$asset"
tmp=$(download_file "https://github.com/$REPO/releases/download/$version/$asset")
rm_exit "$tmp"
apt_install "$tmp"
rm_exit_cleanup "$tmp"

# set wezterm as default term
# sudo update-alternatives --set x-terminal-emulator /usr/bin/open-wezterm-here
x_term="$(which x-terminal-emulator || printf '/usr/bin/x-terminal-emulator')"
wez="$(which wezterm-gui)"
if [ -z "$wez" ]; then abort "Something went wrong setting wezterm as default term" 0; fi

sudo update-alternatives --install "$x_term" x-terminal-emulator "$wez" 50
sudo update-alternatives --set x-terminal-emulator "$wez"

success
