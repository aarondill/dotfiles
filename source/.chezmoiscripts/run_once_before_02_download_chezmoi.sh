#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

URL=https://get.chezmoi.io
bin_dir="/usr/local/bin" # Fixed location

log "Installing chezmoi to '${bin_dir}/chezmoi'"
# use like '$sudo do_something' - could break with SUDO="something with spaces"
sudo=
if ! [ -w "${bin_dir}/chezmoi" ]; then
  sudo="${SUDO:-sudo}" # not writeable
fi

$sudo sh -c "$(download "$URL" progress)" "chezmoi-updater" -b "$bin_dir"
success
