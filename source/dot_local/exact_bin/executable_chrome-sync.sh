#!/bin/sh
# Syncs the google-chrome assets to /dev/shm to decrease disk writes and improve speeds
# This should be run before and after google-chrome if possible

sync_shm() {
  static="static-$1/"
  link="$1"
  volatile="/dev/shm/$1-$USER"

  IFS=
  set -efu

  if [ ! -r "$volatile" ]; then
    mkdir -m0700 "$volatile"
  fi

  if [ "$(readlink "$link")" != "$volatile" ]; then
    mv "$link" "$static"
    ln -s "$volatile" "$link"
  fi

  if [ -e "$link/.unpacked" ]; then
    rsync -av --delete --exclude .unpacked "./$link/" "./$static/"
  else
    rsync -av "./$static/" "./$link/"
    touch "$link/.unpacked"
  fi
}

# PROFILE
cd ~/.config/
sync_shm "google-chrome"

# CACHE
cd ~/.cache/
sync_shm "google-chrome"
