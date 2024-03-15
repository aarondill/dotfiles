#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if ! has_pacman; then
  # STOP! deps may not be installed, hopefully handled elsewhere
  abort "pacman is not installed, skipping pacman installation" 0
fi
PACKAGES=(
  age cronie cmake curl dconf-editor duf github-cli git
  grep inotify-tools less make neofetch neovim net-tools
  openvpn p7zip rsync shfmt tlp trash-cli tree util-linux
  zip unzip zoxide speedtest-cli ripgrep hexedit fuse2
  luajit python-pip base-devel wezterm bat bash-completion
  git-delta vivaldi xdg-user-dirs inetutils
  # fonts
  ttf-nerd-fonts-symbols-mono noto-fonts-cjk noto-fonts-extra ttf-liberation
  # icon fonts
  noto-fonts-emoji ttf-font-awesome
  # Storage tools
  dosfstools exfatprogs e2fsprogs

  pkgfile github-cli wget rlwrap
  pactl pulseaudio lsof
  posix reflector jq
  openssh duplicity os-prober
  imagemagick networkmanager-openvpn
  plocate gdb lua openssh duplicity os-prober imagemagick
  sudo pkgfile posix reflector rlwrap pacutils
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
  wmctrl xdotool xclip xdg-utils xorg-xinit
  arandr thunderbird firefox firejail gimp hplip libreoffice-fresh
  okular onboard gnome-calculator gnome-calendar eog evince nautilus seahorse
  totem file-roller zeal pavucontrol qtqr rhythmbox screenkey simple-scan
  gnome-font-viewer sqlitebrowser transmission-gtk hplip
  xdg-desktop-portal-gnome xdg-desktop-portal-gtk arandr thunderbird
  eog okular gnome-calculator gnome-calendar totem evince nautilus seahorse file-roller
  pavucontrol qtqr rhythmbox screenkey simple-scan simplescreenrecorder
  xdg-desktop-portal-gtk gnome-system-monitor gnome-power-manager
)
GNOME_PACKAGES=(gnome-shell-extension-manager gnome-tweaks gnome-software gnome-software-plugin-flatpak)

function install_if_available() {
  local packages=()
  local package && for package; do
    pacman_is_available "$package" || { err "Could not find '$package'" && continue; }
    packages+=("$package")
  done
  [ ${#packages[@]} -gt 0 ] || return 0
  pacman_install "${packages[@]}"
}

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
log_and_run 'Installing packages' install_if_available "${PACKAGES[@]}"
log_and_run 'Installing graphical packages' install_graphical_packages

[ -e /usr/bin/vim ] || ! has_cmd nvim || mklink "$(cmd_path nvim)" /usr/bin/vim
