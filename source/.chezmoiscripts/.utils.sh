#!/usr/bin/env bash
# ==> .utils.sh <==

# THIS FILE IS SOURCED! preserve the old options
# https://unix.stackexchange.com/a/383581
_OLDOPTS=$(set +o)
case $- in
*e*) _OLDOPTS="$_OLDOPTS; set -e" ;;
*) _OLDOPTS="$_OLDOPTS; set +e" ;;
esac
# for this file's safety, won't affect the functions defined here!
set -euC -o pipefail

# This is run repeatedly, should
# Source this file to get utilities
(return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0
if [ "$_SOURCED" -eq 0 ]; then printf '%s\n' "You should source this file. not run it." >&2; fi

# Use already calculated source_dir if present (from parent script)
SCRIPT_DIR="${SOURCE_DIR:-${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}}/.chezmoiscripts"

export SHELLOPTS
export __FROM_UTILS_SH=1 # used in the .utils.d/* to determine if called from here.
# shellcheck source=./.utils.d/output.sh
. "$SCRIPT_DIR"/.utils.d/output.sh # output functions
# shellcheck source=./.utils.d/flow.sh
. "$SCRIPT_DIR"/.utils.d/flow.sh # control flow functions
# shellcheck source=./.utils.d/files.sh
. "$SCRIPT_DIR"/.utils.d/files.sh # File Utils
# shellcheck source=./.utils.d/text.sh
. "$SCRIPT_DIR"/.utils.d/text.sh # text functions
# shellcheck source=./.utils.d/download.sh
. "$SCRIPT_DIR"/.utils.d/download.sh # download functions
# shellcheck source=./.utils.d/tempfile.sh
. "$SCRIPT_DIR"/.utils.d/tempfile.sh # tempfile functions
# shellcheck source=./.utils.d/github.sh
. "$SCRIPT_DIR"/.utils.d/github.sh # github functions
# shellcheck source=./.utils.d/package.sh
. "$SCRIPT_DIR"/.utils.d/package.sh # Pacman/APT functions
unset __FROM_UTILS_SH

## --------------------------------------------------------------------------------------------------
## ------------------------------------------- Variables --------------------------------------------
## --------------------------------------------------------------------------------------------------

# eg: Linux
KERNEL=$(uname -s)
# eg: x86_64
ARCH=$(uname -m)
# eg: Ubuntu
OS="$(source /etc/os-release && lower <<<"${ID:-${NAME:-}}" | first_upper)"
# eg: /usr/bin/gnome-shell, if empty, gnome not installed
GNOME=$(which gnome-shell 2>/dev/null || printf '')

export ARCH KERNEL OS APT GNOME PACMAN
# Code to source *this* file. DON'T MOVE THIS FILE!
# (re)source this file
source_utils() {
  local SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
  ## uncomment this if copying this code. It's commented to stop recursive checking:
  ## shellcheck source=./.utils.sh
  # shellcheck disable=SC1091
  . "$SOURCE_DIR/.chezmoiscripts/utils.sh"
}

# Should be the last thing.
# Restore the old options. VERY important because this is sourced, not run.
eval "$_OLDOPTS"
