local M = {}

local function apply_text_settings(config)
	-- *THIS* is a word. (default)
	config.selection_word_boundary = " \t\n{}[]()\"'`"

	-- Lmk if i'm missing some stuff (default)
	config.warn_about_missing_glyphs = true

	-- Pasting compatibility with windows. (default - true, equivalent to CarriageReturnAndLineFeed)
	config.canonicalize_pasted_newlines = "CarriageReturnAndLineFeed"
	-- Save me some work! (default "Spaces Only")
	config.quote_dropped_files = "Posix"
end

local function apply_config_settings(config)
	-- bc cool (default)
	config.automatically_reload_config = true

	-- Check for updates of wezterm (default)
	config.check_for_updates = true
	-- Check three times a day (default 86400 - once a day)
	config.check_for_updates_interval_seconds = math.floor((24 * 60 * 60) / 3)
	-- Show me the updates! (default)
	config.show_update_window = true
end

local function apply_window_settings(config)
	-- Change default window size (default 80, 24)
	config.initial_cols = 80
	config.initial_rows = 24
	-- Show more when i shrink font-size (default - true)
	config.adjust_window_size_when_changing_font_size = false

	-- No background processes pls (default)
	config.quit_when_all_windows_are_closed = true
	-- Please don't leave the window open (default)
	config.exit_behavior = "Close"
	-- don't close some important stuff (default)
	config.window_close_confirmation = "AlwaysPrompt"
	-- go ahead and close *these* (default below)
	-- bash, sh, zsh, fish, tmux, nu, cmd.exe, pwsh.exe, powershell.exe
	config.skip_close_confirmation_for_processes_named = {
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
	}

	-- Where am I typing? (default)
	config.scroll_to_bottom_on_input = true
	-- HISTORY! (default 3500)
	config.scrollback_lines = 5000

	-- Consistency! Persistence! (default false)
	config.switch_to_last_active_tab_when_closing_tab = true
end

M.apply = function(config)
	apply_text_settings(config)
	apply_config_settings(config)
	apply_window_settings(config)
end

return M
