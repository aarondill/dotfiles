#!/usr/bin/env bash

# ~/.local/bin/script_utils.sh
#
# A utility script for writing other scripts
# Note: must be in the PATH!
#

# Include this section in any scripts that intend to import this utility module.
if false; then
  set -euC -o pipefail && shopt -s nullglob globstar
  utils=script_utils.sh dir=$(dirname -- "${BASH_SOURCE[0]}") || true
  if [ -f "$dir/$utils" ]; then utils="$dir/$utils"; fi
  . "$utils"
fi

# Set the XDG_*_DIR variables to defaults if not set
XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
XDG_DATA_DIRS=${XDG_DATA_DIRS:-"/usr/local/share/:/usr/share/"}
XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-"/etc/xdg/"}

# The name of the currently running script. Override this if the current filename's basename is not satisfactory.
# If $0 is not defined, defaults to ${BASH_SOURCE[1]} (the calling script)
THIS="$(basename -- "${0:-${BASH_SOURCE[1]}}")" # This script is designed to be sourced. $0 should be the name of the parent script.
function usage() {
  cat <<EOF || true
Usage: $THIS [options] [--] [arguments]
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
# splits arguments by delim argument.
# Note: if string ends in a delim, an empty element will be present in the output
# Usage: split arr '|' "a|b|c" -> arr=(a b c)
function split() {
  local delim="$2" str="$3" elem ends_with_delim=0
  [ -n "$delim" ] || abort "Invalid delimiter" 2
  case "$str" in # Bash-ls chokes if this is on one line!
  *"$delim") ends_with_delim=1 ;; esac
  # shellcheck disable=SC2178 # It's not being treated as a string, declare -n is special
  declare -n __out_arr="$1"  # we can now use __out_arr to assign to outside variable
  __out_arr=()               # clear the output array
  while [ -n "$str" ]; do    # Loop until str is empty
    elem="${str%%"$delim"*}" # strip first delimiter and all trailing string
    str=${str#"$elem"}       # strip element from remaining string
    str=${str#"$delim"}      # strip delimiter if present
    __out_arr+=("$elem")     # return the found element
  done
  # input string ends with delim? add an empty element
  [ "$ends_with_delim" -eq 0 ] || __out_arr+=("")
}

# Usage: find_in_path cmdname ["$0"]
# Finds the (basename of) cmdname in $PATH, optionally excluding the current file
function find_in_path() {
  [ -n "${PATH:-}" ] || return 1
  local path cmd exclude="${2:-}"
  cmd=${1%/} cmd="${1##*/}" # remove trailing slash -- then get basename
  while read -r -d: path; do
    path=${path:-$PWD} # empty path means pwd

    [ -z "$exclude" ] || [ "$path/$cmd" != "$exclude" ] || continue # skip this_file
    [ -x "$path/$cmd" ] || continue                                 # Only executables
    printf '%s' "$path/$cmd" || true
    return 0
  done < <(printf '%s' "$PATH:")
  return 1
}

# Return the path of each command passed, if found
# Always returns an executable file.
function cmdpath() {
  declare -i e=0
  local path=''
  local c && for c in "$@"; do
    path="$(command -v -- "$c")" || true
    [ -x "$path" ] || path=$(find_in_path "$c") || e=1
    [ -n "$path" ] || continue # Skip not found
    printf '%s\n' "$path" || true
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

# Note: each value should be the same as the key
declare -A FILE_TYPES=(
  [symlink]="symlink"     # -L
  [directory]="directory" # -d
  [file]="file"           # -f
  [chardev]="chardev"     # -c
  [blockdev]="blockdev"   # -b
  [fifo]="fifo"           # -f
  [socket]="socket"       # -S
)

# Usage: file_type ./some_file [-s]
# if -s is given, returns 'symbolic link' for all symlinks, whether broken or not
# if -s is not given, returns 'symbolic link' only for broken symlinks
# return values are the values of ${FILE_TYPES[@]}
# NOTE: this may be a very expesive operation, as it has to do several file system operations
# Bash doesn't provide a way to get the file type in a single operation :(
function file_type() {
  local type deref=1              # dereference by default
  [ "${2:-}" != '-s' ] || deref=0 # caller has asked not to dereference

  if ! [ -e "$1" ]; then
    [ -L "$1" ] || return 1     # The file doesn't exist
    type=${FILE_TYPES[symlink]} # broken link
  elif [ "$deref" -eq 0 ] && [ -L "$1" ]; then
    type=${FILE_TYPES[symlink]} # non-broken link, but the caller wants links
  elif [ -f "$1" ]; then
    type=${FILE_TYPES[file]}
  elif [ -d "$1" ]; then
    type=${FILE_TYPES[directory]}
  elif [ -c "$1" ]; then
    type=${FILE_TYPES[chardev]}
  elif [ -b "$1" ]; then
    type=${FILE_TYPES[blockdev]}
  elif [ -p "$1" ]; then
    type=${FILE_TYPES[fifo]}
  elif [ -S "$1" ]; then
    type=${FILE_TYPES[socket]}
  else
    err "Unknown file type: $1. This is a bug!"
    return 3
  fi

  printf '%s\n' "$type" || true
}

# Adds a numerical suffix to a file until a filename is found that doesn't exist
# Note: if used in a subshell, bash will trim the trailing newline:
# for this usecase, provide an outvar. If an outvar is provided, no output will be generated
# usage: get_valid_file FILE [suffix] [outvar]
# If file doesn't end in suffix, then suffix will be ignored.
# Ex: get_unique_filename "file.jpg" ".jpg" -> file-9999.jpg OR file.jpg
# Ex: get_unique_filename "file.ext" -> file.ext-9999 OR file.ext
# Ex: get_unique_filename "file.ext" ".jpg" -> file.ext-9999 OR file.ext
function get_unique_filename() {
  # suffix may be empty
  local original_file="$1" suffix="${2:-}"
  local file_start="${original_file%"$suffix"}"
  [ "$file_start" != "$original_file" ] || suffix='' # ignore suffix if not present
  local _output="$file_start$suffix"

  declare -i i=1
  # broken symlinks fail the -e check, but still exist
  while [ -e "$_output" ] || [ -L "$_output" ]; do
    _output="$file_start-$i$suffix"
    i=$((i + 1))
  done

  local outvar="${3:-}"
  if [ -n "$outvar" ]; then
    unset original_file suffix file_start # Ensure these can't be changed by outvar
    declare -n outvar                     # assignment to outvar goes to named variable
    outvar="$_output"
  else
    printf '%s' "$_output" || true
  fi
}

# Usage: resolve_path path [-s]
# Find the absolute path of a file or directory. If -s is given, doesn't resolve symlinks.
# All but the last component must exist.
# note: relies on dirname, basename, and readlink
# Source: https://stackoverflow.com/a/246128
function resolve_path() {
  local CDPATH='' OLDPWD=''
  local source="${1:-}" dir=''
  [ -n "$source" ] || return 1
  if [ "${2:-}" != '-s' ]; then
    while [ -L "$source" ]; do # resolve $source until the file is no longer a symlink
      dir="$(builtin cd -P -- "$(dirname -- "$source")" &>/dev/null && builtin pwd)"
      source="$(readlink -- "$source")"
      [[ "$source" == /* ]] || source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    dir="$(builtin cd -P -- "$(dirname -- "$source")" &>/dev/null && builtin pwd)"
  else
    dir="$(builtin cd -- "$(dirname -- "$source")" &>/dev/null && builtin pwd)"
  fi
  dir="${dir:-"$PWD"}"
  source="$dir/$(basename -- "$source")"
  printf '%s' "$source"
}

# Find the absolute path of the calling file
function get_script_path() { resolve_path "${1-${BASH_SOURCE[1]:-}}"; }

# If this variable is set to 1, color will be turned on when stdout is a terminal (unless NO_COLOR is set)
declare -i USE_COLOR="${USE_COLOR:-0}"
# If this variable is set to 0, the verbose() function will not output anything, and just calls the arguments
declare -i USE_VERBOSE="${USE_VERBOSE:-1}"
YELLOW_COLOR='' TEAL_COLOR='' RED_COLOR='' PINK_COLOR='' OFF_COLOR=''
if has_cmd tput; then
  YELLOW_COLOR="$(tput setaf 3 2>/dev/null)" || true # Used for warn
  TEAL_COLOR="$(tput setaf 6 2>/dev/null)" || true   # Used for log
  GREEN_COLOR="$(tput setaf 2 2>/dev/null)" || true  # Used for verbose commands
  RED_COLOR="$(tput setaf 1 2>/dev/null)" || true    # Used for error
  PINK_COLOR="$(tput setaf 5 2>/dev/null)" || true   # Used for debug
  BOLD_COLOR="$(tput bold 2>/dev/null)" || true      # Used for success
  OFF_COLOR="$(tput sgr0 2>/dev/null)" || true       # Used to return to default colors
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

# A message
function log() { printf_c "$TEAL_COLOR" '%s\n' "$@" || true; }
function err() { printf_c "$RED_COLOR" "%s\n" "$@" >&2 || true; }
function warn() { printf_c "$YELLOW_COLOR" "%s\n" "$@" >&2 || true; }
function success() { printf_c "$GREEN_COLOR$BOLD_COLOR" "%s\n" "Success!" || true; }
function print_cmd() {
  # ${var@Q} will quote it.
  # Q The expansion is a string that is the value of parameter quoted in a
  # format that can be reused as input.
  local output='>'                   # use > for prompt
  [ "$(id -u)" -ne 0 ] || output='$' # if root, use $ for prompt
  output+=" ${*@Q}"                  # add quoted command line to output
  printf_c "$GREEN_COLOR" '%s\n' "$output" || true
}
# calls log only if USE_VERBOSE is non-zero
function vlog() { [ "${USE_VERBOSE:-0}" -eq 0 ] || log "$@"; }
# prints the command and runs it
# verbose echo do something -> echo do something\ndo something
function verbose() {
  # if USE_VERBOSE != 0, then output current command to stdout
  [ "${USE_VERBOSE:-0}" -eq 0 ] || print_cmd "$@"
  "$@"
}

# trims leading and trailing whitespace
function trim() {
  local orig="$1" trmd=""
  while true; do
    trmd="${orig#[[:space:]]}" trmd="${trmd%[[:space:]]}"
    [ "$trmd" != "$orig" ] || break
    orig="$trmd"
  done
  printf '%s' "$trmd"
}

# confirm "do you really want to do that?"
# Case insensitive matching!
# Accepts: 'y', 'yes', 'Y', and 'Yes' as true (exit 0)
# Accepts: 'n', 'no', 'N', and 'No' as false (exit 1)
# Unrecognized values are considered false (exit 3)
# The second argument can be either y or n (default 'y') to choose the default value (given a blank answer)
function confirm() {
  local confirmation colorized_prompt
  local prompt="$1" default=${2:-y}
  default=${default:0:1} default=${default,,} # lowercase first char of argument
  case "$default" in                          # Set the prompt to have the right default value
  y) prompt+=' [Y/n]' ;; n) prompt+=' [y/N]' ;;
  esac
  colorized_prompt="$(color "$TEAL_COLOR")$prompt$(color "$OFF_COLOR") "
  read -rep "$colorized_prompt" confirmation </dev/tty
  # toLowerCase, then trim
  case "$(trim "${confirmation,,}")" in
  y | yes) return 0 ;;
  n | no) return 1 ;;
  "")                                 # no response
    [ "$default" == 'y' ] || return 1 # default is no, return false
    return 0                          # default is yes, return true
    ;;
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
# Returns true if the given string is an integer value
is_integer() { [ -n "$1" ] && case "$1" in *[!0123456789]*) return 1 ;; esac }
# returns the number of arguments passed to it.
# this can be especially useful with globs
count() { printf '%d\n' "$#" || true; }

# Opens an editor with the given file(s)
# Note: doesn't check for stdout terminality. Ensure the user expects an editor!
# uses \$VISUAL or \$EDITOR if defined
function edit() {
  local editor
  editor=${VISUAL:-${EDITOR:-}}
  [ -n "$editor" ] || editor=$(first_cmd editor sensible-editor vim emacs nano) || abort "Could not find editor" 1
  local cmd=()
  split cmd " " "$editor" # split editor by spaces
  cmd+=(-- "$@")          # add files
  command "${cmd[@]}"     # run the editor
}
# Opens a pager with the given file(s)
# Doesn't page if stdout is not a terminal
# Uses $PAGER if defined
function page() {
  local pager=''
  # Use pager if can, else use cat
  if [ -t 1 ]; then pager=${PAGER:-$(first_cmd pager bat less)} || true; fi
  [ -n "$pager" ] || pager=$(first_cmd cat /bin/cat) || abort "Could not find pager" 1
  local cmd=()
  split cmd " " "$pager" # split pager by spaces
  cmd+=(-- "$@")         # add files
  command "${cmd[@]}"    # run the pager
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
