return {
	-- bc cool (default)
	-- automatically_reload_config = true,
	automatically_reload_config = false,

	-- Check for updates of wezterm (default)
	check_for_updates = true,
	-- Check three times a day (default 86400 - once a day)
	check_for_updates_interval_seconds = math.floor((24 * 60 * 60) / 3),
	-- Show me the updates! (default)
	show_update_window = true,
}
