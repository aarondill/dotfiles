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
  rm_exit "$temp"

  # Clone to tempdir
  git clone --quiet -- "$REPO_URL" "$temp" >/dev/null

  # build from source
  pushd "$temp" >/dev/null
  sudo_cmd make install
  popd >/dev/null

  # cleanup
  rm_exit_cleanup "$temp"
}

log_and_run "Installing $REPO_URL" install_from_make
