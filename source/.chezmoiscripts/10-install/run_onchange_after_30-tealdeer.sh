#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Hard coded, but whatever
FILE="tealdeer-linux-x86_64-musl"
DESTINATION=/usr/local/bin/tldr
REPO='dbrgn/tealdeer'

version=$(get_latest_version_github "$REPO") # v1.6.1
if has_cmd tldr && [ "$(tldr --version)" = "tealdeer ${version#v}" ]; then
  abort 'already up to date.' 0
fi

install_from_github "$REPO" 'latest' "$FILE" "$DESTINATION"
success
