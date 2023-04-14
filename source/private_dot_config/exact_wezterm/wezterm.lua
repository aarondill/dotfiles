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

config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.85

return config
