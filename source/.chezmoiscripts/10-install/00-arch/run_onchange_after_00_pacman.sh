#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if ! has_pacman; then
  # STOP! deps may not be installed, hopefully handled elsewhere
  abort "pacman is not installed, skipping pacman installation" 0
fi
# find-the-command
PACKAGES=(
  age cronie cmake curl dconf-editor duf github-cli git
  grep inotify-tools less make neofetch neovim net-tools
  openvpn p7zip rsync shfmt tlp trash-cli tree util-linux
  zip unzip zoxide speedtest-cli ripgrep hexedit fuse2
  luajit python-pip base-devel wezterm bat bash-completion
  git-delta vivaldi
  # fonts
  ttf-nerd-fonts-symbols-mono noto-fonts-cjk noto-fonts-extra
  # icon fonts
  noto-fonts-emoji ttf-font-awesome
  # Storage tools
  dosfstools exfatprogs e2fsprogs
)
VIRTUAL_MACHINE_PACKAGES=(
  # VM management. Technically, only virt-manager is graphical, but they are used together
  virt-manager qemu-desktop
  # virsh
  libvirt
  # virt-clone, etc...
  virt-install
)
GRAPHICAL_PACKAGES=(
  dconf-editor gparted gucharmap spotify-launcher
  wmctrl xdotool xclip xdg-utils
)
GNOME_PACKAGES=(gnome-shell-extension-manager gnome-tweaks gnome-software gnome-software-plugin-flatpak)

function install_if_available() {
  local packages=() package
  for package; do
    if pacman_is_available "$package"; then
      packages+=("$package")
    else
      err "Could not find '$package'"
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  # The user still has to confirm, but that's good here
  pacman_install "${packages[@]}"
}

function install_packages() { install_if_available "${PACKAGES[@]}"; }

function install_graphical_packages() {
  local graphical_packages=("${GRAPHICAL_PACKAGES[@]}")
  # If gnome is not installed, ask confirmation, else just install
  if [ -n "$GNOME" ]; then graphical_packages+=("${GNOME_PACKAGES[@]}"); fi
  if ! has_cmd X && ! has_cmd Xorg && [ -z "$GNOME" ]; then
    confirm "Xorg is not installed, would you still like to install gui applications?"
  fi
  if has_cmd virt-manager || confirm "Would you like to install qemu-desktop and other virtual machine packages?"; then
    graphical_packages=("${graphical_packages[@]}" "${VIRTUAL_MACHINE_PACKAGES[@]}")
  fi
  if has_cmd flatpak || confirm "Would you like to install flatpak?"; then
    graphical_packages=("${graphical_packages[@]}" flatpak)
  fi
  install_if_available "${graphical_packages[@]}"
}

# no install neovim latest, bc should already be
log_and_run 'Updating sources/packages' pacman_update
log_and_run 'Installing packages' install_packages
log_and_run 'Installing graphical packages' install_graphical_packages
# Gnome comes with it, but I don't want it.
if pacman_is_installed gnome-characters; then pacman_remove gnome-characters; fi
# Install vim symlink to nvim - throws is /usr/bin/vim is defined.
if ! [ -f /usr/bin/vim ] && which nvim &>/dev/null; then sudo_cmd ln -s -T "$(which nvim)" /usr/bin/vim; fi
