#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_fff() {
  local DEST=${BINDIR:-'/usr/local/bin'}/fff
  local url='https://raw.githubusercontent.com/dylanaraps/fff/master/fff'
  download_file sudo "$url" "$DEST" 755 # Download file to bindir with rwxr-xr-x perms
}

log_and_run 'installing fff' install_fff
