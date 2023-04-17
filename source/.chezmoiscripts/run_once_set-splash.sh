#!/bin/bash
# Install vortex-ubuntu-plymouth-theme splash screen

tempdir=$(mktemp -d) && (
	# Stop on error and remove temporary dir
	set -e
	trap 'rm -rf "$tempdir"' EXIT

	# Clone and cd into repo
	git clone 'https://github.com/emanuele-scarsella/vortex-ubuntu-plymouth-theme' "$tempdir" --depth 1
	cd "$tempdir"

	# Create conf.d to show the splash on boot
	if [[ -f /etc/initramfs-tools/conf.d/splash ]]; then
		printf '%s\n' 'Overriding /etc/initramfs-tools/conf.d/splash'
		sleep 3 # Allow user to halt
	fi
	printf 'FRAMEBUFFER=y' | sudo tee /etc/initramfs-tools/conf.d/splash >/dev/null
	# Runing update is not necessary because the install script will do it

	# Run install script
	sudo chmod +x "$tempdir/install"
	sudo "$tempdir/install"

)
