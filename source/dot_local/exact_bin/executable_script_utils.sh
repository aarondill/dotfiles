#!/usr/bin/env bash

# ~/.local/bin/script_utils.sh
#
# A utility script for writing other scripts
# Note: must be in the PATH!
#

# Include this section in any scripts that intend to import this utility module.
if false; then
  set -euC -o pipefail
  shopt -s nullglob globstar # Better globs
  . script_utils.sh || exit
fi

# The name of the currently running script. Override this if the current filename's basename is not satisfactory.
# If $0 is not defined, defaults to ${BASH_SOURCE[1]} (the calling script)
THIS="$(basename -- "${0:-${BASH_SOURCE[1]}}")" # This script is designed to be sourced. $0 should be the name of the parent script.
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

# Return the path of each command passed, if found
function cmdpath() {
  local e=0
  local c && for c in "$@"; do
    command -v -- "$c" || e="$?"
  done
  return "$e"
}
# Returns 1 if all commands are available, 0 otherwise
function has_cmd() {
  local c && for c in "$@"; do
    command -v -- "$c" &>/dev/null || return "$?"
  done
}
# an alias for has_cmd
function has() { has_cmd "$@"; }

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

# If this variable is set to 1, color will be turned on when stdout is a terminal (unless NO_COLOR is set)
declare -i USE_COLOR=0
# If this variable is set to 0, the verbose() function will not output anything, and just calls the arguments
declare -i USE_VERBOSE=1
YELLOW_COLOR='' TEAL_COLOR='' RED_COLOR='' PINK_COLOR='' OFF_COLOR=''
if has_cmd tput; then
  YELLOW_COLOR="$(tput setaf 3 2>/dev/null || printf '')" # Used for warn
  TEAL_COLOR="$(tput setaf 6 2>/dev/null || printf '')"   # Used for log
  GREEN_COLOR="$(tput setaf 2 2>/dev/null || printf '')"  # Used for verbose commands
  RED_COLOR="$(tput setaf 1 2>/dev/null || printf '')"    # Used for error
  PINK_COLOR="$(tput setaf 5 2>/dev/null || printf '')"   # Used for debug
  BOLD_COLOR="$(tput bold 2>/dev/null || printf '')"      # Used for success
  OFF_COLOR="$(tput sgr0 2>/dev/null || printf '')"       # Used to return to default colors
fi

# Usage: color "$(tput setaf 3)"
# Only outputs if stdout is a terminal and environment variables are correct
# respects: FORCE_COLOR!=0, USE_COLOR!=0, NO_COLOR==''
# note: if FORCE_COLOR is set and non-zero, other checks are ignored
# If you use tput to get color codes (you should!), it will handle the TERM variable
# Outputs the escape code using printf
function color() {
  [ "${FORCE_COLOR:-}" != 0 ] || return 0  # FORCE_COLOR must not be 0
  if [ -z "${FORCE_COLOR:-}" ]; then       # If FORCE_COLOR is set, don't do any other checks
    [ -t 1 ] || return 0                   # stdout must be a terminal
    [ "${USE_COLOR:-0}" != 0 ] || return 0 # USE_COLOR must be non-zero
    [ -z "${NO_COLOR:-}" ] || return 0     # NO_COLOR must be null
  fi
  printf '%b' "$@" || true
}

# printf in color. Note: this won't work with -v!
# If stdout is not a terminal, or USE_COLOR is 0, calls printf without changing the color codes
# Outputs the color code $1, then runs printf with the remaining arguments and then sets the color back to default
# Returns printf's return code
function printf_c() {
  local code=0
  color "$1" || true
  # shellcheck disable=SC2059 # This is a printf wrapper. it needs to have variables in the format string
  printf "${@:2}" || code="$?"
  color "$OFF_COLOR" || true
  return "$code"
}

# Outputs only if $DEBUG is set
function debug() { [ -z "${DEBUG:-}" ] || printf_c "$PINK_COLOR" 'DEBUG: %s\n' "$@" >&2 || true; }
function log() { printf_c "$TEAL_COLOR" '%s\n' "$@" || true; }
function err() { printf_c "$RED_COLOR" "%s\n" "$@" >&2 || true; }
function warn() { printf_c "$YELLOW_COLOR" "%s\n" "$@" >&2 || true; }
function success() { printf_c "$GREEN_COLOR$BOLD_COLOR" "%s\n" "Success!" || true; }
# prints the command and runs it
# verbose echo do something -> echo do something\ndo something
function verbose() {
  # ${var@Q} will quote it.
  # Q The expansion is a string that is the value of parameter quoted in a
  # format that can be reused as input.
  # if USE_VERBOSE != 0, then output current command to stdout
  if [ "${USE_VERBOSE:-0}" -ne 0 ]; then
    local output='>'                   # use > for prompt
    [ "$(id -u)" -ne 0 ] || output='$' # if root, use $ for prompt
    output+=" ${*@Q}"                  # add quoted command line to output
    printf_c "$GREEN_COLOR" '%s\n' "$output" || true
  fi
  "$@"
}

# confirm "do you really want to do that?"
# Case insensitive matching!
# Accepts: 'y', 'yes', 'Y', and 'Yes' as true (exit 0)
# Accepts: 'n', 'no', 'N', and 'No' as false (exit 1)
# Unrecognized values are considered false (exit 3)
# The second argument can be either y or n (default 'y') to choose the default value (given a blank answer)
function confirm() {
  local prompt="$1" default=${2:-y}
  local confirmation colorized_prompt
  colorized_prompt="$(color "$TEAL_COLOR")$prompt [Y/n]$(color "$OFF_COLOR") "
  read -rep "$colorized_prompt" confirmation </dev/tty
  if [ -z "$confirmation" ]; then     # no response
    [ "$default" == 'y' ] || return 1 # default is no, return false
    return 0                          # default is yes, return true
  fi

  local trimed=${confirmation,,}
  trimed=${trimed# *}
  case "${confirmation,,}" in
  y | yes) return 0 ;;
  n | no) return 1 ;;
  *) return 3 ;;
  esac
}

# Usage: abort message [code]
function abort() { err "$1" && exit "${2:-1}"; }

# Output a message about missing dependencies and return 1 if any
# Use `set -e`, or `|| exit` to exit on error
function check_dependencies() {
  local cmd missing=()
  for cmd in "$@"; do
    if ! has_cmd "$cmd"; then missing+=("$cmd"); fi
  done
  if [ "${#missing[@]}" -eq 0 ]; then return 0; fi
  # Output an error if there are missing dependencies
  err "$THIS: $(join ', ' "${missing[@]}") is required to use this program!"
  return 1 # this will exit on `set -e`
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
# Use to set the $sudo array to an executable command
# Usage: set_sudo_cmd && exec "${sudo[@]}" other-command
function set_sudo_cmd() {
  sudo=()
  [ "$(id -u)" -ne 0 ] || return 0               # root, sudo is empty
  read -ra sudo -d '' <<<"${SUDO:-sudo}" || true # non-root, read in sudo from $SUDO
}
# Use in place of sudo. sudo ls -> sudo_cmd ls
function sudo_cmd() {
  local sudo=()
  set_sudo_cmd
  "${sudo[@]}" "$@"
}

tmpfiles=()
# Cleans up the tmp files. If _cleanup is defined, calls it with the same arguments
# Usage: cleanup [files...]
# If no files are specified, cleans up all files in "${tmpfiles[@]}"
function cleanup() {
  local files=("${tmpfiles[@]}")
  [ "$?" -eq 0 ] || files=("$@") # If arguments are given, clean up *only* those
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
    [ "$progress" = 1 ] || cmd+=(-s)
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

# Anything below here is an example. it will only run if this script is directly ran.
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
