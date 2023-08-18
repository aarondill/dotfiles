#!/usr/bin/env bash
# ==> github.sh <==
(return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0
if [ "$_SOURCED" -eq 0 ]; then # for shellcheck
  case "${BASH_SOURCE[0]}" in  # newline to fix bash-lsp syntax error
  */*) _script_dir=${BASH_SOURCE%/*} ;; *) _script_dir=./ ;; esac
  _script_dir=$(cd -P -- "$_script_dir" &>/dev/null && pwd -P) # eval symlinks (dirs, not the script itself)
  # shellcheck source=./output.sh
  . "$_script_dir/output.sh" # err log
  # shellcheck source=./flow.sh
  . "$_script_dir/flow.sh" # abort
  # shellcheck source=./download.sh
  . "$_script_dir/download.sh" # get_url_headers download_file
fi
unset _SOURCED _script_dir

## --------------------------------------------------------------------------------------------------
## --------------------------------------------- GitHub ---------------------------------------------
## --------------------------------------------------------------------------------------------------

# get_latest_version_github "someone/something" -> v1.2.3 (tagname)
function get_latest_version_github() (
  set -e                              # in subshell
  local version_url version repo="$1" # combined $OWNER/$REPO
  # version_url=$(get_url_headers "https://github.com/$repo/releases/latest" | grep -m1 -iF "location:" | tr -d '\r')
  # version="${version_url##*/}" # remove everything up to last slash
  version=$(curl "https://api.github.com/repos/$repo/releases/latest" | grep "tag_name" | cut -d'"' -f4) # parsing JSON...
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

  if [ "$version" = "latest" ]; then version=$(get_latest_version_github "$github_repo"); fi

  log_github_install "$github_repo" "$version" "$asset" "$destination"
  download_file "https://github.com/$github_repo/releases/download/$version/$asset" "$destination" +x
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
