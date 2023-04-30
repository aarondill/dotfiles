#!/usr/bin/env bash
unset PS1
eval "$(starship init bash)"
starship_precmd || true
