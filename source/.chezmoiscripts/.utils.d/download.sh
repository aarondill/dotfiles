## --------------------------------------------------------------------------------------------------
## -------------------------------------------- Download --------------------------------------------
## --------------------------------------------------------------------------------------------------

# get_url_headers <URL> - outputs to stdout. Pipe it where you need.
# this should output *only* the headers and should follow redirects.
# Note, this output may differ depending on whether curl or wget is installed. Be cautious.
function get_url_headers() {
  if [ -z "${1:-}" ]; then
    abort "'get_url_headers' requires a URL argument." 3
  fi
  if command -v curl &>/dev/null; then
    curl -sSfLI "$1" || return
  elif command -v wget &>/dev/null; then
    wget -qS "$1" -O /dev/null 2>&1 || return
  fi
}
# download <URL> ['progress']- outputs to stdout. Pipe it where you need.
# if the exact string 'progress' is passed as the second argument,
# the command will output progress information to stderr. This is for the user, not to parse.
# this should output *only* the contents and should follow redirects.
function download() {
  if [ -z "${1:-}" ]; then
    abort "'download' requires a URL argument." 3
  fi
  local progress=0
  if [ "${2:-}" = progress ]; then progress=1; fi
  if command -v curl &>/dev/null; then
    local quiet=-s
    [ "$progress" -eq 1 ] && quiet=
    curl $quiet -SfL "$1" || return
  elif command -v wget &>/dev/null; then
    local quiet=-q
    [ "$progress" -eq 1 ] && quiet=
    wget $quiet -O- "$1" || return
  fi
}

# download_file <URL> [destination] [mode]
# destination should be the *final* filename, not a directory.
# this function handles escalation to root when possible.
# if destination is not present, outputs the temp file on stdout.
# You are expected to cleanup this file after use. It will not be cleaned up on exit.
# The easiest way is to call rm_exit with the file!
function download_file() {
  local sudo='' dir=''
  local file_url=$1 dest=${2:-} mode=${3:-}
  local temp

  if [ -n "$dest" ]; then
    dir=$(dirname "$dest")
  fi
  # might still exist if the user cancels with SIGINT - can't be avoided without overwriting global trap states
  if ! temp=$(mktemp); then
    abort "Could not create temporary directory" 1
  fi
  {
    download "$file_url" >|"$temp"

    # Stop if no dest
    if [ -z "$dest" ]; then
      if [ -n "$mode" ]; then chmod "$mode" "$temp"; fi
      printf '%s' "$temp"
      return 0
    fi

    if ! mkdir -p "$dir"; then
      sudo=${SUDO:-sudo}
      log "Creating directory failed, trying again with sudo"
      $sudo mkdir -p "$dir" || abort "could not create directory $dir"
    fi

    if ! [ -w "$dir" ]; then sudo=${SUDO:-sudo}; fi
    $sudo install --no-target-directory -- "$temp" "$dest" # resets permissions
    if [ -n "$mode" ]; then $sudo chmod "$mode" "$dest"; fi
    rm -rf -- "$temp"
  } || rm -rf -- "$temp"
}
