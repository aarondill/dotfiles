#! /usr/bin/env bash

#region ## Utility functions {{{1

KERNEL=$(uname -s) # eg: Linux
ARCH=$(uname -m)   # eg: x86_64
OS=$(lsb_release -si)
export ARCH KERNEL

#region ### Output Utility Functions {{{2

function log() { printf '%s\n' "$@"; }
function success() { printf "$(tput setaf 2)%s$(tput sgr0)\n" "Success!"; }
function err() { printf '%s\n' "$@" >&2; }
function confirm() {
  read -rep "$* (Y/n) " confirmation
  if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
    return 0
  fi
  return 1
}

#endregion
#endregion
#region ### Text utility functions {{{2
function lower() { local t && t="$(cat -)" && printf '%s' "${t,,}"; }
function first_lower() { local t && t="$(cat -)" && printf '%s' "${t,}"; }
function upper() { local t && t="$(cat -)" && printf '%s' "${t^^}"; }
function first_upper() { local t && t="$(cat -)" && printf '%s' "${t^}"; }

#endregion
#region ### Boolean utility functions {{{2
# returns 0 if all cmds are available, 1 otherwise
function is_accessible_cmd() {
  declare -i failed=0
  for cmd; do command -v "$cmd" &>/dev/null || failed=1; done
  return $failed
}

function flatpak_is_installed() { flatpak info -- "$@" &>/dev/null; }

function is_installed_apt() { dpkg -s "$@" &>/dev/null; }

function is_available_apt() { test -n "$(apt-cache show -- "$1" 2>/dev/null)"; }
#endregion
#region ### Control flow utility functions {{{2

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

#endregion
#region ### APT utility functions {{{2
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
#endregion
#region ### Flatpak utility functions {{{2

# usage: flatpak_install [source] package
function flatpak_install() { flatpak install -y --noninteractive -- "$@"; }
# shellcheck disable=SC2120 # I know it doesn't recieve arguments. it updates all without arguments.
function flatpak_update() { flatpak update -y --noninteractive -- "$@"; }

#endregion
#region ### Github utility functions {{{2
function get_latest_version_github() (
  set -e            # in subshell
  declare REPO="$1" # combined $OWNER/$REPO
  version=$(curl -sI "https://github.com/$REPO/releases/latest" | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
  if [ -z "$version" ]; then
    err "Failed while attempting to install $REPO. Please manually install at https://github.com/$REPO/releases"
    return 2
  fi
  echo "$version"
)
# usage: `install_from_github aaron/example latest example.sh /usr/local/bin/example`
function install_from_github() (
  set -e # runs in subshell, so doesn't affect outside
  local github_repo=$1 version=$2 asset=$3 destination=$4 TMP
  if [[ -z "$github_repo" ]]; then
    err "GitHub repo can not be an empty string"
    return 2
  elif [[ -z "$asset" ]]; then
    err "asset can not be an empty string"
    return 2
  elif [[ -z "$destination" ]]; then
    err "destination can not be an empty string"
    return 2
  fi

  if [ "$version" = "latest" ]; then version=$(get_latest_version_github "$github_repo"); fi

  log_github_install "$github_repo" "$version" "$asset" "$destination"

  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  curl -SsLf "https://github.com/$github_repo/releases/download/$version/$asset" -o "$TMP"
  sudo mv "$TMP" "$destination" >/dev/null
  sudo chmod +x "$destination"

  rm -f "$TMP" && trap '' EXIT # Cleanup
)
# usage: log_github_install aaron/example latest example.sh /usr/local/bin/
function log_github_install() {
  local github_repo=$1 version=$2 asset=$3 destination=$4
  log "Installing $github_repo version $version ($asset) to $destination"
}
#endregion
#region ### General utility functions {{{2
# download_file [sudo] <file> <destination> [mode]
function download_file() {
  local cmd=() file_url=$1 dest=$2 mode=$3 need_sudo=''

  if [ "$1" = "sudo" ]; then
    need_sudo=true
  fi
  if [ "$need_sudo" ]; then
    file_url=$2 dest=$3 mode=$4
    cmd=("sudo" "${cmd[@]}")
  fi

  cmd=("${cmd[@]}" curl -sSfL "$file_url" -o "$dest" --create-dirs)

  echo "${cmd[@]}" # show the constructed command
  "${cmd[@]}"      # Run the constructed command

  local cmd=(chmod "$mode" "$dest")
  if [ "$need_sudo" ]; then
    cmd=(sudo "${cmd[@]}")
  fi

  echo "${cmd[@]}" # show the constructed command
  "${cmd[@]}"      # Run the constructed command
}
#endregion
#region ## Actual Code {{{1
#region ### APT {{{2
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
    zeal gnome-software gnome-software-plugin-flatpak gnome-tweaks
}
#endregion
#region ### PNPM/Node {{{2
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

  log 'Installing pnpm global packages'
  pnpm i --silent -g

  log 'installing n through pnpm'
  pnpm i --silent -g n

}

#endregion
#region ### PPAs {{{2
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
  sudo apt update
  install_if_available_apt "$@"
  sudo apt install -f
}

#endregion
#region ### Snaps {{{2
function install_snaps() {
  true # don't do anything 🤷‍♂️ - I don't want any snaps
}

#endregion
#region ### Flatpak {{{2
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

#endregion
#region ### Bitwarden {{{2
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
    set -e

    curl -sSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o "$temp_dir/bw.zip"
    unzip -qq "$temp_dir/bw.zip" -d "$temp_dir"
    sudo mv -f "$temp_dir/bw" /usr/local/bin/bw
    sudo chmod +x /usr/local/bin/bw
  )
}

#endregion
#region ### FZF {{{2
function install_fzf() {
  local REPO=junegunn/fzf BINLOCATION=${BINLOCATION:-/usr/bin}
  local targetFile="$BINLOCATION/fzf"
  local version
  version=$(get_latest_version_github "$REPO") || return

  case "$KERNEL $ARCH" in
  "Darwin arm64") asset="fzf-$version-darwin_arm64.zip" ;;
  "Darwin x86_64") asset="fzf-$version-darwin_amd64.zip" ;;
  "Linux armv5"*) asset="fzf-$version-linux_armv5.tar.gz" ;;
  "Linux armv6"*) asset="fzf-$version-linux_armv6.tar.gz" ;;
  "Linux armv7"*) asset="fzf-$version-linux_armv7.tar.gz" ;;
  "Linux armv8"*) asset="fzf-$version-linux_arm64.tar.gz" ;;
  "Linux aarch64"*) asset="fzf-$version-linux_arm64.tar.gz" ;;
  "Linux loongarch64") asset="fzf-$version-linux_loong64.tar.gz" ;;
  "Linux ppc64le") asset="fzf-$version-linux_ppc64le.tar.gz" ;;
  "Linux "*64) asset="fzf-$version-linux_amd64.tar.gz" ;;
  "Linux s390x") asset="fzf-$version-linux_s390x.tar.gz" ;;
  "FreeBSD "*64) asset="fzf-$version-freebsd_amd64.tar.gz" ;;
  "OpenBSD "*64) asset="fzf-$version-openbsd_amd64.tar.gz" ;;
  "CYGWIN"*" "*64) asset="fzf-$version-windows_amd64.zip" ;;
  "MINGW"*" "*64) asset="fzf-$version-windows_amd64.zip" ;;
  "MSYS"*" "*64) asset="fzf-$version-windows_amd64.zip" ;;
  "Windows"*" "*64) asset="fzf-$version-windows_amd64.zip" ;;
  esac

  if [ -z "$asset" ]; then
    echo "No prebuilt binary available for $KERNEL $ARCH"
    return 1
  fi

  url=https://github.com/$REPO/releases/download/$version/$asset

  log_github_install "$REPO" "$version" "$asset" "$targetFile"

  if [[ "$asset" =~ tar.gz$ ]]; then
    curl -sSfL "$url" | tar -xzf - -O | sudo tee "$targetFile" >/dev/null
  else
    temp_dir=$(mktemp -d) && (
      trap 'rm -rf "$temp_dir"' EXIT
      set -e # stop on failure
      local temp=$temp_dir/fzf.zip
      curl -fLo "$temp" "$url"
      unzip -o "$temp"
      sudo mv "$temp" "$targetFile"
    )
  fi
  sudo chmod +x "$targetFile"
}
#endregion
#region ### Grub Editor {{{2
function install_grub_editor() (
  set -e # run in subshell
  declare temp_dir version REPO=Thenujan-0/grub-editor
  if ! { [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; }; then
    err 'Only amd64 and x86_64 are supported at this time.'
    return 1
  fi

  version=$(get_latest_version_github "$REPO") # v1.0.0

  asset=grub-editor_${version#v}-1_amd64.deb # grub-editor_1.0.0-1_amd64.deb - no other files are available.
  # Download the .deb
  temp_dir=$(mktemp -d) &&
    (
      # In a subshell, so runs at end of block
      trap 'rm -rf $temp_dir' EXIT
      set -e
      local destination=$temp_dir/grub-editor.deb
      log_github_install "$REPO" "$version" "$asset" "$destination"
      curl -sSL "https://github.com/$REPO/releases/download/$version/$asset" -o "$destination"
      sudo apt install "$destination"
    )
)
#endregion
#region ### Fx {{{2
function install_fx() {
  local ext short_arch asset
  local BINDIR=${BINDIR:-'/usr/local/bin'}
  if [ "$KERNEL" == "windows" ]; then
    ext='.exe'
  elif ! { [ "$KERNEL" = 'Darwin' ] || [ "$KERNEL" = 'Linux' ]; }; then
    err "Unsupported OS: $KERNEL"
    return 1
  fi

  case "$ARCH" in
  x86_64 | amd64)
    short_arch=amd64
    ;;
  arm64 | aarch64)
    short_arch=arm64
    ;;
  *)
    err "Unsupported architecture: $ARCH"
    return 1
    ;;
  esac

  asset="fx_${KERNEL,,}_${short_arch}${ext}"
  install_from_github antonmedv/fx latest "$asset" "$BINDIR/fx"
}

#endregion
#endregion
#region ### Fff {{{2
function install_fff() {
  local DEST=${BINDIR:-'/usr/local/bin'}/fff
  local url='https://raw.githubusercontent.com/dylanaraps/fff/master/fff'
  download_file sudo "$url" "$DEST" 755 # Download file to bindir with rwxr-xr-x perms
}

#endregion
#region ### Wezterm {{{2
function install_wezterm() (
  set -e # run in subshell
  if [ "$OS" != "Ubuntu" ]; then
    log 'This script currently only supports ubuntu. More support comming soon. (Hopefully)'
    return 0
  fi
  declare temp_dir version REPO=wez/wezterm

  version=$(get_latest_version_github "$REPO") # v1.0.0

  asset=wezterm-${version}.Ubuntu22.04.deb # hard coding to Ubuntu22.04.deb for now
  # Download the .deb
  temp_dir=$(mktemp -d) &&
    (
      # In a subshell, so runs at end of block
      trap 'rm -rf $temp_dir' EXIT
      set -e
      local destination=$temp_dir/wezterm.deb
      log_github_install "$REPO" "$version" "$asset" "$destination"
      curl -sSL "https://github.com/$REPO/releases/download/$version/$asset" -o "$destination"
      sudo apt install "$destination"
    )
  # set wezterm as default term
  sudo update-alternatives --set x-terminal-emulator /usr/bin/open-wezterm-here
)
#endregion
#region ### Lazygit {{{2
function install_lazygit() (
  set -e
  local LAZYGIT_VERSION REPO FILE DESTINATION
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  FILE="lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  BINDIR=/usr/local/bin
  REPO='jesseduffield/lazygit'

  log_github_install "$REPO" "$LAZYGIT_VERSION" "$FILE" "$BINDIR"

  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  curl -SsLf "https://github.com/$REPO/releases/download/v$LAZYGIT_VERSION/$FILE" -o "$TMP"
  # output to destination
  tar -xvz -C "$BINDIR" -f "$TMP" lazygit
  sudo chmod +x "$BINDIR/lazygit"

  rm -f "$TMP" && trap '' EXIT # Cleanup
)
#endregion

#region ### Java {{{2
function install_java() (
  set -e
  local URL=https://download.java.net/java/GA/jdk20.0.1/b4887098932d415489976708ad6d1a4b/9/GPL/openjdk-20.0.1_linux-x64_bin.tar.gz
  local DESTINATION="/usr/lib/jvm" # Fixed location
  log "downloading java 20.0.1 (fixed version)"

  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  curl -SsLf "$URL" -o "$TMP"
  # output to destination
  sudo tar -xz -C "$DESTINATION" -f "$TMP"

  rm -f "$TMP" && trap '' EXIT # Cleanup

  name=$(tar -ztf "$TMP" | head -n 1 | cut -d'/' -f1) # hack to get name of top folder
  # This is my own script! should be in .local/bin/update-java!
  sudo ~/.local/bin/update-java "$DESTINATION/$name"
)
#endregion
### Non-Funcion Code {{{1

if ! confirm "Would you like to install some things?"; then
  err 'Aborting.'
  exit 0
fi

# Only run if apt is available
installed_or_log apt && {
  log_and_run 'installing neovim nightly ppa' sudo add-apt-repository -y ppa:neovim-ppa/unstable ||
    log "Yeah, that didn't work. Neovim will be installed from default repos."
  log_and_run 'Installing apt packages' install_apt_packages
  log_and_run 'Installing graphical (gnome) apt packages' install_graphical_apt_packages
}

is_accessible_cmd pnpm || log_and_run 'Installing NodeJS and pnpm' install_pnpm_and_node

# Gnome comes with it, but I don't want it.
remove_if_installed_apt gnome-characters

# Should already be installed, sanity check
is_accessible_cmd gpg curl && {
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

log_and_run 'Installing fzf' install_fzf

if is_accessible_cmd apt && ! is_available_apt grub-editor; then
  log_and_run "Installing grub-editor" install_grub_editor
fi

log_and_run 'installing proprietary packages' install_proprietary_software spotify-client code google-chrome-stable

log_and_run 'installing fx' install_fx

log_and_run 'installing fff' install_fff

# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if is_accessible_cmd apt && ! is_available_apt wezterm; then
  log_and_run 'installing wezterm' install_wezterm
fi

log_and_run 'installing lazygit' install_lazygit

log_and_run 'installing java' install_java

installed_or_log snap && (
  set -e
  log 'disconnecting firefox:hunspell'
  CONNECTONS=$(snap connections firefox | awk '/firefox:host-hunspell/{print $3}')
  # If still connected, disconnect
  if [ "$CONNECTONS" != '-' ]; then
    snap disconnect firefox:host-hunspell
  fi
  success
)
#endregion
