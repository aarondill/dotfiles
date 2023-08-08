#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

install_cargo() {
  local tmp
  tmp="$(mktemp)"
  rm_exit "$tmp"
  curl --proto '=https' --tlsv1.2 -sSfL https://sh.rustup.rs -o "$tmp"
  sh "$tmp" --profile minimal --no-modify-path
  rm_exit_cleanup "$tmp"
}

if has_cmd rustup; then
  log_and_run "Updating rustup/cargo" rustup update
else
  log_and_run "Installing cargo using rustup" install_cargo
fi
