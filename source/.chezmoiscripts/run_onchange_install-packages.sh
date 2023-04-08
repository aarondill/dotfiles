#! /usr/bin/env bash

## Utility functions {{{1

### APT utility functions {{{2

function quiet_apt() { sudo apt-get -qq "$@" >/dev/null; }

function remove_if_installed_apt() {
  local package
  for package; do
    if dpkg -s "$package" &>/dev/null; then
      quiet_apt remove -- "$package"
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
      echo "Could not find '$package' in apt repos"
    fi
  done
  quiet_apt install -- "${available_packages[@]}"
}

### Flatpak utility functions {{{2

# usage: flatpak_install [source] package
function flatpak_install() { flatpak install -y --noninteractive -- "$@" >/dev/null; }
# shellcheck disable=SC2120 # I know it doesn't recieve arguments. it updates all without arguments.
function flatpak_update() { flatpak update -y --noninteractive -- "$@" >/dev/null; }

### Boolean utility functions {{{2

function is_accessible_cmd() { command -v "$1" &>/dev/null; }

function flatpak_is_installed() { flatpak info -- "$@" &>/dev/null; }

function is_installed_apt() { dpkg -s "$@" &>/dev/null; }

function is_available_apt() { test -n "$(apt-cache show -- "$1" 2>/dev/null)"; }

### Github utility functions {{{2
function get_latest_version_github() {
  declare OWNER="$1" REPO="$2"
  version=$(curl -sI "https://github.com/$OWNER/$REPO/releases/latest" | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
  if [ -z "$version" ]; then
    err "Failed while attempting to install $REPO. Please manually install at https://github.com/$OWNER/$REPO/releases"
    return 2
  fi
  echo "$version"
}

### Control flow utility functions {{{2

function log_and_run() {
  # Usage: log_and_run "Installing something" apt install -y something
  local task command args
  task="$1"
  command="$2"
  args=("${@:3}")
  (
    set -e
    log "${task^}..." # Uppercase
    "$command" "${args[@]}"
    success
  ) || err "Something went wrong while ${task,}!" # Lowercase
}

function installed_or_log() {
  if ! is_accessible_cmd "$1"; then
    err "${1^} is not installed, skipping ${1^} installation"
    return 1
  fi
  return 0
}

### Output Utility Functions {{{2

function log() { printf '%s\n' "$@"; }
# shellcheck disable=SC2120 # I know it never recieve arguments, it has defaults.
function success() { printf "$(tput setaf 2)%s$(tput sgr0)\n" "${@:-Success!}"; }

function err() { printf '%s\n' "$@" >&2; }

function confirm() {
  read -rep "$* (Y/n) " confirmation
  if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
    return 0
  fi
  return 1
}

## Actual Code {{{1
function install_apt_packages() {
  sudo -v
  install_if_available_apt age anacron autopoint bat cmake command-not-found curl \
    dconf-editor duf fwts gh git golang-go grep ifupdown inotify-tools less make \
    neofetch neovim net-tools openvpn p7zip-full python3-neovim rsync shfmt tlp \
    trash-cli tree util-linux xclip xdg-utils zip zoxide htop
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
    zeal gnome-software gnome-software-plugin-flatpak gnome-tweakss
}

function install_pnpm_and_node() {
  sudo -v
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
}

function setup_ppa_spotify() {
  sudo -v
  curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
}
function setup_ppa_vscode() {
  sudo -v
  curl -sS https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
}
function setup_ppa_google-chrome() {
  sudo -v
  curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/google-chrome.gpg
  echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google.list >/dev/null
}

# Run setup_ppa_* first!
function install_proprietary_software() {
  quiet_apt update
  install_if_available_apt "$@"
  quiet_apt install -f
}

function install_snaps() {
  true # don't do anything 🤷‍♂️ - I don't want any snaps
}

function install_flatpaks() {
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
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
}

function install_bitwarden_desktop() {
  declare DESTINATION=/usr/local/bin/bitwarden
  sudo curl -sSL 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=appimage' -o "$DESTINATION"
  sudo chown root "$DESTINATION"
  sudo chmod +x "$DESTINATION"
}

function install_bitwarden_cli() {
  declare temp_dir
  temp_dir=$(mktemp -d) && (
    # Executed in a subshell, so this will run on end of block
    trap 'rm -rf $temp_dir' EXIT

    curl -sSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o "$temp_dir/bw.zip" &&
      unzip "$temp_dir/bw.zip" -d "$temp_dir" &&
      sudo mv -f "$temp_dir/bw" /usr/local/bin/bw &&
      sudo chmod +x /usr/local/bin/bw
  )
}

function install_fzf() {
  declare OWNER=junegunn REPO=fzf BINLOCATION="/usr/bin"
  version=$(get_latest_version_github "$OWNER" "$REPO") || return

  if [[ "$(uname)" != "Linux" ]]; then
    err "This script only supports Linux distributions"
    return 2
  fi
  arch=$(uname -m)
  if [[ "$arch" == "aarch64" ]]; then
    suffix="-linux_arm64.tar.gz"
  elif [[ "$arch" == "x86_64" ]]; then
    # ASSUMES AMD
    suffix="-linux_amd64.tar.gz"
  else
    err "Could not determine architecture to install $REPO"
    return 2
  fi
  url=https://github.com/$OWNER/$REPO/releases/download/$version/$REPO-$version$suffix
  targetFile="$BINLOCATION/fzf"
  # Download and extract the tar.gz archive
  curl -sSL "$url" | tar xzf - -O | sudo tee "$targetFile" >/dev/null
  sudo chmod +x "$targetFile"
}

function install_grub_editor() {
  declare OWNER=Thenujan-0 REPO=grub-editor suffix="1_amd64.deb" temp_dir
  version=$(get_latest_version_github "$OWNER" "$REPO") || return

  url=https://github.com/$OWNER/$REPO/releases/download/$version/${REPO}_${version#v}-${suffix}
  # Download the .deb
  temp_dir=$(mktemp -d) &&
    (
      # In a subshell, so runs at end of block
      trap 'rm -rf $temp_dir' EXIT
      curl -sSL "$url" -o "$temp_dir/grub-editor.deb" &&
        quiet_apt install "$temp_dir/grub-editor.deb"
    )
}

function install_fx() {
  declare temp_dir
  # Do this to ensure that files in cwd aren't deleted when moving final binary
  temp_dir=$(mktemp -d) && (
    trap 'rm -rf "$temp_dir"' EXIT
    # In subshell - doesn't affect outside
    cd "$temp_dir"
    # Installs to /usr/local/bin/fx - needs sudo to write to
    curl https://fx.wtf | sudo sh
  )
}

### Non-Funcion Code {{{1

if ! confirm "Would you like to install some things?"; then
  err 'Aborting.'
  exit 2
fi

# Only run if apt is available
installed_or_log apt && {
  log_and_run 'Installing apt packages' install_apt_packages
  log_and_run 'Installing graphical (gnome) apt packages' install_graphical_apt_packages
}

is_accessible_cmd pnpm || log_and_run 'Installing NodeJS and pnpm' install_pnpm_and_node

# Gnome comes with it, but I don't want it.
remove_if_installed_apt gnome-characters

# Should already be installed, sanity check
quiet_apt install gpg curl && {
  log_and_run 'installing spotify ppa' setup_ppa_spotify
  log_and_run 'installing vscode ppa' setup_ppa_vscode
  log_and_run 'installing google chrome ppa' setup_ppa_google-chrome
  log_and_run 'installing proprietary packages' install_proprietary_software spotify-client code google-chrome-stable
}

installed_or_log snap &&
  log_and_run "Installing snaps" install_snaps

installed_or_log flatpak && {
  is_accessible_cmd apt && remove_if_installed_apt cheese # Replace the existing cheese package with the flatpak package
  log_and_run "Installing flatpak packages" install_flatpaks
  log_and_run 'Updating flatpak packages' flatpak_update
}

# Ignore if already installed, updates itself
is_accessible_cmd bitwarden ||
  log_and_run "Installing bitwarden desktop" install_bitwarden_desktop

log_and_run "Installing bitwarden CLI" install_bitwarden_cli

is_accessible_cmd fzf ||
  log_and_run 'Installing fzf' install_fzf

if is_accessible_cmd apt && ! is_available_apt grub-editor; then
  log_and_run "Installing grub-editor" install_grub_editor
fi

log_and_run 'installing proprietary packages' install_proprietary_software spotify-client code google-chrome-stable
