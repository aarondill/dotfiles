#! /usr/bin/env bash
set -euC -o pipefail
export SHELLOPTS
# Source utils
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-"$(chezmoi source-path)"}"
# shellcheck source=../.utils.sh
. "$SOURCE_DIR/.chezmoiscripts/.utils.sh"

function install_fzf() {
  local REPO=junegunn/fzf BINLOCATION=${BINLOCATION:-/usr/bin}
  local targetFile="$BINLOCATION/fzf"
  local version
  version=$(get_latest_version_github "$REPO") # 0.42.0

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
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
    local temp="$temp_dir/fzf.zip"
    curl -sSfL "$url" -o "$temp"
    unzip -o "$temp"
    sudo mv "$temp" "$targetFile"
    # cleanup
    rm -rf "$temp_dir" && trap '' EXIT
  fi
  sudo chmod +x "$targetFile"
}

log_and_run 'Installing fzf' install_fzf
