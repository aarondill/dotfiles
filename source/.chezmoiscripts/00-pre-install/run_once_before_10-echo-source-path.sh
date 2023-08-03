#!/usr/bin/env bash
set -euC -o pipefail
err() { printf '%s\n' "$@" >&2; }

chezmoi="${CHEZMOI_EXECUTABLE:-$(which chezmoi 2>/dev/null || printf '')}"

source_path='Could not find chezmoi in PATH'
if [ -x "$chezmoi" ]; then source_path="$("$chezmoi" source-path)"; fi

printf "%s = %s\n" "CHEZMOI_SOURCE_DIR" "${CHEZMOI_SOURCE_DIR:-Not Defined}"
printf "%s = %s\n" "chezmoi source-path" "$source_path"

# Only when both defined, check whether same. won't break if run explicitly.
if [ -n "$source_path" ] && [ -n "${CHEZMOI_SOURCE_DIR:-}" ] && [ "$source_path" != "${CHEZMOI_SOURCE_DIR:-}" ]; then
  err 'chezmoi source-path and CHEZMOI_SOURCE_DIR do not match! This is most likely an error'
  err 'This may be fixed by running chezmoi apply again.'
  exit 1
fi
