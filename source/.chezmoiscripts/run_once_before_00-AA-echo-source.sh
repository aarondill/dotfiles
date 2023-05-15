#!/usr/bin/env bash

echo "CHEZMOI_SOURCE_DIR=$CHEZMOI_SOURCE_DIR"
printf 'chezmoi source-path = %s' "$(chezmoi source-path)"
