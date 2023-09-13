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
  rm_exit "$TMP_DIR"

  git_clone 'https://git.launchpad.net/ubuntu/+source/humanity-icon-theme' "$TMP_DIR" 'ubuntu/devel'
  sudo_cmd mv -vi "$TMP_DIR/Humanity" "$TMP_DIR/Humanity-Dark" "/usr/share/icons"

  rm_exit_cleanup "$TMP_DIR"
}

function install_yaru() {
  local TMP_DIR

  if has_apt; then
    apt_install libgtk-3-dev git meson sassc
  elif has_pacman; then
    pacman_install gtk3 git meson sassc
  else
    abort "Could not install dependencies for yaru theme. Please install it yourself manually" 0
  fi

  TMP_DIR=$(mktemp -d)
  rm_exit "$TMP_DIR"
  git_clone 'https://github.com/ubuntu/yaru.git' "$TMP_DIR"

  local meson=meson
  if ! version_gt "$("$meson" --version)" "0.59.0"; then
    local meson_version tmp_file
    meson_version=$(get_latest_version_github "mesonbuild/meson") # 1.2.0
    log "Installing meson $meson_version"
    tmp_file="$TMP_DIR/meson-$meson_version.tar.gz"
    install_from_github "mesonbuild/meson" "$meson_version" "meson-$meson_version.tar.gz" "$tmp_file"
    log "Unpacking $tmp_file"
    tar xf "$tmp_file" -C "$TMP_DIR"
    meson="$TMP_DIR/meson-$meson_version/meson.py"
  fi

  pushd "$TMP_DIR" >/dev/null
  "$meson" build # requires meson >=0.59!

  popd >/dev/null
  pushd "$TMP_DIR/build" >/dev/null
  ninja
  sudo_cmd ninja install

  rm_exit_cleanup "$TMP_DIR"
  popd >/dev/null
}

if ! [ -d /usr/share/icons/Humanity/ ] || ! [ -d /usr/share/icons/Humanity-Dark/ ]; then
  log_and_run "Installing Humanity icon theme" install_humanity_icons
fi

if ! [ -d /usr/share/icons/Yaru/ ] || ! [ -d /usr/share/icons/Yaru-dark/ ]; then
  log_and_run "Installing Yaru theme" install_yaru
fi
