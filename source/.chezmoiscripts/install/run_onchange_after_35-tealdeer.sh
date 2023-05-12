#! /usr/bin/env bash
set -eu
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

FILE="tealdeer-linux-x86_64-musl"
DESTINATION=/usr/local/bin/tldr
REPO='dbrgn/tealdeer'

install_from_github $REPO latest "$FILE" "$DESTINATION"
success
