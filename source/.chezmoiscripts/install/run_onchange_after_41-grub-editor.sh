#! /usr/bin/env bash
# Source utils
set -euC -o pipefail
export SHELLOPTS

SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_grub_editor() (
  declare temp_dir version REPO="Thenujan-0/grub-editor"
  if ! [ "$ARCH" = "x86_64" ] && ! [ "$ARCH" = "amd64" ]; then
    abort 'Only amd64 and x86_64 are supported at this time.'
  fi

  version=$(get_latest_version_github "$REPO") # v1.0.0

  asset=grub-editor_${version#v}-1_amd64.deb # grub-editor_1.0.0-1_amd64.deb - no other files are available.
  # Download the .deb
  temp_dir=$(mktemp -d)

  trap 'rm -rf "$temp_dir"' EXIT
  local destination=$temp_dir/grub-editor.deb
  log_github_install "$REPO" "$version" "$asset" "$destination"
  curl -sSL "https://github.com/$REPO/releases/download/$version/$asset" -o "$destination"
  sudo "$APT" install -y "$destination"
  # cleanup
  rm -rf "$temp_dir" && trap '' EXIT
)

if [ -n "$APT" ] && ! is_available_apt grub-editor; then
  log_and_run "Installing grub-editor" install_grub_editor
fi
