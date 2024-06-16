#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# NOTE: Assumes firefox is in /usr/bin/firefox-esr
# We can't extrapolate because we create a new symlink below
firefox=/usr/bin/firefox
firefox_esr=/usr/bin/firefox-esr
firejail_links=("/usr/local/bin/firefox-esr" "/usr/local/bin/firefox")

# if hasn't already run
if ! [ -e "$firefox" ] && [ -x "$firefox_esr" ]; then
  log "linking $firefox_esr to $firefox"
  mklink "$firefox_esr" "$firefox"
  success
else
  err "$firefox already linked to esr. Skipping linking."
fi

firejail=$(cmd_path firejail) || abort 'firejail not found. Skipping firejail links.' 0

log "Setting up firefox with firejail at $firejail"
for c in "${firejail_links[@]}"; do
  name=$(basename -- "$c")
  if has_cmd "$name"; then
    if ! [ -L "$c" ]; then
      log "Linking $firejail to $c"
      sudo_mkdir -p -- "$(dirname -- "$c")"
      mklink "$firejail" "$c"
    else
      err "Skipping link $c. Link already exists."
    fi
  fi
done
success
