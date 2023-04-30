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
	if f then
		io.close(f)
	end
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

return M
