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
  # Set local mode
  dconf write '/org/gnome/shell/extensions/extensions-sync/provider' '"Local"'
  # Set local file mode
  dconf write '/org/gnome/shell/extensions/extensions-sync/provider' '"Local"'
  # Set backup location
  dconf write '/org/gnome/shell/extensions/extensions-sync/backup-file-location' "\"file://$HOME/.config/extensions-sync.json\""
  busctl --user call org.gnome.Shell /io/elhan/ExtensionsSync io.elhan.ExtensionsSync read # load from the file
fi
