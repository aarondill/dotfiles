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
dargs=()       # javadoc
classpath=     # output_dir will be automatically included
output_dir=    # or "dist". Relative to this_dir
input_files=() # a list of files to copy (symlink) to the output_dir. Releative to this_dir
main_class=    # the class containing the main method if different

# END CONFIGURATION

this="$(basename "$0")"
this_dir="$(readlink -f -- "$(dirname "$0")")" # might break if cwd is a symlink
[ -f "$this_dir/.config" ] && . "$this_dir/.config"
export -n stdin_file cargs jargs dargs classpath output_dir input_files main_class # don't export these

# COLOR vars to keep from branching to tput repeatedly
RED_COLOR="$(tput setaf 1 2>/dev/null || printf '')"
YELLOW_COLOR="$(tput setaf 11 2>/dev/null || printf '')"
# GREEN_COLOR="$(tput setaf 2 2>/dev/null || printf '')"
BOLD_COLOR="$(tput bold 2>/dev/null || printf '')"
RESET_COLOR="$(tput sgr0 2>/dev/null || printf '')"

THIS="$this" # Used in err.
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

java_class=$(basename "$this_dir") # /dir/ClassName/test.sh -> ClassName

usage() {
  cat <<EOF
  Usage: $this [options] [--] [args]
  Run ${main_class:-"$java_class".java} with the given arguments

  Options:
    -h, --help          Show this message and exit.
    -o, --output        Set the output directory
    -i, --input         Set the input file
    -t, --test          Alias for -i -
    -d, --doc           Only generate documentation using javadoc
    -c, --compile       Compile the program (default)
    -l, --cleanup       Cleanup the program (default)
    -r, --run           Run the program (default)
    --do                Set do order (default: "run:compile:cleanup:")

  Note: to generate documentation and run, use \`$this -d -c -r\`
EOF
  :
}

do=
args=()
while [ $# -gt 0 ]; do
  case "$1" in
  -o | --output) output_dir="$2" && shift ;;
  -h | --help) usage && exit 0 ;;
  # handle ./cmd -i - to allow user input
  -i | --input) stdin_file="$2" && shift ;;
  -t | --test) stdin_file=- ;; # alias for `-i -`
  -d | --doc) do=:doc: ;;
  -c | --compile) do+=:compile: ;; # note: default. only for overriding
  -r | --run) do+=:run: ;;         # note: default. only for overriding
  -l | --cleanup) do+=:cleanup: ;; # note: default. only for overriding
  --do) do="$2" && shift ;;        # set do manually
  --*=*)                           # Handle `--opt=val` -> `--opt val`
    opt=${1%%=*} val=${1##*=}
    set -- TO_BE_SHIFTED "$opt" "$val" "$@"
    ;;
  --) args+=("$@") && break ;;
  -*) abort "Unknown option: $1" ;;
  *) args+=("$@") && break ;; # on first non-option, treat the rest as arguments for the script
  esac
  shift
done
set -- "${args[@]}"

output_dir="$(resolve "${output_dir:-.}")" # relative to $this_dir -- default is $this_dir
java_file="$(resolve "$java_class.java")"  # relative to $this_dir
# relative to $output_dir
class_files=("$(resolve "$java_class.class" "$output_dir")")
# Add main class if given
[ -z "${main_class:-}" ] || class_files+=("$(resolve "$main_class.class" "$output_dir")")

stdin_file=$(resolve "${stdin_file:-}" "$output_dir") # relative to $output_dir
doc_dest="$(resolve "doc" "$output_dir")"             # relative to $output_dir

if ! [ -f "$java_file" ]; then abort "Could not find '$java_file'. Please double check the names of both files." 1; fi
if ! [ -d "$output_dir" ]; then
  log "Creating output directory"
  show_run mkdir -p "$output_dir"
fi

# ensure stdin_file gets copied to output_dir
if [ -n "$stdin_file" ] && [ "$stdin_file" != '-' ]; then input_files+=("$stdin_file"); fi
# only log if input files is non-empty
[ "${#input_files[@]}" -eq 0 ] || log "Setting up input files"
for f in "${input_files[@]}"; do
  link_dest=$(resolve "$(basename "$f")" "$output_dir")
  link_src="$(resolve "$f")"
  if ! [ -e "$link_src" ]; then continue; fi   # source file doesn't exist
  if [ -e "$link_dest" ]; then continue; fi    # destination file already exists
  show_run ln -Tsi -- "$link_src" "$link_dest" # dead links will be interactively replaced
done

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

_classpath="$output_dir"
if [ -n "$classpath" ]; then _classpath="$_classpath:$classpath"; fi

[ "${do:0-1}" == ":" ] || do="$do:"       # ensure do ends in a colon
do=${do//::/:}                            # no empty elements
do="${do#:}"                              # ensure do doesn't start with a colon
[ "$do" != : ] || do=''                   # no only seperator
[ -n "$do" ] || do='compile:run:cleanup:' # default to compile:run:cleanup
while [ -n "$do" ]; do
  code=0 command="${do%%:*}" # first element of do
  case "$command" in
  doc)
    # used to link to the correct documentation versions
    JAVA_MAJOR_VERSION=$(java -version 2>&1 | grep -oP 'version "?(1\.)?\K\d+')
    show_run rm -rf -- "$doc_dest"
    show_run javadoc \
      -link "https://docs.oracle.com/en/java/javase/$JAVA_MAJOR_VERSION/docs/api/" \
      -docencoding UTF-8 \
      -charset UTF-8 \
      -nonavbar -notree -noindex -nohelp -nodeprecatedlist \
      -d "$doc_dest" \
      --class-path "$_classpath" \
      -private "${dargs[@]}" \
      "$java_file" "$@"
    ;;
  compile)
    show_run javac \
      --class-path "$_classpath" \
      -d "$output_dir" \
      "${cargs[@]}" "$java_file"
    ;;
  run)
    stdin show_run java \
      --class-path "$_classpath" \
      "${jargs[@]}" "${main_class:-"$java_class"}" "$@"
    ;;
  cleanup)
    show_run rm -f "${class_files[@]}"
    ;;
  '') abort "Empty command! This is a bug!" 3 ;;
  *) abort "Unrecognized command: $command" 3 ;;
  esac || code="$?"
  if [ "$code" != 0 ]; then
    log
    err "Command failed with exit code: $code"
    exit "$code"
  fi
  do="${do#*:}" # remove first element (up to colon)
done
