#!/usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Use the install script! We love this! :)
install_script="$(curl -sSfL https://starship.rs/install.sh)"
# If ends in print_install, remove it. It's annoying. Be as safe as possible.
if [ "print_install" = "$(tail -n1 <<<"$install_script")" ]; then
  install_script=$(head -n1 <<<"$install_script")
fi
sh -c "$install_script" -- -y -b /usr/local/bin
