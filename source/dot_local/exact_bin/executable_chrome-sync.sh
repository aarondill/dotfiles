#!/bin/sh

static="static-google-chrome/"
link="google-chrome"
volatile="/dev/shm/google-chrome-$USER"

IFS=
set -efu

cd ~/.config/

if [ ! -r "$volatile" ]; then
  mkdir -m0700 "$volatile"
fi

if [ "$(readlink "$link")" != "$volatile" ]; then
  mv "$link" "$static"
  ln -s "$volatile" "$link"
fi

if [ -e "$link/.unpacked" ]; then
  rsync -av --delete --exclude .unpacked "./$link/" "./$static/"
else
  rsync -av "./$static/" "./$link/"
  touch "$link/.unpacked"
fi
