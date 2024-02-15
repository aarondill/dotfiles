#!/usr/bin/env bash
# The file containing files to auto update
export CONFIG_FILES=~/.config/chezmoi/autoupdate
# A stored copy of the crontab
export CRONTAB_FILE=~/.config/crontab
# A stored copy of the dconf settings
export DCONF_BACKUP=~/.config/dconf/dconf-backup.ini
# The directory under $source where files from / are stored
export ROOT_FOLDER=~/.root

check_dependencies chezmoi
target=$(chezmoi target-path) || abort "Could not find target-path"
[ -d "$target" ] || abort "target-path is not a directory: ${target}"
source=$(chezmoi source-path) || abort "Could not find source-path"
[ -d "$source" ] || abort "source-path is not a directory: ${source}"
