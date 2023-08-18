# requires ./flow.sh -- has_cmd sudo_cmd cmd_or_sudo

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- Files ----------------------------------------------
## --------------------------------------------------------------------------------------------------

# make an absolute path relative
# relto should likely be a directory path
# This does not require that either path exists
# usage: relpath relto path
function relpath() {
  local relto=$1
  local path=$2
  if has_cmd realpath; then
    realpath --canonicalize-missing --no-symlinks --relative-to="$relto" "$path"
  elif has_cmd perl; then
    perl -le 'use File::Spec; print File::Spec->abs2rel(@ARGV)' FILE BASE
  else
    err "Could not find a command to resolve relative paths"
    # no output -- should we output the full path?
  fi
}

# usage: sudo_writable file cmd...
# Will call the command with sudo if the file is not writable, else calls normally
function sudo_writable() {
  sudo=(sudo_cmd)
  [ -w "$dest" ] && sudo=()
  "${sudo[@]}" "$@"
}

# usage: sudo_mkdir MKDIR_ARGS...
function sudo_mkdir() {
  cmd_or_sudo mkdir "$@"
}

# usage: mklink linkto linkname
function mklink() {
  local relpath source=$1 dest=$2
  relpath=$(relpath "$(dirname -- "$source")" "$dest")
  sudo_writable "$dest" ln -sf "$relpath" "$dest"
}
