#!/usr/bin/env bash
# Remove the "to run a command using sudo..." at start up.
set -euC -o pipefail

if sudo sudo -V | grep -q -- --enable-admin-flag; then
  cat <<'EOF' | sudo tee /etc/sudoers.d/disable_admin_file_in_home >/dev/null
# Disable ~/.sudo_as_admin_successful file
Defaults !admin_flag
EOF
fi

sudo sed '/sudo hint/,/To run a command/s/cat <<-EOF/true <<-EOF/' /etc/bash.bashrc -i

if [ -f ~/.sudo_as_admin_successful ]; then
  rm ~/.sudo_as_admin_successful
fi
