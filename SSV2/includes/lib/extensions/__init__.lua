-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


math.randomseed(os.time())

---@type table<table, table<integer, string>>
local EnumNamesCache <const> = {}
local Chrono <const>         = require("includes.modules.Chrono")
Bit                          = require("includes.modules.Bit") -- exposed globally sicne it's used all over the project.

for _, path in ipairs({
	"includes.lib.extensions.std_string",
	"includes.lib.extensions.std_math",
	"includes.lib.extensions.std_table",
	"includes.lib.extensions.std_io",

	"includes.lib.extensions.api_stats",
	"includes.lib.extensions.api_pointer",

	-- api_imgui must be required in the GUI class.
}) do require(path) end


Time               = Chrono.Time
Timer              = Chrono.Timer
TimePoint          = Chrono.TimePoint
DateTime           = Chrono.DateTime
_F                 = string.format

---@diagnostic disable: lowercase-global
yield              = coroutine.yield
sleep              = Time.Sleep
---@diagnostic enable: lowercase-global

local type         = type
local rawget       = rawget
local getmetatable = getmetatable
local math_type    = math.type
local tostring     = tostring

-- Macro for the `Translator:Translate` method.
---@param label string
---@param ... any optional string formatting
---@return string
function _T(label, ...)
	if (not Translator) then return label end
	return Translator:Translate(label, ...)
end

-- Lua version of Bob Jenskins' [Jenkins One At A Time](https://en.wikipedia.org/wiki/Jenkins_hash_function) hash function.
---@param key string
---@return joaat_t
local function Joaat(key)
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
end; _J = _G.joaat or Joaat

--#region Global functions

-- A dummy function (no-operation).
function NOP() end

-- Checks if the provided runtime argument matches its expected type. Only single types are supported at the moment.
---@param arg any The argument to check.
---@param argName string The name of the argument.
---@param expected string|Obj|unknown The expected type. Can be a string type as used with the `type` function or a reference to an object/class.
---@param onErrorCallback? fun(msg: string) Optional function to handle the error message in case of mismatch. Defaults to `error`.
---@return boolean success, string message
function AssertArg(arg, argName, expected, onErrorCallback)
	if (not IsInstance(arg, expected)) then
		local expectedType = type(expected)
		local argType      = type(arg)
		if ((expected == "float" or expected == "integer") and argType == "number") then
			---@diagnostic disable-next-line
			argType = math_type(arg) -- 'got integer' or 'got float' instead makes more sense than 'got number'
		end

		local expectedName = expectedType == "string" and expected or expected.__type or expectedType
		if (argType == "table") then
			argType = arg.__type or "table"
		end

		local err      = _F("Invalid argument '%s'! Expected '%s', got '%s' instead.", argName, expectedName, argType)
		local callback = onErrorCallback or error
		callback(err)
		return false, err
	end

	return true, ""
end

-- We do have an `ArgDescriptor` struct and an `ArgParser` module that are not included in the project because
--
-- it's getting unnecessarily bloated for no significant benefit. This simple annotation does the job fine.
---@class BasicArgDescriptor
---@field [1] any argument
---@field [2] string|Obj|unknown expected type
---@field [3] string? argument name

-- Checks if the provided runtime arguments match their expected types. Exits on first mismatch.
--
-- Both Lua's default type names as well as references to our own custom classes/objects are supported as expected types.
--
-- Example Usage:
--```Lua
-- local success = AssertArgs({
-- 	{ iParam0,      "number",  "iParam0" },
-- 	{ bParam1,      "boolean" }, -- here the param's position will be used as the arg's name; ie: "2".
-- 	{ targetPlayer, Player,    "targetPlayer" },
-- 	{ pData,        "pointer", "pData" },
-- }, { msg_handler = log.warning }) -- On failure, a warning log will be used instead of throwing an error.
--```
---@param descriptors array<BasicArgDescriptor> An array of tables where each table has the arg as the first key, the expected type as the second, and optionally the arg's name as the third.
---@param opts? { msg_handler: fun(msg: string), test_run: boolean}
---@return boolean success
function AssertArgs(descriptors, opts)
	opts           = opts or {}
	local test_run = opts.test_run or false
	local msgh     = test_run and log.warning or opts.msg_handler
	local fdebug   = log.fdebug

	for i, v in ipairs(descriptors) do
		local arg      = v[1]
		local expected = v[2]
		local name     = v[3] or tostring(i)
		if (not AssertArg(arg, name, expected, msgh)) then
			if (not test_run) then
				return false
			end
		elseif (test_run) then
			fdebug("%s: pass", name)
		end
	end

	return true
end

-------

local ISINSTANCE_STD_TYPES <const>  = {
	["table"]    = true,
	["string"]   = true,
	["number"]   = true,
	["boolean"]  = true,
	["function"] = true,
	["userdata"] = true
}
local ISINSTANCE_MATH_TYPES <const> = {
	["integer"] = true,
	["float"]   = true
}

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
-- local myveh = LocalPlayer:GetVehicle()
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

	if (obj == T) then
		return true
	end

	local obj_type <const> = type(obj)
	local T_type <const>   = type(T)
	local obj_mt           = getmetatable(obj)
	local T_mt             = getmetatable(T)

	if (obj_mt == T) then
		return true
	end

	if (T_type == "string" and T == "pointer" and obj_type == "userdata") then
		return (obj_mt and type(obj_mt.rip) == "function" or false)
	end

	if (T_type == "table") then
		if (obj_type == "userdata" and T.__type == "vec3") then
			return obj_mt and obj_mt.__type == T.__type
		end

		local is_obj = rawget(T, "__index") ~= nil
			or rawget(T, "__type") ~= nil
			or rawget(T, "__base") ~= nil
			or T_mt ~= nil
			or (type(T_mt) == "table" and rawget(T_mt, "__call") ~= nil)

		if (is_obj) then
			if (obj_type == "table" and obj.__type and obj.__type == T.__type) then
				return true
			end

			if (not obj_mt) then
				return false
			end

			-- this fucker is heavy. it takes a full millisecond to test LocalPlayer against Entity (3 base classes up)
			-- TODO: refactor the `Class` function to cache the inheritance chain in each new class using a set or a basic table<T, true>
			local cls = rawget(obj_mt, "__index")
			if (cls) then obj_mt = cls end

			while (obj_mt) do
				if (obj_mt == T) then
					return true
				end
				obj_mt = rawget(obj_mt, "__base")
			end
			return false
		end
	end

	if (T_type == "string") then
		if ((obj_type) == "number" and ISINSTANCE_MATH_TYPES[T]) then
			return math_type(obj) == T
		end

		if (ISINSTANCE_STD_TYPES[T]) then
			if (obj_type == "table") then
				return (obj_type == T and obj_mt == nil)
			else
				return obj_type == T
			end
		end
	end

	return false
end

local SIZEOF_TYPES <const> = {
	["nil"]       = 0x0,
	["boolean"]   = 0x1,
	["function"]  = 0x8,
	["pointer"]   = 0x8,
	["vec2"]      = 0x8,
	["vec3"]      = 0xC,
	["vec4"]      = 0x10,
	["fMatrix44"] = 0x40,
	-- ["DataBuffer"] = function(t) return t:Size() end,
	["number"]    = function(t) return math.sizeof(t) end,
	["string"]    = function(t)
		local len = #t
		return len == 0 and 0 or (len + 1 --[[null terminator]])
	end,
}
-- Returns a symbolic size, not actual memory usage.
---@param T any
---@param seen? table Circular reference
---@return number
function SizeOf(T, seen)
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

	local known = SIZEOF_TYPES[resolved_type]
	if (known) then
		if (type(known) == "function") then
			return known(T)
		end
		return known
	end

	if (T_type == "table") then
		local size_method = T.Size
		if (type(size_method) == "function") then
			return size_method(T)
		end

		if (IsInstance(T.m_size, "number")) then
			return T.m_size
		end

		if (T.__enum or IsInstance(T.__sizeof, "function")) then
			return T.__sizeof(T)
		end

		if (IsInstance(T.__len, "function")) then
			return T.__len(T)
		end

		if (IsInstance(T.__type, "string")) then
			return GenericClass.m_size -- 0x40
		end

		seen = seen or {}
		if (seen[T]) then
			return 0
		end
		seen[T] = true
		return table.sizeof(T, seen)
	end

	return 0
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
---@generic R1, R2, R3, R4, R5, R6, R7, R8, R9, R10
---@generic K: anyval
---@generic V
---@param case K
---@param cases table<K, ValueOrFunction<V>>
---@return V|R1, R2?, R3?, R4?, R5?, R6?, R7?, R8?, R9?, R10?
function Match(case, cases)
	local result = cases[case] or cases["default"]
	assert(result ~= nil, "No case matched and no default provided!")
	return (type(result) == "function") and result() or result
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
---@param case anyval
function Switch(case)
	return function(cases)
		return Match(case, cases)
	end
end

---@param e Enum
---@param index integer
function EnumToString(e, index)
	if (type(e) ~= "table") then
		return "Unknown"
	end

	local cache = EnumNamesCache[e]
	if (not cache) then
		cache = {}
		EnumNamesCache[e] = cache
	end

	local cachedName = cache[index]
	if (cachedName) then return cachedName end

	for k, v in pairs(e) do
		if (v == index) then
			local name = tostring(k)
			cache[index] = name
			return name
		end
	end

	cache[index] = "Unknown"
	return "Unknown"
end

-- Pauses execution until a condition is met.
--
-- All logic after this call will only execute once the provided function returns a truthy value.
--
-- If the condition isn't met before the optional timeout is reached, `TaskWait` throws an error to prevent further execution.
---@param func fun(args: any): boolean
---@param args any
---@param timeout? milliseconds -- Optional timeout in milliseconds. Defaults to 1200ms.
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
	if (not IsInstance(args, "table")) then
		args = { args }
	end

	local start_time = Time.Millis()
	while (not func(table.unpack(args))) do
		if ((Time.Millis() - start_time) > timeout) then
			error("Timeout reached!")
		end
		yield()
	end

	return true
end

---@param t table
---@param mt table|metatable
---@param seen? set<table>
function RecursiveSetMetatable(t, mt, seen)
	seen = seen or {}
	if (seen[t]) then return end
	seen[t] = true

	for _, v in pairs(t) do
		if (type(v) == "table" and getmetatable(v) == nil) then
			RecursiveSetMetatable(v, mt, seen)
		end
	end

	return setmetatable(t, mt)
end

-- Simply adds a number suffix if a file with the same name and extension already exists.
---@param base_name string
---@param extension string
---@return string
function GenerateUniqueFilename(base_name, extension)
	local filename = _F("%s%s", base_name, extension)
	local suffix   = 0

	while (io.exists(filename)) do
		suffix   = suffix + 1
		filename = _F("%s_%d%s", base_name, suffix, extension)
	end

	return filename
end

--#endregion
