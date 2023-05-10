#!/usr/bin/env bash

# ~/.local/bin/script_utils.sh
#
# A template script for writing good scripts
# could be improved, but 🤷
#
set -eu

THIS=script_utils.sh
usage() {
  cat <<EOF
$THIS [options] [--] [arguments]
                  
This does <SOMETHING>

Options:
-h, --help        show this message
-s, --long=long   do something with \$long
EOF
  return 0
}

log() { printf '%s\n' "$@"; }
err() { printf "$THIS: %s\n" "$@" >&2; }
abort() { err "$1" && exit "${2:-1}"; }

# Sets the variable $args to an array of positional arguments
# Usage: parse_args "$@"
function parse_args() {
  # If awaiting an argument
  local next='' next_arg='' end=false
  declare -g args=()
  for arg in "$@"; do
    if [ $end = true ]; then
      args+=("$arg") && continue
    elif [ -n "$next" ]; then
      # -x to expose outside function
      declare -g "$next"="$arg"
      next=""
    else
      case "$arg" in
      --*) split_arg=("$arg") ;;
      -*)
        [[ "$arg" =~ ${arg//?/(.)} ]]                 # splits into array
        declare -a split_arg=("${BASH_REMATCH[@]:1}") # copy array for later
        split_arg=("${split_arg[@]/#/-}")
        ;;
      esac

      case "$arg" in
      --help | -h) usage && exit 0 ;;
      --) end=true ;;
      -s | --long) next=long_setting next_arg="$arg" ;;
      --long=*) long_setting="${arg#*=}" ;;
      --*) abort "Invalid option -- ${arg#--}" 2 ;;
      -*) abort "Invalid option -- ${arg#-}" 2 ;;
      *) args+=("$arg") ;;
      esac
    fi
  done
  # If awaiting an argument, but end of args
  if [ -n "$next" ]; then abort "$next_arg requires an argument" 2; fi
}

long_setting=''
parse_args "$@"

# Do something with empty positionals
if [ "${#args[@]}" -eq 0 ]; then :; fi
# Do something with --long
echo "$long_setting"
