#!/usr/bin/env bash
wait_key() {
  local code=0
  read -n1 -s -r -p "Checking stdin safety. Press any key to continue." || code=$?
  printf '\n'
  return "$code"
}
if ! [ -t 0 ] || ! wait_key; then
  printf '%s\n' "Don't run this in a pipe. Stdin must be accessible to the terminal for prompts." >&2
  exit 1
fi
