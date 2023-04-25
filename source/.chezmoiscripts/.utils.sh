#!/bin/bash
# Source this file to get utilities

function log() { printf '%s\n' "$@"; }
function err() { printf '%s\n' "$@" >&2; }
function success() { printf "$(tput setaf 2)%s$(tput sgr0)\n" "Success!"; }
function abort() { err "$@" && exit 2; }
function abort0() { err "$@" && exit 0; }

# Code to source *this* file. DON'T MOVE THIS FILE!
# SOURCE_DIR=$(chezmoi source-path)
# # shellcheck source=.utils.sh
# . "$SOURCE_DIR/.chezmoiscripts/utils.sh"
