# requires ./flow.sh -- has_cmd

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- Files ----------------------------------------------
## --------------------------------------------------------------------------------------------------

# make an absolute path relative
# relto should likely be a directory path
# usage: relpath relto path
relpath() {
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
