#!/usr/bin/env bash

# ~/.local/bin/script_utils.sh
#
# A template script for writing good scripts
# could be improved, but 🤷
#

set -euC -o pipefail

THIS=script_utils.sh
usage() {
  cat <<EOF || return 0
$THIS [options] [--] [arguments]
                  
This does SOMETHING

Options:
-h, --help        show this message
-l, --long=long   do something with \$long
-s, --short       enable short
EOF
}

log() { printf '%s\n' "$@"; }
err() { printf "${THIS:}: %s\n" "$@" >&2; }
abort() { err "$1" && exit "${2:-1}"; }

# Returns a string that should be 'eval'ed to set the positional arguments
# Store the string in a variable (ie ARGSTRING) to maintain the exit code if parse_args fails.
# Input: $LONGOPTS,$SHORTOPTS
# eval "$(parse_args "$@")"
function parse_args() {
  # -allow a command to fail with !’s side effect on errexit
  # -use return value from ${PIPESTATUS[0]}, because ! hosed $?
  # shellcheck disable=SC2251
  ! getopt --test >/dev/null
  if [[ "${PIPESTATUS[0]}" -ne 4 ]]; then abort "Enhanced getopt is required for this script to work. Please install it." 1; fi

  local parsed
  if parsed=$(getopt --options="$SHORTOPTS" --longoptions="$LONGOPTS" --name "${THIS-$0}" -- "$@"); then
    # output getopt’s output this way to handle the quoting right:
    printf '%s' "set -- $parsed"
    return 0
  fi
  # getopt has already complained about wrong arguments to stdout - Exit script
  exit 2
}

# option --long/-l requires 1 argument
LONGOPTS=help,short,long:
SHORTOPTS=h,s,l:
ARGSTRING="$(parse_args "$@")"
eval "$ARGSTRING"

while true; do
  case "$1" in
  -h | --help) usage && exit 0 ;;
  -s | --short) short=true && shift ;;
  -l | --long) long="$2" && shift 2 ;;
  --) shift && break ;;
  *) abort "This is a bug" 3 ;;
  esac
done
# handle non-option arguments
if [[ "$#" -eq 0 ]]; then abort "POS_ARGUMENT is required" 2; fi
