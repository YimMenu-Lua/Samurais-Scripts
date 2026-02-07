-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: lowercase-global

math.randomseed(os.time())

local LUA_TABLE_OVERHEAD <const> = 3 * 0x8 -- 0x18
local Clock <const> = require("includes.modules.Time")

INT_SIZES = {
	int8_t   = 0x1,
	int16_t  = 0x2,
	int32_t  = 0x4,
	int64_t  = 0x8,
	uint8_t  = 0x1,
	uint16_t = 0x2,
	uint32_t = 0x4,
	uint64_t = 0x8,
}


Bit       = require("includes.modules.Bit")
Cast      = require("includes.modules.Cast")

Time      = Clock.Time
Timer     = Clock.Timer
TimePoint = Clock.TimePoint
DateTime  = Clock.DateTime
yield     = coroutine.yield
sleep     = Time.sleep
_F        = string.format


--#region Global functions

-- A dummy function that returns its parameter or nil.
---@generic T
---@param arg? T
---@return T
function DummyFunc(arg)
	return arg
end

-- Returns whether `obj` is an instance of `T`. Can be used instead of Lua's default `type` function.
--
-- **Usage Example**:
-- - String types, similar to the default `type` function:
--```Lua
-- print(IsInstance(123, "number")) -> true
--```
-- - Math types, similar to the default `math.type` function:
--```Lua
-- print(IsInstance(123, "float")) -- -> false
-- print(IsInstance(1.23, "float")) -- -> true
--```
-- - Classes:
--```Lua
-- local myveh = Self:GetVehicle()
-- print(IsInstance(myveh, Vehicle)) -- -> true
-- print(IsInstance(myveh, Object)) -- -> false
-- print(IsInstance(myveh, Entity)) -- -> true
-- print(IsInstance(myveh, "table")) -- -> false
-- print(IsInstance(myveh, {})) -- -> false
--```
---@param obj any
---@param T anyval
---@return boolean
function IsInstance(obj, T)
	if (obj == nil) then
		return T == "nil"
	end

	local std_types <const>  = {
		["table"]    = true,
		["string"]   = true,
		["number"]   = true,
		["boolean"]  = true,
		["function"] = true,
		["userdata"] = true
	}

	local math_types <const> = {
		["integer"] = true,
		["float"]   = true
	}

	local obj_type <const>   = type(obj)
	local T_type <const>     = type(T)
	if (T_type == "string" and T == "pointer" and obj_type == "userdata") then
		return (type(obj.rip) == "function")
	end
	local obj_mt = getmetatable(obj)
	local T_mt = getmetatable(T)

	if (T_type == "table") then
		-- special case for vec3 since it's defined as a usertype in C++ but we extended it
		-- so it became a hybrid: An instance of vec3 (from vec3:new, vec3:zero, or a return from a native function)
		-- is of type "userdata" but vec3 itself is of type "table". Since we guard against returning true on classes vs regular tables,
		-- IsInstance(vec3:new(1, 2, 3), vec3) returns false. This check fixes the issue and correctly returns true.
		if (obj_type == "userdata" and T.__type == "vec3") then
			return obj_mt and obj_mt.__type == T.__type
		end

		local is_obj = rawget(T, "__index") ~= nil
			or rawget(T, "__type") ~= nil
			or rawget(T, "__base") ~= nil
			or T_mt ~= nil
			or (type(T_mt) == "table" and rawget(T_mt, "__call") ~= nil)

		if (is_obj) then
			while obj_mt do
				if (obj_mt == T) then
					return true
				end
				obj_mt = rawget(obj_mt, "__base")
			end
			return false
		else
			if (obj_mt or T_mt) then
				return obj_mt == T_mt
			end
		end
	end

	if (T_type == "string") then
		if ((obj_type) == "number" and math_types[T]) then
			return math.type(obj) == T
		end

		if (std_types[T]) then
			if (obj_type == "table") then
				return (obj_type == T and obj_mt == nil)
			else
				return obj_type == T
			end
		end
	end

	return false
end

-- A poor man's `sizeof` 🥲
---@param T any
---@param seen? table Circular reference
---@return number
function SizeOf(T, seen)
	local types <const> = {
		["boolean"]   = 0x1,
		["vec2"]      = 0x8,
		["vec3"]      = 0xC,
		["vec4"]      = 0x10,
		["fMatrix44"] = 0x40,
		["function"]  = 0x8,
		["pointer"]   = 0x8,
		["nil"]       = 0x0,
	}

	local T_type <const> = type(T)
	local resolved_type -- fwd decl

	if (T_type == "table" or T_type == "userdata") then
		if (IsInstance(T, "pointer")) then
			resolved_type = "pointer"
		elseif (IsInstance(T.__type, "string")) then
			resolved_type = T.__type
		end
	else
		resolved_type = T_type
	end

	local known = types[resolved_type]
	if (known) then
		return known
	end

	if (T_type == "string") then
		return #T + 1
	end

	if (T_type == "number") then
		return math.sizeof(T)
	end

	if (T_type == "table") then
		seen = seen or {}
		if seen[T] then
			return 0
		end
		seen[T] = true

		if (IsInstance(T.m_size, "number")) then
			return T.m_size
		end

		if (T.__enum or IsInstance(T.__sizeof, "function")) then
			return T:__sizeof()
		end

		if (IsInstance(T.__len, "function")) then
			return T:__len()
		end

		if (IsInstance(T.__type, "string")) then
			return GenericClass.m_size -- 0x40
		end

		return table.sizeof(T, seen)
	end

	return 0
end

-- A switch-case construct. This is only beneficial if you have **A LOT** of `if` statements;
--
-- otherwise regular `if-elseif-else` chains or cached lookup tables are faster and create less overhead.
--
-- **[Note]**: Avoid calling this per-frame. This function creates a closure every time it's called and the reason
--
-- for this is that it allows for more flexible and dynamic case handling. Also looks fancier lol
--
-- Example:
--
--```Lua
-- local result = Switch(value) {
--     [1] = function() return "one" end,
--     [2] = function() return "two" end,
--     default = "default"
-- }
--```
--
-- If you want a version with less overhead, use `Match` instead:
--
--```Lua
-- local cases = {
--     [1] = function() return "one" end,
--     [2] = function() return "two" end,
--     default = "default"
-- }
-- local result = Match(value, cases)
--```
---@param case number|string
function Switch(case)
	return function(cases)
		local result = cases[case] or cases["default"]
		assert(result ~= nil, "No case matched and no default provided!")
		return (type(result) == "function") and result() or result
	end
end

-- A switch-case construct without the closure overhead of `Switch`.
--
-- **Usage Example**:
--
--```Lua
-- local cases = {
--     [1] = function() return "one" end,
--     [2] = function() return "two" end,
--     default = "other"
-- }
-- local result = Match(value, cases)
--```
---@generic K: number|string
---@generic V
---@param case K
---@param cases table<K, ValueOrFunction<V>>
---@return V
function Match(case, cases)
	local result = cases[case] or cases["default"]
	assert(result ~= nil, "No case matched and no default provided!")
	return (type(result) == "function") and result() or result
end

---@param e Enum
---@param index integer
function EnumToString(e, index)
	if (type(e) ~= "table") then
		return ""
	end

	for k, v in pairs(e) do
		if (v == index) then
			return tostring(k)
		end
	end

	return "Unknown"
end

-- Lua version of Bob Jenskins' "Jenkins One At A Time" hash function
--
-- https://en.wikipedia.org/wiki/Jenkins_hash_function
---@param key string
---@return joaat_t
function Joaat(key)
	local hash = 0
	key = key:lower()

	for i = 1, #key do
		hash = hash + string.byte(key, i)
		hash = hash + (hash << 10)
		hash = hash & 0xFFFFFFFF
		hash = hash ~ (hash >> 6)
	end

	hash = hash + (hash << 3)
	hash = hash & 0xFFFFFFFF
	hash = hash ~ (hash >> 11)
	hash = hash + (hash << 15)
	hash = hash & 0xFFFFFFFF
	return hash
end

-- Pauses execution until a condition is met.
--
-- All logic after this call will only execute once the provided function returns a truthy value.
--
-- If the condition isn't met before the optional timeout is reached, `TaskWait` throws an error to prevent further execution.
---@param func fun(args: any): boolean
---@param args any
---@param timeout? milliseconds  -- Optional timeout in milliseconds. Defaults to 1200ms.
function TaskWait(func, args, timeout)
	local ftype = type(func)
	if (ftype ~= "function") then
		error(_F("Invalid argument #1! Function expected, got %s instead", ftype), 2)
	end

	args    = args or {}
	timeout = timeout or 1200

	if (timeout <= 0) then
		error("Optional timeout must be greater than zero.", 2)
	end

	-- It is essential to use IsInstance here instead of type(args) == "table"
	-- otherwise passing objects and userdata will fail.
	if not IsInstance(args, "table") then
		args = { args }
	end

	local start_time = Time.millis()
	while (not func(table.unpack(args))) do
		if ((Time.millis() - start_time) > timeout) then
			error("Timeout reached!")
		end
		yield()
	end

	return true
end

---@param t table
---@param mt table|metatable
function RecursiveSetmetatable(t, mt)
	for _, v in pairs(t) do
		if (type(v) == "table" and getmetatable(v) == nil) then
			RecursiveSetmetatable(v, mt)
		end
	end
	return setmetatable(t, mt)
end

-- Simply adds a number suffix if a file with the same name and extension already exists.
---@param base_name string
---@param extension string
---@return string
function GenerateUniqueFilename(base_name, extension)
	local filename = string.format("%s%s", base_name, extension)
	local suffix = 0

	while (io.exists(filename)) do
		suffix = suffix + 1
		filename = string.format("%s_%d%s", base_name, suffix, extension)
	end

	return filename
end

--#endregion

--#region extensions

--#region YimMenu

-- Equality comparator for pointer objects.
---@type Comparator<pointer, pointer>
function memory.pointer:__eq(right)
	if not IsInstance(right, "pointer") then
		return false
	end

	return self:get_address() == right:get_address()
end

---Casts the pointer to an object.
---
---**IMPORTANT:** You must only cast to objects that take a pointer parameter in their constructors.
---
---**Example Usage:**
---```lua
---local cvehicle = memory.handle_to_ptr(self.get_veh()):as(CVehicle)
---```
---@generic T
---@param obj T
---@return T
function memory.pointer:as(obj)
	local obj_type = type(obj)
	if (obj_type ~= "table") then
		error(_F("Invalid parameter #1: Table expected, got %s instead.", obj_type))
	end

	if (type(obj.__from_ptr) == "boolean" and not obj.__from_ptr) then
		error(_F("Class '%s' does not take a pointer.", obj.__type or tostring(obj)))
	end

	local mt = getmetatable(obj)
	if (mt and type(mt.__call) == "function") then
		return obj(self)
	end

	if (type(obj.new) == "function") then
		return obj.new(self)
	end

	if (type(obj.init) == "function") then
		local instance = setmetatable({}, obj)
		instance.init(obj, self)
		return obj
	end

	error(_F("Class '%s' has no valid pointer constructor", obj.__type or tostring(obj)))
end

-- Retrieves a 32-bit displacement value from the memory address, optionally adding an offset and adjustment.
--
-- **Example Usage:**
-- ```lua
-- displacement = pointer:get_disp32(offset, adjust)
-- ```
---@param offset? integer
---@param adjust? integer
---@return number -- imm32 displacement
function memory.pointer:get_disp32(offset, adjust)
	if self:is_null() then
		log.warning("Failed to get imm32 displacement!")
		return 0
	end

	offset = offset or 0
	adjust = adjust or 0
	local val = self:add(offset):get_int()
	return val + adjust
end

---@return vec3
function memory.pointer:get_vec3()
	local x = self:add(0x4):get_float()
	local y = self:add(0x8):get_float()
	local z = self:add(0xC):get_float()
	return vec3:new(x, y, z)
end

---@param vector3 vec3
function memory.pointer:set_vec3(vector3)
	self:add(0x4):set_float(vector3.x)
	self:add(0x8):set_float(vector3.y)
	self:add(0xC):set_float(vector3.z)
end

---@return vec4
function memory.pointer:get_vec4()
	local x = self:add(0x4):get_float()
	local y = self:add(0x8):get_float()
	local z = self:add(0xC):get_float()
	local w = self:add(0x10):get_float()

	return vec4:new(x, y, z, w)
end

---@param vector4 vec4
function memory.pointer:set_vec4(vector4)
	self:add(0x4):set_float(vector4.x)
	self:add(0x8):set_float(vector4.y)
	self:add(0xC):set_float(vector4.z)
	self:add(0x10):set_float(vector4.w)
end

---@return fMatrix44
function memory.pointer:get_matrix44()
	return fMatrix44:new(
		self:add(0x00):get_float(), self:add(0x04):get_float(), self:add(0x08):get_float(), self:add(0x0C):get_float(),
		self:add(0x10):get_float(), self:add(0x14):get_float(), self:add(0x18):get_float(), self:add(0x1C):get_float(),
		self:add(0x20):get_float(), self:add(0x24):get_float(), self:add(0x28):get_float(), self:add(0x2C):get_float(),
		self:add(0x30):get_float(), self:add(0x34):get_float(), self:add(0x38):get_float(), self:add(0x3C):get_float()
	)
end

---@param matrix fMatrix44
function memory.pointer:set_matrix44(matrix)
	local m1 = matrix:R1()
	local m2 = matrix:R2()
	local m3 = matrix:R3()
	local m4 = matrix:R4()

	self:add(0x00):set_float(m1.x); self:add(0x04):set_float(m1.y); self:add(0x08):set_float(m1.z); self:add(0x0C)
		:set_float(m1.w)

	self:add(0x10):set_float(m2.x); self:add(0x14):set_float(m2.y); self:add(0x18):set_float(m2.z); self:add(0x1C)
		:set_float(m2.w)

	self:add(0x20):set_float(m3.x); self:add(0x24):set_float(m3.y); self:add(0x28):set_float(m3.z); self:add(0x2C)
		:set_float(m3.w)

	self:add(0x30):set_float(m4.x); self:add(0x34):set_float(m4.y); self:add(0x38):set_float(m4.z); self:add(0x3C)
		:set_float(m4.w)
end

---@param size? number bytes
function memory.pointer:dump(size)
	size = size or 0x10
	if self:is_null() then
		log.debug("Memory Dump<nullptr>")
		return
	end

	local result = {}

	for i = 0, size - 1 do
		local byte = self:add(i):get_byte()
		table.insert(result, string.format("%02X", byte))
	end

	log.fdebug(
		"Memory Dump<0x%X + 0x%X>: %s",
		self:get_address(),
		size,
		table.concat(result, " ")
	)
end

---@param size? number bytes
function memory.pointer:create_pattern(size)
	if (self:is_null()) then
		return ""
	end

	size = size or 0x10
	local out = {}
	local REG_DIRECT_RANGE <const> = Range(0xC0, 0x100)

	for i = 0, size - 1 do
		local byte = self:add(i):get_byte()
		out[#out + 1] = REG_DIRECT_RANGE:Contains(byte)
			and "??"
			or string.format("%02X", byte)
	end

	return table.concat(out, " ")
end

--#endregion

-- stdlib --

--#region tablib

---@param t table
---@param key string|number
---@param value any
table.matchbykey = function(t, key, value)
	if not t or (table.getlen(t) == 0) then
		return
	end

	for k, v in pairs(t) do
		if k == key then
			return v
		end
	end
end

---@param t table
---@param value any
---@return string|number|nil -- the table key where the value was found or nil
table.matchbyvalue = function(t, value)
	if not t or (table.getlen(t) == 0) then
		return nil
	end

	for k, v in pairs(t) do
		if v == value then
			return k
		end
	end

	return nil
end

---@param t table
---@param value any
table.find = function(t, value)
	if (#t == 0) then
		return false
	end

	for i = 1, table.getlen(t) do
		if type(t[i]) == "table" then
			return table.find(t[i], value)
		else
			if type(t[i]) == type(value) then
				if t[i] == value then
					return true
				end
			end
		end
	end

	return false
end

---@generic T
---@param t table<any, T>
---@param pred Predicate<T>
---@return T|nil
function table.findfirst(t, pred)
	for _, v in pairs(t) do
		if pred(v) then
			return v
		end
	end

	return nil
end

---@generic T
---@param arr array<T>
---@param pred Predicate<T>
---@return array<T>
function table.filter(arr, pred)
	local out = {}

	for _, v in ipairs(arr) do
		if pred(v) then
			out[#out + 1] = v
		end
	end

	return out
end

-- Serializes tables in pretty format and avoids circular reference.
---@param tbl table
---@param indent? number
---@param key_order? table
---@param seen? table
table.serialize = function(tbl, indent, key_order, seen)
	indent = indent or 2
	seen = seen or {}

	if seen[tbl] then
		return '"<circular reference>"'
	end

	seen[tbl] = true

	local function get_indent(level)
		return string.rep(" ", level)
	end

	local is_array = #tbl > 0
	local pieces = {}

	local function is_empty_table(t)
		return type(t) == "table" and next(t) == nil
	end

	local function serialize_value(v, depth)
		if (type(v) == "string") then
			return string.format("%q", v)
		elseif (type(v) == "number" or type(v) == "boolean" or type(v) == "function") then
			return tostring(v)
		elseif (type(v) == "table") then
			if is_empty_table(v) then
				return "{}"
			elseif seen[v] then
				return "<circular reference>"
			else
				return table.serialize(v, depth, key_order, seen)
			end
		elseif (getmetatable(v) and v.__type) then
			return tostring(v.__type)
		elseif (type(v) == "userdata") then
			if (v.rip and v.get_address) then
				return string.format("<pointer@0x%X>", v:get_address())
			end
			return "<userdata>"
		end
		return "<unsupported>"
	end

	table.insert(pieces, "{\n")

	local keys = {}

	if is_array then
		for i = 1, #tbl do
			table.insert(keys, i)
		end
	else
		if key_order then
			for _, k in ipairs(key_order) do
				if tbl[k] ~= nil then
					table.insert(keys, k)
				end
			end

			for k in pairs(tbl) do
				if not table.find(keys, k) then
					table.insert(keys, k)
				end
			end
		else
			for k in pairs(tbl) do
				table.insert(keys, k)
			end

			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)
		end
	end

	for _, k in ipairs(keys) do
		local v = tbl[k]
		local ind = get_indent(indent + 1)

		if is_array then
			table.insert(pieces, ind .. serialize_value(v, indent + 1) .. ",\n")
		else
			local key
			if type(k) == "string" and k:match("^[%a_][%w_]*$") then
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

table.print = function(t)
	print(table.serialize(t))
end

-- Returns the number of values in a table. Doesn't count nil fields.
---@param t table
---@return number
table.getlen = function(t)
	if not t then
		return 0
	end

	local count = 0

	for _ in pairs(t) do
		count = count + 1
	end

	return count
end

---@return boolean
table.is_array = function(t)
	return #t > 0
end

-- Calculates an estimate of a table's size in memory.
--
-- NOTE: This is **VERY** inaccurate.
---@param t table
---@param seen? table
---@return number
table.sizeof = function(t, seen)
	if (type(t) ~= "table") then
		return 0
	end

	seen = seen or {}
	if seen[t] then
		return 0
	end
	seen[t] = true

	local size = LUA_TABLE_OVERHEAD
	for k, v in pairs(t) do
		size = size + SizeOf(k, seen) + SizeOf(v, seen)
	end

	return size
end

-- Returns the number of duplicate items in a table.
---@param t table
---@param value string | number | integer | table
table.getduplicates = function(t, value)
	local count = 0

	for _, v in ipairs(t) do
		if (value == v) then
			count = count + 1
		end
	end

	return count
end

-- Removes duplicate items from a table and returns a new one with the results.
--
-- If `debug` is set to `true`, it adds a table with duplicate items to the return as well.
---@param t table
---@param debug? boolean
table.removeduplicates = function(t, debug)
	local t_exists, t_clean, t_dupes, t_result = {}, {}, {}, {}

	for _, v in ipairs(t) do
		if not t_exists[v] then
			t_clean[#t_clean + 1] = v
			t_exists[v] = true
		else
			if debug then
				t_dupes[#t_dupes + 1] = v
			end
		end
	end

	if debug then
		t_result.clean = t_clean
		t_result.dupes = t_dupes
	end

	return debug and t_result or t_clean
end

---@param t table
---@param seen? table
table.copy = function(t, seen)
	seen = seen or {}
	if seen[t] then
		return seen[t]
	end

	local out = {}
	seen[t] = out

	for k, v in pairs(t) do
		if (type(v) == "table") then
			out[k] = table.copy(v, seen)
		else
			out[k] = v
		end
	end

	return out
end

---@param a table
---@param b table
---@param seen? table
---@return boolean
function table.is_equal(a, b, seen)
	if (a == b) then
		return true
	end

	if (type(a) ~= type(b)) then
		return false
	end

	if (type(a) ~= "table") then
		return false
	end

	seen = seen or {}
	if (seen[a] and seen[b]) then
		return true
	end
	seen[a], seen[b] = true, true

	for k, v in pairs(a) do
		if (not table.is_equal(v, b[k], seen)) then
			return false
		end
	end

	for k in pairs(b) do
		if (a[k] == nil) then
			return false
		end
	end

	return true
end

---@param t table
---@param path string
---@return any
function table.get_nested_key(t, path)
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
function table.set_nested_key(t, path, value)
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
---@param t table
---@param opts? { out?: table, path?: string, ignored_keys: Set<string> | Predicate<K, V, P?>}
---@return string
function table.snapshot(t, opts)
	opts = opts or {}
	out  = opts.out or {}
	path = opts.path or ""

	for k, v in pairs(t) do
		if (opts.ignored_keys) then
			if (IsInstance(opts.ignored_keys, Set) and opts.ignored_keys:Contains(k)) then
				goto continue
			elseif (type(opts.ignored_keys) == "function" and opts.ignored_keys(k, v, path)) then
				goto continue
			end
		end

		local p = path .. "." .. tostring(k)
		out[#out + 1] = p .. ":" .. type(v)
		if type(v) == "table" then
			table.snapshot(v, { out = out, path = p, ignored_keys = opts.ignored_keys })
		end

		::continue::
	end

	table.sort(out)
	return table.concat(out, "|")
end

---@generic K, V
---@param t table
---@param pred Predicate<K, V>
---@return boolean -- success/failure
function table.erase_first_if(t, pred)
	for k, v in pairs(t) do
		if (pred(k, v)) then
			t[k] = nil
			return true
		end
	end

	return false
end

---@generic K, V
---@param t table
---@param pred Predicate<K, V>
---@return boolean, integer -- success/failure and count of removed items
function table.erase_if(t, pred)
	local count = 0

	if (table.is_array(t)) then
		for i = #t, 1, -1 do
			if pred(i, t[i]) then
				table.remove(t, i)
				count = count + 1
			end
		end
	else
		local temp = {}
		for k, v in pairs(t) do
			if pred(k, v) then
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

--#endregion

--#region stringlib

-- Generates a random string.
---@param length? number
---@param isalnum? boolean Alphanumeric
---@return string
string.random = function(length, isalnum)
	local str_table = {}
	local charset   = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	length          = length or math.random(1, 10)
	length          = math.min(length or math.random(1, 10), 128)

	if (isalnum) then
		charset = charset .. "0123456789"
	end

	for _ = 1, length do
		local index = math.random(1, #charset)
		table.insert(str_table, charset:sub(index, index))
	end

	return table.concat(str_table)
end

-- Returns whether a string is alphabetic.
---@param str string
---@return boolean
string.isalpha = function(str)
	return str:match("^%a+$") ~= nil
end

-- Returns whether a string is numeric.
---@param str string
---@return boolean
string.isdigit = function(str)
	return str:match("^%d+$") ~= nil
end

-- Returns whether a string is alpha-numeric.
---@param str string
---@return boolean
string.isalnum = function(str)
	return str:match("^%w+$") ~= nil
end

---@param str string
---@return boolean
string.iswhitespace = function(str)
	return str:match("^%s*$") ~= nil
end

---@param str? string
---@return boolean
string.isnull = function(str)
	return str == nil
end

string.isempty = function(str)
	return #str == 0
end

---@param str string?
---@return boolean
string.isnullorempty = function(str)
	if str == nil then
		return true
	end

	return str:isempty()
end

---@param str string?
---@return boolean
string.isnullorwhitespace = function(str)
	if str == nil then
		return true
	end

	return str:iswhitespace()
end

-- A string is considered invalid if any of these conditions are true:
-- - `nil`
-- - `empty`
-- - `white space`
---@param str? string
---@return boolean
string.isvalid = function(str)
	return type(str) == "string"
		and not str:isempty()
		and not str:iswhitespace()
end

-- Returns whether a string starts with the provided prefix.
---@param str string
---@param prefix string
---@return boolean
string.startswith = function(str, prefix)
	return str:sub(1, #prefix) == prefix
end

-- Returns whether a string contains the provided substring.
---@param str string
---@param sub string
---@return boolean
string.contains = function(str, sub)
	return str:find(sub, 1, true) ~= nil
end

-- Returns whether a string ends with the provided suffix.
---@param str string
---@param suffix string
---@return boolean
string.endswith = function(str, suffix)
	return str:sub(- #suffix) == suffix
end

-- Inserts a string into another string at the given position.
---@param str string
---@param pos integer
---@param text string
string.insert = function(str, pos, text)
	pos = math.max(1, math.min(pos, #str + 1))
	return str:sub(1, pos) .. text .. str:sub(pos)
end

-- Replaces all occurrances of `old` string with `new` string.
--
-- Returns the new string and the count of all occurrances.
---@param str string
---@param old string
---@param new string
---@return string, number
string.replace = function(str, old, new)
	if old == "" then
		return str, 0
	end

	return str:gsub(old:gsub("([^%w])", "%%%1"), new)
end

-- Joins a table of strings using a separator.
---@param sep string
---@param tbl string[]
---@return string
string.join = function(sep, tbl)
	return table.concat(tbl, sep)
end

-- Removes leading and trailing white space from a string.
---@param str string
---@return string
string.trim = function(str)
	return str:match("^%s*(.-)%s*$")
end

-- Splits a string by a separator and returns a table of strings.
---@param str string
---@param sep string
---@param maxsplit? integer Optional: limit the number of splits.
---@return string[]
string.split = function(str, sep, maxsplit)
	local result, count = {}, 0
	local pattern = "([^" .. sep .. "]+)"

	for part in str:gmatch(pattern) do
		table.insert(result, part)
		count = count + 1

		if maxsplit and count >= maxsplit then
			local rest = str:match("^" .. (("([^" .. sep .. "]+)" .. sep):rep(count)) .. "(.+)$")
			if rest then
				table.insert(result, rest)
			end
			break
		end
	end

	return result
end

-- Same as `string.split` but starts from the right.
---@param str string
---@param sep string
---@param maxsplit? integer Optional: limit the number of splits.
---@return string[]
string.rsplit = function(str, sep, maxsplit)
	local splits = {}

	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(splits, part)
	end

	local total = #splits
	if not maxsplit or maxsplit <= 0 or maxsplit >= total - 1 then
		return splits
	end

	local head = {}
	for i = 1, total - maxsplit - 1 do
		table.insert(head, splits[i])
	end

	local tail = table.concat(splits, sep, total - maxsplit, total)
	table.insert(head, tail)
	return head
end

-- Python-like `partition` implementation: Splits a string into 3 parts: before, separator, after
---@param str string
---@param sep string
---@return string, string, string
string.partition = function(str, sep)
	local start_pos, end_pos = str:find(sep, 1, true)

	if not start_pos then
		return str, "", ""
	end

	return str:sub(1, start_pos - 1), sep, str:sub(end_pos + 1)
end

-- Same as `string.partition` but starts from the right.
---@param str string
---@param sep string
---@return string, string, string
string.rpartition = function(str, sep)
	local start_pos, end_pos = str:reverse():find(sep:reverse(), 1, true)

	if not start_pos then
		return "", "", str
	end

	local rev_index = #str - end_pos + 1
	return str:sub(1, rev_index - 1), sep, str:sub(rev_index + #sep)
end

---@param str string
---@param len number
---@param char string
---@return string
string.padleft = function(str, len, char)
	return _F("%s%s", string.rep(char or " ", math.max(0, len - #str)), str)
end

---@param str string
---@param len number
---@param char string
---@return string
string.padright = function(str, len, char)
	return _F("%s%s", str, string.rep(char or " ", math.max(0, len - #str)))
end

-- Capitalizes the first letter in a string.
---@param str string
---@return string
string.capitalize = function(str)
	return (str:lower():gsub("^%l", string.upper))
end

-- Capitalizes the first letter of each word in a string.
---@param str string
---@return string
string.titlecase = function(str)
	return (str:gsub("(%a)([%w_']*)", function(a, b)
		return a:upper() .. b:lower()
	end))
end

---@param value number|string
---@return string
string.formatint = function(value)
	local s, _ = tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
	return s
end

---@param value number|string
---@param currency? string
---@return string
string.formatmoney = function(value, currency)
	return _F("%s%s", currency or "$", string.formatint(value))
end

---@param str string
string.hex2string = function(str)
	return (str:gsub("%x%x", function(digits)
		return string.char(tonumber(digits, 16))
	end))
end

---@param v string|number
---@return string
string.hex = function(v)
	local _type = type(v)
	if (_type == "string") then
		return (string.gsub(v, ".", function(char)
			return _F("%02x", string.byte(char))
		end))
	elseif (_type == "number") then
		return _F("0x%X", v)
	end

	return ""
end

--#endregion

--#region mathlib

---@param n number
---@param x number
---@return number
math.round = function(n, x)
	return tonumber(string.format("%." .. (x or 0) .. "f", n)) or 0
end

---@param ... any
---@return number
math.sum = function(...)
	local result = 0
	local args = type(...) == "table" and ... or { ... }

	for i = 1, table.getlen(args) do
		if type(args[i]) == "number" then
			result = result + args[i]
		end
	end

	return result
end

---@param n number
---@param min number
---@param max number
---@return boolean
math.is_inrange = function(n, min, max)
	return n >= min and n <= max
end

-- This ignores floating point precision.
--
-- For normal numbers, use regular equality comparison.
--
-- https://www.lua.org/pil/2.3.html
---@param a float
---@param b float
---@param e? float Optional epsilon (threshold)
---@return boolean
function math.is_equal(a, b, e)
	e = e or 1e-6
	return a == b or math.abs(a - b) < 1e-6
end

---@param n integer
math.sizeof = function(n)
	local t_n = type(n)
	assert(t_n == "number",
		_F("Attempt to call math.sizeof on a non-integer value. Number expected, got %s instead!", t_n)
	)

	if (n == 0 or IsInstance(n, "float")) then
		return 0x4
	end

	local int_infer <const> = {
		["unsigned"] = {
			{ Cast.AsUint8_t,  "uint8_t" },
			{ Cast.AsUint16_t, "uint16_t" },
			{ Cast.AsUint32_t, "uint32_t" },
			{ Cast.AsUint64_t, "uint64_t" },
		},
		["signed"] = {
			{ Cast.AsInt8_t,  "int8_t" },
			{ Cast.AsInt16_t, "int16_t" },
			{ Cast.AsInt32_t, "int32_t" },
			{ Cast.AsInt64_t, "int64_t" },
		}
	}

	local c = Cast(n)
	local key = n < 0 and "signed" or "unsigned"
	local _t = int_infer[key]

	for i = 1, #_t do
		local method, size_key = _t[i][1], _t[i][2]
		local value = method(c)

		if math.is_equal(n, value, 1e-9) then
			return INT_SIZES[size_key]
		end
	end

	return 0x4
end

---@param v number
---@param min number
---@param max number
---@return number
function math.clamp(v, min, max)
	return math.max(min, math.min(max, v))
end

---@param a number
---@param b number
---@param t number delta
function math.lerp(a, b, t)
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- Generates a trianguar wave oscillating between 1 and -1
---@param t number
---@return number
function math.tent(t)
	return 2 * math.abs(2 * (t - math.floor(t + 0.5))) - 1
end

-- 3x²-2x²
---@param x number
---@return number
function math.smooth_step(x)
	return x * x * (3 - 2 * x)
end

---@return int32_t
function math.int32_min()
	return -2 ^ 31
end

---@return int32_t
function math.int32_max()
	return 2 ^ 31
end

---@return uint32_t
function math.uint32_min()
	return 0
end

---@return uint32_t
function math.uint32_max()
	return 2 ^ 32
end

--#endregion

--#endregion
