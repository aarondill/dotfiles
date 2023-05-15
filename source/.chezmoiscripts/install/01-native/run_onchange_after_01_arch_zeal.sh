#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if [ -z "$PACMAN" ]; then
  # STOP! deps may not be installed, hopefully handled elsewhere
  abort0 "pacman is not installed, skipping pacman zeal installation"
fi
