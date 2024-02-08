#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

destination="/usr/lib/jvm" # Fixed location
function install_java() {
  local tmp version="$1" url="$2"
  if [ -x "$destination/jdk-$version/bin/java" ]; then
    log "jdk-$version is already installed."
    return 0
  fi
  log "downloading jdk-$version"
  tmp=$(download_file "$url")
  rm_exit "$tmp"
  # output to destination
  log "unpacking jdk-$version"
  sudo_cmd mkdir -p "$destination"
  sudo_cmd tar -xz -C "$destination" -f "$tmp"
  rm_exit_cleanup "$tmp"
}
base_url="https://download.java.net/java" update_version="21.0.2"
declare -A versions=(
  [17.0.2]="$base_url/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz" # Don't use this version! It's outdated!
  [21.0.2]="$base_url/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz"
  [23]="$base_url/early_access/jdk23/8/GPL/openjdk-23-ea+8_linux-x64_bin.tar.gz"
)

if [ -z "${versions[$update_version]:-}" ]; then
  abort "Ensure update_version is in the installed versions list!" 2
fi
for v in "${!versions[@]}"; do
  install_java "$v" "${versions[$v]}"
done

# This is my own script! should be in ~/.local/bin/update-java!
log "updating java to $destination/jdk-$update_version"
sudo_cmd ~/.local/bin/update-java --quiet --yes "$destination/jdk-$update_version"
