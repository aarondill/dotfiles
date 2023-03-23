#! /usr/bin/env bash
# Installs frequently used packages. Must be manually editted!
function remove_if_installed_apt() {
  local package
  for package; do
    if dpkg -s "$package" &>/dev/null; then
      sudo apt remove -y -- "$package"
    fi
  done
}
function quiet_apt() {
  # usage: quiet_apt install package
  # Errors are still displayed!
  # -qq implies -y, output to /dev/null to hide info
  sudo apt-get -qq "$@" >/dev/null
}
function install_if_available_apt() {
  declare -i exit=0
  local package
  for package; do
    if is_available_apt "$package"; then
      # If failed, set exit to failure code
      quiet_apt install -- "$package" || exit=$?
    else
      echo "It appears that $package is not available from the apt repositories."
    fi
  done
  return $exit
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
function err() {
  printf '%s\n' "$@" >&2
}
read -rep "Would you like to install some things? (yes) " confirmation
if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
  # Get user password
  sudo -v
  # TODO, make this count which are available and install at once
  (
    set -e
    log 'Installing apt packages...'
    install_if_available_apt age anacron apt apt-clone autopoint bat command-not-found \
      curl dconf-editor duf flatpak fwts gh gimp git gnome-shell-extension-manager \
      golang-go gparted grep gucharmap httpie ifupdown inotify-tools \
      less luckybackup make neofetch neovim net-tools okular openvpn \
      python3-neovim qtqr rsync shfmt tlp trash-cli tree util-linux xclip httpie \
      xdg-utils zeal zip zoxide gnome-software gnome-software-plugin-flatpak
    log 'success!'
  ) || err 'something went wrong installing apt packages!'
  # Maintain sudo after long install
  sudo -v
  if ! is_accessible_cmd pnpm; then
    log 'installing nodejs and pnpm...'
    (
      set -e # stop immediately on error!
      install_if_available_apt npm
      which npm >/dev/null # exits if fails
      # Setup n
      "$(which npm)" install --silent -g n
      sudo mkdir -p /usr/local/n
      sudo chown -- "$(whoami)" /usr/local/n
      n --quiet lts # installs node and npm

      # Remove npm from apt
      "$(which npm)" remove --silent -g n
      quiet_apt autoremove npm

      # Setup pnpm
      corepack enable
      corepack prepare pnpm@latest --activate >/dev/null
      pnpm i --silent -g n
      log 'Success!'
    ) || err 'Something went wrong installing nodejs and pnpm!'
  fi
  remove_if_installed_apt gnome-characters

  # setup for custom ppas
  quiet_apt install gpg curl # should already be installed, but sanity check

  # Require custom ppas
  log 'installing spotify ppa'
  curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null

  log 'installing vscode ppa'
  curl -sS https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

  log 'installing google-chrome ppa'
  curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/google-chrome.gpg
  echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google.list >/dev/null

  log 'Installing spotify-client, code, and google-chrome packages'
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
    log 'Setting up flatpak'
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    (
      set -e
      log 'Installing flatpak packages...'
      remove_if_installed_apt cheese
      flatpak install -y --noninteractive flathub com.github.johnfactotum.Foliate >/dev/null
      flatpak install -y --noninteractive flathub com.github.tchx84.Flatseal >/dev/null
      flatpak install -y --noninteractive flathub com.valvesoftware.Steam >/dev/null
      flatpak install -y --noninteractive flathub io.mrarm.mcpelauncher >/dev/null
      flatpak install -y --noninteractive flathub org.gnome.Boxes >/dev/null
      flatpak install -y --noninteractive flathub org.gnome.Cheese >/dev/null
      flatpak install -y --noninteractive flathub org.libretro.RetroArch >/dev/null
      flatpak install -y --noninteractive flathub com.github.alainm23.planner >/dev/null
      log 'Success!'
    ) || err 'Something went wrong installing flatpak packages'
  else
    log "Flatpak is not installed, skipping flatpak installations."
  fi
  if ! is_accessible_cmd bitwarden &>/dev/null; then
    (
      set -e
      log 'Installing bitwarden desktop...'
      # Is an appimage
      sudo curl -sSL 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=appimage' -o /usr/local/bin/bitwarden
      sudo chmod +x /usr/local/bin/bitwarden
      log 'Success!'
    ) || err 'Something went wrong installing bitwarden desktop'
  fi
  if ! bw --version &>/dev/null; then
    (
      set -e
      log 'Installing bitwarden CLI...'
      # Is a zip file
      temp_dir=$(mktemp --tmpdir -d 'config-install-XXXXXX')
      sudo curl -sSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o "$temp_dir/bw.zip"
      unzip "$temp_dir/bw.zip"
      mv "$temp_dir/bw" /usr/local/bin/bw
      rm -rf "$temp_dir"
      sudo chmod +x /usr/local/bin/bw
      log 'Success!'
    ) || err 'Something went wrong installing bitwarden CLI'
  fi

  # TODO, make this automatic!
  if ! is_accessible_cmd fzf &>/dev/null; then
    log "fzf should be downloaded from the git repo and placed in /usr/bin/fzf"
  fi
  if ! is_available_apt grub-editor; then
    log 'grub-editor can be downloaded from the git repo at https://github.com/Thenujan-0/grub-editor/releases/latest'
  fi
fi
