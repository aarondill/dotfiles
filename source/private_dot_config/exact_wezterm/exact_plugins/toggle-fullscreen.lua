local wezterm = require("wezterm")

return require("util").define_key({
  key = "F",
  mods = "CTRL",
  action = wezterm.action.ToggleFullScreen,
})
