#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if ! has_cmd bun; then
  log "Installing bun using install script"
  tmp_file=$(download_file https://bun.sh/install)
  rm_exit "$tmp_file"

  SHELL="Don't Change My Bash Config!!" bash -- "$tmp_file"

  rm_exit_cleanup "$tmp_file"
  success
fi

BUN_COMPLETION="${BUN_COMPLETION:-${BUN_INSTALL:-$HOME/.bun}/complete.bash}"
log "Installing bun completions to '$BUN_COMPLETION'"
mkdir -p "$(dirname -- "$BUN_COMPLETION")"
SHELL=bash bun completions >|"$BUN_COMPLETION"
