#!/usr/bin/env bash
if ! [ "$DISABLE_CUSTOM_PS1" = 1 ]; then
  return
fi
unset PS1
eval "$(starship init bash)"
starship_precmd || true
