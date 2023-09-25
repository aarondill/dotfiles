#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_delta() {
  local short_arch='' asset=''
  local REPO=dandavison/delta
  local tmp

  fname=git-delta
  case "$ARCH" in
  x86_64 | amd64)
    short_arch=amd64
    fname=git-delta-musl # prefer the musl version (my preference, optional)
    ;;
  arm64 | aarch64) short_arch=arm64 ;;
  i386) short_arch=i386 ;;
  armv7l) short_arch=armhf ;; # correct?
  *)
    err "Unsupported architecture: $ARCH"
    return 1
    ;;
  esac

  # git-delta-musl_VERSION_amd64.deb
  # git-delta_VERSION_amd64.deb
  # git-delta_VERSION_arm64.deb
  # git-delta_VERSION_armhf.deb
  # git-delta_VERSION_i386.deb
  version=$(get_latest_version_github "$REPO") # 0.16.5

  if has_cmd dpkg-query && apt_is_installed "git-delta-musl"; then
    local installed_version
    installed_version=$(dpkg-query --showformat='${Version}' --show git-delta-musl)
    if [ "$installed_version" = "$version" ]; then
      abort 'Already up to date' 0
    fi
  fi

  asset="${fname}_${version}_${short_arch}.deb"
  tmp=$(mktemp)
  rm_exit "$tmp"
  install_from_github "$REPO" "$version" "$asset" "$tmp"
  apt_install "$tmp"
  rm_exit_cleanup "$tmp"
}
if ! has_apt; then
  abort 'This script only supports Ubuntu/Debian. Please install delta through your package manager.' 0
fi
log_and_run 'installing delta' install_delta
