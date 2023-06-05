#!/usr/bin/env bash
wait_key() { read -r -p "Checking stdin safety. Press enter to continue."; }
if ! [ -t 0 ] || ! wait_key; then
  printf '%s\n' "Don't run this in a pipe. Stdin must be accessible to the terminal for prompts." >&2
  exit 1
fi
