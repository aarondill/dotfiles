#!/usr/bin/env bash
set -euC -o pipefail
# Runs the java file specified with the given stdin and arguments
# Be careful to avoid variables that collide with the template program (~/.local/bin/new)
# Included are FILEPATH,REALPATH,FILENAME,DIRNAME,DATE,TIME,EXTENSION,BASENAME,ROOT and potentially more
# All variables will be in all capitals.

# BEGIN CONFIGURATION

# stdin. Tabs will be maintained
stdin=
IFS='' read -r -d '' stdin <<'EOF' || true
EOF
stdin_file=    # This will override stdin. Relative to output_dir (use input_files if needed), use - to specify stdin
cargs=()       # javac
jargs=()       # java
classpath=     # output_dir will be automatically included
output_dir=    # or "dist". Relative to this_dir
input_files=() # a list of files to copy (symlink) to the output_dir. Releative to this_dir

# END CONFIGURATION

# COLOR vars to keep from branching to tput repeatedly
RED_COLOR="$(tput setaf 1 2>/dev/null || printf '')"
YELLOW_COLOR="$(tput setaf 11 2>/dev/null || printf '')"
# GREEN_COLOR="$(tput setaf 2 2>/dev/null || printf '')"
BOLD_COLOR="$(tput bold 2>/dev/null || printf '')"
RESET_COLOR="$(tput sgr0 2>/dev/null || printf '')"

THIS="${0-test.sh}" # Used in err.
THIS="${THIS##*/}"
log() { if [ -t 1 ]; then printf "$YELLOW_COLOR$BOLD_COLOR%s\n$RESET_COLOR" "$@"; fi; }
show_run() {
  log "Running: $*"
  log ''
  "$@"
}
err() { if [ -t 2 ]; then printf "${THIS:+$THIS: }$RED_COLOR$BOLD_COLOR%s\n$RESET_COLOR" "$@" >&2; fi; }
abort() { err "$1" && exit "${2:-1}"; }
# make a relative path absolute, according to $2 or $this_dir
resolve() {
  local path="${1:-}"
  local relto="${2:-$this_dir}"
  local ret=''
  case "$path" in
  '' | -) ret="$path" ;; # if passed an empty string, return the empty string
  /*) ret="$path" ;;
  ./*) ret="$relto/${path#./}" ;;
  .) ret="$relto" ;;
  *) ret="$relto/$path" ;;
  esac
  ret=${ret%/} # strip trailing slash
  if [ -t 1 ]; then
    printf '%s\n' "$ret" # newline for output
  else                   #
    printf '%s' "$ret"   # no newline
  fi
}

if [ "${1:-}" == '-t' ] || [ "${1:-}" == '--test' ]; then
  # handle ./cmd --test to allow user input
  # HACK: no way to not use this. (ie '--' doesn't work.)
  stdin_file=- && shift 1
fi

this_dir="$(readlink -f -- "$(dirname "$0")")" # might break if cwd is a symlink
this="$(basename "$0")"

java_class=${this%.test.sh}                             # ClassName.test.sh -> ClassName
java_class=${java_class%.sh}                            # ClassName.sh -> ClassName
output_dir="$(resolve "${output_dir:-.}")"              # relative to $this_dir -- default is $this_dir
java_file="$(resolve "$java_class.java")"               # relative to $this_dir
class_file=$(resolve "$java_class.class" "$output_dir") # relative to $output_dir
stdin_file=$(resolve "${stdin_file:-}" "$output_dir")   # relative to $output_dir

if ! [ -f "$java_file" ]; then abort "Could not find '$java_file'. Please double check the names of both files." 1; fi
if [ -f "$class_file" ]; then
  log "Cleaning up old class file"
  show_run rm -f "$class_file"
fi

if [ -n "$stdin_file" ] && ! [ "$stdin_file" = - ]; then
  if ! [ -e "$stdin_file" ]; then
    abort "Could not find '$stdin_file'. Please double check the name of the file, or remove it from the stdin_file." 1
  fi
fi
stdin() {
  # setup stdin_file if it exists -- override the stdin variable above
  if ! [ -t 0 ] || [ "${stdin_file:-}" = - ]; then
    "$@"
  elif [ -e "${stdin_file:-}" ]; then
    "$@" <"$stdin_file"
  elif [ -n "${stdin:-}" ]; then
    "$@" <<<"$stdin"
  else
    "$@"
  fi
}

cd "$this_dir"
if ! [ -d "$output_dir" ]; then
  log "Creating output directory"
  show_run mkdir -p "$output_dir"
fi

log "Setting up input files"
for f in "${input_files[@]}"; do
  link_dest=$(resolve "$(basename "$f")" "$output_dir")
  link_src="$(resolve "$f")"
  if ! [ -e "$link_src" ]; then continue; fi   # source file doesn't exist
  if [ -e "$link_dest" ]; then continue; fi    # destination file already exists
  show_run ln -Tsi -- "$link_src" "$link_dest" # dead links will be interactively replaced
done

_classpath="$output_dir"
if [ -n "$classpath" ]; then _classpath="$_classpath:$classpath"; fi

show_run javac --class-path "$_classpath" -d "$output_dir" "${cargs[@]}" "$java_file"

code=0
stdin show_run java --class-path "$_classpath" "$java_class" "${jargs[@]}" "$@" || code=$?

if [ "$code" != 0 ]; then
  log
  err "Command failed with exit code: $code"
fi

exit "$code"
