local M = {}

---print(string.format(s, ...))
---@param s string|number
---@param ... any
---@see string.format
function M.printf(s, ...)
  print(string.format(s, ...))
end

---checks if a file exists on the filesystem (is readable to current user)
---@param name string path to the file (relative to CWD)
---@return boolean file is readable
function M.file_exists(name)
  local f = io.open(name, "r")
  if f then f:close() end
  return f ~= nil
end

---Deep merges t2 into t1. MODIFIES t1!
---@param t1 table table to merge into
---@param t2 table table to merge from
---@return table t1 modified t1
function M.tbl_merge_modify(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k]) == "table") then
      M.tbl_merge_modify(t1[k], v)
    else
      t1[k] = v
    end
  end
  return t1
end

---Return from plugin file to define a key shortcut.
---@param key {key:string, mods?:string|string[], action?:unknown}
---@return fun(config:table):nil
function M.define_key(key)
  return function(config)
    if config.keys then
      config.keys[#config.keys + 1] = key
    else
      config.keys = { key }
    end
  end
end

M.os = M.os or {}
---Runs cmd and returns stdout
---Note: stderr will be displayed on the output stream
---@param cmd string the command to run
---@param raw boolean? if true, no processing will be done on the output
---@return string
function M.os.capture(cmd, raw)
  local f = assert(io.popen(cmd, "r"))
  local s = assert(f:read("*a"))
  f:close()
  --stylua: ignore
  if raw then return s end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  s = string.gsub(s, "[\n\r]+", " ")
  return s
end

return M
