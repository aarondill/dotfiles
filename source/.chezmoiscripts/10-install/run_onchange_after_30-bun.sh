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

  SHELL="Don't Change My Bash Config!!" run_own_shell bash -- "$tmp_file"

  rm_exit_cleanup "$tmp_file"
  success
fi

file=~/.local/share/bash-completion/completions/bun
log "Installing bun completions"
mkdir -p "$(dirname -- "$file")"
SHELL=bash bun completions >|"$file"
