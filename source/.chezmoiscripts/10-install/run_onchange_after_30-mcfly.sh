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
  current_version=$(run_own_shell mcfly --version | cut -d ' ' -f 2)
  latest_version=$(get_latest_version_github "$repo")
  if [ "${latest_version#v}" == "$current_version" ]; then abort "mcfly is already up to date" 0; fi

  sudo_cmd true
  args=(sh -s -- --git "$repo" --to "$bindir" --tag "$latest_version" --force)
  if ! [ -w "$bindir" ]; then
    args=(sudo_cmd "${args[@]}")
  fi
  download https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | "${args[@]}"
}
log_and_run 'installing mcfly' install_mcfly
