-- Pull in the wezterm API
local wezterm = require("wezterm")
local util = require("util")
local theme = require("theme")
local usage_settings = require("functional_setting")
local term = require("term")
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

theme.apply(config)
usage_settings.apply(config)

local root_terminfo = "/lib/terminfo/w/wezterm"
local local_terminfo = os.getenv("HOME") .. "/.terminfo/w/wezterm"
if util.file_exists(root_terminfo) or util.file_exists(local_terminfo) then
	config.term = "wezterm"
end

return config
