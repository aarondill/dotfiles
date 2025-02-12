#!/bin/sh
# Fail if we can't get an exclusive lock on autorandr (imediately unlocks)
LOCKFILE=/tmp/.autorandr-lock # NOTE: This needs to be the same as ../block.d/00-thinkpad.sh
flock -x -n "$LOCKFILE" true
