#!/usr/bin/env bash
# ==> files.sh <==
SCRIPT_DIR="${SOURCE_DIR:-${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}}/.chezmoiscripts" # defined in parent script
_script_dir="$SCRIPT_DIR/.utils.d"
if [ -z "$__FROM_UTILS_SH" ]; then
  # shellcheck source=./flow.sh
  . "$_script_dir/flow.sh" # has_cmd sudo_cmd cmd_or_sudo
fi
unset _script_dir

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
    realpath --canonicalize-missing --no-symlinks --relative-to="$relto" -- "$path"
  elif has_cmd perl; then
    perl -le 'use File::Spec; print File::Spec->abs2rel(@ARGV)' -- "$path" "$relto"
  else
    err "Could not find a command to resolve relative paths"
    # no output -- should we output the full path?
  fi
}

# usage: sudo_writable file cmd...
# Will call the command with sudo if the file is not writable, else calls normally
function sudo_writable() {
  local dest="${1:-}"
  shift # don't call sudo_cmd with the file
  sudo=(sudo_cmd)
  [ -n "$dest" ] && [ -w "$dest" ] && sudo=()
  "${sudo[@]}" "$@"
}

# usage: sudo_mkdir MKDIR_ARGS...
function sudo_mkdir() {
  cmd_or_sudo mkdir "$@"
}

# usage: mklink_abs linkto [linkname]
# makes a symbolic link to the specified file using ln -s.
# forces ln with -f. So files *will* be overwritten.
function mklink_abs() {
  local source="$1" dest="${2:-}"
  args=(-sf -- "$source")
  [ -n "$dest" ] && args+=("$dest")
  sudo_writable "$dest" ln "${args[@]}"
}

# usage: mklink linkcontent [linkname]
# makes relative links.
# see mklink_abs for more information
function mklink() {
  local relative_content=''
  local linkcontent=$1 linkname=${2:-}
  if [ -n "$linkname" ]; then # Allow empty linkname (use cwd) -- How ln works
    relative_content="$(relpath "$(dirname -- "$linkname")" "$linkcontent")"
  else
    relative_content="$(relpath "./$(basename -- "$linkcontent")" "$linkcontent")"
  fi
  mklink_abs "$relative_content" "$linkname"
}

# usage: _test_all OP files...
# returns 0 if 'test OP' passes for all arguments, 1 otherwise.
# Returns 2 if no arguments are passed. Useful with globs
# OP must start with a dash '-', or the script will abort
_test_all() {
  local op="${1:-}"
  case "$op" in
  -*) ;;
  *) abort "Invalid argument to _test_all: $op" 2 ;;
  esac
  if [ "$#" -eq 0 ]; then return 2; fi
  for f in "$@"; do
    test "$op" "$f" || return 1
  done
  return 0
}
# returns 0 if all arguments are files that exist, 1 otherwise. Returns 2 if no arguments are passed. Useful with globs
function is_file() { _test_all -f "$@"; }
# returns 0 if all arguments are dirs that exist, 1 otherwise. Returns 2 if no arguments are passed. Useful with globs
function is_dir() { _test_all -d "$@"; }
# returns 0 if all arguments are links that exist, 1 otherwise. Returns 2 if no arguments are passed. Useful with globs
function is_link() { _test_all -L "$@"; }
# returns 0 if all arguments exist (file or dir), 1 otherwise. Returns 2 if no arguments are passed. Useful with globs
function file_exists() { _test_all -e "$@"; }
