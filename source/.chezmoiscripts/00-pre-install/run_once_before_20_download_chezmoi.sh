#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

URL=https://get.chezmoi.io
bin_dir="/usr/local/bin" # Fixed location

log "Installing chezmoi to '${bin_dir}/chezmoi'"
file=$(download_file "$URL")
rm_exit "$file"
sudo_writable "$bin_dir/chezmoi" sh "$file" -b "$bin_dir"
rm_exit_cleanup "$file"
success
