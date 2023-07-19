#!/usr/bin/env bash
set -euC -o pipefail
# Syncs the google-chrome assets to /dev/shm to decrease disk writes and improve speeds
# This should be run before and after google-chrome if possible
if ! command -v rsync >/dev/null 2>&1; then
  printf '%s\n' "rsync is required to run $0" >&2
  exit 1
elif ! command -v dirname >/dev/null 2>&1; then
  printf '%s\n' "dirname is required to run $0" >&2
  exit 1
elif ! command -v basename >/dev/null 2>&1; then
  printf '%s\n' "basename is required to run $0" >&2
  exit 1
elif ! command -v tr >/dev/null 2>&1; then
  printf '%s\n' "tr is required to run $0" >&2
  exit 1
fi

# doesn't follow the last symlink. ie, in /sym/sym/sym/sym --> /real/real/real/sym
function realpath {
  if ! [ -d "$(dirname -- "$1")" ]; then
    return 1 # fail if not exist
  fi
  dir=$(
    cd "$(dirname -- "$1")" >/dev/null
    pwd -P
  )
  printf "%s\n" "$dir/$(basename -- "$1")"
}

sync_shm() {
  local path volatile static link
  path=$(realpath "$1")

  link="$path"
  static="$(dirname -- "$path")/static-$(basename -- "$path")"
  volatile="/dev/shm/$(printf '%s' "$path" | tr '/' '_')-$USER"

  if [ ! -r "$volatile" ]; then
    mkdir -m0700 -- "$volatile"
  fi

  if ! [ -e "$link" ] && ! [ -L "$link" ]; then
    mkdir -- "$link"
  fi

  if [ "$(readlink "$link")" != "$volatile" ]; then
    if [ -L "$link" ]; then # $link is a link to the wrong place
      rm -- "$link"
    else # $link is the real on-disk folder
      mv -- "$link" "$static"
    fi
    ln -s -- "$volatile" "$link"
  fi

  if [ -e "$link/.unpacked" ]; then
    rsync --inplace -au --delete --exclude .unpacked -- "$link/" "$static/"
  else
    rsync -a -- "$static/" "$link/"
    touch -- "$link/.unpacked"
  fi
}

# PROFILE
conf_dir=${CHROME_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}
sync_shm "$conf_dir/google-chrome"

# CACHE
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
sync_shm "$cache_dir/google-chrome"
