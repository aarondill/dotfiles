#!/bin/bash
# Install vortex-ubuntu-plymouth-theme splash screen

set -e

# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing vortex-ubuntu-plymouth-theme splash screen"
if [ "$OS" != "Ubuntu" ]; then
  log "This script is only available for Ubuntu" >&2
  exit 0
fi

for p in plymouth libplymouth5 plymouth-label; do
  if ! command -v apt &>/dev/null; then
    log "Can not install dependency $p using apt"
    break # Don't check other dependencies
  fi
  dpkg -l $p &>/dev/null || {
    log "installing $p package from apt"
    sudo apt-get install -qq $p >/dev/null
    success
  }
done

tempdir=$(mktemp -d)
# Stop on error and remove temporary dir
trap 'rm -rf "$tempdir"' EXIT

# Clone and cd into repo
git clone 'https://github.com/emanuele-scarsella/vortex-ubuntu-plymouth-theme' "$tempdir" --depth 1
cd "$tempdir"

# Create conf.d to show the splash on boot
if [[ -f /etc/initramfs-tools/conf.d/splash ]]; then
  printf '%s\n' 'Overriding /etc/initramfs-tools/conf.d/splash'
  sleep 3 # Allow user to halt
fi
printf 'FRAMEBUFFER=y' | sudo tee /etc/initramfs-tools/conf.d/splash >/dev/null
# Runing update is not necessary because the install script will do it

# Run install script
sudo chmod +x "$tempdir/install"
sudo "$tempdir/install"
