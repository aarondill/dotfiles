#!/usr/bin/env bash
function err(){ printf '%s\n' "$@" >&2 || true; }
function abort(){ err "$1" && exit "${2:-1}"; }
if [ -z "$MY_PROFILE_HAS_LOADED" ]; then
	err "Load the profile with this command to ensure proper environment for setup:"
	abort '. ~/.profile' 1
fi
