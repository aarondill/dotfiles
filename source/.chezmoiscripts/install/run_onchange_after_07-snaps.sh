#! /usr/bin/env bash
set -e
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_snaps() {
  true # don't do anything 🤷‍♂️ - I don't want any snaps
}

installed_or_log snap &&
  log_and_run "Installing snaps" install_snaps
installed_or_log snap && (
  log 'disconnecting firefox:hunspell'
  CONNECTONS=$(snap connections firefox | awk '/firefox:host-hunspell/{print $3}')
  # If still connected, disconnect
  if [ "$CONNECTONS" != '-' ]; then
    snap disconnect firefox:host-hunspell
  fi
  success
)
