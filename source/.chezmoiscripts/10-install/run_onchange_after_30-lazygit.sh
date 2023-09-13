#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_lazygit() (
  local version file
  local BINDIR=/usr/local/bin
  local REPO='jesseduffield/lazygit'
  version=$(get_latest_version_github "$REPO") # v0.39.3
  file="lazygit_${version#v}_Linux_x86_64.tar.gz"
  if has_cmd lazygit; then
    local installed_version
    installed_version=$(lazygit --version | tr ',' '\n' | sed 's/^\s*//g' | grep '^version=' | cut -d= -f2-)
    if [ "v$installed_version" = "$version" ]; then
      abort 'Already up to date' 0
    fi
  fi

  tmp=$(mktemp)
  rm_exit "$tmp"
  install_from_github "$REPO" "$version" "$file" "$tmp"
  # output to destination
  sudo_cmd tar -xz -C "$BINDIR" -f "$tmp" lazygit
  sudo_cmd chmod +x "$BINDIR/lazygit"

  rm_exit_cleanup "$tmp"
)

log_and_run 'installing lazygit' install_lazygit
