#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_lazygit() (
  local LAZYGIT_VERSION REPO FILE
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  FILE="lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  BINDIR=/usr/local/bin
  REPO='jesseduffield/lazygit'

  log_github_install "$REPO" "$LAZYGIT_VERSION" "$FILE" "$BINDIR"

  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  curl -SsLf "https://github.com/$REPO/releases/download/v$LAZYGIT_VERSION/$FILE" -o "$TMP"
  # output to destination
  sudo tar -xvz -C "$BINDIR" -f "$TMP" lazygit
  sudo chmod +x "$BINDIR/lazygit"

  rm -f "$TMP" && trap '' EXIT # Cleanup
)

log_and_run 'installing lazygit' install_lazygit
