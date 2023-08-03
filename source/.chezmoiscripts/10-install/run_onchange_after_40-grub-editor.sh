#! /usr/bin/env bash
# Source utils
set -euC -o pipefail
export SHELLOPTS

SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_grub_editor() (
  local temp version REPO="Thenujan-0/grub-editor"
  if ! [ "$ARCH" = "x86_64" ] && ! [ "$ARCH" = "amd64" ]; then
    abort 'Only amd64 and x86_64 are supported at this time.'
  fi

  version=$(get_latest_version_github "$REPO") # v1.0.0
  if has_cmd dpkg-query; then
    local installed_version
    installed_version=$(dpkg-query --showformat='${Version}' --show grub-editor) # 1.2-1 # -1 seems to be constant
    if [ "v$installed_version" = "$version-1" ]; then
      abort 'Already up to date' 0
    fi
  fi

  local asset=grub-editor_${version#v}-1_amd64.deb # grub-editor_1.0.0-1_amd64.deb - no other files are available.
  log_github_install "$REPO" "$version" "$asset"
  # Download the .deb
  temp=$(download_file "https://github.com/$REPO/releases/download/$version/$asset")
  rm_exit "$temp"
  apt_install "$temp"
  rm_exit_cleanup "$temp" # cleanup
)

if has_apt && ! apt_is_available grub-editor; then
  log_and_run "Installing grub-editor" install_grub_editor
fi
