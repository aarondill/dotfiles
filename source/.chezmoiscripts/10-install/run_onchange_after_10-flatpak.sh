#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function flatpak_is_installed() { flatpak info -- "$@" &>/dev/null; }
# usage: flatpak_install [source] package
function flatpak_install() { sudo flatpak install -y -- "$@"; }
# shellcheck disable=SC2120 # I know it doesn't recieve arguments. it updates all without arguments.
function flatpak_update() { sudo flatpak update -y -- "$@"; }

function install_flatpaks() {
  trap 'err Aborting; exit 1' INT TERM QUIT
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak_apps=(
    com.github.johnfactotum.Foliate com.github.tchx84.Flatseal
    com.valvesoftware.Steam io.mrarm.mcpelauncher
    org.libretro.RetroArch io.github.alainm23.planify
  )
  for flatpak_app in "${flatpak_apps[@]}"; do
    if ! flatpak_is_installed "$flatpak_app"; then
      log "Installing ${flatpak_app}"
      flatpak_install "$flatpak_app" || return 1
    fi
  done
}

installed_or_log flatpak || exit 0

confirm "Would you like to install flatpak packages? this may take a while." || exit 0

log_and_run "Installing flatpak packages" install_flatpaks
log_and_run 'Updating flatpak packages' flatpak_update
