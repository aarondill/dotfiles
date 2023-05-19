#!/usr/bin/bash

################################################################################
# startup.sh
#
# This shell program is for testing a startup like rc.local using systemd.
# By Aaron Dill
#
################################################################################

# This program should be placed in /usr/local/bin

################################################################################

# don't output to tty1.
dmesg -D
