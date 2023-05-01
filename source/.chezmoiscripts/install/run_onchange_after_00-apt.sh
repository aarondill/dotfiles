#! /usr/bin/env bash
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function remove_if_installed_apt() {
  local package
  for package; do
    if dpkg -s "$package" &>/dev/null; then
      sudo apt remove -y -- "$package"
    fi
  done
}
function install_if_available_apt() {
  declare -a available_packages
  available_packages=()
  local package
  for package; do
    if is_available_apt "$package"; then
      available_packages+=("$package")
      log "Installing $package"
    else
      err "Could not find '$package' in apt repos"
    fi
  done
  sudo apt install -y -- "${available_packages[@]}"
}

function install_apt_packages() {
  sudo -v
  install_if_available_apt age anacron autopoint bat cmake command-not-found curl \
    dconf-editor duf fwts gh git golang-go grep ifupdown inotify-tools less make \
    neofetch neovim net-tools openvpn p7zip-full python3-neovim rsync shfmt tlp \
    trash-cli tree util-linux xclip xdg-utils zip zoxide htop apt-file speedtest-cli \
    ripgrep
  is_accessible_cmd apt &&
    install_if_available_apt apt-clone aptitude
}

function install_graphical_apt_packages() {
  sudo -v
  # If gnome is not installed, ask confirmation, else just install
  if ! (is_installed_apt gnome-shell || confirm "Gnome is not installed, would you still like to install gui applications?"); then
    return 2
  fi

  install_if_available_apt dconf-editor flatpak gimp \
    gnome-shell-extension-manager gparted gucharmap luckybackup okular qtqr \
    zeal gnome-software gnome-software-plugin-flatpak gnome-tweaks gnome-boxes
}

# Only run if apt is available
installed_or_log apt && {
  log_and_run 'installing neovim nightly ppa' sudo add-apt-repository -y ppa:neovim-ppa/unstable ||
    log "Yeah, that didn't work. Neovim will be installed from default repos."
  log_and_run 'Installing apt packages' install_apt_packages
  log_and_run 'Installing graphical (gnome) apt packages' install_graphical_apt_packages
  # Gnome comes with it, but I don't want it.
  remove_if_installed_apt gnome-characters
  # Replace the existing cheese package with the flatpak package
  remove_if_installed_apt cheese
  # Install vim symlink to nvim
  if command -v nvim &>/dev/null; then
    sudo update-alternatives --install /usr/bin/vim neovim "$(which nvim)" 100 || true
  fi
}
