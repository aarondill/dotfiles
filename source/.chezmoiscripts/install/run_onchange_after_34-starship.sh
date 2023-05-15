#!/usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Use the install script! We love this! :)
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin
