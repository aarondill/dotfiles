#! /usr/bin/env bash
set -eu
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

DESTINATION=/usr/local/bin/has

log "Installing has from git.io/_has"
sudo=''

if [ -f "$DESTINATION" ] && ! [ -w "$DESTINATION" ]; then sudo='sudo'; fi
if ! [ -f "$DESTINATION" ] && ! [ -w "$(dirname -- "$DESTINATION")" ]; then sudo=sudo; fi
curl -sSfL https://git.io/_has | $sudo tee "$DESTINATION" >/dev/null

success
