#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_humanity_icons() {
  local TMP_DIR

  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  git clone --single-branch --branch=ubuntu/devel 'https://git.launchpad.net/ubuntu/+source/humanity-icon-theme' "$TMP_DIR"
  sudo mv -vi "$TMP_DIR/Humanity" "$TMP_DIR/Humanity-Dark" "/usr/share/icons"

  rm -rf "$TMP_DIR" && trap '' EXIT # cleanup
}

function install_yaru() (
  local TMP_DIR

  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT
  if [ -n "$APT" ]; then
    sudo "$APT" install libgtk-3-dev git meson sassc
  elif [ -n "$PACMAN" ]; then
    sudo "$PACMAN" -S libgtk-3-dev git meson sassc
  else
    abort "Could not install dependencies for yaru theme. Please install it yourself manually" 0
  fi

  git clone --filter=tree:0 --single-branch https://github.com/ubuntu/yaru.git "$TMP_DIR"

  local meson=meson
  if ! version_gt "$("$meson" --version)" "0.59.0"; then
    local meson_version tmp_file
    meson_version=$(get_latest_version_github "mesonbuild/meson")
    log "Installing meson $meson_version"
    tmp_file="$TMP_DIR/meson-$meson_version.tar.gz"
    install_from_github "mesonbuild/meson" "$meson_version" "meson-$meson_version.tar.gz" "$tmp_file"
    cd "$TMP_DIR"
    log "Unpacking $tmp_file"
    tar xf "$tmp_file"
    meson="$TMP_DIR/meson-$meson_version/meson.py"
  fi

  cd "$TMP_DIR"
  "$meson" build # requires meson >=0.59!

  cd build
  ninja
  sudo ninja install

  rm -rf "$TMP_DIR" && trap '' EXIT # cleanup
)

if ! [ -d /usr/share/icons/Humanity/ ] || ! [ -d /usr/share/icons/Humanity-Dark/ ]; then
  log_and_run "Installing Humanity icon theme" install_humanity_icons
fi

if ! [ -d /usr/share/icons/Yaru/ ] || ! [ -d /usr/share/icons/Yaru-dark/ ]; then
  log_and_run "Installing Yaru theme" install_yaru
fi
