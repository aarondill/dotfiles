#!/bin/sh
set -eu
# Syncs the google-chrome assets to /dev/shm to decrease disk writes and improve speeds
# This should be run before and after google-chrome if possible
if ! command -v rsync >/dev/null 2>&1; then
  printf '%s\n' "Rsync is required to run $0" >&2
  exit 1
fi

sync_shm() {
  static="static-$1/"
  link="${1%/}"
  volatile="/dev/shm/$1-$USER"

  IFS=
  set -efu

  if [ ! -r "$volatile" ]; then
    mkdir -m0700 -- "$volatile"
  fi

  if ! [ -e "$link" ] && ! [ -f "$link" ]; then
    mkdir -- "$link"
  fi

  if [ "$(readlink "$link")" != "$volatile" ]; then
    mv -- "$link" "$static"
    ln -s -- "$volatile" "$link"
  fi

  if [ -e "$link/.unpacked" ]; then
    rsync --inplace -au --delete --exclude .unpacked "./$link/" "./$static/"
  else
    rsync -a "./$static/" "./$link/"
    touch -- "$link/.unpacked"
  fi
}

# PROFILE
conf_dir=${CHROME_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}
cd "$conf_dir"
sync_shm "google-chrome"

# CACHE
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
cd "$cache_dir"
sync_shm "google-chrome"
