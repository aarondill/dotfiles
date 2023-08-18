#!/usr/bin/env bash
# ==> text.sh <==
SCRIPT_DIR="${SOURCE_DIR:-${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}}/.chezmoiscripts" # defined in parent script
_script_dir="$SCRIPT_DIR/.utils.d"
if [ -z "$__FROM_UTILS_SH" ]; then
  true # source here if needed
fi
unset _script_dir

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
