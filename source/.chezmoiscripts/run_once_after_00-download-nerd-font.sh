#!/usr/bin/env bash

# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing NerdFonts"

NERDFONTSDIR=~/.local/share/fonts/NerdFonts/
REGULAR_FILE=UbuntuMonoNerdFontMono-Regular.ttf
# Test arbitrary file to ensure that nerd fonts is installed
if [ -f "$NERDFONTSDIR/$REGULAR_FILE" ]; then abort0 "NerdFonts are already installed!"; fi

log "Downloading nerd fonts repository"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

git clone --filter=blob:none 'https://github.com/ryanoasis/nerd-fonts' "$TMP_DIR"
"$TMP_DIR/install.sh" --use-single-width-glyphs --install-to-user-path UbuntuMono

rm -rf "$TMP_DIR" && trap '' EXIT
success
