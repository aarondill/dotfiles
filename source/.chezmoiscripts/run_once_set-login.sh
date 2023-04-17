#!/bin/bash
# Install ubuntu-gdm-set-background
set -e
function log() { printf '%s\n' "$@"; }
function success() { printf "$(tput setaf 2)%s$(tput sgr0)\n" "Success!"; }

log "Installing ubuntu-gdm-set-background"
OWNER="aarondill"
FILE="ubuntu-gdm-set-background"
DESTINATION="/usr/local/bin/$FILE"
curl -SsfL "https://raw.githubusercontent.com/$OWNER/ubuntu-gdm-set-background/main/$FILE" |
	tee "$DESTINATION" >/dev/null
chmod +x "$DESTINATION"
success

log "Downloading sky_stars_moon_144720_1600x900.jpg"
# Download image file
TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT
curl -SsfL "https://images.wallpaperscraft.com/image/single/sky_stars_moon_144720_1600x900.jpg" -o "$TEMP_FILE"
success

log 'Setting sky_stars_moon_144720_1600x900.jpg as current lock screen image'
sudo "$DESTINATION" --image "$TEMP_FILE" || true # Always returns 1...
success

log 'Cleaning up temporary file'
rm -f "$TEMP_FILE" && trap '' EXIT # Clean up and remove trap
