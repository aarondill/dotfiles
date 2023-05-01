#! /usr/bin/env bash
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_grub_editor() (
  set -e # run in subshell
  declare temp_dir version REPO="Thenujan-0/grub-editor"
  if ! [ "$ARCH" = "x86_64" ] && ! [ "$ARCH" = "amd64" ]; then
    abort 'Only amd64 and x86_64 are supported at this time.'
  fi

  version=$(get_latest_version_github "$REPO") # v1.0.0

  asset=grub-editor_${version#v}-1_amd64.deb # grub-editor_1.0.0-1_amd64.deb - no other files are available.
  # Download the .deb
  temp_dir=$(mktemp -d) &&
    (
      # In a subshell, so runs at end of block
      trap 'rm -rf $temp_dir' EXIT
      set -e
      local destination=$temp_dir/grub-editor.deb
      log_github_install "$REPO" "$version" "$asset" "$destination"
      curl -sSL "https://github.com/$REPO/releases/download/$version/$asset" -o "$destination"
      sudo "$APT" install "$destination"
    )
)

if is_accessible_cmd apt && ! is_available_apt grub-editor; then
  log_and_run "Installing grub-editor" install_grub_editor
fi
