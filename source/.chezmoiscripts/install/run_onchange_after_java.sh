#! /usr/bin/env bash
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

DESTINATION="/usr/lib/jvm" # Fixed location
VERSION=20.0.1
URL=https://download.java.net/java/GA/jdk20.0.1/b4887098932d415489976708ad6d1a4b/9/GPL/openjdk-20.0.1_linux-x64_bin.tar.gz

set -e

if [ -f "$DESTINATION/jdk-$VERSION/bin/java" ]; then
  abort0 "jdk-$VERSION is already installed."
fi

log "downloading jdk-$VERSION (fixed version)"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

curl -SsLf "$URL" -o "$TMP"
# output to destination
sudo tar -xz -C "$DESTINATION" -f "$TMP"

rm -f "$TMP" && trap '' EXIT # Cleanup
# This is my own script! should be in ~/.local/bin/update-java!
sudo ~/.local/bin/update-java "$DESTINATION/jdk-$VERSION"
