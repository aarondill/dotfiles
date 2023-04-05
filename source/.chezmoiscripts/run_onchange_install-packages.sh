#! /usr/bin/env bash
# Installs frequently used packages.
function remove_if_installed_apt() {
  local package
  for package; do
    if dpkg -s "$package" &>/dev/null; then
      quiet_apt remove -- "$package"
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
  declare -a available_packages
  available_packages=()
  local package
  for package; do
    if is_available_apt "$package"; then
      available_packages+=("$package")
      log "Installing $package"
    else
      echo "Could not find '$package' in apt repos"
    fi
  done
  quiet_apt install -- "${available_packages[@]}"
}
function is_installed_apt() {
  dpkg -s "$@" &>/dev/null
}
function is_available_apt() {
  test -n "$(apt-cache show -- "$1" 2>/dev/null)"
}
function flatpak_install() {
  # usage: flatpak_install install [flathub] package
  # Errors are still displayed!
  flatpak install -y --noninteractive -- "$@" >/dev/null
}
function flatpak_is_installed() {
  # usage: flatpak_is_installed package
  flatpak info -- "$@" >/dev/null
}

# shellcheck disable=SC2120 # I know it doesn't recieve arguments. It's intentional.
function flatpak_update() {
  # usage: flatpak_update package
  # Errors are still displayed!
  flatpak update -y --noninteractive -- "$@" >/dev/null
}
function is_accessible_cmd() {
  command -v "$1" &>/dev/null
}
function log() {
  printf '%s\n' "$@"
}
# shellcheck disable=SC2120 # I know it doesn't recieve arguments.
function success() {
  printf "$(tput setaf 2)%s$(tput sgr0)\n" "${@:-Success!}"
}
function err() {
  printf '%s\n' "$@" >&2
}
read -rep "Would you like to install some things? (Y/n) " confirmation
if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
  # Get user password
  sudo -v
  # Only run if apt is available
  if is_accessible_cmd apt; then
    (
      set -e
      log 'Installing apt packages...'
      install_if_available_apt age anacron apt apt-clone autopoint bat cmake command-not-found curl \
        dconf-editor duf fwts gh git golang-go grep ifupdown inotify-tools less make \
        neofetch neovim net-tools openvpn p7zip-full python3-neovim rsync shfmt tlp \
        trash-cli tree util-linux xclip xdg-utils zip zoxide
      success
    ) || err 'something went wrong installing apt packages!'

    continue=0
    # If gnome is not installed, ask confirmation, else just install
    if is_installed_apt gnome-shell; then
      continue=1
    else
      read -rep "Are you sure? (yes) " confirmation
      if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
        continue=1
      fi
    fi

    if [ "$continue" = "1" ]; then
      sudo -v
      (
        set -e
        log 'Installing graphical (gnome) apt packages...'
        install_if_available_apt dconf-editor flatpak gimp \
          gnome-shell-extension-manager gparted gucharmap luckybackup okular qtqr \
          zeal gnome-software gnome-software-plugin-flatpak
        success
      ) || err 'something went wrong installing graphical (gnome) apt packages!'
    fi
  fi
  # Maintain sudo after long install
  sudo -v
  if ! is_accessible_cmd pnpm; then
    log 'installing nodejs and pnpm...'
    (
      set -e # stop immediately on error!
      # Setup n
      log 'Setting up /usr/local files for n'
      sudo mkdir -p /usr/local/bin /usr/local/lib/node_modules /usr/local/include /usr/local/share /usr/local/n
      sudo chown -R "$(whoami)" /usr/local/bin /usr/local/lib/node_modules /usr/local/include /usr/local/share /usr/local/n

      log 'installing node lts through n...'
      curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | /usr/bin/env bash -s -- lts

      # Setup pnpm
      log 'installing pnpm'
      corepack enable
      corepack prepare pnpm@latest --activate >/dev/null

      log 'installing n through pnpm'
      pnpm i --silent -g n
      success
    ) || err 'Something went wrong installing nodejs and pnpm!'
  fi
  remove_if_installed_apt gnome-characters

  # setup for custom ppas
  quiet_apt install gpg curl # should already be installed, but sanity check

  log 'installing proprietary applications'

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
  success # Not really guarenteed, but whatever

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
    (
      set -e
      log 'Installing flatpak packages...'
      remove_if_installed_apt cheese
      flatpak_apps=(
        com.github.johnfactotum.Foliate com.github.tchx84.Flatseal
        com.valvesoftware.Steam io.mrarm.mcpelauncher org.gnome.Boxes
        org.gnome.Cheese org.libretro.RetroArch com.github.alainm23.planner
      )
      for flatpak_app in "${flatpak_apps[@]}"; do
        if ! flatpak_is_installed "$flatpak_app"; then
          flatpak_install "$flatpak_app"
        fi
      done
      success
    ) || err 'Something went wrong installing flatpak packages'
    (
      set -e
      log 'Updating flatpak packages...'
      flatpak_update # Update all the packages
      success
    ) || err 'Something went wrong updating flatpak packages'
  else
    log "Flatpak is not installed, skipping flatpak installations."
  fi

  # Don't run if already installed because the appimage updates itself
  if ! is_accessible_cmd bitwarden; then
    (
      set -e
      log 'Installing bitwarden desktop...'
      declare DESTINATION=/usr/local/bin/bitwarden
      sudo curl -sSL 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=appimage' -o "$DESTINATION"
      sudo chown root "$DESTINATION"
      sudo chmod +x "$DESTINATION"
      success
    ) || err 'Something went wrong installing bitwarden desktop'
  fi

  (
    set -e
    log 'Installing bitwarden CLI...'
    # // Download and unzip the CLI
    # // temp_dir=$(mktemp -d)
    # // sudo curl -sSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o "$temp_dir/bw.zip"
    # // unzip "$temp_dir/bw.zip"
    # // mv -f "$temp_dir/bw" /usr/local/bin/bw
    # // rm -rf "$temp_dir"
    # zcat can only unzip a single file archive, but this allows me to skip the temporary directory
    curl -sSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' | zcat | sudo tee "/usr/local/bin/bw" >/dev/null
    sudo chmod +x /usr/local/bin/bw
    success
  ) || err 'Something went wrong installing bitwarden CLI'

  # TODO, make this automatic!
  if ! is_accessible_cmd fzf &>/dev/null; then
    (
      set -e
      log 'installing fzf...'
      declare OWNER=junegunn REPO=fzf BINLOCATION="/usr/bin"
      version=$(curl -sI https://github.com/$OWNER/$REPO/releases/latest | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
      if [ -z "$version" ]; then
        err "Failed while attempting to install $REPO. Please manually install at https://github.com/$OWNER/$REPO/releases"
        exit 2
      fi
      if [[ "$(uname)" != "Linux" ]]; then
        err "This script only supports Linux distributions"
        exit 2
      fi
      arch=$(uname -m)
      if [[ "$arch" == "aarch64" ]]; then
        suffix="-linux_arm64.tar.gz"
      elif [[ "$arch" == "x86_64" ]]; then
        # ASSUMES AMD
        suffix="-linux_amd64.tar.gz"
      else
        err "Could not determine architecture to install $REPO"
        exit 2
      fi
      url=https://github.com/$OWNER/$REPO/releases/download/$version/$REPO-$version$suffix
      targetFile="$BINLOCATION/fzf"
      # Download and extract the tar.gz archive
      curl -sSL "$url" | tar xzf - -O | sudo tee "$targetFile" >/dev/null
      sudo chmod +x "$targetFile"
      success
    ) || err "something went wrong installing fzf"
  fi

  if ! is_available_apt grub-editor; then
    log "Installing grub-editor..."
    (
      set -e
      declare OWNER=Thenujan-0 REPO=grub-editor suffix="1_amd64.deb" TEMP
      version=$(curl -sI https://github.com/$OWNER/$REPO/releases/latest | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
      if [ -z "$version" ]; then
        err "Failed while attempting to install $REPO. Please manually install at https://github.com/$OWNER/$REPO/releases"
        exit 2
      fi
      url=https://github.com/$OWNER/$REPO/releases/download/$version/${REPO}_${version#v}-${suffix}
      # Download the .deb
      TEMP=$(mktemp 'grub-editor.XXXXXXX.deb' --tmpdir)
      curl -sSL "$url" -o "$TEMP"
      quiet_apt install "$TEMP"
      rm "$TEMP"
      success
    ) || err "something went wrong installing grub-editor"
  fi
fi
