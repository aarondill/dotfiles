#!/usr/bin/env bash

echo "CHEZMOI_SOURCE_DIR=$CHEZMOI_SOURCE_DIR"
printf 'chezmoi source-dir = %s' "$(chezmoi source-dir)"
