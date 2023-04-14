local M = {}

local function apply_colors(config)
	-- This is where you actually apply your config choices
	config.color_scheme = "LiquidCarbonTransparentInverse" -- overridden
	-- Don't like the curser? can change
	-- config.color_scheme = "Ef-Dark"

	-- ✨transparency✨ (default - 1)
	config.window_background_opacity = 0.85
	-- yes pls (default - true, equivalent to BrightAndBold)
	config.bold_brightens_ansi_colors = "BrightAndBold"
end

M.apply = function(config)
	apply_colors(config)
	-- I don´t wanna see no tabs if I aint usin' them. (default - false)
	config.hide_tab_bar_if_only_one_tab = true

	-- Point out when input echo is disabled (default)
	config.detect_password_input = true

	-- nopety nope nope nope. (default "SystemBeep")
	config.audible_bell = "Disabled"

	-- Show the title, and keep a border for resizing (default)
	config.window_decorations = "TITLE|RESIZE"
	-- No padding pls
	-- default: left = '1cell', right = '1cell', top = '0.5cell', bottom = '0.5cell'
	config.window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	}

	-- I see you! Show me more of it pls (default 12.0)
	config.font_size = 9.5
	-- You too! (default 14.0)
	config.command_palette_font_size = 9.5
end

return M
