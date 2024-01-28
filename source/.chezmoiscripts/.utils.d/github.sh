#!/usr/bin/env bash
# ==> github.sh <==
_UTIL_D="$(dirname -- "${BASH_SOURCE[0]}")"
if [ -z "${_LEADER:-}" ]; then
  _LEADER="${BASH_SOURCE[0]}"
  _OLD_PWD="$(pwd)"
  builtin cd -- "$_UTIL_D"
  . ../.utils.sh # assert_source_once
fi
assert_source_once "${BASH_SOURCE[0]}" || return 0

if true; then
  . ./output.sh   # err log
  . ./flow.sh     # abort
  . ./download.sh # get_url_headers download_file
  . ./json.sh     # get_json_prop
fi

if [ "${BASH_SOURCE[0]}" = "$_LEADER" ]; then
  builtin cd -- "$_OLD_PWD"
  unset _OLD_PWD _UTIL_D _LEADER
fi

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- GitHub ---------------------------------------------
## --------------------------------------------------------------------------------------------------

# get_latest_version_github "someone/something" -> v1.2.3 (tagname)
function get_latest_version_github() (
  set -e # in subshell

  local version_url version repo="$1" # combined $OWNER/$REPO
  version=$(download "https://api.github.com/repos/$repo/releases/latest" | get_json_prop 'tag_name')
  if [ -z "$version" ]; then
    err "Failed while attempting to install $repo. Please manually install at https://github.com/$repo/releases"
    return 2
  fi
  printf '%s' "$version"
)

# get_latest_version_github "someone/something" -> v1.2.3 (tagname)
function get_latest_version_gitlab() (
  set -e                              # in subshell
  local version version_url repo="$1" # combined $OWNER/$REPO
  version_url=$(get_url_headers "https://gitlab.com/$repo/-/releases/permalink/latest" | grep -m1 -iF "location:" | tr -d '\r')
  version="${version_url##*/}" # remove everything up to last slash
  if [ -z "$version" ]; then
    err "Failed while attempting to install $repo. Please manually install at https://gitlab.com/$repo/releases"
    return 2
  fi
  printf '%s' "$version"
)

# install_from_github aaron/example latest example.sh /usr/local/bin/example
function install_from_github() (
  set -e # runs in subshell, so doesn't affect outside
  local github_repo=$1 version=$2 asset=$3 destination=$4
  if [ -z "$github_repo" ]; then err "GitHub repo can not be an empty string" && return 2; fi
  if [ -z "$asset" ]; then err "asset can not be an empty string" && return 2; fi
  if [ -z "$destination" ]; then err "destination can not be an empty string" && return 2; fi

  local url="https://github.com/$github_repo"
  case "$version" in
  latest) url+="/releases/latest/download/$asset" ;; # Skip the version lookup using the static 'latest' url
  *) url+="/releases/download/$version/$asset" ;;    # download from the given version
  esac

  log_github_install "$github_repo" "$version" "$asset" "$destination"
  download_file "$url" "$destination" +x
)
# usage: log_github_install <repo> <version> [asset] [dest]
# example: log_github_install aaron/example latest example.sh /usr/local/bin/ http...
function log_github_install() {
  local github_repo="$1" version="$2" asset="${3:-}" destination="${4:-}"
  local msg="Installing $github_repo version $version"
  [ -z "$asset" ] || msg+=" ($asset)"
  [ -z "$destination" ] || msg+=" to $destination"
  log "$msg"
}

# usage: git_clone <repo> [dest] [branch]
function git_clone() {
  local repo=$1 dest=${2:-} branch=${3:-} opts args
  # opts=(--depth=1 --filter=tree:0 --single-branch)
  opts=(--depth=1 --single-branch) # fastest/least storage possible
  [ -z "$branch" ] || opts+=("--branch=$branch")
  args=("$repo")
  [ -z "$dest" ] || args+=("$dest")
  git clone "${opts[@]}" -- "${args[@]}"
}
