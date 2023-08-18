#!/usr/bin/env bash
# ==> output.sh <==
(return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0
if [ "$_SOURCED" -eq 0 ]; then # for shellcheck
  case "${BASH_SOURCE[0]}" in  # newline to fix bash-lsp syntax error
  */*) _script_dir=${BASH_SOURCE%/*} ;; *) _script_dir=./ ;; esac
  _script_dir=$(cd -P -- "$_script_dir" &>/dev/null && pwd -P) # eval symlinks (dirs, not the script itself)
  true                                                         # source here if needed
fi
unset _SOURCED _script_dir

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
