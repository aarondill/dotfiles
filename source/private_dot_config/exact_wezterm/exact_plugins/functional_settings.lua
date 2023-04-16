return {
	---- text_settings

	-- *THIS* is a word. (default)
	selection_word_boundary = " \t\n{}[]()\"'`",

	-- Lmk if i'm missing some stuff (default)
	warn_about_missing_glyphs = true,

	-- Pasting compatibility with windows. (default - true, equivalent to CarriageReturnAndLineFeed)
	canonicalize_pasted_newlines = "CarriageReturnAndLineFeed",
	-- Save me some work! (default "Spaces Only")
	quote_dropped_files = "Posix",

	---- config/update settings

	-- bc cool (default)
	automatically_reload_config = true,

	-- Check for updates of wezterm (default)
	check_for_updates = true,
	-- Check three times a day (default 86400 - once a day)
	check_for_updates_interval_seconds = math.floor((24 * 60 * 60) / 3),
	-- Show me the updates! (default)
	show_update_window = true,

	---- window_settings

	-- Change default window size (default 80, 24)
	initial_cols = 80,
	initial_rows = 24,
	-- Show more when i shrink font-size (default - true)
	adjust_window_size_when_changing_font_size = false,

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

	-- Where am I typing? (default)
	scroll_to_bottom_on_input = true,
	-- HISTORY! (default 3500)
	scrollback_lines = 5000,

	-- Consistency! Persistence! (default false)
	switch_to_last_active_tab_when_closing_tab = true,
}
