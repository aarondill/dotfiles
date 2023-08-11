#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_mcfly() {
  local bindir='/usr/local/bin'
  local repo="cantino/mcfly"
  sudo_cmd true
  args=(sh -s -- --git "$repo" --to "$bindir")
  if [ -w "$bindir" ]; then
    args=(sudo_cmd "${args[@]}")
  fi
  download https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | "${args[@]}"
}
log_and_run 'installing mcfly' install_mcfly
