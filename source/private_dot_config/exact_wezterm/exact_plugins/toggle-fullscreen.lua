local wezterm = require("wezterm")

return require("util").define_key({
	key = "n",
	mods = "SHIFT|CTRL",
	action = wezterm.action.ToggleFullScreen,
})
