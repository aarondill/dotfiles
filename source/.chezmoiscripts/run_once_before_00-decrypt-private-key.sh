#!/usr/bin/env bash
set -euC -o pipefail

# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Decrypting age key for encrypted files"
if ! command -v age &>/dev/null; then
  if command -v apt &>/dev/null; then
    err "Age is not present, attempting to install using apt"
    sudo apt install age
  else
    err "Age is not present. Please install it before running this script."
  fi
fi

if [ ! -f "$HOME/.config/chezmoi/key.txt" ]; then
  mkdir -p "$HOME/.config/chezmoi"
  age --decrypt --output "$HOME/.config/chezmoi/key.txt" "$SOURCE_DIR/key.txt.age"
  chmod 600 "$HOME/.config/chezmoi/key.txt"
fi
