#!/usr/bin/env bash
# ==> output.sh <==
if false; then
  . ../.utils.sh # assert_source_once
fi
assert_source_once || return 0
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
