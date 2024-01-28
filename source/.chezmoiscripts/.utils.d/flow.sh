#!/usr/bin/env bash
# ==> flow.sh <==
_UTIL_D="$(dirname -- "${BASH_SOURCE[0]}")"
if [ -z "${_LEADER:-}" ]; then
  _LEADER="${BASH_SOURCE[0]}"
  _OLD_PWD="$(pwd)"
  builtin cd -- "$_UTIL_D"
  . ../.utils.sh # assert_source_once
fi
assert_source_once "${BASH_SOURCE[0]}" || return 0

if true; then
  . ./output.sh # err, log, success
fi

if [ "${BASH_SOURCE[0]}" = "$_LEADER" ]; then
  builtin cd -- "$_OLD_PWD"
  unset _OLD_PWD _UTIL_D _LEADER
fi

## --------------------------------------------------------------------------------------------------
## ------------------------------------------ Control Flow ------------------------------------------
## --------------------------------------------------------------------------------------------------

# abort "something went wrong!" 1
function abort() { err "$1" && exit "${2:-2}"; }
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
# confirm_exact "Type '%s' to confirm?" "exact confirmation"
# Strings are evaluated using printf
function confirm_exact() {
  local prompt confirmation
  local confirm_string=$2
  # shellcheck disable=SC2059 # I know this is *generally* wrong, but this is intentional.
  prompt="$(printf "$1" "$2")"
  read -rep "$prompt " confirmation </dev/tty
  [ "$confirmation" = "$confirm_string" ]
}
# Usage: log_and_run "Installing something" apt install -y something
function log_and_run() {
  local err_status=0 opts=''
  local task="$1" cmd=("${@:2}")
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
    "${cmd[@]}"
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
  if ! has_cmd "$1"; then
    err "${1^} is not installed, skipping ${1^} installation"
    return 1
  fi
  return 0
}

# returns 0 if all cmds are available, 1 otherwise
# has_cmd apt ls git
function has_cmd() {
  declare -i failed=0 # declare=local
  local cmd &&
    for cmd; do command -v -- "$cmd" &>/dev/null || failed=1; done
  return "$failed"
}

# returns the path of the command given
function cmd_path() { command -v -- "$1"; }

# usage: has_cmd <cmds>...
# Find the first available command in a list and print it.
# example: nodejs=$(first_cmd node nodejs)
function first_cmd() {
  local cmd
  local cmds=("$@")
  if [ "${#cmds}" -eq 0 ] && ! [ -t 0 ]; then # if none given, and stdin is not a terminal
    readarray -t cmds                         # then split stdin by newline
  fi
  for cmd in "${cmds[@]}"; do
    if has_cmd "$cmd"; then
      printf '%s' "$cmd"
      return 0
    fi
  done
  return 1
}

# usage: wait_key [prompt]
# default prompt: 'Press enter to continue'
function wait_key() { read -r -p "${1:-Press enter to continue}"; }

# Use instead of sudo. This will handle the case where the user is root.
# note: the sudo command can be user specified, so don't pass any flag
function sudo_cmd() {
  local _sudo
  # shellcheck disable=SC2206 # quoting is intentional
  [ "$(id -u)" -ne 0 ] && _sudo=(${SUDO:-sudo}) || _sudo=()
  "${_sudo[@]}" "$@"
}

# usage: cmd_or_sudo CMD...
# runs cmd, then if it fails, tries again with sudo.
function cmd_or_sudo() {
  local code=0 cmd
  cmd=("$@")
  "${cmd[@]}" || code=$?
  if [ "$code" -ne 0 ]; then
    code=1
    err "Running '${cmd[*]}' failed, trying again with sudo"
    sudo_cmd "${cmd[@]}" || code=$?
  fi
  if [ "$code" -ne 0 ]; then
    err "Could not run command '${cmd[*]}'"
  fi
  return "$code"
}
