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
  tmp=$(download_file "$url" '' '' progress) #These files are big, so we want to show progress
  rm_exit "$tmp"
  # output to destination
  log "unpacking jdk-$version"
  sudo_cmd mkdir -p "$destination"
  sudo_cmd tar -xz -C "$destination" -f "$tmp"
  rm_exit_cleanup "$tmp"
}
base_url="https://download.java.net/java" update_version="26.0.1"
declare -A versions=(
  [27]="$base_url/early_access/jdk27/21/GPL/openjdk-27-ea+21_linux-x64_bin.tar.gz"
  [22.0.1]="$base_url/GA/jdk22.0.1/c7ec1332f7bb44aeba2eb341ae18aca4/8/GPL/openjdk-22.0.1_linux-x64_bin.tar.gz"
  [26.0.1]="$base_url/GA/jdk26.0.1/458fda22e4c54d5ba572ab8d2b22eb83/8/GPL/openjdk-26.0.1_linux-x64_bin.tar.gz"
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
