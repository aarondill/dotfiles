#!/usr/bin/env bash
set -euC -o pipefail
internet="$(which internet 2>/dev/null || printf '%s' "$HOME/.local/bin/internet")"
# Exit on fail, if it exists
if [ -x "$internet" ]; then "$internet"; fi
