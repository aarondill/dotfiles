#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"
INSTALL_URL=https://starship.rs/install.sh
INSTALL_DIR=/usr/local/bin

# Use the install script! We love this! :)
install_script="$(download "$INSTALL_URL")"
# If ends in print_install, remove it. It's annoying. Be as safe as possible.
if [ "print_install" = "$(tail -n1 <<<"$install_script")" ]; then
  install_script=$(head -n-1 <<<"$install_script")
fi
log "Installing starship from $INSTALL_URL"
sudo_writable "$INSTALL_DIR/starship" sh -c "$install_script" -- -y -b "$INSTALL_DIR"
success
