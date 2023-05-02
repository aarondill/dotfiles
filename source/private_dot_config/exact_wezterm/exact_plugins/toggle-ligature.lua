local wezterm = require("wezterm")

wezterm.on("toggle-ligature", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if not overrides.harfbuzz_features then
		-- If we haven't overridden it yet, then override with ligatures disabled
		overrides.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
	else
		-- else we did already, and we should disable out override now
		overrides.harfbuzz_features = nil
	end
	window:set_config_overrides(overrides)
end)

return function(config)
	local keys = {
		key = "E",
		mods = "CTRL",
		action = wezterm.action.EmitEvent("toggle-ligature"),
	}

	if config.keys then
		config.keys[#config.keys + 1] = keys
	else
		config.keys = { keys }
	end
	return {}
end
