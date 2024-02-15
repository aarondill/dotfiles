#!/usr/bin/env bash

# Find the absolute path of the calling file
# note: relies on dirname, basename, and readlink
# Source: https://stackoverflow.com/a/246128
function get_script_path() {
  local CDPATH='' OLDPWD=''
  # note: ${1-other}, no colon. if given empty string, fail fast
  local source="${1-${BASH_SOURCE[1]:-}}" dir=''
  [ -n "$source" ] || return 1
  while [ -L "$source" ]; do # resolve $source until the file is no longer a symlink
    dir="$(builtin cd -P -- "$(dirname -- "$source")" &>/dev/null && builtin pwd)"
    source="$(readlink -- "$source")"
    [[ "$source" == /* ]] || source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  dir="$(builtin cd -P -- "$(dirname -- "$source")" &>/dev/null && builtin pwd)"
  dir="${dir:-"$PWD"}"
  source="$dir/$(basename -- "$source")"
  printf '%s' "$source"
}
abort() {
  printf '%s\n' "$1" >&2 || true
  exit "${2:-1}"
}

this=$(get_script_path "${BASH_SOURCE[0]}")
script="$(dirname -- "$this")/$(basename -- "$0")"
[ "$script" != "$this" ] || abort "$(basename -- "$this"): can not execute self!"
exec -- "$script"
