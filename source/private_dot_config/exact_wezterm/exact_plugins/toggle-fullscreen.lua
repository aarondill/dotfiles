local wezterm = require("wezterm")

return require("util").define_key({
	key = "K",
	mods = "CTRL",
	action = wezterm.action.ToggleFullScreen,
})
