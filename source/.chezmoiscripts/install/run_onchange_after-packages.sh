#! /usr/bin/env bash
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

#region ## Actual Code {{{1
#region ### Java {{{2
function install_java() (
  set -e
  local URL=https://download.java.net/java/GA/jdk20.0.1/b4887098932d415489976708ad6d1a4b/9/GPL/openjdk-20.0.1_linux-x64_bin.tar.gz
  local DESTINATION="/usr/lib/jvm" # Fixed location
  log "downloading java 20.0.1 (fixed version)"

  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  curl -SsLf "$URL" -o "$TMP"
  # output to destination
  sudo tar -xz -C "$DESTINATION" -f "$TMP"

  name=$(tar -ztf "$TMP" | head -n 1 | cut -d'/' -f1) # hack to get name of top folder
  rm -f "$TMP" && trap '' EXIT                        # Cleanup
  # This is my own script! should be in .local/bin/update-java!
  sudo ~/.local/bin/update-java "$DESTINATION/$name"
)
#endregion
### Non-Funcion Code {{{1

log_and_run 'installing java' install_java

#endregion
