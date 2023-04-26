#!/bin/bash
# Installs extension sync gnome extension
set -e

# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if ! [ -f /usr/bin/gnome-session ]; then
  # Gnome is not installed
  abort0 "gnome is not installed, so skipping extension synchronization"
fi
DESTINATION="$HOME/.local/share/gnome-shell/extensions/extensions-sync@elhan.io"
if [ -d "$DESTINATION" ]; then
  abort0 "extensions-sync is already installed at $DESTINATION, skipping extension installation"
fi

# Pick a package manager!
NPM=$(which yarn 2>/dev/null) || abort "yarn is required to install extensions sync"

## Install extensions sync

# Exits on fail because set -e
TEMP=$(mktemp -d)
trap 'rm -rf ${TEMP}' EXIT

git clone https://github.com/oae/gnome-shell-extensions-sync.git "$TEMP"

cd "$TEMP"
"$NPM" install
# "$NPM" run build # This doesn't work because clean:schema exits 1 if not present
# HACK: run build doesn't work. Here's the steps it took when I wrote this.
"$NPM" run build:ts                                                  ## Build the extension
"$NPM" run clean:schema || true                                      # This may fail, but it's fine!
glib-compile-schemas ./resources/schemas --targetdir=./dist/schemas/ # from build:schema

mkdir -p -- "$(dirname -- "$DESTINATION")"
mv -T -- "$TEMP/dist" "$DESTINATION" # keep the dist directory as the final result

# Clean up and remove trap
rm -rf "$TEMP" && trap '' EXIT && cd -

## Sync if present

# If sync file exists, read from it
if [ -f "$HOME/.config/extensions-sync.json" ]; then
  # Set local file mode
  dconf write '/org/gnome/shell/extensions/extensions-sync/provider' '"Local"'
  # Set backup location
  dconf write '/org/gnome/shell/extensions/extensions-sync/backup-file-location' "\"file://$HOME/.config/extensions-sync.json\""
  busctl --user call org.gnome.Shell /io/elhan/ExtensionsSync io.elhan.ExtensionsSync read # load from the file
fi
