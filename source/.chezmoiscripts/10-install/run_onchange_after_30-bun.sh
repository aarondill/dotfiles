#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

current_bun='' latest_bun=''
if has_cmd bun; then
  current_bun=$(bun --version)                          # 1.0.14
  latest_bun=$(get_latest_version_github 'oven-sh/bun') # bun-v1.0.14
  latest_bun=${latest_bun#bun-v}                        # 1.0.14
fi

if ! has_cmd bun || vers_gte "$current_bun" "$latest_bun"; then
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
