# requires ./output.sh -- err, log, success

## --------------------------------------------------------------------------------------------------
## ------------------------------------------ Control Flow ------------------------------------------
## --------------------------------------------------------------------------------------------------

# abort "something went wrong!" 1
function abort() { err "$1" && exit "${2:-2}"; }
# confirm "do you really want to do %s?" "that" --> ...do that? (Y/n)
# Strings are evaluated using printf
function confirm() {
  local PROMPT confirmation
  # shellcheck disable=SC2059 # I know this is *generally* wrong, but this is intentional.
  PROMPT="$(printf "$1" "${@:2}")"
  read -rep "$PROMPT (Y/n) " confirmation </dev/tty
  if [ -z "$confirmation" ] || [[ "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
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
  for cmd; do command -v "$cmd" &>/dev/null || failed=1; done
  return "$failed"
}
# usage: wait_key [prompt]
# default prompt: 'Press enter to continue'
wait_key() { read -r -p "${1:-Press enter to continue}"; }
