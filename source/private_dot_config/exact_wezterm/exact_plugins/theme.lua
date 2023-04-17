return {

	-- color_scheme = "LiquidCarbonTransparentInverse", -- overridden
	-- Don't like the curser? can change?
	color_scheme = "Ef-Dark",

	-- ✨transparency✨ (default - 1)
	window_background_opacity = 0.85,
	-- yes pls (default - true, equivalent to BrightAndBold)
	bold_brightens_ansi_colors = "BrightAndBold",

	-- I don´t wanna see no tabs if I aint usin' them. (default - false)
	hide_tab_bar_if_only_one_tab = true,

	-- Point out when input echo is disabled (default)
	detect_password_input = true,

	-- nopety nope nope nope. (default "SystemBeep")
	audible_bell = "Disabled",

	-- Show the title, and keep a border for resizing (default)
	window_decorations = "TITLE|RESIZE",
	-- No padding pls
	-- default: left = '1cell', right = '1cell', top = '0.5cell', bottom = '0.5cell'
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
}
