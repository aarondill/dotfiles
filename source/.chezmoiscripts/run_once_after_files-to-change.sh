#!/usr/bin/env bash

# source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log 'These files must be changed if the hard-drive uuids have changed'
log "/etc/default/grub, /etc/fstab, /etc/initramfs-tools/conf.d/resume"
# Wait for user input!
log 'press any key to continue...'
read -n1 -rs </dev/tty
