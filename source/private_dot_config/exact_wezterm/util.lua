local M = {}

function M.file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

---private implementation of tbl_copy
---@param obj any
---@param seen any
---@return any
---@private
local function copy(obj, seen)
	if type(obj) ~= "table" then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do
		res[copy(k, s)] = copy(v, s)
	end
	return res
end
---deep copies a table.
---@param obj table input table
---@return table new_table copied table
function M.tbl_copy(obj)
	return copy(obj, nil)
end

---local implementation of tbl_merge. MODIFIES the input table!
---@param t1 table
---@param t2 any
---@return any
local function local_tbl_merge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k]) == "table") then
			local_tbl_merge(t1[k], v)
		else
			t1[k] = v
		end
	end
	return t1
end

---Deep merges two tables, overwriting values in t1 with t2. This function makes a copy
---of the original table, so it's safe to use both tables without changes being made.
---@param t1 table
---@param t2 table
---@return table
function M.tbl_merge(t1, t2)
	local new_t1 = M.tbl_copy(t1)
	return local_tbl_merge(t1, t2)
end

return M
