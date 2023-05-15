#!/usr/bin/env bash
set -euC -o pipefail
# Use the install script! We love this! :)
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin
