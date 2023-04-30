#! /usr/bin/env bash

# If pnpm is installed
if type pnpm &>/dev/null; then
    # Clear the cache, only output on error
    pnpm store prune >/dev/null
fi
