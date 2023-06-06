#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Use the install script! We love this! :)
install_script="$(curl -sSfL https://starship.rs/install.sh)"
# If ends in print_install, remove it. It's annoying. Be as safe as possible.
if [ "print_install" = "$(tail -n1 <<<"$install_script")" ]; then
  install_script=$(head -n1 <<<"$install_script")
fi
log "Installing starship from $install_script"
sh -c "$install_script" -- -y -b /usr/local/bin
success
