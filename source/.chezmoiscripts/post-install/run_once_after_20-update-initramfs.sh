#!/usr/bin/env bash
# this finds the largest swap partition and *offers* to replace important instances of the backed up source with the uuid
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

RESUME_FILE=/etc/initramfs-tools/conf.d/resume

if ! [ -d "$(dirname -- "$RESUME_FILE")" ]; then
  abort 'This script only supports initramfs, please manually setup resume for your initramfs system' 0
fi

BIG_SWAP_LINE=$(tail -n+2 </proc/swaps | LC_ALL=C sort -t$'\t' -nk3 | tail -n1)
BIG_SWAP_PATH=$(awk '{print $1}' <<<"$BIG_SWAP_LINE") # /dev/sda1
BIG_SWAP_TYPE=$(awk '{print $2}' <<<"$BIG_SWAP_LINE") # file | partition

if [ "$BIG_SWAP_TYPE" = "file" ]; then
  abort0 "Swap files are not supported by this script. Please use a swap partition or setup youself :)"
fi

[ -f "$RESUME_FILE" ] && WARNING="(This will overwrite $RESUME_FILE)" || WARNING=''

BIG_SWAP_LABEL=$(blkid -s LABEL -o value "$BIG_SWAP_PATH")

# fallback to parition label
[ -z "$BIG_SWAP_LABEL" ] && BIG_SWAP_LABEL="$(blkid -o value -s PARTLABEL "$BIG_SWAP_PATH")"
# don't leave it empty.
[ -z "$BIG_SWAP_LABEL" ] && BIG_SWAP_LABEL="No Label"

confirm "Would you like to use $BIG_SWAP_PATH ($BIG_SWAP_LABEL) as your swap to resume from? $WARNING" || abort0 'Aborting'
if [ -f "$RESUME_FILE" ]; then
  log "overwriting $RESUME_FILE"
  sudo rm -f -- "$RESUME_FILE"
fi

BIG_SWAP_UUID="$(blkid -o value -s UUID "$BIG_SWAP_PATH")"
printf 'RESUME=UUID=%s\n' "$BIG_SWAP_UUID" | sudo tee "$RESUME_FILE" >/dev/null
# update the initramfs-tools
sudo update-initramfs -u

success
