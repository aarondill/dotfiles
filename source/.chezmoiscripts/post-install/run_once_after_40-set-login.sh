#!/bin/bash
# Install ubuntu-gdm-set-background
set -e
IMAGE="https://images.wallpaperscraft.com/image/single/sky_stars_moon_144720_1600x900.jpg"

# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing ubuntu-gdm-set-background"

os="$(lsb_release -is)"
if [ "$os" != "Ubuntu" ]; then
  log "This script is only available for Ubuntu" >&2
  exit 0
fi

OWNER="PRATAP-KUMAR"

codename="$(grep UBUNTU_CODENAME /etc/os-release | cut -d = -f 2)"
if [ "$codename" = "lunar" ]; then
  FILE="ubuntu-gdm-set-background-23.04"
else
  FILE="ubuntu-gdm-set-background"
fi

DESTINATION="/usr/local/bin/$FILE"
sudo curl -SsfL "https://raw.githubusercontent.com/$OWNER/ubuntu-gdm-set-background/main/$FILE" -o "$DESTINATION"
sudo chmod +x "$DESTINATION"
success

log "Downloading background image"
# Download image file
TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT
curl -SsfL "$IMAGE" -o "$TEMP_FILE"
success

log 'Setting image as current lock screen image'
sudo "$DESTINATION" --image "$TEMP_FILE" || exit 0
success

log 'Cleaning up temporary file'
rm -f "$TEMP_FILE" && trap '' EXIT # Clean up and remove trap
success
