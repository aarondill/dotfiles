#!/bin/bash
# this tars the '~/.root' directory and unzips it at '/'
# This script *MUST* ask confirmation! These are breaking changes!
# This script should aslo suggest running 'sudo update-grub' and 'sudo update-initramfs -u'
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

ROOTBACKUP="$HOME/.root"
TARDESTFILE="$(mktemp)"
trap 'rm -f "$TARDESTFILE"' EXIT

confirm 'Would you like to update / with the contents of %s?' "$ROOTBACKUP" || abort0 "Aborting"

# Find safe backup directory
BACKUPDIR_ROOT="/backup"
BACKUPDIR="$BACKUPDIR_ROOT"
declare -i I=1
while [ -d "$BACKUPDIR" ]; do
  BACKUPDIR="$BACKUPDIR_ROOT-$I"
  I=$((I + 1))
done

declare -i BACKUP=0
confirm 'Would you like to keep backups of overwritten files in / in %s?' "$BACKUPDIR" && BACKUP=1

# Don't record /home/$USER/.root/, instead start at subdirs
find "$ROOTBACKUP"/ -maxdepth 1 -mindepth 1 -type d -printf '%f\0' |
  tar -cf "$TARDESTFILE" -C "$ROOTBACKUP"/ --null -T -

if [ $BACKUP -ne 0 ]; then
  # List files
  FILES=$(tar -tf "$TARDESTFILE" | sed 's/^/\//')
  for file in $FILES; do
    # Ensure unreadable files are still copied
    if sudo test -f "$file"; then
      # Ensure destination directory exists -- sudo so can be located at root
      sudo mkdir -p "$BACKUPDIR/$(dirname -- "$file")"
      # copy the file to the destination
      sudo cp -T -- "$file" "$BACKUPDIR/$file"
    fi
  done
fi

log "Last chance to safely stop overwrite of root. Press ctrl-c to cancel."

# On ctrl-c, previous trap will occur, removing temporary file. backup will remain, but not a problem.
secs=$((5))
while [ $secs -gt 0 ]; do
  echo -ne "$secs\033[0K\r"
  sleep 1
  secs=$((secs - 1))
done

# Important! Overwrites files in ROOT!
# --no-same-owner to ensure owned by root (sudo)
sudo tar --no-same-owner -xf "$TARDESTFILE" -C /

log "NOTE: Please consider running 'update-grub' and 'update-initramfs -u' 'dpkg-reconfigure console-setup -phigh' in case these files changed (or the corresponding commmands)."
success
