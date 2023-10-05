#!/bin/bash
# Installs extension sync gnome extension
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# non-fatal. exit 0
function sync_extensions_abort() { abort 'Something went wrong syncing extensions' 0; }
function sync_extensions() {
  ## Sync if present
  if ! [ -f "$HOME/.config/extensions-sync.json" ]; then
    return 0
  fi

  # If sync file exists, read from it
  # Set local file mode
  dconf write '/org/gnome/shell/extensions/extensions-sync/provider' '"Local"' || sync_extensions_abort
  # Set backup location
  dconf write '/org/gnome/shell/extensions/extensions-sync/backup-file-location' '"file://'"$HOME"'/.config/extensions-sync.json"' || sync_extensions_abort
  # Allow no matter what version - not safe, but idc
  dconf write '/org/gnome/shell/disable-extension-version-validation' "true" || sync_extensions_abort
  # load from the file
  busctl --user call org.gnome.Shell /io/elhan/ExtensionsSync io.elhan.ExtensionsSync read || {
    err "failed to sync extensions, check that extensions-sync supports your current gnome version"
    return 0
  }
}

if ! [ -f /usr/bin/gnome-session ]; then
  # Gnome is not installed
  abort "gnome is not installed, so skipping extension synchronization" 0
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
rm_exit "$TEMP"

git_clone 'https://github.com/oae/gnome-shell-extensions-sync.git' "$TEMP"

pushd "$TEMP" >/dev/null
"$NPM" install
# "$NPM" run build # This doesn't work because clean:schema exits 1 if not present
# HACK: run build doesn't work. Here's the steps it took when I wrote this.
"$NPM" run build:ts                                                  ## Build the extension
"$NPM" run clean:schema || true                                      # This may fail, but it's fine!
glib-compile-schemas ./resources/schemas --targetdir=./dist/schemas/ # from build:schema

mkdir -p -- "$(dirname -- "$DESTINATION")"
mv -T -- "$TEMP/dist" "$DESTINATION" # keep the dist directory as the final result

popd >/dev/null
rm_exit_cleanup "$TEMP"

sync_extensions
