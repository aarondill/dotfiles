-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
config.color_scheme = "LiquidCarbonTransparentInverse"
-- Don't like the curser? can change
config.color_scheme = "Ef-Dark"

-- I don´t wanna see no tabs if I aint usin' them. (default - false)
config.hide_tab_bar_if_only_one_tab = true
-- ✨transparency✨ (default - 1)
config.window_background_opacity = 0.85
-- Show more when i shrink font-size (default - true)
config.adjust_window_size_when_changing_font_size = false
-- bc cool (default)
config.automatically_reload_config = true
-- yes pls (default - true, equivalent to BrightAndBold)
config.bold_brightens_ansi_colors = "BrightAndBold"
-- Pasting compatibility with windows. (default - true, equivalent to CarriageReturnAndLineFeed)
config.canonicalize_pasted_newlines = "CarriageReturnAndLineFeed"
-- Check for updates of wezterm (default)
config.check_for_updates = true
-- Check three times a day (default 86400 - once a day)
config.check_for_updates_interval_seconds = math.floor((24 * 60 * 60) / 3)
-- Show me the updates! (default)
config.show_update_window = true
-- Please don't leave the window open (default)
config.exit_behavior = "Close"
-- Point out when input echo is disabled (default)
config.detect_password_input = true
-- No background processes pls (default)
config.quit_when_all_windows_are_closed = true
-- Save me some work! (default "Spaces Only")
config.quote_dropped_files = "Posix"
-- Change default window size (default 80, 24)
config.initial_cols = 80
config.initial_rows = 24
-- Where am I typing? (default)
config.scroll_to_bottom_on_input = true
-- Show the title, and keep a border for resizing (default)
config.window_decorations = "TITLE|RESIZE"
-- HISTORY! (default 3500)
config.scrollback_lines = 5000
-- *THIS* is a word. (default)
config.selection_word_boundary = " \t\n{}[]()\"'`"

function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

local root_terminfo = "/lib/terminfo/w/wezterm"
local local_terminfo = os.getenv("HOME") .. "/.terminfo/w/wezterm"
if file_exists(root_terminfo) or file_exists(local_terminfo) then
	-- TODO: Should I install it?
	config.term = "wezterm"
end

return config
