#! /usr/bin/env bash
set -euC -o pipefail
shopt -s nullglob
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if ! has_apt; then
  # STOP! if dependencies aren't installed, other things will fail, but can't use apt.
  abort "Apt is not installed, skipping apt install script" 0
fi

PACKAGES=(
  age anacron cmake command-not-found consolation curl dosfstools duf e2fsprogs
  exfatprogs fonts-font-awesome fonts-noto-cjk fonts-noto-color-emoji
  fonts-noto-mono gh git grep hexedit inotify-tools less libfuse2 luajit make
  neofetch neovim net-tools openvpn p7zip-full progress python3-pip ripgrep rsync
  speedtest-cli tlp trash-cli tree util-linux zip zoxide
)
if [ "$OS" = "Debian" ]; then
  # Different name in debian, also only available in testing
  PACKAGES+=(golang-mvdan-sh)
else
  PACKAGES+=(shfmt)
fi

VIRTUAL_MACHINE_PACKAGES=(
  # VM management.
  virt-manager
  # virsh
  libvirt-clients
  # virt-clone, etc
  virtinst
)

GRAPHICAL_PACKAGES=(
  dconf-editor gparted gucharmap luckybackup zeal
  wmctrl xdotool xclip xdg-utils
  # firefox-esr firejail # not really graphical, but I only use it for firefox, so I don't need it otherwise
)

GNOME_PACKAGES=(
  gnome-shell-extension-manager gnome-tweaks
  gnome-software gnome-software-plugin-flatpak
)

function install_if_available() {
  local packages=() package
  for package; do
    if apt_is_available "$package"; then
      packages+=("$package")
    else
      err "Could not find '$package'"
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  apt_install "${packages[@]}"
}

function install_packages() { install_if_available "${PACKAGES[@]}"; }

function install_graphical_packages() {
  local graphical_packages=("${GRAPHICAL_PACKAGES[@]}")
  # If gnome is not installed, ask confirmation, else just install
  if [ -n "$GNOME" ]; then graphical_packages+=("${GNOME_PACKAGES[@]}"); fi
  if ! has_cmd X && ! has_cmd Xorg && [ -z "$GNOME" ]; then
    confirm "Xorg is not installed, would you still like to install gui applications?" || return 0
  fi
  if has_cmd virt-manager || confirm "Would you like to install qemu-desktop and other virtual machine packages?"; then
    graphical_packages=("${graphical_packages[@]}" "${VIRTUAL_MACHINE_PACKAGES[@]}")
  fi
  if has_cmd flatpak || confirm "Would you like to install flatpak?"; then
    graphical_packages=("${graphical_packages[@]}" flatpak)
  fi
  install_if_available "${graphical_packages[@]}"
}

# if [ "$OS" = "Ubuntu" ]; then
# # Disabled because I'm not using a local repo
# if ! file_exists /etc/apt/sources.list.d/neovim-ppa-ubuntu-unstable-*.list; then
#   log_and_run 'installing neovim nightly ppa' sudo_cmd add-apt-repository --no-update -y ppa:neovim-ppa/unstable
# fi
# # Disabled to increase stability
# if ! file_exists /etc/apt/sources.list.d/deki-ubuntu-firejail-*.list; then
#   log_and_run 'installing firejail ppa' sudo_cmd add-apt-repository --no-update -y ppa:deki/firejail
# fi
# fi

log_and_run 'Updating sources' apt_update
log_and_run 'Installing packages' install_packages
log_and_run 'Installing graphical packages' install_graphical_packages
# Gnome comes with it, but I don't want it.
if apt_is_installed gnome-characters; then apt_remove gnome-characters; fi
# Install vim symlink to nvim
if has_cmd update-alternatives && has_cmd nvim && ! [ "$(readlink -e /usr/bin/vim)" = "$(cmd_path nvim)" ]; then
  sudo_cmd update-alternatives --install /usr/bin/vim vim "$(cmd_path nvim)" 100 || true
fi
