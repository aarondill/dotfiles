local plugin = require("plugin")

plugin("theme")
plugin("functional_settings")
plugin("term")
plugin("toggle-transparency")

return plugin.get_config()
