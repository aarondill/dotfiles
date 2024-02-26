#!/usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# prefix with - to disable
# use +-service to enable a service that begins with a -
# If the service does not exist, nothing is done
services=(
  NetworkManager.service
  bluetooth.service
  consolation.service
  cronie.service
  pkgfile-update.timer
  tlp.service
  -NetworkManager-wait-online.service
)

for s in "${services[@]}"; do
  do=enable
  [ "${s:0:1}" != "-" ] || do=disable
  s="${s#-}" # remove leading dash
  s="${s#+}" # remove leading plus
  systemctl list-unit-files -- "$s" &>/dev/null || continue
  verbose sudo_cmd systemctl "$do" --now -- "$s"
done
