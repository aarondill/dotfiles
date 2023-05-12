#! /usr/bin/env bash
set -euC -o pipefail
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

# Defined in utils.sh
if [ -z "$APT" ]; then
  # STOP! if dependencies aren't installed, other things will fail, but can't use apt.
  abort0 "Apt is not installed, skipping apt install script"
fi

PACKAGES=(
  age anacron autopoint bat cmake command-not-found curl
  dconf-editor duf fwts gh git golang-go grep ifupdown inotify-tools less make
  neofetch neovim net-tools openvpn p7zip-full python3-neovim rsync shfmt tlp
  trash-cli tree util-linux xclip xdg-utils zip zoxide htop speedtest-cli
  ripgrep libfuse2 hexedit luajit python3-pip ppa-purge xdotool
)
GRAPHICAL_PACKAGES=(
  dconf-editor flatpak gimp gparted gucharmap luckybackup okular qtqr
  zeal gnome-software gnome-software-plugin-flatpak gnome-boxes
)
GNOME_PACKAGES=(gnome-shell-extension-manager gnome-tweaks)

function remove_if_installed() {
  local package packages=()
  for package; do
    if dpkg -s "$package" &>/dev/null; then
      packages+=("$package")
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  sudo "$APT" remove -y -- "${packages[@]}"
}
function install_if_available() {
  local packages=() package
  for package; do
    if is_available_apt "$package"; then
      packages+=("$package")
    else
      err "Could not find '$package'"
    fi
  done
  if [ ${#packages[@]} -eq 0 ]; then return 0; fi
  sudo "$APT" install -y -- "${packages[@]}"
}

function install_packages() { install_if_available "${PACKAGES[@]}"; }

function install_graphical_packages() {
  local graphical_packages=("${GRAPHICAL_PACKAGES[@]}")
  # If gnome is not installed, ask confirmation, else just install
  if [ -z "$GNOME" ]; then
    confirm "Gnome is not installed, would you still like to install gui applications?"
  else
    graphical_packages+=("${GNOME_PACKAGES[@]}")
  fi
  install_if_available "${graphical_packages[@]}"
}

log_and_run 'installing neovim nightly ppa' sudo add-apt-repository -n -y -P ppa:neovim-ppa/unstable
log_and_run 'Updating sources' sudo "$APT" update
log_and_run 'Installing packages' install_packages
log_and_run 'Installing graphical packages' install_graphical_packages
# Gnome comes with it, but I don't want it.
# Replace the existing cheese package with the flatpak package
remove_if_installed gnome-characters cheese
# Install vim symlink to nvim
if command -v nvim &>/dev/null; then
  if ! [ "$(basename -- "$(update-alternatives --query vim | grep 'Value: /.\+' | cut -d' ' -f2-)")" = nvim ]; then
    sudo update-alternatives --install /usr/bin/vim vim "$(which nvim)" 100 || true
  fi
fi
