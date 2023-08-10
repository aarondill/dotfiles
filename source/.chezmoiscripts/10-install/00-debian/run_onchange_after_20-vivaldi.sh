#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if ! has_apt; then
  abort "Apt not installed, skipping vivaldi install. Please install through your package manager" 0
fi

VIVALDI_STEAM=stable VIVALDI_STEAM_SHORT_ALT=stable
DEBARCH=
case "$ARCH" in
x86_64) DEBARCH="amd64" ;;
i?86) DEBARCH="i386" ;;
arm*) DEBARCH="armhf" ;;
aarch64*) DEBARCH="arm64" ;;
*) abort "The architecture $ARCH is not supported." 1 ;;
esac

function install_vivaldi() {
  local version=$1
  sudo_cmd true
  temp_file=$(download_file "https://downloads.vivaldi.com/$VIVALDI_STEAM_SHORT_ALT/${VIVALDI_STEAM}_${version}_${DEBARCH}.deb")
  rm_exit "$temp_file"
  apt_install "$temp_file"
  rm_exit_cleanup "$temp_file"
}
function get_vivaldi_version() {
  local vivaldi_version
  # Work out the latest stable Vivaldi if VIVALDI_VERSION is unset
  vivaldi_version=${VIVALDI_VERSION:-$(download "http://repo.vivaldi.com/archive/deb/dists/stable/main/binary-$DEBARCH/Packages.gz" | gzip -d | grep -A6 -x "Package: vivaldi-$VIVALDI_STEAM" | sed -n "/Version/s/.* //p" | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n 1)}
  printf '%s' "$vivaldi_version"
}

vivaldi_version=$(get_vivaldi_version)
log_and_run "Installing vivaldi version $vivaldi_version" install_vivaldi "$vivaldi_version"
