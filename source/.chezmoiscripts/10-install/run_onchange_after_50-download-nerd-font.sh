#!/usr/bin/env bash
set -euC -o pipefail

# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing NerdFonts"

NERD_FONT_TO_INSTALL=UbuntuMono
NERD_FONTS_DIR=~/.local/share/fonts/NerdFonts/
REGULAR_FILE=UbuntuMonoNerdFontMono-Regular.ttf
# Test arbitrary file to ensure that nerd fonts is installed
if [ -f "$NERD_FONTS_DIR/$REGULAR_FILE" ]; then abort "NerdFonts are already installed!" 0; fi

log "Downloading nerd fonts repository, this may take a while"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# This is very costly
# Only download toplevel files
git clone --sparse --filter=blob:none 'https://github.com/ryanoasis/nerd-fonts' "$TMP_DIR"
log "Downloading $NERD_FONT_TO_INSTALL fonts"
# Download specific files for $NERD_FONT_TO_INSTALL fonts
git -C "$TMP_DIR" sparse-checkout add "patched-fonts/$NERD_FONT_TO_INSTALL"

log "Installing $NERD_FONT_TO_INSTALL fonts"
# ALl files should be downloaded already!
"$TMP_DIR/install.sh" --use-single-width-glyphs --install-to-user-path "$NERD_FONT_TO_INSTALL"

rm -rf "$TMP_DIR" && trap '' EXIT
success
