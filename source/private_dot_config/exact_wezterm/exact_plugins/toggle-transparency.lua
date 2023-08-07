local wezterm = require("wezterm")

wezterm.on("toggle-opacity", function(window)
  local overrides = window:get_config_overrides() or {}
  if not overrides.window_background_opacity then
    overrides.window_background_opacity = 1
  else
    overrides.window_background_opacity = nil
  end
  window:set_config_overrides(overrides)
end)

return require("util").define_key({
  key = "B",
  mods = "CTRL",
  action = wezterm.action.EmitEvent("toggle-opacity"),
})
