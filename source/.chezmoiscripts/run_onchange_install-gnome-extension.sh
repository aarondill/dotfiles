#!/bin/bash
# Installs extension sync gnome extension
set -e
if ! [ -f /usr/bin/gnome-session ]; then
  # Gnome is not installed
  echo "gnome is not installed, so skipping extension synchronization" >&2
  return 0
fi

# Install using gnome-shell-extension-installer
curl -sSfL 'https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer' |
  bash /dev/stdin 1486

# If sync file exists, read from it
if [ -f "$HOME/.config/extensions-sync.json" ]; then
  busctl --user call org.gnome.Shell /io/elhan/ExtensionsSync io.elhan.ExtensionsSync read # load from the file
fi
