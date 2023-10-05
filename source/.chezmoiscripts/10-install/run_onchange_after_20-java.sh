#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

destination="/usr/lib/jvm" # Fixed location
version=20.0.2
url=https://download.java.net/java/GA/jdk20.0.2/6e380f22cbe7469fa75fb448bd903d8e/9/GPL/openjdk-20.0.2_linux-x64_bin.tar.gz

if [ -x "$destination/jdk-$version/bin/java" ]; then
  abort "jdk-$version is already installed." 0
fi

log "downloading jdk-$version (fixed version)"

tmp=$(download_file "$url")
rm_exit "$tmp"
# output to destination
sudo_cmd mkdir -p "$destination"
sudo_cmd tar -xz -C "$destination" -f "$tmp"
rm_exit_cleanup "$tmp"
# This is my own script! should be in ~/.local/bin/update-java!
sudo_cmd ~/.local/bin/update-java --quiet --yes "$destination/jdk-$version"
