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

# traps to remove the given file on exit
# This can be called mutltiple times.
# Do *NOT* trap EXIT after calling!
# Note: THIS will override any other exit traps!
function rm_exit() {
  for file; do
    _TEMPFILES=("${_TEMPFILES[@]}" "$file")
  done
  trap "_cleanup_tempfiles" EXIT
}

# deletes the file given and removes it from the exit trap
function rm_exit_cleanup() {
  rm -fr -- "$@" || true
  for file_to_rm; do

    for i in "${!_TEMPFILES[@]}"; do
      if [[ "${_TEMPFILES[$i]}" = "$file_to_rm" ]]; then
        unset "_TEMPFILES[$i]" # remove from array (won't expand into empty, so okay)
      fi
    done

  done
}
