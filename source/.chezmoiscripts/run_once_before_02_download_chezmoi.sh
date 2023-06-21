#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

URL=https://get.chezmoi.io
bin_dir="/usr/local/bin" # Fixed location

log "Installing chezmoi to '${bin_dir}/chezmoi'"
sh -c "$(download "$URL" progress)" -- -b "${bin_dir}"
success
