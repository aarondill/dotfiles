#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"
if [ -z "$APT" ]; then
  # STOP! if dependencies aren't installed, other things will fail, but can't use apt.
  abort0 "Apt is not installed, skipping apt install script"
fi

PACKAGES=(age anacron autopoint bat cmake command-not-found curl
  dconf-editor duf fwts gh git golang-go grep ifupdown inotify-tools less make
  neofetch neovim net-tools openvpn p7zip-full python3-neovim rsync shfmt tlp
  trash-cli tree util-linux xclip xdg-utils zip zoxide htop apt-file speedtest-cli
  ripgrep apt-clone aptitude libfuse2 hexedit luajit python3-pip ppa-purge xdotool)
GRAPHICAL_PACKAGES=(dconf-editor flatpak gimp
  gnome-shell-extension-manager gparted gucharmap luckybackup okular qtqr
  zeal gnome-software gnome-software-plugin-flatpak gnome-tweaks gnome-boxes)

function remove_if_installed_apt() {
  local package packages=()
  for package; do
    if dpkg -s "$package" &>/dev/null; then
      packages+=("$package")
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  sudo "$APT" remove -y -- "${packages[@]}"
}
function install_if_available_apt() {
  local packages=() package
  for package; do
    if is_available_apt "$package"; then
      packages+=("$package")
    else
      err "Could not find '$package' in apt repos"
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  sudo "$APT" install -y -- "${packages[@]}"
}

function install_apt_packages() { install_if_available_apt "${PACKAGES[@]}"; }

function install_graphical_apt_packages() {
  # If gnome is not installed, ask confirmation, else just install
  if ! is_installed_apt gnome-shell; then
    confirm "Gnome is not installed, would you still like to install gui applications?" || return 2
  fi
  install_if_available_apt "${GRAPHICAL_PACKAGES[@]}"
}

# Only run if apt is available - exits if false
installed_or_log apt

log_and_run 'installing neovim nightly ppa' sudo add-apt-repository -n -y -P ppa:neovim-ppa/unstable
log_and_run 'Updating apt sources' sudo "$APT" update
log_and_run 'Installing apt packages' install_apt_packages
log_and_run 'Installing graphical (gnome) apt packages' install_graphical_apt_packages
# Gnome comes with it, but I don't want it.
# Replace the existing cheese package with the flatpak package
remove_if_installed_apt gnome-characters cheese
# Install vim symlink to nvim
if command -v nvim &>/dev/null; then
  if ! [ "$(basename -- "$(update-alternatives --query vim | grep 'Value: /.\+' | cut -d' ' -f2-)")" = nvim ]; then
    sudo update-alternatives --install /usr/bin/vim vim "$(which nvim)" 100 || true
  fi
fi
