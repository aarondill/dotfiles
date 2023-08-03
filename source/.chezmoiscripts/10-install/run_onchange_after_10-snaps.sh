#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_snaps() {
  true # don't do anything 🤷‍♂️ - I don't want any snaps
}

installed_or_log snap || exit 0
log_and_run "Installing snaps" install_snaps

log 'disconnecting firefox:hunspell'
CONNECTON=$(snap connections firefox | awk '/firefox:host-hunspell/{print $3}')
# If still connected, disconnect
if [ -n "$CONNECTON" ] && [ "$CONNECTON" != '-' ]; then
  sudo snap disconnect firefox:host-hunspell
fi
success
