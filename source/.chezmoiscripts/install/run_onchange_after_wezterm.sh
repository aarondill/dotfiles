#! /usr/bin/env bash
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_wezterm() (
  set -e # run in subshell
  if [ "$OS" != "Ubuntu" ]; then
    log 'This script currently only supports ubuntu. More support comming soon. (Hopefully)'
    return 0
  fi
  declare temp_dir version REPO=wez/wezterm

  version=$(get_latest_version_github "$REPO") # v1.0.0

  asset=wezterm-${version}.Ubuntu22.04.deb # hard coding to Ubuntu22.04.deb for now
  # Download the .deb
  temp_dir=$(mktemp -d) &&
    (
      # In a subshell, so runs at end of block
      trap 'rm -rf $temp_dir' EXIT
      set -e
      local destination=$temp_dir/wezterm.deb
      log_github_install "$REPO" "$version" "$asset" "$destination"
      curl -sSL "https://github.com/$REPO/releases/download/$version/$asset" -o "$destination"
      sudo apt install "$destination"
    )
  # set wezterm as default term
  sudo update-alternatives --set x-terminal-emulator /usr/bin/open-wezterm-here
)

# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if is_accessible_cmd apt && ! is_available_apt wezterm; then
  log_and_run 'installing wezterm' install_wezterm
fi
