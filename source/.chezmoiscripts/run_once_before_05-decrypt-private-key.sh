#!/usr/bin/env bash
set -euC -o pipefail

# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Decrypting age key for encrypted files"
if ! command -v age &>/dev/null; then
  err "Age is not present, attempting to install."
  # Exits on failure
  if [ -n "$APT" ]; then
    sudo "$APT" install age
  elif [ -n "$PACMAN" ]; then
    sudo "$PACMAN" -S --needed age
  else
    abort "age is required to decrypt files. Please install it and try again." 1
  fi
fi

if [ ! -f "$HOME/.config/chezmoi/key.txt" ]; then
  mkdir -p "$HOME/.config/chezmoi"
  age --decrypt --output "$HOME/.config/chezmoi/key.txt" "$SOURCE_DIR/key.txt.age"
  chmod 600 "$HOME/.config/chezmoi/key.txt"
fi
