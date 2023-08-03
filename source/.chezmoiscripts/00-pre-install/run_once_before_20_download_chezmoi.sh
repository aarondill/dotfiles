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
sudo=()
if ! [ -w "${bin_dir}/chezmoi" ]; then
  # shellcheck disable=SC2206 # Intentional splitting
  sudo=(${SUDO:-sudo}) # not writeable
fi

file=$(download_file "$URL")
rm_exit "$file"
"${sudo[@]}" sh "$file" -b "$bin_dir"
rm_exit_cleanup "$file"
success
