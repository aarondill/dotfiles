#!/usr/bin/env bash
# ==> github.sh <==
assert_source_once "${BASH_SOURCE[0]}" || return 0
if true; then
  . ./output.sh   # err log
  . ./flow.sh     # abort
  . ./download.sh # get_url_headers download_file
  . ./json.sh     # get_json_prop
  . ../.utils.sh  # assert_source_once
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
  if [[ -z "$github_repo" ]]; then
    err "GitHub repo can not be an empty string"
    return 2
  elif [[ -z "$asset" ]]; then
    err "asset can not be an empty string"
    return 2
  elif [[ -z "$destination" ]]; then
    err "destination can not be an empty string"
    return 2
  fi

  local url="https://github.com/$github_repo"
  if [ "$version" = "latest" ]; then
    # Skip the version lookup using the static 'latest' url
    url+="/releases/latest/download/$asset"
  else
    # download from the given version
    url+="/releases/download/$version/$asset"
  fi

  log_github_install "$github_repo" "$version" "$asset" "$destination"
  download_file "$url" "$destination" +x
)
# usage: log_github_install <repo> <version> [asset] [dest]
# example: log_github_install aaron/example latest example.sh /usr/local/bin/
function log_github_install() {
  local github_repo=$1 version=$2 asset=${3:-} destination=${4:-}
  local msg="Installing $github_repo version $version"
  if [ -n "$asset" ]; then msg+=" ($asset)"; fi
  if [ -n "$destination" ]; then msg+=" to $destination"; fi
  log "$msg"
}

# usage: git_clone <repo> [dest] [branch]
function git_clone() {
  local repo=$1 dest=${2:-} branch=${3:-} opts args
  # opts=(--depth=1 --filter=tree:0 --single-branch)
  opts=(--depth=1 --single-branch) # fastest/least storage possible
  if [ -n "$branch" ]; then opts+=("--branch=$branch"); fi

  args=("$repo")
  if [ -n "$dest" ]; then args+=("$dest"); fi

  git clone "${opts[@]}" -- "${args[@]}"
}
