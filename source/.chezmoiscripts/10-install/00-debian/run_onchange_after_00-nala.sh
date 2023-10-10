#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"
REPO=volian/nala REPO_ID=39215670

read -r -d '' PYTHON_CODE <<-'EOF' || true
import sys, json
for ln in json.load(sys.stdin)["assets"]["links"]: print(ln["direct_asset_url"], end="\n")
EOF

function install_nala() {
  local tmp_dir keyring_url scar_url

  # https://gitlab.com/volian/volian-archive/uploads/b20bd8237a9b20f5a82f461ed0704ad4/volian-archive-keyring_0.1.0_all.deb
  # https://gitlab.com/volian/volian-archive/uploads/d6b3a118de5384a0be2462905f7e4301/volian-archive-nala_0.1.0_all.deb
  # https://gitlab.com/volian/volian-archive/uploads/4ba4a75e391aa36f0cbe7fb59685eda9/volian-archive-scar_0.1.0_all.deb
  while read -r; do
    case "$REPLY" in
    */volian-archive-keyring_*_all.deb) keyring_url=$REPLY ;;
    */volian-archive-scar_*_all.deb) scar_url=$REPLY ;;
    esac
  done < <(download "https://gitlab.com/api/v4/projects/$REPO_ID/releases/permalink/latest" | python3 -c "$PYTHON_CODE")

  tmp_dir=$(mktemp -d)
  rm_exit "$tmp_dir"
  download_file "$keyring_url" "$tmp_dir/keyring.deb"
  download_file "$scar_url" "$tmp_dir/scar.deb"
  apt_install "$tmp_dir/keyring.deb" "$tmp_dir/scar.deb"
  rm_exit_cleanup "$tmp_dir"

  apt_update
  apt_install nala
}

# Shouldn't be, but I got an issue about python-markup-it
if [ "$OS" != "Ubuntu" ]; then abort "Nala is only supported on Ubuntu" 0; fi

if ! has_apt; then exit 0; fi
if has_cmd nala; then
  cvers="$(nala --version)"                    # nala 0.13.0
  lvers="$(get_latest_version_gitlab "$REPO")" # v0.13.0
  if [ "$cvers" = "nala ${lvers#v}" ]; then abort "Already up to date! Aborting" 0; fi
fi

log_and_run "Installing nala" install_nala

# log_and_run 'Setting up nala sources' sudo_cmd nala fetch --auto -y
