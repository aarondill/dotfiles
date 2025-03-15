#!/usr/bin/env bash
# ==> output.sh <==
_UTIL_D="$(dirname -- "${BASH_SOURCE[0]}")"
if [ -z "${_LEADER:-}" ]; then
  _LEADER="${BASH_SOURCE[0]}"
  _OLD_PWD="$(pwd)"
  builtin cd -- "$_UTIL_D"
  . ../.utils.sh # assert_source_once
fi
assert_source_once "${BASH_SOURCE[0]}" || return 0

if [ "${BASH_SOURCE[0]}" = "$_LEADER" ]; then
  builtin cd -- "$_OLD_PWD"
  unset _OLD_PWD _UTIL_D _LEADER
fi

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- Output ---------------------------------------------
## --------------------------------------------------------------------------------------------------

# COLOR vars to keep from branching to tput repeatedly
RED_COLOR="$(tput setaf 1 2>/dev/null)" || true
BLUE_COLOR="$(tput setaf 6 2>/dev/null)" || true
GREEN_COLOR="$(tput setaf 2 2>/dev/null)" || true
BOLD_COLOR="$(tput bold 2>/dev/null)" || true
RESET_COLOR="$(tput sgr0 2>/dev/null)" || true
TEAL_COLOR="$(tput setaf 6 2>/dev/null)" || true
YELLOW_COLOR="$(tput setaf 3 2>/dev/null)" || true
PINK_COLOR="$(tput setaf 5 2>/dev/null)" || true
export RED_COLOR BLUE_COLOR GREEN_COLOR BOLD_COLOR RESET_COLOR TEAL_COLOR YELLOW_COLOR PINK_COLOR

# log "hello world"
function log() { printf "${BLUE_COLOR}${BOLD_COLOR}%s\n${RESET_COLOR}" "$@" || true; }
# err "goodbye world" -- shows in bold red - Use $THIS to show `script: error`
function err() { printf "${THIS:+$THIS:}${RED_COLOR}${BOLD_COLOR}%s\n${RESET_COLOR}" "$@" >&2 || true; }
# warn "goodbye world" -- shows in bold yellow - Use $THIS to show `script: error`
function warn() { printf "${THIS:+$THIS:}${YELLOW_COLOR}${BOLD_COLOR}%s\n${RESET_COLOR}" "$@" >&2 || true; }
# debug "debug message"
function debug() { printf "${RED_COLOR}${BOLD_COLOR}DEBUG: %s\n${RESET_COLOR}" "$@" >&2 || true; }
# success - no arguments
function success() { printf "${GREEN_COLOR}${BOLD_COLOR}%s${RESET_COLOR}\n" "Success!" || true; }
# verbose echo do something -> echo do something\ndo something
function verbose() {
  declare -i i=0
  for a in "$@"; do
    i=$((i + 1))
    printf "'%s'" "$a"
    if [ "$i" -lt "$#" ]; then printf ' '; else printf '\n'; fi # print ' ' if not last, or \n if last
  done
  "$@" # run the input
}
