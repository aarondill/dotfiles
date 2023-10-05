#!/usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

PACKAGE_NAME="bat-musl"

log "installing $PACKAGE_NAME"

REPO=sharkdp/bat
# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if ! has_apt; then
  abort "This script only supports debian-based distos. install manually from $REPO" 0
fi

version=$(get_latest_version_github "$REPO") # v0.23.0
if has_cmd dpkg-query && apt_is_installed "$PACKAGE_NAME"; then
  installed_version=$(dpkg-query --showformat='${Version}' --show "$PACKAGE_NAME")
  if [ "v$installed_version" = "$version" ]; then
    abort 'Already up to date' 0
  fi
fi

arch=
case "$ARCH" in
x86_64) arch=amd64 ;;
i386 | i686) arch=i686 ;;
esac

asset="${PACKAGE_NAME}_${version#v}_${arch}.deb"

tmp_dir=$(mktemp -d) || abort 'Could not create temporary directory'
rm_exit "$tmp_dir"
install_from_github "$REPO" "$version" "$asset" "$tmp_dir/$PACKAGE_NAME.deb"
apt_install "$tmp_dir/$PACKAGE_NAME.deb"
rm_exit_cleanup "$tmp_dir"
