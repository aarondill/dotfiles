#! /usr/bin/env bash
# Source utils
SOURCE_DIR=$(chezmoi source-path)
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

#region ## Actual Code {{{1
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

  name=$(tar -ztf "$TMP" | head -n 1 | cut -d'/' -f1) # hack to get name of top folder
  rm -f "$TMP" && trap '' EXIT                        # Cleanup
  # This is my own script! should be in .local/bin/update-java!
  sudo ~/.local/bin/update-java "$DESTINATION/$name"
)
#endregion
### Non-Funcion Code {{{1

if ! confirm "Would you like to install some things?"; then
  err 'Aborting.'
  exit 0
fi

log_and_run 'installing proprietary packages' install_proprietary_software spotify-client code google-chrome-stable

log_and_run 'installing fx' install_fx

# Wezterm will inform of updates itself, only run if not already installed (and apt is available to install with)
if is_accessible_cmd apt && ! is_available_apt wezterm; then
  log_and_run 'installing wezterm' install_wezterm
fi

log_and_run 'installing lazygit' install_lazygit

log_and_run 'installing java' install_java

#endregion
