#!/usr/bin/env bash
set -euC -o pipefail
function log() { printf '%s\n' "$@" || true; }
function err() { printf '%s\n' "$@" >&2 || true; }
function abort() {
  err "$1"
  exit "${2:-1}"
}
# Syncs the google-chrome assets to /dev/shm to decrease disk writes and improve speeds
# This should be run before and after google-chrome if possible
function required() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      abort "$cmd is required to run $0" 1
    fi
  done
}
# This is the main third-party dependency, which may not be installed. Many systems include it, but it can't be guarenteed.
required rsync
# These are POSIX, so should be present on any posix system
required dirname basename
# These are coreutils and expected to always be present
required mkdir rm mv ln touch tr

# doesn't follow the last symlink. ie, in /sym/sym/sym/sym --> /real/real/real/sym
function posix_realpath {
  if ! [ -d "$(dirname -- "$1")" ]; then
    return 1 # fail if not exist
  fi
  dir=$(
    cd "$(dirname -- "$1")" >/dev/null
    pwd -P
  )
  log "$dir/$(basename -- "$1")"
}

function sync_shm() {
  local path volatile static link
  path=$(posix_realpath "$1")

  link="${path%/}"
  static="${path%/}-static"
  volatile="/dev/shm/$(printf '%s' "${path%/}" | tr '/' '_')-$USER"

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

  if [ -e "$link/.unpacked" ]; then # we have alredy unpacked (run once before)
    # move (inplace) newer files from unpacked to static, removing any that no longer exist and excluding the .unpacked file
    rsync --inplace --archive --update --delete --exclude .unpacked -- "$link/" "$static/"
  else # We have not run before (just moved $link to $static or fresh boot)
    # Move files from static to the unpacked directory
    rsync --archive -- "$static/" "$link/"
    touch -- "$link/.unpacked"
  fi
}

if [ "$#" -gt 0 ]; then abort "This script accepts no arguments." 2; fi

# if [ -n "${SOMMELIER_VERSION:-}" ]; then abort "ChromeOS development environment is currently not supported." 1; fi

conf_dir=${XDG_CONFIG_HOME:-$HOME/.config}
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
local_dir=$HOME/.local/share # other setups are not supported with firefox

# default BROWSER to x-www-browser/vivaldi if not specified.
# This is used for systemd services which don't get .profile/.bashrc env variables
if [ -z "${BROWSER:-}" ]; then
  [ -x "/usr/bin/x-www-browser" ] &&
    BROWSER="$(realpath "/usr/bin/x-www-browser" 2>/dev/null)" ||
    BROWSER="vivaldi"
fi

if ! [ -x "$BROWSER" ] && ! command -v "$BROWSER" >/dev/null 2>/dev/null; then
  abort "$BROWSER is not installed. Aborting." 1
fi

case "$BROWSER" in # Sync active browser (or vivaldi as default)
*vivaldi*)
  # msg="Vivaldi chrome sync is disabled to test stability! Don't forget to reenable this."
  # err "$msg"
  # DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u aaron)/bus" DISPLAY=:0 notify-send "Warning" "$msg" 2>/dev/null || true
  sync_shm "$conf_dir/vivaldi"  # PROFILE
  sync_shm "$cache_dir/vivaldi" # CACHE
  ;;
*firefox*)
  sync_shm "$local_dir/firefox" # Everything is firejailed into this directory
  ;;
*google-chrome*)
  sync_shm "$conf_dir/google-chrome"  # PROFILE
  sync_shm "$cache_dir/google-chrome" # CACHE
  ;;
*) abort "Browser $BROWSER is not supported" 3 ;;
esac
