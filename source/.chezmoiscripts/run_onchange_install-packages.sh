#! /usr/bin/env bash
# Installs frequently used packages. Must be manually editted!
function remove_if_installed_apt() {
  local package
  for package in; do
    if dpkg -s "$package" &>/dev/null; then
      sudo apt remove -y -- "$package"
    fi
  done
}
function quiet_apt(){
  # usage: quiet_apt install package
  # Errors are still displayed!
  # -qq implies -y, output to /dev/null to hide info
  sudo apt-get -qq "$@" >/dev/null
}
function install_if_available_apt() {
  local package
  for package in; do
    if is_available_apt "$package"; then
      quiet_apt install -- "$package"
    else
      echo "It appears that $package is not available from the apt repositories."
    fi
  done
}
function is_available_apt() {
  test -n "$(apt-cache show -- "$1" 2>/dev/null)"
}
function is_accessible_cmd() {
  command -v "$1" &>/dev/null
}
function log() {
  printf '%s\n' "$@"
}
read -rep "Would you like to install some things? (yes) " confirmation
if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
  # Get user password
  sudo -v
  # TODO, make this count which are available and install at once
  install_if_available_apt age anacron apt apt-clone autopoint bat command-not-found \
    curl dconf-editor duf flatpak fwts gh gimp git gnome-shell-extension-manager \
    golang-go gparted grep gucharmap httpie ifupdown inotify-tools \
    less luckybackup make neofetch neovim net-tools okular openvpn \
    python3-neovim qtqr rsync shfmt tlp trash-cli tree util-linux xclip httpie \
    xdg-utils zeal zip zoxide gnome-software gnome-software-plugin-flatpak
  # Maintain sudo after long install
  sudo -v
  if ! is_accessible_cmd pnpm; then
    log 'installing nodejs. After getting node setup using `n`, run `sudo apt remove nodejs`'
    install_if_available_apt npm
    npm install -g n
    sudo mkdir -p /usr/local/n
    sudo chown -- "$(whoami)" /usr/local/n
    n lts # installs node and npm
    corepack enable
    corepack prepare --activate pnpm@latest
    pnpm i -g n
    npm remove -g n
    quiet_apt autoremove npm
  fi
  remove_if_installed_apt gnome-characters

  # setup for custom ppas
  quiet_apt install wget gpg curl

  # Require custom ppas
  log 'installing spotify ppa'
  curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null

  log 'installing vscode ppa'
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

  log 'installing google-chrome ppa'
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/google-chrome.gpg
  echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google.list >/dev/null

  quiet_apt update
  install_if_available_apt spotify-client code google-chrome-stable
  quiet_apt install -f

  # Maintain sudo
  sudo -v
  # Install some snaps, if snap is installed
  if is_accessible_cmd snap &>/dev/null; then
    true # install snaps here if desired
    # sudo snap install bitwarden
  else
    log "Snap is not installed, skipping snap installations."
  fi

  # Install flatpaks, if flatpak is installed
  if is_accessible_cmd flatpak &>/dev/null; then
    # remove cheese if present
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    remove_if_installed_apt cheese
    sudo flatpak install com.github.johnfactotum.Foliate \
      com.github.tchx84.Flatseal \
      com.valvesoftware.Steam \
      io.mrarm.mcpelauncher \
      org.gnome.Boxes \
      org.gnome.Cheese \
      org.libretro.RetroArch \
      com.github.alainm23.planner
  else
    log "Flatpak is not installed, skipping flatpak installations."
  fi
  if ! is_accessible_cmd bitwarden &>/dev/null; then
    log "The bitwarden appimage can be installed from their website and should be placed in /usr/local/bin/bitwarden"
  fi

  if ! is_accessible_cmd fzf &>/dev/null; then
    log "fzf should be downloaded from the git repo and placed in /usr/bin/fzf"
  fi
  if ! is_available_apt grub-editor; then
    log 'grub-editor can be downloaded from the git repo at https://github.com/Thenujan-0/grub-editor/releases/latest'
  fi
fi
