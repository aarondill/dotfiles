#!/usr/bin/env bash
# ==> package.sh <==
_UTIL_D="$(dirname -- "${BASH_SOURCE[0]}")"
if [ -z "${_LEADER:-}" ]; then
  _LEADER="${BASH_SOURCE[0]}"
  _OLD_PWD="$(pwd)"
  builtin cd -- "$_UTIL_D"
  . ../.utils.sh # assert_source_once
fi
assert_source_once "${BASH_SOURCE[0]}" || return 0

if true; then
  . ./flow.sh # abort
fi

if [ "${BASH_SOURCE[0]}" = "$_LEADER" ]; then
  builtin cd -- "$_OLD_PWD"
  unset _OLD_PWD _UTIL_D _LEADER
fi

## --------------------------------------------------------------------------------------------------
## ------------------------------------------- APT utils --------------------------------------------
## --------------------------------------------------------------------------------------------------
# Path to apt (or nala) for installation/removal of packages
APT=$(which nala 2>/dev/null || which apt 2>/dev/null || printf '')
function apt_is_installed() { dpkg -s "$@" &>/dev/null; }
function apt_is_available() { for pac; do test -n "$(apt-cache show -- "$pac" 2>/dev/null)" || return 1; done; }
# usage: apt_install file_or_package
# NOTE: ensure files end in .deb!
function apt_install() { sudo_cmd "$APT" install -- "$@"; }
# Just updates, not upgrade - upgrade shouldn't be necessary, leave that to the user.
function apt_update() { sudo_cmd "$APT" update; }
function apt_is_held() { for pac; do [ -n "$(apt-mark showhold -- "$pac")" ] || return 1; done; }
function apt_remove() { sudo_cmd "$APT" purge -- "$@"; } # purge for symmetry with pacman. Be careful!
function has_apt() { [ -n "$APT" ]; }

## --------------------------------------------------------------------------------------------------
## ----------------------------------------- Pacman utils -------------------------------------------
## --------------------------------------------------------------------------------------------------

# Path to pacman for installation/removal of packages
PACMAN=$(which yay 2>/dev/null || which pacman 2>/dev/null || printf '')
# Internal function. don't call.
_pacman_exec() (
  export -n SHELLOPTS # makepkg/yay doesn't play nice with this
  "$@"
)
# treat yay like pacman (no sudo/--repo)
function pacyay() {
  args=("$@")
  case "$PACMAN" in
  */yay) args=("$PACMAN" --repo "${args[@]}") ;;
  *) args=(sudo_cmd "$PACMAN" "${args[@]}") ;;
  esac
  _pacman_exec "${args[@]}"
}
function pacman_is_installed() { for pac; do pacyay -Q -- "$pac" &>/dev/null || return 1; done; }
function pacman_is_available() { for pac; do pacyay -Si -- "$pac" &>/dev/null || return 1; done; }
# usage: pacman_install package
function pacman_install() { pacyay -S --needed -- "$@"; }
function pacman_update() { pacyay -Syu; }
function pacman_remove() { pacyay -Rncus -- "$@"; } # Careful here!
# install aur packages. not repo. use pacman_* for that.
function yay_install() {
  has_cmd yay || abort "Make sure yay is installed before using yay_install." 127
  _pacman_exec yay --aur -S --needed -- "$@"
}
function has_pacman() { [ -n "$PACMAN" ]; }
# relies on GNU sort!

# usage: vers_eq 1 1. Returns 1==1
vers_eq() { [ "$1" = "$2" ]; }
# usage: vers_lte 1 2. Returns 1<=2
vers_lte() { printf '%s\n' "$1" "$2" | sort -C -V; }
# usage: vers_gte 1 2. Returns 1>=2
vers_gte() { vers_lte "$2" "$1"; } # 1>=2 iff 2<=1
# usage: vers_lt 1 2. Returns 1<2
vers_lt() { ! vers_eq "$1" "$2" && vers_lte "$1" "$2"; } # x<y iff x=!y && x<=y
# usage: vers_gt 1 2. Returns 1>2
vers_gt() { ! vers_eq "$1" "$2" && vers_gte "$1" "$2"; } # x>y iff x=!y && x>=y
