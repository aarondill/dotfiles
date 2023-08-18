#!/usr/bin/env bash
# ==> output.sh <==
SCRIPT_DIR="${SOURCE_DIR:-${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}}/.chezmoiscripts" # defined in parent script
_script_dir="$SCRIPT_DIR/.utils.d"
if [ -z "$__FROM_UTILS_SH" ]; then
  true # source here if needed
fi
unset _script_dir

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
