#!/usr/bin/env bash

# ~/.local/bin/script_utils.sh
#
# A template script for writing good scripts
# could be improved, but 🤷
#

set -euC -o pipefail
shopt -s nullglob globstar # Better globs

THIS="script_utils.sh"
function usage() {
  cat <<EOF || return 0
$THIS [options] [--] [arguments]
                  
This does SOMETHING
the environment variable \`SUDO\` can be set to use a different
program for root elevation. It will be split by the shell, so
spaces in the program name will likely be mutilited.

Options:
-h, --help        show this message
-l, --long=long   do something with \$long
-s, --short       enable short
EOF
}
# joins arguments by first argument.
# Usage: join "|" a b c "d e" -> "a|b|c|d e"
function join() {
  local sep="${1:-}" ret="${2:-}"
  if ! shift 2; then return 0; fi
  printf "%s" "$ret" "${@/#/$sep}" || true
}
# Outputs only if $DEBUG is set
function debug() { [ -z "${DEBUG:-}" ] || printf 'DEBUG: %s\n' "$@" >&2 || true; }
function log() { printf '%s\n' "$@" || true; }
function err() { printf "%s\n" "$@" >&2 || true; }
function abort() { err "$1" && exit "${2:-1}"; }
# Return the path of each command passed
function cmdpath() {
  local c && for c in "$@"; do
    command -v -- "$c" 2>/dev/null || printf '\n' || true
  done
}
function has_cmd() {
  local c && for c in "$@"; do
    command -v -- "$c" 2>/dev/null || return "$?"
  done
}
# use like '"${sudo[@]}" do_something'
# shellcheck disable=SC2206 # Splitting is intentional.
sudo=(${SUDO:-sudo})
[ "$(id -u)" -eq 0 ] && sudo=()

# Returns a string that should be 'eval'ed to set the positional arguments
# Store the string in a variable (ie ARGSTRING) to maintain the exit code if parse_args fails.
# Input: $LONGOPTS,$SHORTOPTS
# eval "$(parse_args "$@")"
function parse_args() {
  local parsed
  local code=0 && getopt --test &>/dev/null || code=$?
  if [ "$code" -ne 4 ]; then abort "Enhanced getopt is required for this script to work. Please install it." 1; fi
  parsed=$(getopt --options="$SHORTOPTS" --longoptions="$LONGOPTS" --name "${THIS:-$0}" -- "$@") ||
    exit 2                     # getopt has already complained about wrong arguments to stdout - Exit script
  printf '%s' "set -- $parsed" # output getopt’s output this way to handle the quoting right
}

# option --long/-l requires 1 argument
LONGOPTS="help,short,long:" SHORTOPTS="h,s,l:"
ARGSTRING="$(parse_args "$@")" && eval "$ARGSTRING" || exit

while true; do
  case "$1" in
  -h | --help) usage && exit 0 ;;
  -s | --short) short="true" && shift ;;
  -l | --long) long="$2" && shift 2 ;;
  --) shift && break ;;
  *) abort "This is a bug" 3 ;;
  esac
done
# handle non-option arguments
if [[ "$#" -eq 0 ]]; then abort "POS_ARGUMENT is required" 2; fi
