#!/usr/bin/env bash

# -e: exit on error
# -u: exit on unset variables
# -C don't overwrite files by accident
# -o pipefail fail a pipe if anything fails
set -euC -o pipefail

RED=$(tput setaf 2 2>/dev/null || printf '')
BLUE=$(tput setaf 4 2>/dev/null || printf '')
RESET_COLOR=$(tput sgr0 2>/dev/null || printf '')

log() { printf "$BLUE%s$RESET_COLOR\n" "$@"; }
err() { printf "$RED%s$RESET_COLOR\n" "$@" >&2; }
abort() { err "$1" && exit "${2:-1}"; }

install_chezmoi() {
  local bin_dir="${BINDIR:-/usr/local/bin}"
  local chezmoi="${bin_dir}/chezmoi"
  local chezmoi_install_script
  log "Installing chezmoi to '${chezmoi}'"
  if command -v curl &>/dev/null; then
    chezmoi_install_script="$(curl -fsSL https://get.chezmoi.io)"
  elif command -v wget &>/dev/null; then
    chezmoi_install_script="$(wget -qO- https://get.chezmoi.io)"
  else
    abort "To install chezmoi, you must have curl or wget." 1
  fi
  sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
}

# `if cmd; then true; else cmd; fi` to fix syntax highlighting
if ! chezmoi="$(command -v chezmoi)"; then
	install_chezmoi
	chezmoi="$(command -v chezmoi)"
fi

# POSIX way to get script dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"

args=(init --source="${script_dir}")

if [ -n "${DOTFILES_ONE_SHOT:-}" ]; then args+=(--one-shot); else args+=(--apply); fi

if [ -n "${DOTFILES_DEBUG:-}" ]; then args+=(--debug); fi

log "Setting up environment"
bin_dir="$(dirname -- "$chezmoi")"
if [[ ":$PATH:" != *":$bin_dir"* ]]; then
  # security issue, but who tf cares
  PATH="$bin_dir:$PATH"
fi

log "Running '$chezmoi ${args[*]}'"
# replace current process with chezmoi
exec "$chezmoi" "${args[@]}"
