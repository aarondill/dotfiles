#!/usr/bin/env bash

# THIS FILE IS SOURCED! preserve the old options
# https://unix.stackexchange.com/a/383581
OLDOPTS=$(set +o)
case $- in
*e*) OLDOPTS="$OLDOPTS; set -e" ;;
*) OLDOPTS="$OLDOPTS; set +e" ;;
esac
# for this file's safety, won't affect the functions defined here!
set -euC -o pipefail

# This is run repeatedly, should
# Source this file to get utilities
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ "$sourced" -eq 0 ]; then err "You should source this file. not run it."; fi

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- Output ---------------------------------------------
## --------------------------------------------------------------------------------------------------

# COLOR vars to keep from branching to tput repeatedly
RED_COLOR="$(tput setaf 1 2>/dev/null)"
BLUE_COLOR="$(tput setaf 6 2>/dev/null)"
GREEN_COLOR="$(tput setaf 2 2>/dev/null)"
BOLD_COLOR="$(tput bold 2>/dev/null)"
RESET_COLOR="$(tput sgr0 2>/dev/null)"

# log "hello world"
function log() { printf "$BLUE_COLOR$BOLD_COLOR%s\n$RESET_COLOR" "$@"; }
# err "goodbye world" -- shows in bold red - Use $THIS to show `script: error`
function err() { printf "${THIS:+$THIS:}$RED_COLOR$BOLD_COLOR%s\n$RESET_COLOR" "$@" >&2; }
# success - no arguments
function success() { printf "$GREEN_COLOR$BOLD_COLOR%s$RESET_COLOR\n" "Success!"; }

## --------------------------------------------------------------------------------------------------
## ------------------------------------------ Control Flow ------------------------------------------
## --------------------------------------------------------------------------------------------------

# abort "something went wrong!" 1
function abort() { err "$1" && exit "${2:-2}"; }
# confirm "do you really want to do %s?" "that" --> ...do that? (Y/n)
# Strings are evaluated using printf
function confirm() {
  # shellcheck disable=SC2059 # I know this is *generally* wrong, but this is intentional.
  PROMPT="$(printf "$1" "${@:2}")"
  read -rep "$PROMPT (Y/n) " confirmation </dev/tty
  if [[ -z "$confirmation" ]] || [[ "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
    return 0
  fi
  return 1
}
# Usage: log_and_run "Installing something" apt install -y something
function log_and_run() {
  local err_status=0 opts=''
  local task="$1" command="$2" args=("${@:3}")
  log "${task^}..." # Uppercase

  # store errexit option
  case $- in
  *e*) opts='set -e' ;;
  *) opts='set +e' ;;
  esac

  # Sometimes I regret shell scripting things.
  # This is because set -e doesn't work in a conditional.
  # We *want* this to exit on failure, but not exit *this* shell
  # I wish bash was just smarter than this, but instead, we do this.
  # Got the snippet here: https://stackoverflow.com/a/11092989
  set +e
  (
    set -e
    "$command" "${args[@]}"
  )
  err_status=$?
  set -e

  if [ "$err_status" -ne 0 ]; then
    err "Something went wrong while ${task,}!" # Lowercase
    return "$err_status"
  fi
  success
  # set -e back to it's previous state
  eval "$opts"
}
# installed_or_log snap
function installed_or_log() {
  if ! is_accessible_cmd "$1"; then
    err "${1^} is not installed, skipping ${1^} installation"
    return 1
  fi
  return 0
}

# returns 0 if all cmds are available, 1 otherwise
# is_accessible_cmd apt ls git
function is_accessible_cmd() {
  declare -i failed=0
  for cmd; do command -v "$cmd" &>/dev/null || failed=1; done
  return $failed
}

## --------------------------------------------------------------------------------------------------
## ------------------------------------------- Text Utils -------------------------------------------
## --------------------------------------------------------------------------------------------------

# lower <<<"HELLO" -> "hello"
function lower() { local t && t="$(cat -)" && printf '%s' "${t,,}"; }
# first_lower <<<"HELLO" -> "hELLO"
function first_lower() { local t && t="$(cat -)" && printf '%s' "${t,}"; }
# upper <<<"hello" -> "HELLO"
function upper() { local t && t="$(cat -)" && printf '%s' "${t^^}"; }
# first_upper <<<"hello" -> "Hello"
function first_upper() { local t && t="$(cat -)" && printf '%s' "${t^}"; }
# requires sort -V to sort version strings. Errors if $1 is before $2
function version_gt() {
  local hasV=$1 ExpecV=$2 versions=
  versions="$(printf '%s\n' "$hasV" "$ExpecV")"
  # shellcheck disable=SC2319 # $? *should* refer to the condition, not the sort command
  test "$versions" != "$(sort -V <<<"$versions")" || return "$?"
}

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- GitHub ---------------------------------------------
## --------------------------------------------------------------------------------------------------

# get_latest_version_github "someone/something" -> v1.2.3 (tagname)
function get_latest_version_github() (
  set -e            # in subshell
  declare REPO="$1" # combined $OWNER/$REPO
  version=$(curl -sfI "https://github.com/$REPO/releases/latest" | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
  if [ -z "$version" ]; then
    err "Failed while attempting to install $REPO. Please manually install at https://github.com/$REPO/releases"
    return 2
  fi
  echo "$version"
)

# get_latest_version_github "someone/something" -> v1.2.3 (tagname)
function get_latest_version_gitlab() (
  set -e            # in subshell
  declare REPO="$1" # combined $OWNER/$REPO
  version=$(curl -sfI "https://gitlab.com/$REPO/-/releases/permalink/latest" | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
  if [ -z "$version" ]; then
    err "Failed while attempting to install $REPO. Please manually install at https://gitlab.com/$REPO/releases"
    return 2
  fi
  echo "$version"
)

# install_from_github aaron/example latest example.sh /usr/local/bin/example
function install_from_github() (
  set -e # runs in subshell, so doesn't affect outside
  local github_repo=$1 version=$2 asset=$3 destination=$4 TMP
  if [[ -z "$github_repo" ]]; then
    err "GitHub repo can not be an empty string"
    return 2
  elif [[ -z "$asset" ]]; then
    err "asset can not be an empty string"
    return 2
  elif [[ -z "$destination" ]]; then
    err "destination can not be an empty string"
    return 2
  fi

  if [ "$version" = "latest" ]; then version=$(get_latest_version_github "$github_repo"); fi

  log_github_install "$github_repo" "$version" "$asset" "$destination"

  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  curl -SsLf "https://github.com/$github_repo/releases/download/$version/$asset" -o "$TMP"
  sudo mv "$TMP" "$destination" >/dev/null
  sudo chmod +x "$destination"

  rm -f "$TMP" && trap '' EXIT # Cleanup
)
# usage: log_github_install aaron/example latest example.sh /usr/local/bin/
function log_github_install() {
  local github_repo=$1 version=$2 asset=$3 destination=$4
  log "Installing $github_repo version $version ($asset) to $destination"
}

## --------------------------------------------------------------------------------------------------
## -------------------------------------------- Download --------------------------------------------
## --------------------------------------------------------------------------------------------------

# download <URL> ['progress']- outputs to stdout. Pipe it where you need.
# if the exact string 'progress' is passed as the second argument,
# the command will output progress information to stderr. This is for the user, not to parse.
# this should output *only* the contents and should follow redirects.
function download() {
  if [ -z "${1:-}" ]; then
    abort "'download' requires a URL argument." 3
  fi
  local progress=0
  if [ "${2:-}" = progress ]; then progress=1; fi
  if command -v curl &>/dev/null; then
    local quiet=-s
    [ "$progress" -eq 1 ] && quiet=
    curl $quiet -SfL "$1" || return
  elif command -v wget &>/dev/null; then
    local quiet=-q
    [ "$progress" -eq 1 ] && quiet=
    wget $quiet -O- "$1" || return
  fi
}

# This function deletes the file in the first argument, then returns the previous code
function cleanup() {
  local last_exit=$?
  local file=${1:-}
  rm -fr -- "$file"
  return "${last_exit}"
}

# download_file <URL> <destination> [mode]
# destination should be the *final* filename, not a directory.
# this function handles escalation to root when possible.
function download_file() {
  local cmd=() sudo='' dir=''
  local file_url=$1 dest=$2 mode=${3:-}

  dir=$(dirname "$dest")
  # might still exist if the user cancels with SIGINT - can't be avoided without overwriting global trap states
  temp=$(mktemp)
  {
    download "$file_url" >|"$temp"
    if ! mkdir -p "$dir"; then
      sudo=${SUDO:-sudo}
      log "Creating directory failed, trying again with sudo"
      $sudo mkdir -p "$dir" || abort "could not create directory $dir"
    fi

    if ! [ -w "$dest" ]; then sudo=${SUDO:-sudo}; fi
    $sudo install --no-target-directory -- "$temp" "$dest"
    if [ -n "$mode" ]; then $sudo chmod "$mode" "$temp"; fi
    cleanup "$temp"
  } || cleanup "$temp"
}

## --------------------------------------------------------------------------------------------------
## ------------------------------------------- APT utils --------------------------------------------
## --------------------------------------------------------------------------------------------------
function is_installed_apt() { dpkg -s "$@" &>/dev/null; }
function is_available_apt() { test -n "$(apt-cache show -- "$1" 2>/dev/null)"; }

## --------------------------------------------------------------------------------------------------
## ------------------------------------------- Variables --------------------------------------------
## --------------------------------------------------------------------------------------------------

# eg: Linux
KERNEL=$(uname -s)
# eg: x86_64
ARCH=$(uname -m)
# eg: Ubuntu
OS="$(source /etc/os-release && lower <<<"${ID:-${NAME:-}}" | first_upper)"
# eg: /usr/bin/gnome-shell, if empty, gnome not installed
GNOME=$(which gnome-shell 2>/dev/null || printf '')

# Path to apt (or nala) for installation/removal of packages
APT=$(which nala 2>/dev/null || which apt 2>/dev/null || printf '')
# Path to pacman for installation/removal of packages
PACMAN=$(which pacman 2>/dev/null || printf '')

export ARCH KERNEL OS APT GNOME PACMAN
# Code to source *this* file. DON'T MOVE THIS FILE!
# (re)source this file
source_utils() {
  SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
  ## uncomment this if copying this code. It's commented to stop recursive checking:
  ## shellcheck source=./.utils.sh
  . "$SOURCE_DIR/.chezmoiscripts/utils.sh"
}

# Should be the last thing.
# Restore the old options. VERY important because this is sourced, not run.
eval "$OLDOPTS"
