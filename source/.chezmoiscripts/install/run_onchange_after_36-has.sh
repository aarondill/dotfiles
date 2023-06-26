#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

DESTINATION=/usr/local/bin/has

log "Installing has from git.io/_has"
sudo=''

if [ -f "$DESTINATION" ] && ! [ -w "$DESTINATION" ]; then sudo='sudo'; fi
if ! [ -f "$DESTINATION" ] && ! [ -w "$(dirname -- "$DESTINATION")" ]; then sudo=sudo; fi

$sudo curl -sSfL https://git.io/_has -o "$DESTINATION"
$sudo chmod +x "$DESTINATION"

success
