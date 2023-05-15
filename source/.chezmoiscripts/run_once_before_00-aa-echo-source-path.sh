#!/usr/bin/env bash
set -euC -o pipefail
printf "%s = %s" "CHEZMOI_SOURCE_DIR" "$CHEZMOI_SOURCE_DIR"

chezmoi="${CHEZMOI_EXECUTABLE:-$(which chezmoi 2>/dev/null || printf '')}"
if [ -x "$chezmoi" ]; then
  printf "%s = %s" "chezmoi source-path" "$("$chezmoi" source-path)"
fi
