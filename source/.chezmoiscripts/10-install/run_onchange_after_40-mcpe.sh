#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_mcpe_launcher() (
  local version file
  local BINDIR=/usr/local/bin REPO='minecraft-linux/appimage-builder'
  local dest=$BINDIR/mcpe-launcher
  version=$(get_latest_version_github "$REPO") #  v0.14.0-788
  file="Minecraft_Bedrock_Launcher-x86_64-${version//-/.}.AppImage"
  install_from_github "$REPO" "$version" "$file" "$dest"
)
log_and_run 'installing mcpe-launcher' install_mcpe_launcher
