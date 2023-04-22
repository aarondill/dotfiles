#!/bin/bash
# Installs extension sync gnome extension
if ! [ -f /usr/bin/gnome-session ]; then
  # Gnome is not installed
  return 0
fi

curl -sSfL 'https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer' |
  bash /dev/stdin 1486
