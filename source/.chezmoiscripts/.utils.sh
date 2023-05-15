#!/usr/bin/env bash
# This is run repeatedly, should
# Source this file to get utilities
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ "$sourced" -eq 0 ]; then err "You should source this file. not run it."; fi

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- Output ---------------------------------------------
## --------------------------------------------------------------------------------------------------

# log "hello world"
function log() { printf "$(tput setaf 11 2>/dev/null)$(tput bold 2>/dev/null)%s\n$(tput sgr0)" "$@"; }
# err "goodbye world" -- shows in bold red - Use $THIS to show `script: error`
function err() { printf "${THIS:+$THIS:}$(tput setaf 1 2>/dev/null)$(tput bold 2>/dev/null)%s\n$(tput sgr0)" "$@" >&2; }
# success - no arguments
function success() { printf "$(tput setaf 2 2>/dev/null)$(tput bold 2>/dev/null)%s$(tput sgr0)\n" "Success!"; }

## --------------------------------------------------------------------------------------------------
## ------------------------------------------ Control Flow ------------------------------------------
## --------------------------------------------------------------------------------------------------

# abort "something went wrong!" 1
function abort() { err "$1" && exit "${2:-2}"; }
# abort0 "something went wrong!" -- exits 0
function abort0() { abort "$1" 0; }
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
  local task command args
  task="$1"
  command="$2"
  args=("${@:3}")
  log "${task^}..." # Uppercase
  "$command" "${args[@]}" || {
    code=$?
    err "Something went wrong while ${task,}!" # Lowercase
    return "$code"
  }
  success
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

# download_file [sudo] <file> <destination> [mode]
function download_file() {
  local cmd=()

  local sudo=''
  if [ "$1" = "sudo" ]; then
    sudo='sudo'
    shift
  fi
  local file_url=$1 dest=$2 mode=$3

  cmd=(curl -sSfL "$file_url" -o "$dest" --create-dirs)
  printf '%s ' $sudo "${cmd[@]}" # Show the constructed command
  $sudo "${cmd[@]}"              # Run the constructed command

  cmd=(chmod "$mode" "$dest")
  printf '%s ' $sudo "${cmd[@]}" # Show the constructed command
  $sudo "${cmd[@]}"              # Run the constructed command
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
OS="$(source /etc/os-release && lower <<<"${NAME:-${ID:-}}" | first_upper)"
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
