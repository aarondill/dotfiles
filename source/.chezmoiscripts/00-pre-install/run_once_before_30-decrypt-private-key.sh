#!/usr/bin/env bash
set -euC -o pipefail

# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Decrypting age key for encrypted files"
if ! has_cmd age; then
  err "Age is not present, attempting to install."
  # Exits on failure
  if has_apt; then
    apt_install age
  elif has_pacman; then
    pacman_install age
  fi
fi
# install failed, abort
has_cmd age || abort "age is required to decrypt files. Please install it and try again." 1

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
if ! [ -f "$config_dir/key.txt" ]; then
  mkdir -p "$config_dir"
  age --decrypt --output "$config_dir/key.txt" "$SOURCE_DIR/key.txt.age"
  chmod 600 "$config_dir/key.txt"
fi
