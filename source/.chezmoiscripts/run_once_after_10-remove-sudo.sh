#!/usr/bin/env bash
# Remove the "to run a command using sudo..." at start up.

sudo sed '/sudo hint/,/To run a command/s/cat <<-EOF/true <<-EOF/' /etc/bash.bashrc -i
