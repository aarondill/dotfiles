#!/usr/bin/env bash
set -euC -o pipefail
shopt -s nullglob globstar
XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/share:/usr/local/share}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

desktop_files=()
# split $XDG_DATA_DIRS on colons
IFS=: read -ra desktop_dirs <<<"$XDG_DATA_DIRS"
for dir in "${desktop_dirs[@]}" "$XDG_DATA_HOME"; do
  for file in "$dir/applications/"*.desktop; do
    desktop_files+=("${file##*/}") # strip leading path
  done
done

filetype=$(xdg-mime query filetype "$1")
app=$(printf '%s\n' "${desktop_files[@]}" | sort | uniq | rofi -dmenu -i -p "Select default app for $filetype")
if [ -z "$app" ]; then
  printf '%s\n' "aborted" >&2
  exit 1
fi
app=${app##*/}
xdg-mime default "$app" "$filetype"
echo "$app set as default application to open $filetype"
