local util = require("util")
local size = { x = 80, y = 25 } -- Default
local do_full = os.getenv("WEZTERM_FULL_SCREEN")
if do_full and do_full ~= "" then
	local r = util.os.capture("stty size 2>/dev/null")

	local iter = r:gmatch("%d+")
	local x = tonumber(iter())
	local y = tonumber(iter())
	---@cast x integer?
	---@cast y integer?
	size = { x = x or size.x, y = y or size.y }
end

return {
	-- Change default window size (default 80, 24)
	initial_cols = size.x,
	initial_rows = size.y,
	-- Show more when i shrink font-size (default - true)
	adjust_window_size_when_changing_font_size = false,

	-- Consistency! Persistence! (default false)
	switch_to_last_active_tab_when_closing_tab = true,
}
