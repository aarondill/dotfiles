#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log "Installing bun using install script"
tmp_file=$(download_file https://bun.sh/install)
rm_exit "$tmp_file"

SHELL="Don't Change My Bash Config!!" bash -- "$tmp_file"

rm_exit_cleanup "$tmp_file"
success
