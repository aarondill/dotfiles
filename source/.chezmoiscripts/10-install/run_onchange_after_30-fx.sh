#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_fx() {
  local ext='' short_arch='' asset=''
  local BINDIR='/usr/local/bin'
  if [ "$KERNEL" == "windows" ]; then
    ext='.exe'
  elif ! { [ "$KERNEL" = 'Darwin' ] || [ "$KERNEL" = 'Linux' ]; }; then
    err "Unsupported OS: $KERNEL"
    return 1
  fi

  case "$ARCH" in
  x86_64 | amd64)
    short_arch=amd64
    ;;
  arm64 | aarch64)
    short_arch=arm64
    ;;
  *)
    err "Unsupported architecture: $ARCH"
    return 1
    ;;
  esac

  asset="fx_${KERNEL,,}_${short_arch}${ext}"
  version=$(get_latest_version_github antonmedv/fx) # 24.1.0
  if has_cmd fx && [ "$(fx --version)" == "$version" ]; then
    abort "Already up to date" 0
  fi
  install_from_github antonmedv/fx latest "$asset" "$BINDIR/fx"
}
log_and_run 'installing fx' install_fx
