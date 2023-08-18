#!/usr/bin/env bash
# ==> text.sh <==
(return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0
if [ "$_SOURCED" -eq 0 ]; then # for shellcheck
  case "${BASH_SOURCE[0]}" in  # newline to fix bash-lsp syntax error
  */*) _script_dir=${BASH_SOURCE%/*} ;; *) _script_dir=./ ;; esac
  _script_dir=$(cd -P -- "$_script_dir" &>/dev/null && pwd -P) # eval symlinks (dirs, not the script itself)
  true                                                         # source here if needed
fi
unset _SOURCED _script_dir

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
