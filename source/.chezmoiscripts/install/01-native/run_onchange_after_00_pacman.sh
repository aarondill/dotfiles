#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if [ -z "$PACMAN" ]; then
  # STOP! deps may not be installed, hopefully handled elsewhere
  abort "pacman is not installed, skipping pacman installation" 0
fi
# find-the-command
PACKAGES=(
  age cronie cmake curl dconf-editor duf github-cli git
  grep inotify-tools less make neofetch neovim net-tools
  openvpn p7zip rsync shfmt tlp trash-cli tree util-linux
  xclip xdg-utils zip unzip zoxide speedtest-cli ripgrep hexedit
  luajit python-pip xdotool base-devel wezterm bat bash-completion
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
  dconf-editor flatpak gparted gucharmap
  # These are setup on ubuntu through a ppa
  code spotify-launcher
)
GNOME_PACKAGES=(gnome-shell-extension-manager gnome-tweaks gnome-software gnome-software-plugin-flatpak)

function remove_if_installed() {
  local package packages=()
  for package; do
    if "$PACMAN" -Qi "$package" &>/dev/null; then
      packages+=("$package")
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  # The user still has to confirm, but that's good here
  sudo "$PACMAN" -Rsn -- "${packages[@]}"
}

is_available_pacman() {
  # DON'T call it like this, but if a list of packages is passed, this will handle them
  for package in "$@"; do pacman -Ss "^${package}\$" &>/dev/null || return 1; done
}

function install_if_available() {
  local packages=() package
  for package; do
    if is_available_pacman "$package"; then
      packages+=("$package")
    else
      err "Could not find '$package'"
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  # The user still has to confirm, but that's good here
  sudo "$PACMAN" -S --needed -- "${packages[@]}"
}

function install_packages() { install_if_available "${PACKAGES[@]}"; }

function install_graphical_packages() {
  local graphical_packages=("${GRAPHICAL_PACKAGES[@]}")
  # If gnome is not installed, ask confirmation, else just install
  if [ -n "$GNOME" ]; then graphical_packages+=("${GNOME_PACKAGES[@]}"); fi
  if ! is_accessible_cmd X && ! is_accessible_cmd Xorg && [ -z "$GNOME" ]; then
    confirm "Xorg is not installed, would you still like to install gui applications?"
  fi
  if confirm "Would you like to install qemu-desktop and other virtual machine packages?"; then
    graphical_packages=("${graphical_packages[@]}" "${VIRTUAL_MACHINE_PACKAGES[@]}")
  fi
  install_if_available "${graphical_packages[@]}"
}

# no install neovim latest, bc should already be
log_and_run 'Updating sources/packages' sudo "$PACMAN" -Syu
log_and_run 'Installing packages' install_packages
log_and_run 'Installing graphical packages' install_graphical_packages
# Gnome comes with it, but I don't want it.
remove_if_installed gnome-characters
# Install vim symlink to nvim - throws is /usr/bin/vim is defined.
if ! [ -f /usr/bin/vim ] && which nvim &>/dev/null; then sudo ln -s -T "$(which nvim)" /usr/bin/vim; fi
