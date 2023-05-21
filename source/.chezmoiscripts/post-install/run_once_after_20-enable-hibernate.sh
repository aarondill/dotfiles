#!/usr/bin/env bash
# this finds the largest swap partition and *offers* to replace important instances of the backed up source with the uuid
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

GRUB_RESUME_FILE=/etc/default/grub.d/resume.cfg
INITRAMFS_RESUME_FILE=/etc/initramfs-tools/conf.d/resume

if ! [ -d "$(dirname -- "$INITRAMFS_RESUME_FILE")" ]; then INITRAMFS_RESUME_FILE=''; fi

BIG_SWAP_LINE=$(tail -n+2 </proc/swaps | LC_ALL=C sort -t$'\t' -nk3 | tail -n1)
BIG_SWAP_PATH=$(awk '{print $1}' <<<"$BIG_SWAP_LINE") # /dev/sda1
BIG_SWAP_TYPE=$(awk '{print $2}' <<<"$BIG_SWAP_LINE") # file | partition

if [ "$BIG_SWAP_TYPE" = "file" ]; then abort0 "Swap files are not supported by this script. Please use a swap partition or setup youself :)"; fi

WARNING=""
if [ -f "$INITRAMFS_RESUME_FILE" ]; then
  WARNING="WARNING: This will overwrite '$INITRAMFS_RESUME_FILE'"
fi
if [ -f "$GRUB_RESUME_FILE" ]; then
  if [ -z "$WARNING" ]; then
    WARNING="WARNING: This will overwrite '$GRUB_RESUME_FILE'"
  else
    WARNING="$WARNING and '$GRUB_RESUME_FILE'"
  fi
fi

BIG_SWAP_LABEL=$(blkid -s LABEL -o value "$BIG_SWAP_PATH" 2>/dev/null || printf '')
# fallback to parition label
[ -z "$BIG_SWAP_LABEL" ] && BIG_SWAP_LABEL="$(blkid -o value -s PARTLABEL "$BIG_SWAP_PATH" 2>/dev/null || printf '')"
[ -z "$BIG_SWAP_LABEL" ] && BIG_SWAP_LABEL="No Label"

confirm "Would you like to use $BIG_SWAP_PATH ($BIG_SWAP_LABEL) as your swap to resume from? $WARNING" || abort0 'Aborting'

BIG_SWAP_UUID="$(blkid -o value -s UUID "$BIG_SWAP_PATH")"
printf 'RESUME=UUID=%s\n' "$BIG_SWAP_UUID" | sudo tee "$INITRAMFS_RESUME_FILE" >/dev/null

# Setup grub config file
cat <<EOF | sudo tee "$GRUB_RESUME_FILE" >/dev/null
#!/usr/bin/env sh
# MAKE SURE this matches your swap partition's UUID
GRUB_CMDLINE_LINUX_DEFAULT="\$GRUB_CMDLINE_LINUX_DEFAULT resume=UUID='$BIG_SWAP_UUID'"
EOF
log "Run these commands to use the changes: " "'update-initramfs -u -k all'" "'update-grub'"

success
