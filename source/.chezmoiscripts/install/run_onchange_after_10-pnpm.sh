#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function add_global_dir_to_path() {
  local global_bin_dir
  global_bin_dir="$(pnpm config get global-bin-dir 2>/dev/null || printf '')"
  if [ -z "$global_bin_dir" ]; then return 1; fi
  if [[ ":$PATH:" = *:"$global_bin_dir":* ]]; then return 0; fi
  PATH="$PATH:$global_bin_dir"
}

function install_pnpm_and_node() {
  sudo -v
  # Setup n
  log 'Setting up /usr/local files for n'
  sudo mkdir -p /usr/local/bin /usr/local/lib/node_modules /usr/local/include /usr/local/share /usr/local/n
  sudo chown -R "$(whoami)" /usr/local/bin /usr/local/lib/node_modules /usr/local/include /usr/local/share /usr/local/n

  log 'installing node lts through n...'
  (
    export -n SHELLOPTS &&
      curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | /usr/bin/env bash -s -- lts
  )

  # Setup pnpm
  log 'installing pnpm'
  corepack enable
  corepack prepare pnpm@latest --activate >/dev/null

  add_global_dir_to_path || [ -n "$PNPM_HOME" ]

  log 'installing n through pnpm'
  # requires wget
  pnpm i -g n
}

install_pnpm_global_packages() {
  add_global_dir_to_path || [ -n "$PNPM_HOME" ]
  pnpm i -g n
}

if ! is_accessible_cmd wget; then
  err "wget is not present, attempting to install."
  if [ -n "$APT" ]; then
    sudo "$APT" install wget
  elif [ -n "$PACMAN" ]; then
    sudo "$PACMAN" -S wget
  else
    abort "wget is required to install n. Please install it and try again." 1
  fi
fi

is_accessible_cmd pnpm || log_and_run 'Installing NodeJS and pnpm' install_pnpm_and_node
is_accessible_cmd pnpm && log_and_run 'Installing pnpm global packages' install_pnpm_global_packages
