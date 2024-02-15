#!/usr/bin/env bash
check_dependencies chezmoi
# This is the target for chezmoi. This is usually $HOME, but could be different
target=$(chezmoi target-path) || abort "Could not find target-path"
[ -d "$target" ] || abort "target-path is not a directory: ${target}"
# This is the source of the chezmoi repository.
# If .chezmoiroot is present, it will not be the root of the git repository.
source=$(chezmoi source-path) || abort "Could not find source-path"
[ -d "$source" ] || abort "source-path is not a directory: ${source}"
# This is the git repository directory (root).
# This may match $source, or it may be different if .chezmoiroot is present.
chezmoi_dir=$(chezmoi execute-template '{{.chezmoi.workingTree}}')
[ -d "$chezmoi_dir" ] || abort "chezmoi.workingTree is not a directory: ${chezmoi_dir}"

# The file containing files to auto update
export CONFIG_FILES="$chezmoi_dir/autoupdate"
# A stored copy of the crontab
# This file should be in a location that is backed up by chezmoi
export CRONTAB_FILE=~/.config/crontab
# A stored copy of the dconf settings -- Not directly backed up by chezmoi
export DCONF_BACKUP=~/.config/dconf/dconf-backup.ini
# The directory under $source where files from / are stored
# This directory should be in a location that is backed up by chezmoi
export ROOT_FOLDER=~/.root

# returns 0 for not-managed files
has_changed() { [ -n "$(chezmoi status -- "$1" 2>/dev/null)" ]; }
is_managed() { [ -n "$(chezmoi source-path -- "$1" 2>/dev/null)" ]; }
is_encrypted() { [ -n "$(chezmoi list --include=encrypted -- "$1")" ]; }
