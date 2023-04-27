#!/bin/bash
# this finds the largest swap partition and *offers* to replace important instances of the backed up source with the uuid
set -e
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

RESUME_FILE=/etc/initramfs-tools/conf.d/resume

BIG_SWAP_PATH=$(tail -n+2 </proc/swaps | LC_ALL=C sort -t$'\t' -nk3 | tail -n1 | awk '{print $1}')

[ -f "$RESUME_FILE" ] && WARNING="(This will overwrite $RESUME_FILE)" || WARNING=''

confirm "Would you like to use $BIG_SWAP_PATH as your swap to resume from? $WARNING" || abort0 'Aborting'
if [ -f "$RESUME_FILE" ]; then
  log "overwriting $RESUME_FILE"
  sudo rm -f -- "$RESUME_FILE"
fi
# Works with swapfile (should)
BIG_SWAP_UUID="$(sudo swaplabel "$BIG_SWAP_PATH" | awk '{print $2}')"
printf 'RESUME=UUID=%s\n' "$BIG_SWAP_UUID" | sudo tee "$RESUME_FILE" >/dev/null
# update the initramfs-tools
sudo update-initramfs -u

success
