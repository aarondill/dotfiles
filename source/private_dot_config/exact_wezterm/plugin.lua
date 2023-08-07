local util = require("util")
local wezterm = require("wezterm")

-- allow calling the export (or export.plugin)
local M = {}
---calls M.plugin(...)
setmetatable(M, {
  __call = function(_, ...)
    return M.plugin(...)
  end,
})

-- Create config object
local config = {}
-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then config = wezterm.config_builder() end

---function to get current configuration. Returns a reference to the table! This table may change with **ANY** call from this module.
---@return table config
function M.get_config()
  return config
end

local function merge_config(merge)
  return util.tbl_merge_modify(config, merge)
end

---Requires plugins.mod and merges the configuration with the returned table, or runs the returned function with the current configuration as an argument and merges the returned table. nil return values are ignored. If a table is passed, it's iterated (recursively) with ipairs and each module is required.
---@param mod string| string[] the module located under plugins to require
---@return table config current configuration (after merge)
function M.plugin(mod)
  -- If a table is passed in, call on each plugin.
  if type(mod) == "table" then
    for _, p in ipairs(mod) do
      M.plugin(p)
    end
    --- END! return the changed configuration
    return config
  end

  if type(mod) ~= "string" then
    util.printf("plugin expected string, got %s", type(mod))
    return config
  end

  local suc, export = pcall(require, "plugins." .. mod)
  if not suc then
    util.printf("require of plugins.%s failed: %s", mod, export)
    return config
  end

  -- if type=="module" then import each plugin in the list relative to the module. ONLY works with init.lua
  if type(export) == "table" and export.type == "module" then
    for _, p in ipairs(export) do
      M.plugin(mod .. "." .. p)
    end
    return config
  end

  -- If table, merge with config
  if type(export) == "table" then return merge_config(export) end

  -- If function, call with current config and merge result
  if type(export) == "function" then
    local suc, res = pcall(export, config)

    -- Failed!
    if not suc then
      util.printf("Module plugins.%s threw error: %s", mod, res)

    -- Returned table, merge
    elseif type(res) == "table" then
      return merge_config(res)

    -- That isn't a table!
    elseif res then
      util.printf("Module plugins.%s returned fun():%s, expected fun():table.", mod, type(res))
    end

  -- Not table or function!
  elseif export then
    util.printf("Module plugins.%s exported a %s, expected table or fun(c:table):table", mod, type(export))
  end

  -- Something went wrong, just return current config
  return config
end

return M
