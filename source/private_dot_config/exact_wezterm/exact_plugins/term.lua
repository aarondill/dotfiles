local util = require("util")

local root_terminfo = "/lib/terminfo/w/wezterm"
local local_terminfo = os.getenv("HOME") .. "/.terminfo/w/wezterm"
if util.file_exists(root_terminfo) or util.file_exists(local_terminfo) then
	return {
		term = "wezterm",
	}
end

return {}
