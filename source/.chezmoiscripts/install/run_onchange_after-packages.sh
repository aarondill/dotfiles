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

log_and_run 'installing fx' install_fx

log_and_run 'installing lazygit' install_lazygit

log_and_run 'installing java' install_java

#endregion
