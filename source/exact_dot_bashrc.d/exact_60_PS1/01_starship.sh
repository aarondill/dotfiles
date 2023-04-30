#!/usr/bin/env bash
# Only if custom is not in use
if ! [ "$DISABLE_CUSTOM_PS1" = 1 ]; then
  return
fi

# For compat. Starship will set this
unset PS1

# Init starship
eval "$(starship init bash)"

# Force first load to ensure that PS1 gets set
true
# or true, I don't care if this fails, starship should handle itself.
starship_precmd || true

# Set the title of the window
function set_win_title() {
  # Create (GIT: TOP-LEVEL) for titlebar
  local git_base=""
  if [[ $git_available ]] && git rev-parse &>/dev/null; then # In git
    git_base=" (GIT: "
    if [[ "$(git rev-parse --is-inside-work-tree)" = "true" ]]; then # In work tree
      git_base+=$(basename -- "$(git rev-parse --show-toplevel 2>/dev/null)")
    else # In .git
      git_base+=$(basename -- "$(realpath -- "$(git rev-parse --git-dir)/..")")
    fi
    git_base+=")"
  fi
  # Escapes for setting titlebar
  local title='\[\e]0;' end='\a\]'
  local title_bar="$title\W$git_base: \u$end\${debian_chroot:+(\$debian_chroot)}"
  echo -ne "\033]0; $(basename "$PWD") \007"
}
# Please starship, do it!
export starship_precmd_user_func="set_win_title"
