#!/usr/bin/env bash
# ==> tempfile.sh <==
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
## -------------------------------------------- Tempfile --------------------------------------------
## --------------------------------------------------------------------------------------------------

# An internal array. DON'T overwrite this!
_TEMPFILES=()
# An internal function. Don't call this.
_cleanup_tempfiles() {
  if [ ${#_TEMPFILES[@]} -gt 0 ]; then
    rm -rf -- "${_TEMPFILES[@]}"
  fi
}
# An internal function. Don't call this.
_add_tempfiles() {
  local file temp
  for file; do
    for temp in "${_TEMPFILES[@]}"; do
      if [ "$file" = "$temp" ]; then continue 2; fi # continue `for file;` loop
    done
    _TEMPFILES=("${_TEMPFILES[@]}" "$file")
  done
}

# traps to remove the given file on exit
# This can be called mutltiple times.
# Do *NOT* trap EXIT after calling!
# Note: THIS will override any other exit traps!
function rm_exit() {
  _add_tempfiles "$@"
  trap "_cleanup_tempfiles" EXIT
}

# deletes the file given and removes it from the exit trap
# safe to call even if the trap has not been set (ie, library code!)
# exits with status of previous code
function rm_exit_cleanup() {
  local exit="$?" file_to_rm i
  rm -fr -- "$@" || true
  for file_to_rm; do

    for i in "${!_TEMPFILES[@]}"; do
      if [[ "${_TEMPFILES[$i]}" = "$file_to_rm" ]]; then
        unset "_TEMPFILES[$i]" # remove from array (won't expand into empty, so okay)
      fi
    done

  done
  return "$exit"
}
