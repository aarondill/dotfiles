#!/bin/bash
# Install vortex-ubuntu-plymouth-theme splash screen
set -euC -o pipefail

# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing vortex-ubuntu-plymouth-theme splash screen"
if [ "$OS" != "Ubuntu" ]; then abort "This script is only available for Ubuntu" 0; fi

apt_install plymouth libplymouth5 plymouth-label

tempdir=$(mktemp -d)
# Stop on error and remove temporary dir
rm_exit "$tempdir"

# Create conf.d to show the splash on boot
if [ -f /etc/initramfs-tools/conf.d/splash ]; then
  log 'Overriding /etc/initramfs-tools/conf.d/splash'
  sleep 3 # Allow user to halt
fi
printf '%s\n' 'FRAMEBUFFER=y' | sudo tee /etc/initramfs-tools/conf.d/splash >/dev/null
# Runing update is not necessary because the install script will do it

# Clone repo
git clone 'https://github.com/emanuele-scarsella/vortex-ubuntu-plymouth-theme' "$tempdir" --depth 1

# Run install script
chmod +x "$tempdir/install"
sudo "$tempdir/install"
rm_exit_cleanup "$tempdir"
