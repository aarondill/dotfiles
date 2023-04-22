#!/bin/bash
# Installs extension sync gnome extension
set -e
if ! [ -f /usr/bin/gnome-session ]; then
  # Gnome is not installed
  echo "gnome is not installed, so skipping extension synchronization" >&2
  return 0
fi

# Pick a package manager!
NPM=$(which pnpm 2>/dev/null || which yarn 2>/dev/null || which npm 2>/dev/null)
if ! [ -x "${NPM}" ]; then
  echo "npm, pnpm, or yarn are required to install extensions sync" >&2
  exit 1
fi

## Install extensions sync

# Exits on fail because set -e
TEMP=$(mktemp -d)
trap 'rm -rf ${TEMP}' EXIT

git clone https://github.com/oae/gnome-shell-extensions-sync.git "$TEMP"

cd "$TEMP"
"$NPM" install # Any of the three can do these two commands
"$NPM" run build
mv -- "$PWD/dist" "$HOME/.local/share/gnome-shell/extensions/extensions-sync@elhan.io" # keep the dist directory as the final result

## Sync if present

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
