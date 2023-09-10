#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

groups=(adm cdrom video plugdev input lpadmin vboxusers libvirt loadkeys power)
user="$(id -un)"

log "Adding user groups to $user"

if [ -z "$user" ] || [ "$user" == 'root' ]; then abort "Can't set groups on user '$user'" 1; fi
if has_cmd getent; then
  function group_exists() { getent group -- "$1" &>/dev/null; }
elif has_cmd perl; then
  function group_exists() { perl -e 'my $gid = getgrnam($ARGV[0]); exit 1 if !defined($gid)' -- "$1"; }
else
  abort 'perl or getent is required to add groups' 1
fi

for group in "${groups[@]}"; do
  group_exists "$group" || {
    log "Skipping group '$group' because does it not exist"
    continue # group doesn't exist, skip it
  }
  log "Adding group $group"
  sudo_cmd usermod -a -G "$group" -- "$user" # add to the group
done
success
