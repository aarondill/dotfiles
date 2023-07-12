#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# dependencies installed on each distribution
DEBIAN_DEPS=(build-essential ninja-build cmake)
ARCH_DEPS=(build-essential ninja-build cmake)
# Cloned into tempdir
REPO_URL='https://github.com/chase/awrit'

export WARNINGS=none

install_dependencies() {
  # Try install deps *first*
  if [ -n "$APT" ]; then
    if [ "${#DEBIAN_DEPS[@]}" -gt 0 ]; then
      sudo "$APT" install -y "${DEBIAN_DEPS[@]}"
    fi
  elif [ -n "$PACMAN" ]; then
    if [ "${#ARCH_DEPS[@]}" -gt 0 ]; then
      sudo "$PACMAN" -S --needed -- "${ARCH_DEPS[@]}"
    fi
  elif [ "${SKIP_DEP_FORCE:-}" != "true" ]; then
    err "Unable to install dependencies to build '$REPO_URL'"
    err "Please install the following dependencies (names are from debian repositories):"
    err "Run again with SKIP_DEP_FORCE=true to try again."
    err "${DEBIAN_DEPS[@]}"
    exit 2
  fi
}

install_awrit() {
  # Temp directory
  temp=$(mktemp -d)
  trap 'rm -rf "$temp"' EXIT

  # Clone to tempdir
  git clone --quiet -- "$REPO_URL" "$temp" >/dev/null

  # build from source
  cd "$temp"
  (
    export -n SHELLOPTS # Let shells set their own options
    cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release -S . -B build
    cmake --build build
    # install to the prefix /usr/local
    sudo cmake --install build --prefix /usr/local
  )

  # cleanup
  rm -rf "$temp" && trap '' EXIT
}

log_and_run "dependencies for $REPO_URL" install_dependencies
log_and_run "Installing $REPO_URL" install_awrit
