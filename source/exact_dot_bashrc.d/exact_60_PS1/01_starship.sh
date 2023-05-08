#!/usr/bin/env bash
return
# Only if custom is not in use
if ! [ "$DISABLE_CUSTOM_PS1" = 1 ]; then
  return
fi

# Set the title of the window
function set_win_title() {
  local cwd title end who git_available git_base git_base_path
  git_available=
  if { command -v git && git --version; } &>/dev/null; then
    git_available=1
  fi

  # Create (GIT: TOP-LEVEL) for titlebar
  git_base=""
  if [ "$git_available" = 1 ] && git rev-parse &>/dev/null; then # In git
    git_base=" (git: "
    if [[ "$(git rev-parse --is-inside-work-tree)" = "true" ]]; then # In work tree
      git_base_path="$(git rev-parse --show-toplevel 2>/dev/null)"
      git_base+=$(basename -- "$git_base_path")
    else # In .git
      git_base_path="$(git rev-parse --git-dir)/.."
      git_base+=$(basename -- "$(realpath -- "$git_base_path")")
    fi
    git_base+=")"
  fi
  # Escapes for setting titlebar
  title='\033]0;' end='\007'
  cwd=$PWD
  if [ "$cwd" = "$HOME" ]; then cwd='~'; else cwd=$(basename -- "$cwd"); fi
  who=$(whoami)

  local title_bar="$title$who: $cwd$git_base$end"
  printf "%b" "$title_bar"
}
# Please starship, do it!
export starship_precmd_user_func="set_win_title"

# For compat. Starship will set this
unset PS1

# Init starship
eval "$(starship init bash)"

# Force first load to ensure that PS1 gets set
true
# or true, I don't care if this fails, starship should handle itself.
starship_precmd || true
