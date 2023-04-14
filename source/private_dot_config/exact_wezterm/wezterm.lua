-- Pull in the wezterm API
local wezterm = require("wezterm")
local theme = require("theme")
local usage_settings = require("functional_settings")
local term = require("term")
local function create_conf_obj()
	-- In newer versions of wezterm, use the config_builder which will
	-- help provide clearer error messages
	if wezterm.config_builder then
		return wezterm.config_builder()
	end
	return {}
end

local config = create_conf_obj()

theme.apply(config)
usage_settings.apply(config)
term.apply(config)

return config
