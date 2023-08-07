return {
  -- No background processes pls (default)
  quit_when_all_windows_are_closed = true,
  -- Please don't leave the window open (default)
  exit_behavior = "Close",
  -- don't close some important stuff (default)
  window_close_confirmation = "AlwaysPrompt",
  -- go ahead and close *these* (default below)
  -- bash, sh, zsh, fish, tmux, nu, cmd.exe, pwsh.exe, powershell.exe
  skip_close_confirmation_for_processes_named = {
    "dash",
    "bash",
    "sh",
    "zsh",
    "fish",
    "tmux",
    "nu",
    "cmd.exe",
    "pwsh.exe",
    "powershell.exe",
  },
}
