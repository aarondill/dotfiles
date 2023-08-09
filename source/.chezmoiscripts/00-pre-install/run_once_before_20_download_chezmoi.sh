#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

URL=https://get.chezmoi.io
bin_dir="/usr/local/bin" # Fixed location

log "Installing chezmoi to '${bin_dir}/chezmoi'"
no_sudo=y
if ! [ -w "${bin_dir}/chezmoi" ]; then
  no_sudo=
fi

file=$(download_file "$URL")
rm_exit "$file"
sudo_cmd sh "$file" -b "$bin_dir"
rm_exit_cleanup "$file"
success
