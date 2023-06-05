#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Cloned into tempdir
REPO_URL='https://github.com/evanpurkhiser/linux-vt-setcolors'

install_from_make() {
  # Shows on errors
  THIS="Make"

  # Temp directory
  temp=$(mktemp -d)
  trap 'rm -rf "$temp"' EXIT

  # Clone to tempdir
  git clone --quiet -- "$REPO_URL" "$temp" >/dev/null

  # build from source
  cd "$temp"
  sudo make install

  # cleanup
  rm -rf "$temp" && trap '' EXIT
}

log_and_run "Installing $REPO_URL" install_from_make
