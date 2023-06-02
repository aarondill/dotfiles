#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_nala() {
  local TMP_DIR

  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  read -r -d '' PYTHON_CODE <<-'EOF' || true
import sys, json
for ln in json.load(sys.stdin)["assets"]["links"]: print(ln["direct_asset_url"], end="\0")
EOF

  # move to tmpdir to save files
  pushd "$TMP_DIR" >/dev/null

  curl -sSfL 'https://gitlab.com/api/v4/projects/39215670/releases/permalink/latest/' |
    # null seperated
    python3 -c "$PYTHON_CODE" |
    # Save to CWD
    xargs -0 -I{} -- curl -sSfL "{}" -O

  # Get back to where we started
  popd >/dev/null

  keyring=$(find "$TMP_DIR" -name "volian-archive-keyring_*_all.deb")
  scar=$(find "$TMP_DIR" -name 'volian-archive-scar_*_all.deb')
  sudo apt-get install --assume-yes "$keyring" "$scar"

  rm -rf "$TMP_DIR" && trap '' EXIT # cleanup

  sudo apt-get update --quiet --assume-yes >/dev/null
  sudo apt-get install --assume-yes nala

  # only changes in this file, but should be reevaluated each file
  APT=$(which nala 2>/dev/null)
}

if [ "$OS" != "Ubuntu" ]; then abort "Nala is only supported on Ubuntu" 0; fi

is_accessible_cmd apt || exit 0
if ! is_accessible_cmd nala; then
  log_and_run "Installing nala" install_nala
fi

# log_and_run 'Setting up nala sources' sudo nala fetch --auto -y
