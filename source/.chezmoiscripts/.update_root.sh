#!/bin/bash
# this finds the largest swap partition and *offers* to replace important instances of the backed up source with the uuid
set -e
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

biggest_swap=$(tail -n+2 </proc/swaps | LC_ALL=C sort -t$'\t' -nk3 | tail -n1 | awk '{print $1}')
confirm "would you like to use $biggest_swap as your swap to resume from?"
"RESUME=UUID="
