#!/usr/bin/env bash
set -euC -o pipefail

# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing NerdFonts"

if has_pacman; then
  pacman_install ttf-ubuntu-mono-nerd
else
  NERD_FONT_TO_INSTALL=UbuntuMono                 # name to download
  NERD_FONTS_DIR=~/.local/share/fonts/NerdFonts/  # destination
  REGULAR_FILE=UbuntuMonoNerdFontMono-Regular.ttf # An arbitray file in destination that is included
  REPO=ryanoasis/nerd-fonts

  # Test arbitrary file to ensure that nerd fonts is installed
  if [ -f "$NERD_FONTS_DIR/$REGULAR_FILE" ]; then
    abort "NerdFonts are already installed!" 0
  fi

  mkdir -p -- "$NERD_FONTS_DIR" # ensure destination exists
  tmp=$(mktemp) || abort "Could not create temp file"
  rm_exit "$tmp"

  install_from_github "$REPO" latest "$NERD_FONT_TO_INSTALL.zip" "$tmp"

  log "Unzipping $NERD_FONT_TO_INSTALL font"
  unzip -- "$tmp" -d "$NERD_FONTS_DIR"

  rm_exit_cleanup "$tmp"
fi
success
