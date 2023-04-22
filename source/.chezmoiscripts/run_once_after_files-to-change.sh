#!/usr/bin/env bash
function log() { printf '%s\n' "$@"; }
log 'These files must be changed if the hard-drive uuids have changed'
log "/etc/default/grub, /etc/fstab, /etc/initramfs-tools/conf.d/resume"
# Wait for user input!
log 'press any key to continue...'
read -n1 -rs </dev/tty
