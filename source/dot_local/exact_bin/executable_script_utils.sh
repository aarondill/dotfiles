#!/usr/bin/env bash

# ~/.local/bin/script_utils.sh
#
# A template script for writing good scripts
# could be improved, but 🤷
#

set -euC -o pipefail
shopt -s nullglob globstar # Better globs

# Include this section in any scripts that intend to import this utility module.
if false; then
  # Find the current file and it's directory
  # Source: https://stackoverflow.com/a/246128
  SOURCE="${BASH_SOURCE[0]:-}" DIR=''
  while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$(builtin cd -P -- "$(command dirname -- "$SOURCE")" &>/dev/null && builtin pwd)" || true
    SOURCE="$(command readlink -- "$SOURCE")" || true
    [[ "$SOURCE" == /* ]] || SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  DIR="$(builtin cd -P -- "$(command dirname -- "$SOURCE")" &>/dev/null && builtin pwd)" || true
  DIR="${DIR:-"$PWD"}"
  utils="$DIR/script_utils.sh"
  [ -f "$utils" ] || utils="$(basename -- "$utils")" || true # If utils is not a file, search for it in "$PATH" instead.
  # shellcheck source=./script_utils.sh
  . "$utils"             # Note: this may error. I can't use it in a conditional or bashls fails.
  [ "$?" -eq 0 ] || exit # set -e means that this line should be irrelevant, but just in case.
fi

THIS="$0"
function usage() {
  cat <<-EOF || return 0
$THIS [options] [--] [arguments]
                  
This does SOMETHING. The program using this script should set it's own usage message by overriding the usage function!

Options:
-h, --help        show this message
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
# prints the command and runs it
# verbose echo do something -> echo do something\ndo something
verbose() {
  # ${var@Q} will quote it.
  # Q The expansion is a string that is the value of parameter quoted in a
  # format that can be reused as input.
  local output="> ${*@Q}"
  log "$output"
  "$@" # run the input
}

# confirm "do you really want to do %s?" "that" --> ...do that? (Y/n)
# Strings are evaluated using printf
function confirm() {
  local prompt confirmation
  # shellcheck disable=SC2059 # I know this is *generally* wrong, but this is intentional.
  prompt="$(printf "$1" "${@:2}")"
  read -rep "$prompt (Y/n) " confirmation </dev/tty
  if [ -z "$confirmation" ] || [[ "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
    return 0
  fi
  return 1
}

# Usage: abort message [code]
function abort() { err "$1" && exit "${2:-1}"; }
# Return the path of each command passed, if found
function cmdpath() {
  local e=0
  local c && for c in "$@"; do
    command -v -- "$c" || e="$?"
  done
  return "$e"
}
function has_cmd() {
  local c && for c in "$@"; do
    command -v -- "$c" &>/dev/null || return "$?"
  done
}
# Returns the first executable command found
function first_cmd() {
  local c && for c in "$@"; do
    has_cmd "$c" || continue
    printf "%s" "$c" || true
    return 0
  done
  return 1 # None found
}
# Use in place of sudo. sudo ls -> sudo_cmd ls
function sudo_cmd() {
  local sudo=()
  if [ "$(id -u)" -ne 0 ]; then # non-root, read in sudo from $SUDO
    read -ra sudo -d '' <<<"${SUDO:-sudo}" || true
  fi
  "${sudo[@]}" "$@"
}

tmpfiles=()
# Cleans up the tmp files. If _cleanup is defined, calls it with the same arguments
# Usage: cleanup [files...]
# If no files are specified, cleans up all files in "${tmpfiles[@]}"
function cleanup() {
  local files=("${tmpfiles[@]}")
  [ $? -eq 0 ] || files=("$@") # If arguments are given, clean up *only* those
  if command -v _cleanup; then _cleanup "$@"; fi
  if [ "${#tmpfiles[@]}" -eq 0 ]; then return 0; fi
  local tmp && for tmp in "${files[@]}"; do
    rm -Rf -- "$tmp"
  done
}
# Adds a temporary file to the list of files to cleanup
# Note: traps the EXIT signal!
function add_tmpfile() {
  tmpfiles+=("$@")
  trap 'cleanup' EXIT
}

# Usage: get_xdg_dir "DOWNLOAD"
# Use the same way as you would use xdg-user-dir
# Exits 1 if no value was found.
# Note: if xdg-user-dir is not installed, this may fail
function get_xdg_dir() {
  local dirname=${1^^}
  local var="XDG_${dirname}_DIR"

  local dir="${!var:-}" # Check the environment
  if [ -z "$dir" ]; then
    # Use xdg-user-dir if available
    ! has_cmd xdg-user-dir || dir="$(xdg-user-dir "$dirname" 2>/dev/null)"
  fi

  [ -n "$dir" ] || return 1
  if [ -t 1 ]; then printf '%s\n' "$dir"; else printf '%s' "$dir"; fi
  return 0
}

# download -p <URL> [output] outputs to stdout if output is not specified
# if -p is passed, the command will output progress information to stderr.
# This is for the user, not to parse.
# this should output *only* the contents and should follow redirects.
function download() {
  local progress=0 cmd=()
  local non_options=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
    "-p") progress=1 ;;
    --) non_options+=("${@:2}") && break ;;
    -?*) abort "Unknown option: $1" ;;
    *) non_options+=("$1") ;;
    esac
    shift
  done
  set -- "${non_options[@]}"

  local url="${1:-}" output="${2:-}"
  [ -n "$url" ] || abort "'download' requires a URL argument." 1
  case "$(first_cmd curl wget)" in
  curl)
    cmd=(curl -SfL -o "${output:-"-"}")
    [ "$progress" -eq 1 ] || cmd+=(-s)
    ;;
  wget)
    cmd=(wget -O "${output:-"-"}")
    [ "$progress" -eq 1 ] || cmd+=(-q)
    ;;
  *) abort "'download' requires 'curl' or 'wget'." 1 ;;
  esac
  cmd+=(-- "$url")

  "${cmd[@]}"
}

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

# If this file is being sourced, stop now!
if [ "$0" != "${BASH_SOURCE[0]}" ]; then return 0; fi

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
if [ "$#" -eq 0 ]; then abort "POS_ARGUMENT is required" 2; fi
log "short=$short"
log "long=$long"
