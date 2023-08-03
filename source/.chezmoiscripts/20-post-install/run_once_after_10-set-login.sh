#!/bin/bash
# Install ubuntu-gdm-set-background
set -euC -o pipefail
IMAGE="https://images.wallpaperscraft.com/image/single/sky_stars_moon_144720_1600x900.jpg"

# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing ubuntu-gdm-set-background"

if [ "$OS" != "Ubuntu" ]; then
  abort "This script is only available for Ubuntu" 0
fi

if ! is_accessible_cmd gdm3 && ! is_accessible_cmd gdm; then
  abort "This script requires gdm to be installed" 0
fi

REPO="PRATAP-KUMAR/ubuntu-gdm-set-background"

codename="$(grep -F "UBUNTU_CODENAME" /etc/os-release | cut -d = -f 2)"
case "$codename" in
lunar) file="ubuntu-gdm-set-background-23.04" ;;
*) file="ubuntu-gdm-set-background" ;;
esac

# dependencies
if ! dpkg -l libglib2.0-dev-bin &>/dev/null; then
  log 'Attemping to install dependencies'
  if [ -z "$APT" ]; then abort "Can't install libglib2.0-dev-bin using apt. Please make sure it's installed"; fi
  apt_install libglib2.0-dev-bin
fi

destination="/usr/local/bin/ubuntu-gdm-set-background"
download_file "https://raw.githubusercontent.com/$REPO/main/$file" "$destination" +x
success

log "Downloading background image"
# Download image file
temp_file="$(download_file "$IMAGE")"
rm_exit "$temp_file"

log 'Setting image as current lock screen image'
sudo "$destination" --image "$temp_file" || abort 'Something went wrong setting the lock screen' 0

log 'Cleaning up temporary files'
rm_exit_cleanup "$temp_file"
success
