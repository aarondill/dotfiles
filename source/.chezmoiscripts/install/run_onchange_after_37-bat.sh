#!/usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

log 'installing bat'

REPO=sharkdp/bat
# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if ! is_accessible_cmd apt; then
  abort "This script only supports debian-based distos. install manually from $REPO" 0
fi

VERSION=$(get_latest_version_github "$REPO") # v0.23.0
arch=
case "$ARCH" in
x86_64) arch=amd64 ;;
i386 | i686) arch=i686 ;;
esac

ASSET="bat-musl_${VERSION#v}_${arch}.deb"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
DESTINATION=$TMP_DIR/bat.deb

log_github_install "$REPO" "$VERSION" "$ASSET" "$DESTINATION"
curl -sSL "https://github.com/$REPO/releases/download/$VERSION/$ASSET" -o "$DESTINATION"
sudo "$APT" install -y "$DESTINATION"

rm -rf "$TMP_DIR" && trap '' EXIT # cleanup
