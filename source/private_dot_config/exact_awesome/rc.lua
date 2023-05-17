-- TODO:
-- Create global tablist for use in all cases

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Focus on mouse over
require("awful.autofocus")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

require("error_handling")

require("theme")(nil)

require("layout.wibar")

require("rules")

require("signals")

require("wallpaper")
