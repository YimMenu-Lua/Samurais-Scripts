-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local LUA_TABLE_OVERHEAD <const> = 3 * 0x8 -- 0x18
local Set                        = require("includes.classes.Set")

---@generic K, V
---@param t table<K, V>
---@param k K table key
---@param default? V default value to return if key is missing
---@overload fun(t: table<K, V>, k: K): V?
---@overload fun(t: table<K, V>, k: K, default: V): V
---@return V
function table.get(t, k, default)
	local v = t[k]
	return v ~= nil and v or default
end

-- Shallow
---@generic K, V
---@param t table<K, V>
---@param value V
---@return K?
function table.matchbyvalue(t, value)
	if (not t or (table.getlen(t) == 0)) then
		return nil
	end

	for k, v in pairs(t) do
		if (v == value) then
			return k
		end
	end

	return nil
end

-- Deep
---@param t table
---@param value anyval
---@param seen? set<table>
function table.find(t, value, seen)
	if (next(t) == nil) then return false end

	seen = seen or {}
	if (seen[t]) then return false end
	seen[t] = true

	for _, v in pairs(t) do
		if (v == value) then
			return true
		end

		if (type(v) == "table") then
			return table.find(v, value, seen)
		end
	end

	return false
end

---@generic K, V
---@param t table<K, V>
---@param predicate fun(k: K, v: V): boolean
---@return V?
function table.findfirst(t, predicate)
	for k, v in pairs(t) do
		if (predicate(k, v)) then
			return v
		end
	end
	return nil
end

-- Returns a new table with items that pass the filter criteria.
---@generic K, V
---@param t table<K, V>
---@param predicate fun(k: K, v: V): boolean
---@return table<K, V>
function table.filter(t, predicate)
	local out = {}
	for k, v in pairs(t) do
		if (predicate(k, v)) then
			out[k] = v
		end
	end
	return out
end

-- Serializes tables in pretty format and avoids circular reference.
---@param t table
---@param indent? number
---@param key_order? table
---@param seen? table
function table.serialize(t, indent, key_order, seen)
	indent = indent or 0
	seen   = seen or {}

	if (seen[t]) then
		return '"<circular reference>"'
	end

	seen[t] = true

	local function get_indent(level)
		return string.rep("\t", level)
	end

	local function serialize_value(v, depth)
		local __type = type(v)
		if (__type == "string") then
			return _F("%q", v)
		elseif (__type == "nil") then
			return __type
		elseif (__type == "number" or __type == "boolean" or __type == "function") then
			return tostring(v)
		elseif (__type == "table") then
			if (table.is_empty(v)) then
				return "{}"
			elseif (seen[v]) then
				return "<circular reference>"
			else
				return table.serialize(v, depth, key_order, seen)
			end
		elseif (__type == "userdata" or (getmetatable(v) and v.__type)) then
			if (v.rip and v.get_address) then
				return _F("<pointer@0x%X>", v:get_address())
			end
			return tostring(v)
		end
		return _F("[%s]:<unsupported>", __type)
	end

	local is_array, size = table.is_array(t)
	local keys           = {}
	local pieces         = {}
	table.insert(pieces, "{\n")

	if (is_array) then
		local array_start = t[0] ~= nil and 0 or 1
		for i = array_start, size do
			table.insert(keys, i)
		end
	else
		if (key_order) then
			for _, k in ipairs(key_order) do
				if t[k] ~= nil then
					table.insert(keys, k)
				end
			end

			for k in pairs(t) do
				if not table.find(keys, k) then
					table.insert(keys, k)
				end
			end
		else
			for k in pairs(t) do
				table.insert(keys, k)
			end

			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)
		end
	end

	for _, k in ipairs(keys) do
		local v   = t[k]
		local ind = get_indent(indent + 1)

		if (is_array) then
			table.insert(pieces, ind .. serialize_value(v, indent + 1) .. ",\n")
		else
			local key
			if (type(k) == "string" and k:match("^[%a_][%w_]*$")) then
				key = k
			else
				key = "[" .. serialize_value(k, indent + 1) .. "]"
			end

			table.insert(pieces, ind .. key .. " = " .. serialize_value(v, indent + 1) .. ",\n")
		end
	end

	table.insert(pieces, get_indent(indent) .. "}")
	return table.concat(pieces)
end

---@param t table
function table.print(t)
	print(table.serialize(t))
end

-- Returns the number of values in a table. Doesn't count nil fields.
---@param t table
---@return number
function table.getlen(t)
	if (next(t) == nil) then return 0 end

	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

---@param t table
---@return boolean, integer size
function table.is_array(t)
	local size = #t
	return size > 0, size
end

---@param t table
---@return boolean
function table.is_empty(t)
	return next(t) == nil
end

-- Calculates an estimate of a table's size in memory.
--
-- NOTE: This is **VERY** inaccurate and does not reflect real memory usage.
---@param t table
---@param seen? table
---@return number
function table.sizeof(t, seen)
	if (type(t) ~= "table") then
		return 0
	end

	seen = seen or {}
	if (seen[t]) then return 0 end
	seen[t] = true

	local size = LUA_TABLE_OVERHEAD
	for k, v in pairs(t) do
		size = size + SizeOf(k, seen) + SizeOf(v, seen)
	end

	return size
end

-- Returns the count of duplicate items in a table (shallow).
---@param t table
---@param value anyval
---@return integer
function table.get_duplicate_count(t, value)
	local count = 0
	for _, v in pairs(t) do
		if (value == v) then
			count = count + 1
		end
	end
	return count
end

-- Returns a table containing duplicate items *(shallow)*.
--
-- If `debug` is set to `true`, it returns a table with two tables for clean and duplicate items.
---@overload fun(t: table): table
---@overload fun(t: table, debug: nil): table
---@overload fun(t: table, debug: false): table
---@overload fun(t: table, debug: true): { dupes: table, clean: table }
---@param t table
---@param debug? boolean
---@return table
function table.get_duplicates(t, debug)
	local seen, t_dupes, t_result = {}, {}, { clean = {} }
	for k, v in pairs(t) do
		if (not seen[v]) then
			if (debug) then
				t_result.clean[k] = v
			end
			seen[v] = true
		else
			t_dupes[k] = v
		end
	end
	seen = nil

	if (debug) then
		t_result.dupes = t_dupes
		return t_result
	end

	return t_dupes
end

-- Removes duplicate items from a table. Mutates in place and returns the count of found items.
---@param t table
---@return integer removed_items_count
function table.remove_duplicates(t)
	local seen, count = {}, 0
	for k, v in pairs(t) do
		if (not seen[v]) then
			seen[v] = k
			count   = count + 1
		end
	end

	for _, key in pairs(seen) do
		t[key] = nil
	end

	seen = nil
	return count
end

---@generic T : table
---@param t T
---@param seen? table<table, table>
---@return T
function table.copy(t, seen)
	seen = seen or {}
	if (seen[t]) then return seen[t] end

	local out = {}
	seen[t]   = out
	for k, v in pairs(t) do
		if (type(v) == "table") then
			out[k] = table.copy(v, seen)
		else
			out[k] = v
		end
	end
	return out
end

-- Merges `src` table into `dest` table.
---@param src table
---@param dest table
---@param path? string
---@param seen? table
function table.merge(src, dest, path, seen)
	if (src == dest) then return end

	seen = seen or {}
	if (seen[src]) then return end
	seen[src] = true

	for k, v in pairs(src) do
		if (dest[k] == nil) then
			dest[k] = v
		elseif (type(v) == "table" and type(dest[k]) == "table") then
			local current_path = path and (path .. "." .. tostring(k)) or tostring(k)
			table.merge(v, dest[k], current_path, seen)
		end
	end
end

---@param t1 table
---@param t2 table
function table.swap(t1, t2)
	if (t1 == t2) then return end

	local temp = {}
	for k, v in pairs(t1) do
		temp[k] = v
		t1[k]   = nil
	end

	for k, v in pairs(t2) do
		t1[k] = v
		t2[k] = temp[k]
	end
	temp = nil
end

-- Overwrites `this` table with `src` table.
---@param this table
---@param src table
---@param seen? table
function table.overwrite(this, src, seen)
	if (this == src) then return end

	seen = seen or {}
	if (seen[src]) then return end
	seen[src] = true

	for k in pairs(this) do
		if (src[k] == nil) then
			this[k] = nil
		end
	end

	for k, v in pairs(src) do
		if (type(v) == "table") then
			if (type(this[k]) ~= "table") then
				this[k] = {}
			end
			table.overwrite(this[k], v, seen)
		else
			this[k] = v
		end
	end
end

---@param t1 table
---@param t2 table
---@param seen? table
---@return boolean
function table.is_equal(t1, t2, seen)
	if (t1 == t2) then
		return true
	end

	if (type(t1) ~= type(t2)) then
		return false
	end

	if (type(t1) ~= "table") then
		return false
	end

	seen = seen or {}
	if (seen[t1] and seen[t2]) then
		return true
	end
	seen[t1], seen[t2] = true, true

	for k, v in pairs(t1) do
		if (not table.is_equal(v, t2[k], seen)) then
			return false
		end
	end

	for k in pairs(t2) do
		if (t1[k] == nil) then
			return false
		end
	end

	return true
end

---@generic K, V
---@param t table<K, V>
---@param path string
---@return V?
function table.get_nested_value(t, path)
	local current = t
	for key in path:gmatch("[^%.]+") do
		current = current[key]
		if (current == nil) then
			return nil
		end
	end

	return current
end

---@param t table
---@param path string
---@param value any
function table.set_nested_value(t, path, value)
	local parts = {}
	for key in path:gmatch("[^%.]+") do
		parts[#parts + 1] = key
	end

	local current = t
	for i = 1, #parts - 1 do
		local key = parts[i]
		if (type(current[key]) ~= "table") then
			current[key] = {}
		end
		current = current[key]
	end

	current[parts[#parts]] = value
end

-- Snapshots a table into a string.
---@generic K, V, P
---@param t table<K, V>
---@param args? { out?: table, path?: string, ignored_keys: Set<string> | Predicate<K, V, P?>}
---@return string
function table.snapshot(t, args)
	args       = args or {}
	local out  = args.out or {}
	local path = args.path or ""

	for k, v in pairs(t) do
		if (args.ignored_keys) then
			if (IsInstance(args.ignored_keys, Set) and args.ignored_keys:Contains(k)) then
				goto continue
			elseif (type(args.ignored_keys) == "function" and args.ignored_keys(k, v, path)) then
				goto continue
			end
		end

		local p = path .. "." .. tostring(k)
		out[#out + 1] = p .. ":" .. type(v)
		if (type(v) == "table") then
			table.snapshot(v, { out = out, path = p, ignored_keys = args.ignored_keys })
		end

		::continue::
	end

	table.sort(out)
	return table.concat(out, "|")
end

---@generic K, V
---@param t table<K, V>
---@param predicate fun(k: K, v: V): boolean
---@return boolean success
function table.erase_first_if(t, predicate)
	for k, v in pairs(t) do
		if (predicate(k, v)) then
			t[k] = nil
			return true
		end
	end
	return false
end

---@generic K, V
---@param t table<K, V>
---@param predicate fun(k: K, v: V): boolean
---@return boolean success, integer count
function table.erase_if(t, predicate)
	local count = 0
	local is_array, size = table.is_array(t)
	if (is_array) then
		for i = size, 1, -1 do
			if (predicate(i, t[i])) then
				table.remove(t, i)
				count = count + 1
			end
		end
	else
		local temp = {}
		for k, v in pairs(t) do
			if (predicate(k, v)) then
				temp[#temp + 1] = k
				count = count + 1
			end
		end

		for _, k in ipairs(temp) do
			t[k] = nil
		end

		temp = nil
	end

	return count > 0, count
end

---@param t table
function table.clear(t)
	for k in pairs(t) do
		t[k] = nil
	end
end
