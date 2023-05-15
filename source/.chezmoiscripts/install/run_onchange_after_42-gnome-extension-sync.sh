#!/bin/bash
# Installs extension sync gnome extension
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function sync_extensions() {
  ## Sync if present
  if ! [ -f "$HOME/.config/extensions-sync.json" ]; then
    return 0
  fi

  # If sync file exists, read from it
  # Set local file mode
  dconf write '/org/gnome/shell/extensions/extensions-sync/provider' '"Local"' || abort0
  # Set backup location
  dconf write '/org/gnome/shell/extensions/extensions-sync/backup-file-location' '"file://'"$HOME"'/.config/extensions-sync.json"' || abort0
  # Allow no matter what version - not safe, but idc
  dconf write '/org/gnome/shell/disable-extension-version-validation' "true" || abort0
  # load from the file
  busctl --user call org.gnome.Shell /io/elhan/ExtensionsSync io.elhan.ExtensionsSync read || {
    err "failed to sync extensions, check that extensions-sync supports your current gnome version"
    return 0
  }
}

if ! [ -f /usr/bin/gnome-session ]; then
  # Gnome is not installed
  abort0 "gnome is not installed, so skipping extension synchronization"
fi
DESTINATION="$HOME/.local/share/gnome-shell/extensions/extensions-sync@elhan.io"

if [ -d "$DESTINATION" ]; then
  # Sync if already exists
  log "extensions-sync is already installed at $DESTINATION, skipping extension installation"
  sync_extensions
  exit 0
fi

# Pick a package manager!
NPM=$(which yarn 2>/dev/null) || abort "yarn is required to install extensions sync"

## Install extensions sync

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

sync_extensions
