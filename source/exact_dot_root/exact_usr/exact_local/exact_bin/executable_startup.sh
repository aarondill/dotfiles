#!/usr/bin/bash

################################################################################
# startup.sh
#
# This shell program is for testing a startup like rc.local using systemd.
#
################################################################################

# This program should be placed in /usr/local/bin

################################################################################

# don't output to tty1.
dmesg -D
# Fix journal message about unknown keymap when using brightness keys (fn key is unknown)
# 112 is usually unused
sudo setkeycodes e05d 112
