#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_pnpm_and_node() {
  sudo -v
  # Setup n
  log 'Setting up /usr/local files for n'
  sudo mkdir -p /usr/local/bin /usr/local/lib/node_modules /usr/local/include /usr/local/share /usr/local/n
  sudo chown -R "$(whoami)" /usr/local/bin /usr/local/lib/node_modules /usr/local/include /usr/local/share /usr/local/n

  log 'installing node lts through n...'
  curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | /usr/bin/env bash -s -- lts

  # Setup pnpm
  log 'installing pnpm'
  corepack enable
  corepack prepare pnpm@latest --activate >/dev/null

  log 'installing n through pnpm'
  pnpm i --silent -g n
}

install_pnpm_global_packages() {
  pnpm i --silent -g n

}

is_accessible_cmd pnpm || log_and_run 'Installing NodeJS and pnpm' install_pnpm_and_node
is_accessible_cmd pnpm && log_and_run 'Installing pnpm global packages' install_pnpm_global_packages
