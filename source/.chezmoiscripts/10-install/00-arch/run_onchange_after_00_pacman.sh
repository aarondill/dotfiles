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
  7zip age base-devel bash-completion bat bluez-utils cmake cronie curl
  dconf-editor ddrescue dosfstools duf duplicity dust e2fsprogs exfatprogs
  expac eza fastfetch ffmpeg fuse2 gdb git git-delta github-cli grep hexedit
  imagemagick inetutils inotify-tools jq lazygit less libpulse lsof lua luajit
  make mdcat moreutils neovim net-tools networkmanager-openvpn nnn
  noto-fonts-cjk noto-fonts-emoji noto-fonts-extra openssh openvpn os-prober
  pacman-contrib pacutils pigz pipewire-pulse pkgfile plocate posix progress pv
  python-pip reflector renameutils ripgrep ripgrep-all rlwrap rsync shfmt
  silicon speedtest-cli strace sudo tlp trash-cli tree ttf-font-awesome
  ttf-liberation ttf-nerd-fonts-symbols-mono unzip util-linux vivaldi wezterm
  wget xdg-user-dirs zip zoxide
)
VIRTUAL_MACHINE_PACKAGES=(
  virt-manager qemu-desktop # VM management. Technically, only virt-manager is graphical, but they are used together
  libvirt                   # virsh
  virt-install              # virt-clone, etc...
)
GRAPHICAL_PACKAGES=(
  arandr dconf-editor eog evince file-roller firefox firejail gimp
  gnome-calculator gnome-calendar gnome-font-viewer gnome-power-manager
  gnome-system-monitor gparted gucharmap hplip libreoffice-fresh mpv mpv-mpris
  pavucontrol screenkey seahorse simple-scan snapshot spotify-launcher
  sqlitebrowser thunderbird transmission-gtk wmctrl xclip
  xdg-desktop-portal-gtk xdg-utils xdotool xorg-xinit zeal
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
