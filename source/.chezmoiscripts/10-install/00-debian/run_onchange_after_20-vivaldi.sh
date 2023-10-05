#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if ! has_apt; then
  abort "Apt not installed, skipping vivaldi install. Please install through your package manager" 0
fi

VIVALDI_STEAM=vivaldi-stable VIVALDI_STEAM_SHORT_ALT=stable
DEBARCH=
case "$ARCH" in
x86_64) DEBARCH="amd64" ;;
i?86) DEBARCH="i386" ;;
arm*) DEBARCH="armhf" ;;
aarch64*) DEBARCH="arm64" ;;
*) abort "The architecture $ARCH is not supported." 1 ;;
esac

function install_vivaldi() {
  local version="$1" temp_dir
  temp_dir=$(mktemp -d)
  rm_exit "$temp_dir"
  download_file "https://downloads.vivaldi.com/$VIVALDI_STEAM_SHORT_ALT/${VIVALDI_STEAM}_${version}_${DEBARCH}.deb" "$temp_dir/vivaldi.deb"
  apt_install "$temp_dir/vivaldi.deb"
  rm_exit_cleanup "$temp_dir"
}
function get_vivaldi_version() {
  local vivaldi_version
  # Work out the latest stable Vivaldi if VIVALDI_VERSION is unset
  vivaldi_version=${VIVALDI_VERSION:-$(download "http://repo.vivaldi.com/archive/deb/dists/stable/main/binary-$DEBARCH/Packages.gz" | gzip -d | grep -A6 -x "Package: $VIVALDI_STEAM" | sed -n "/Version/s/.* //p" | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n 1)}
  printf '%s' "$vivaldi_version"
}

vivaldi_version=$(get_vivaldi_version)
if has_cmd vivaldi; then
  current_version=$(run_own_shell vivaldi --version | sed "s/Vivaldi \(.*\) $VIVALDI_STEAM_SHORT_ALT/\1/g")
  if [ "$current_version-1" = "$vivaldi_version" ]; then
    abort "Vivaldi is already up to date" 0
  fi
fi
log_and_run "Installing vivaldi version $vivaldi_version" install_vivaldi "$vivaldi_version"
