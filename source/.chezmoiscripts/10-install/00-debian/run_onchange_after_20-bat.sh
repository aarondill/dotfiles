#!/usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log 'installing bat'

REPO=sharkdp/bat
# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if [ -z "$APT" ]; then
  abort "This script only supports debian-based distos. install manually from $REPO" 0
fi

version=$(get_latest_version_github "$REPO") # v0.23.0
if is_accessible_cmd dpkg-query; then
  installed_version=$(dpkg-query --showformat='${Version}' --show bat-musl)
  if [ "v$installed_version" = "$version" ]; then
    abort 'Already up to date' 0
  fi
fi

arch=
case "$ARCH" in
x86_64) arch=amd64 ;;
i386 | i686) arch=i686 ;;
esac

asset="bat-musl_${version#v}_${arch}.deb"

log_github_install "$REPO" "$version" "$asset"
tmp=$(download_file "https://github.com/$REPO/releases/download/$version/$asset")
rm_exit "$tmp"
apt_install "$tmp"
rm_exit_cleanup "$tmp"
