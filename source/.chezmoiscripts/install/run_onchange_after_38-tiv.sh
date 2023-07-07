#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# dependencies installed on each distribution
DEBIAN_DEPS=(imagemagick)
ARCH_DEPS=(imagemagick)
# Run in the source directory
PREHOOK=(cd src/main/cpp)
# Passed to *all* make invocations
MAKE_ALL_ARGS=(--silent)
MAKE_ARGS=(LDLIBS=-lstdc++fs)
MAKE_INSTALL_ARGS=()
# Cloned into tempdir
REPO_URL='https://github.com/stefanhaustein/TerminalImageViewer'

export WARNINGS=none

install_from_make() {
  # Shows on errors
  THIS="Make"

  # Try install deps *first*
  if [ -n "$APT" ]; then
    if [ "${#DEBIAN_DEPS[@]}" -gt 0 ]; then
      sudo "$APT" install -y "${DEBIAN_DEPS[@]}"
    fi
  elif [ -n "$PACMAN" ]; then
    if [ "${#ARCH_DEPS[@]}" -gt 0 ]; then
      sudo "$PACMAN" -S --needed -- "${ARCH_DEPS[@]}"
    fi
  else
    err "Unable to install dependencies to build '$REPO_URL'"
    err "Please install the following dependencies (names are from debian repositories):"
    err "${DEBIAN_DEPS[@]}"
    exit 2
  fi

  # Temp directory
  temp=$(mktemp -d)
  trap 'rm -rf "$temp"' EXIT

  # Clone to tempdir
  git clone --quiet -- "$REPO_URL" "$temp" >/dev/null

  # build from source
  cd "$temp"
  "${PREHOOK[@]}"
  (
    export -n SHELLOPTS # Let shells set their own options
    [ -x ./autogen.sh ] && ./autogen.sh
    [ -x ./configure ] && ./configure "${CONFIGURE_ARGS[@]}"
    make "${MAKE_ALL_ARGS[@]}" "${MAKE_ARGS[@]}"
    # Install the updated application
    sudo make "${MAKE_ALL_ARGS[@]}" "${MAKE_INSTALL_ARGS[@]}" install
  )

  # cleanup
  rm -rf "$temp" && trap '' EXIT
}

log_and_run "Installing $REPO_URL" install_from_make
