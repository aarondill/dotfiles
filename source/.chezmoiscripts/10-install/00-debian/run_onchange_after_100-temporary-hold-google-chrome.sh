#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

if [ -z "$APT" ]; then
  abort "This script is only for Ubuntu/Debian" 0
fi

url=http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.198-1_amd64.deb

temp=$(download_file "$url")
rm_exit "$temp"
apt_install "$temp"
sudo apt-mark hold google-chrome-stable
# cleanup
rm_exit_cleanup "$temp"

success
