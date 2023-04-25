#!/bin/bash
# Source this file to get utilities

function log() { printf '%s\n' "$@"; }
function err() { printf '%s\n' "$@" >&2; }
function success() { printf "$(tput setaf 2)%s$(tput sgr0)\n" "Success!"; }
function abort() { err "$@" && exit 2; }
function abort0() { err "$@" && exit 0; }
function confirm() {
  read -rep "$* (Y/n) " confirmation
  if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
    return 0
  fi
  return 1
}
function lower() { local t && t="$(cat -)" && printf '%s' "${t,,}"; }
function first_lower() { local t && t="$(cat -)" && printf '%s' "${t,}"; }
function upper() { local t && t="$(cat -)" && printf '%s' "${t^^}"; }
function first_upper() { local t && t="$(cat -)" && printf '%s' "${t^}"; }

# returns 0 if all cmds are available, 1 otherwise
function is_accessible_cmd() {
  declare -i failed=0
  for cmd; do command -v "$cmd" &>/dev/null || failed=1; done
  return $failed
}

function log_and_run() {
  # Usage: log_and_run "Installing something" apt install -y something
  local task command args
  task="$1"
  command="$2"
  args=("${@:3}")
  (
    set -e
    log "${task^}..." # Uppercase
    "$command" "${args[@]}"
    success
  ) || err "Something went wrong while ${task,}!" # Lowercase
}

function get_latest_version_github() (
  set -e            # in subshell
  declare REPO="$1" # combined $OWNER/$REPO
  version=$(curl -sI "https://github.com/$REPO/releases/latest" | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
  if [ -z "$version" ]; then
    err "Failed while attempting to install $REPO. Please manually install at https://github.com/$REPO/releases"
    return 2
  fi
  echo "$version"
)
# usage: `install_from_github aaron/example latest example.sh /usr/local/bin/example`
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

# download_file [sudo] <file> <destination> [mode]
function download_file() {
  local cmd=() file_url=$1 dest=$2 mode=$3 need_sudo=''

  if [ "$1" = "sudo" ]; then
    need_sudo=true
  fi
  if [ "$need_sudo" ]; then
    file_url=$2 dest=$3 mode=$4
    cmd=("sudo" "${cmd[@]}")
  fi

  cmd=("${cmd[@]}" curl -sSfL "$file_url" -o "$dest" --create-dirs)

  echo "${cmd[@]}" # show the constructed command
  "${cmd[@]}"      # Run the constructed command

  local cmd=(chmod "$mode" "$dest")
  if [ "$need_sudo" ]; then
    cmd=(sudo "${cmd[@]}")
  fi

  echo "${cmd[@]}" # show the constructed command
  "${cmd[@]}"      # Run the constructed command
}

KERNEL=$(uname -s) # eg: Linux
ARCH=$(uname -m)   # eg: x86_64
OS=$(lsb_release -si)
export ARCH KERNEL OS

# Code to source *this* file. DON'T MOVE THIS FILE!
# SOURCE_DIR=$(chezmoi source-path)
# # shellcheck source=.utils.sh
# . "$SOURCE_DIR/.chezmoiscripts/utils.sh"
