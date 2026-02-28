-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eSerializerState
local eSerializerState <const> = {
	INIT      = -1,
	IDLE      = 0,
	FLUSHING  = 1,
	SUSPENDED = 2,
}

-- Optional parameters
---@ignore
---@class SerializerOptionals
---@field pretty? boolean Pretty Encoding
---@field indent? integer Number of indentations for pretty encoding.
---@field strict_parsing? boolean -- Refer to the Json package
---@field encryption_key? string -- Optional key for XOR encryption

--------------------------------------
-- Class: Serializer
--------------------------------------
--[[**¤ Universal Config System For YimMenu-Lua ¤**

  - Author: [SAMURAI (xesdoog)](https://github.com/xesdoog).

  - Uses [JSON.lua package by Jeffrey Friedl](http://regex.info/blog/lua/json).
]]
---@class Serializer : ClassMeta<Serializer>
---@field protected m_initialized boolean
---@field protected __schema_hash joaat_t
---@field protected m_lock_queue array<function>
---@field private m_locked boolean
---@field private m_disabled boolean
---@field private m_file_name string
---@field private m_backup_file string
---@field private m_default_config table
---@field private m_key_states table
---@field private m_dirty boolean
---@field private m_parsing_options { pretty: boolean, indent: string, strict_parsing: boolean }
---@field private m_state eSerializerState
---@field private m_xor_key string
---@field private m_last_write_time TimePoint
---@field public class_types table<string, { serializer:fun(), constructor:fun() }>
---@overload fun(scrname?: string, default_config?: table, runtime_vars?: table, varargs?: SerializerOptionals): Serializer
local Serializer = Class("Serializer")
Serializer.class_types = {}
Serializer.m_deferred_objects = {}
Serializer.json = require("includes.thirdparty.json.json")()
Serializer.default_xor_key =
"\xA3\x4F\xD2\x9B\x7E\xC1\xE8\x36\x5D\x0A\xF7\xB4\x6C\x2D\x89\x50\x1E\x73\xC9\xAF\x3B\x92\x58\xE0\x14\x7D\xA6\xCB\x81\x3F\xD5\x67"
Serializer.b64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
Serializer.__version = "1.0.0"
Serializer.__credits = [[
	  +----------------------------------------------------------------------------------------+
	  |                                                                                        |
	  |                   ¤ Universal Config System For YimMenu-Lua ¤                          |
	  |________________________________________________________________________________________|
	  |                                                                                        |
	  |      - Author: SAMURAI (xesdoog): https://github.com/xesdoog)                          |
	  |                                                                                        |
	  |      - Uses JSON.lua package by Jeffrey Friedl: http://regex.info/blog/lua/json        |
	  |                                                                                        |
	  +----------------------------------------------------------------------------------------+
	]]

assert(Serializer.json.VERSION == "20211016.28", "Bad Json package version.")

---@param script_name? string
---@param default_config? table
---@param runtime_vars? table Runtime variables that will be tracked for auto-save.
---@param varargs? SerializerOptionals
---@return Serializer
function Serializer:init(script_name, default_config, runtime_vars, varargs)
	if (self.m_initialized) then
		return self
	end

	local timestamp        = tostring(os.date("%H_%M_%S"))
	script_name            = script_name or (Backend and Backend.script_name or ("unk_cfg_%s"):format(timestamp))
	varargs                = varargs or {}
	local filename         = script_name:lower():gsub("%s+", "_")

	self.m_default_config  = default_config or { __version = Backend and Backend.__version or self.__version }
	self.m_file_name       = _F("%s.json", filename)
	self.m_backup_file     = _F("%s.bak", filename)
	self.m_xor_key         = varargs.encryption_key or self.default_xor_key
	self.m_state           = eSerializerState.INIT
	self.m_dirty           = false
	self.m_locked          = false
	self.m_disabled        = false
	self.m_lock_queue      = {}
	self.m_key_states      = {}
	self.m_parsing_options = {
		pretty         = (varargs.pretty ~= nil) and varargs.pretty or true,
		indent         = string.rep(" ", varargs.indent or 4),
		strict_parsing = varargs.strict_parsing or false,
	}

	if (not io.exists(self.m_file_name)) then
		self:Parse(self.m_default_config)
	end

	local config_data = self:Read()
	if (type(config_data) ~= "table") then
		log.warning("[Serializer]: Failed to read data! Persistent config will be disabled for this session.")
		self.m_disabled    = true
		self.m_state       = eSerializerState.SUSPENDED
		self.m_initialized = true
		return self
	end

	if (not runtime_vars) then
		runtime_vars = _ENV.GVars or {}
		_ENV.GVars   = runtime_vars
	end

	setmetatable(
		runtime_vars,
		{
			__index = function(_, k)
				local value = self.m_key_states[k]
				if (value ~= nil) then
					return value
				end

				value = config_data[k]
				local saved = self.m_default_config[value]
				if (value ~= nil) then
					runtime_vars[k] = value
					self.m_key_states[k] = value
					self.m_dirty = true
					return value
				elseif (saved ~= nil) then
					runtime_vars[k] = saved
					self.m_key_states[k] = saved
					self.m_dirty = true
				end

				return nil
			end,
			__newindex = function(_, k, v)
				if (type(v) == "table" and getmetatable(v) == nil and type(v.serialize) ~= "function") then
					v = table.copy(v)
				end

				if (self.m_default_config[k] == nil) then
					local value = config_data[k] ~= nil and config_data[k] or v
					self.m_key_states[k] = value
				end

				if (self.m_key_states[k] ~= v) then
					self.m_key_states[k] = v
					self.m_dirty = true
				end
			end
		}
	)

	for key, default_value in pairs(self.m_default_config) do
		local saved_value = config_data[key]
		runtime_vars[key] = saved_value ~= nil and saved_value or default_value
	end

	for key, saved_value in pairs(config_data) do
		runtime_vars[key] = saved_value
	end

	local ignored_set      = Set.new("__schema_hash", "__dev_reset", "__version")
	self.__schema_hash     = _J(table.snapshot(self.m_default_config, { ignored_keys = ignored_set }))
	self.m_state           = eSerializerState.IDLE
	self.m_last_write_time = TimePoint.new()
	self:SyncKeys()
	self:SaveBackup()

	ThreadManager:RegisterLooped("SS_SERIALIZER", function()
		self:OnTick()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		self:OnShutdown()
	end)

	self.m_initialized = true
	return self
end

-- Ensures that saved config matches the default schema.
--
-- Adds missing keys and removes deprecated ones.
---@param runtime_vars? table Optional reference to GVars or other runtime config table.
function Serializer:SyncKeys(runtime_vars)
	if (not self:CanAccess()) then
		return
	end

	local saved       = self:Read()
	local default_cfg = self.m_default_config
	runtime_vars      = runtime_vars or _ENV.GVars or {}

	if (not saved["__schema_hash"] or saved["__schema_hash"] ~= self.__schema_hash) then
		table.merge(default_cfg, runtime_vars)
		saved["__schema_hash"] = self.__schema_hash
		runtime_vars["__schema_hash"] = self.__schema_hash
		self:Parse(saved)
	end
end

-- Registers a new object type for automatic serialization/deserialization
--
-- **Example:**
--
-- - Suppose `MyClass` is a simple class that stores two numbers:
--[[
```Lua
---@class MyClass
---@field a number
---@field b number
local MyClass = Class("MyClass")

---@return MyClass
function MyClass.new(a, b)
	return setmetatable({ a = a, b = b }, MyClass)
end

---@return table
function MyClass:ToJson()
	return { __type = self.__type, a = self.a, b = self.b }
end

---@return MyClass
function MyClass.FromJson(jsonTable)
	return MyClass.new(jsonTable.a, jsonTable.b)
end

Serializer:RegisterNewType("MyClass", MyClass.ToJson, MyClass.FromJson)
```
]]
---@param typename string
---@param serializer function Object to JSON
---@param deserializer function JSON to object
function Serializer:RegisterNewType(typename, serializer, deserializer)
	assert(type(typename) == "string", "Attempt to register an invalid type. Type name should be string.")
	typename = typename:lower():trim()
	self.class_types[typename] = {
		serializer  = serializer,
		constructor = deserializer
	}
end

---@return boolean
function Serializer:CanAccess()
	return self.m_state == eSerializerState.IDLE
end

---@return boolean
function Serializer:IsDisabled()
	return self.m_disabled
end

---@param data string
---@return boolean
function Serializer:IsEncrypted(data)
	return string.is_base64(data)
end

---@return eSerializerState
function Serializer:GetState()
	return self.m_state
end

---@return string
function Serializer:GetStateStr()
	return EnumToString(eSerializerState, self.m_state)
end

---@return milliseconds
function Serializer:GetLastWriteTime()
	return self.m_last_write_time and self.m_last_write_time:Value() or 0
end

---@return milliseconds
function Serializer:GetTimeSinceLastFlush()
	return self.m_last_write_time and self.m_last_write_time:Elapsed() or 0
end

function Serializer:SaveBackup()
	if (not io.exists(self.m_file_name)) then
		return
	end

	local f1 <close> = io.open(self.m_file_name, "r")
	local f2 <close> = io.open(self.m_backup_file, "w")
	if (not f1 or not f2) then
		return
	end

	local data = f1:read("a")
	if (not data) then
		return
	end

	f2:write(data)
	f2:flush()
end

---@return boolean, any
function Serializer:RecoverBackup()
	if (not io.exists(self.m_backup_file)) then
		return false, nil
	end

	local f1 <close> = io.open(self.m_backup_file, "r")
	local f2 <close> = io.open(self.m_file_name, "w")
	if (not f1 or not f2) then
		return false, nil
	end

	local data = f1:read("a")
	if (not data) then
		return false, nil
	end

	f2:write(data)
	f2:flush()
	return true, data
end

-- Waits for idle state before mutating the config table.
--
-- **Note:** Runs in a fiber so you can call `yield/sleep` in your function.
---@param fun function
function Serializer:WithLock(fun)
	if (self:IsDisabled()) then
		fun()
		return
	end

	table.insert(self.m_lock_queue, fun)

	if (self.m_locked) then
		return
	end

	self.m_locked = true

	ThreadManager:Run(function()
		while (#self.m_lock_queue > 0) do
			local f = table.remove(self.m_lock_queue, 1)
			if (type(f) == "function") then
				while (not self:CanAccess()) do
					yield()
				end

				self.m_state = eSerializerState.SUSPENDED
				f()
				self.m_state = eSerializerState.IDLE
			end
		end

		self.m_locked = false
	end)
end

---@param value any
---@return any
function Serializer:Preprocess(value, seen)
	seen = seen or {}
	if (seen[value]) then
		return seen[value]
	end

	local __type = type(value)
	if (__type ~= "table" and __type ~= "userdata") then
		return value
	end

	seen[value] = {}
	local type_name = value.__type
	if (type_name) then
		local name     = tostring(type_name):lower():trim()
		local fallback = self.class_types[name] and self.class_types[name].serializer
		if (type(fallback) == "function") then
			local ok, res = pcall(fallback, value)
			if (ok and type(res) == "table") then
				seen[value] = res
				return res
			end
		end
	end

	if (type(value.serialize) == "function") then
		local ok, res = pcall(value.serialize, value)
		if (ok and (type(res) == "table")) then
			seen[value] = res
			return res
		end
	end

	local out = {}
	seen[value] = out
	for k, v in pairs(value) do
		out[k] = self:Preprocess(v, seen)
	end

	return out
end

---@param value any
---@return any
function Serializer:Postprocess(value)
	if (type(value) ~= "table") then
		return value
	end

	local type_name = rawget(value, "__type")
	if (type_name) then
		local name = tostring(type_name):lower():trim()
		local ctor = self.class_types[name] and self.class_types[name].constructor

		if (type(ctor) == "function") then
			local ok, result = pcall(ctor, value)
			if (ok) then
				return result
			end
		else
			table.insert(self.m_deferred_objects, value)
			return value
		end
	end

	local out = {}
	for k, v in pairs(value) do
		out[self:Postprocess(k)] = self:Postprocess(v)
	end

	return out
end

---@private
---@param data any
---@param etc any
---@return boolean success, string? result
function Serializer:EncodeImpl(data, etc)
	return pcall(self.json.encode,
		self.json,
		data,
		etc,
		{
			pretty = self.m_parsing_options.pretty,
			indent = self.m_parsing_options.indent
		}
	)
end

---@private
---@param data any
---@param etc any
---@return boolean success, any result
function Serializer:DecodeImpl(data, etc)
	return pcall(self.json.decode,
		self.json,
		data,
		etc,
		{ strictParsing = self.m_parsing_options.strict_parsing or false }
	)
end

---@param data any
---@param etc? any
---@return string?
function Serializer:Encode(data, etc)
	local pre     = self:Preprocess(data)
	local ok, res = self:EncodeImpl(pre, etc)
	if (not ok) then
		log.warning("[Serializer]: Failed to encode data!")
		return
	end

	return res
end

---@param data any
---@param etc? any
---@return any
function Serializer:Decode(data, etc)
	local ok, res = self:DecodeImpl(data, etc)
	if (not ok) then
		local function onDecodeError()
			log.warning("[Serializer]: No suitable config backup. Resetting to default.")
			self:Parse(self.m_default_config)
			return table.copy(self.m_default_config)
		end

		log.warning("[Serializer]: Your config file is corrupted! Attempting to recover...")
		local success, recov = self:RecoverBackup()
		if (not success) then
			return onDecodeError()
		end

		if (self:IsEncrypted(recov)) then
			recov = self:Decrypt(recov)
		end

		ok, res = self:DecodeImpl(recov, etc)
		if (not ok) then
			return onDecodeError()
		end

		log.info("[Serializer]: Config backup successfullly recovered.")
	end

	return self:Postprocess(res)
end

---@param data any
function Serializer:Parse(data)
	if (self:IsDisabled()) then
		return
	end

	local f <close> = io.open(self.m_file_name, "w")
	if (not f) then
		log.warning("[Serializer]: Failed to write config file!")
		self.m_disabled = true
		return
	end

	self.m_state = eSerializerState.FLUSHING
	local json   = self:Encode(data)
	if (not json) then
		return
	end

	f:write(json)
	f:flush()
	self.m_state = eSerializerState.IDLE
end

---@return table
function Serializer:Read()
	if (self:IsDisabled()) then
		return table.copy(self.m_default_config)
	end

	local f <close> = io.open(self.m_file_name, "r")
	if (not f) then
		log.warning("[Serializer]: Failed to read config file!")
		self.m_disabled = true
		return table.copy(self.m_default_config)
	end

	local data = f:read("a")
	if (not data or #data == 0) then
		log.warning("[Serializer]: Config data is empty or unreadable.")
		self.m_disabled = true
		return table.copy(self.m_default_config)
	end

	if (self:IsEncrypted(data)) then
		data = self:Decrypt(data)
	end

	return self:Decode(data)
end

---@param item_path string
---@return any
function Serializer:ReadItem(item_path)
	if (type(GVars) ~= "table") then
		log.warning("[Serializer]: No runtime variables table! Returning default value.")
		return table.get_nested_key(self.m_default_config, item_path)
	end

	return table.get_nested_key(GVars, item_path)
end

---@param item_path string
---@param value any
function Serializer:SaveItem(item_path, value)
	if (type(GVars) ~= "table") then
		log.warning("[Serializer]: No runtime variables table!")
		return
	end

	table.set_nested_key(GVars, item_path, value)
end

---@param defaults table
---@param current? table
---@param out table
---@param exceptions Set<string>
---@param prefix? string
function Serializer:DeepReset(defaults, current, out, exceptions, prefix)
	for key, def_val in pairs(defaults) do
		local path = prefix and (prefix .. "." .. key) or key
		out = out or {}

		if (exceptions:Contains(path)) then
			local preserved = table.get_nested_key(_ENV.GVars, path)
			out[key] = preserved ~= nil and preserved or def_val
		elseif (type(def_val) == "table") then
			out[key] = {}
			self:DeepReset(
				def_val,
				type(current) == "table" and current[key] or nil,
				out[key],
				exceptions,
				path
			)
		else
			out[key] = def_val
		end
	end
end

---@param exceptions? Set<string>
function Serializer:Reset(exceptions)
	exceptions = exceptions or Set.new()
	local data = self:Read()
	if (type(data) ~= "table") then
		log.warning("[Serializer]: Invalid data type!")
		return
	end

	self:WithLock(function()
		GUI:Close()
		self.m_state = eSerializerState.SUSPENDED
		sleep(1)

		local temp = {}
		self:DeepReset(self.m_default_config, data, temp, exceptions, nil)
		log.info("[Serializer]: Settings reset. Restarting user interface...")
		self:Parse(temp)

		for k, v in pairs(temp) do
			self.m_key_states[k] = self:Reconstruct(v)
		end

		self:FlushObjectQueue()

		require("includes.services.ThemeManager"):Load()

		if (exceptions) then
			exceptions:Clear()
		end

		sleep(500)
		GUI:Toggle()
		self.m_state = eSerializerState.IDLE
	end)
end

---@param input string
---@return string Base64
function Serializer:B64Encode(input)
	local output = {}
	local n = #input

	for i = 1, n, 3 do
		local a = input:byte(i) or 0
		local b = input:byte(i + 1) or 0
		local c = input:byte(i + 2) or 0
		local triple = (a << 16) | (b << 8) | c

		output[#output + 1] = self.b64_chars:sub(((triple >> 18) & 63) + 1, ((triple >> 18) & 63) + 1)
		output[#output + 1] = self.b64_chars:sub(((triple >> 12) & 63) + 1, ((triple >> 12) & 63) + 1)
		output[#output + 1] = (i + 1 <= n) and self.b64_chars:sub(((triple >> 6) & 63) + 1, ((triple >> 6) & 63) + 1) or
			"="
		output[#output + 1] = (i + 2 <= n) and self.b64_chars:sub((triple & 63) + 1, (triple & 63) + 1) or "="
	end

	return table.concat(output)
end

---@param base64 string
---@return string
function Serializer:B64Decode(base64)
	local b64lookup = {}

	for i = 1, #self.b64_chars do
		b64lookup[self.b64_chars:sub(i, i)] = i - 1
	end

	base64 = base64:gsub("%s", ""):gsub("=", "")
	local output = {}

	for i = 1, #base64, 4 do
		local a = b64lookup[base64:sub(i, i)] or 0
		local b = b64lookup[base64:sub(i + 1, i + 1)] or 0
		local c = b64lookup[base64:sub(i + 2, i + 2)] or 0
		local d = b64lookup[base64:sub(i + 3, i + 3)] or 0
		local triple = (a << 18) | (b << 12) | (c << 6) | d
		output[#output + 1] = string.char((triple >> 16) & 255)
		if i + 2 <= #base64 then
			output[#output + 1] = string.char((triple >> 8) & 255)
		end
		if i + 3 <= #base64 then
			output[#output + 1] = string.char(triple & 255)
		end
	end

	return table.concat(output)
end

---@param input string
---@return string
function Serializer:XOR(input)
	local output = {}
	local key_len = #self.m_xor_key
	for i = 1, #input do
		local input_byte = input:byte(i)
		local key_byte = self.m_xor_key:byte((i - 1) % key_len + 1)
		output[i] = string.char(input_byte ~ key_byte)
	end
	return table.concat(output)
end

---@param data anyval json data
---@return string?
function Serializer:Encrypt(data)
	if (not data or #data == 0) then
		log.warning("[Serializer]: Encryption failed! Data is unreadable.")
		return
	end

	return self:B64Encode(self:XOR(data))
end

---@param data anyval Json data encrypted in base64 + xor
---@return any -- json data or nil
function Serializer:Decrypt(data)
	if (not data or #data == 0) then
		log.warning("[Serializer]: Decryption failed! Data is unreadable.")
		return
	end

	if (not self:IsEncrypted(data)) then
		log.warning("[Serializer]: Data is not encrypted!")
		return
	end

	return self:XOR(self:B64Decode(data))
end

---@private
---@param data any
---@param filename string
function Serializer:WriteInternal(data, filename)
	local f, err = io.open(filename, "w")
	if (not f) then
		log.fwarning("[Serializer]: Failed to open file: %s", err)
		return
	end

	f:write(data)
	f:flush()
	f:close()
end

-- A separate write function that doesn't rely on any setup or state flags.
--
-- Do not use it to write to the Serializer's config file.
---@param data any
---@param filename string
function Serializer:WriteToFile(data, filename)
	if (type(filename) ~= "string" or not filename:endswith(".json")) then
		log.warning("[Serializer]: Invalid file name.")
		return
	end

	if (filename == self.m_file_name) then
		log.warning("[Serializer]: Illegal operation: Attempt to overwrite the main config file.")
		return
	end

	if (not data) then
		log.warning("[Serializer]: Invalid data type.")
		return
	end

	local f, err = io.open(filename, "w")
	if (not f) then
		log.fwarning("[Serializer]: Failed to open file: %s", err)
		return
	end

	f:write(self:Encode(data))
	f:flush()
	f:close()
end

-- A separate read function.
--
-- This can not be used with the main config file.
---@param filename string
---@return any
function Serializer:ReadFromFile(filename)
	if (type(filename) ~= "string" or not filename:endswith(".json")) then
		log.warning("[Serializer]: Invalid file name.")
		return
	end

	if (filename == self.m_file_name) then
		log.warning("[Serializer]: Use Serializer:Read() instead to read the Serializer's config file.")
		return
	end

	local f <close>, err = io.open(filename, "r")
	if (not f) then
		log.fwarning("[Serializer]: Failed to open file: %s", err)
		return
	end

	return self:Decode(f:read("a"))
end

---@param object table
function Serializer:Reconstruct(object)
	if (type(object) ~= "table") then
		return object
	end

	if (object.__type) then
		local name  = tostring(object.__type):lower()
		local entry = self.class_types[name]

		if (entry and type(entry.constructor) == "function") then
			local ok, result = pcall(entry.constructor, object)
			if (ok and result) then
				-- Backend:debug("Reconstructed object: %s", name)
				return result
			else
				-- Backend:debug("Constructor failed for object '%s' error: ", name, result)
				return object
			end
		end
	end

	if (table.is_array(object)) then
		local out = {}
		for i = 1, #object do
			out[i] = self:Reconstruct(object[i])
		end
		return out
	else
		local out = {}
		for k, v in pairs(object) do
			out[k] = self:Reconstruct(v)
		end
		return out
	end
end

function Serializer:FlushObjectQueue()
	self:WithLock(function()
		for _, t in ipairs(self.m_deferred_objects) do
			for k, v in pairs(self.m_key_states) do
				if ((type(v) == "table" and (type(t) == "table"))) then
					self.m_key_states[k] = self:Reconstruct(v)
				end
			end
		end

		self.m_deferred_objects = {}
	end)
end

function Serializer:Flush()
	-- Welp. We need atomic writes. My config got corrupted because of a power outage.
	-- Since th os library doesn't have rename, we can write to a secondary file and check if the write was
	-- successful and the file is readable then write the actual config file. If main gets corrupted, read temp and overwrite
	-- but that's a horrible way to do it: double read/write calls and an unnecessary file just sitting in the config folder.
	--
	-- TODO: contribute a refactored os lib sandbox to YimMenu
	-- that has os.rename. Must group config files in a subfolder tied to the module
	-- otherwise Lua devs would be able to rename other devs' config files (we already can read/write them which is bad enough)
	-- and if the dev is a troll, that's a problem.
	-- Once that's done, regactor this to write to a temp file then swap.

	if (self:IsDisabled()) then
		return
	end

	self:WithLock(function()
		self:Parse(self.m_key_states)
		self.m_dirty = false
		self.m_last_write_time:Reset()
	end)
end

function Serializer:OnTick()
	if (not self.m_initialized or not self:CanAccess()) then
		return
	end

	if (not self.m_dirty and not self.m_last_write_time:HasElapsed(5e3)) then
		yield()
		return
	end

	self:Flush()
	sleep(1e3)
end

function Serializer:OnShutdown()
	if (not self:CanAccess() or not self.m_last_write_time:HasElapsed(2e3)) then
		return
	end

	self:Flush()
end

---@private
---@param mode number 0 | 1
function Serializer:DebugBreak(mode)
	if (not Backend.debug_mode) then
		return
	end

	mode            = mode or 0
	self.m_dirty    = false
	self.m_disabled = true

	if (mode == 0) then
		self:WriteInternal("{ royallyfuckedjson", self.m_file_name)
	elseif (mode == 1) then
		local f = io.open(self.m_file_name, "r")
		if (not f) then
			return
		end

		---@type string?
		local data = f:read("a")
		f:close()

		local f2 <close> = io.open(self.m_file_name, "w")
		if (not f2 or type(data) ~= "string") then
			return
		end

		f2:write(data:sub(1, #data // 2))
	end
end

function Serializer:Dump()
	local out = {
		script_name    = Backend and Backend.script_name or "Samurai's Scripts",
		file_name      = self.m_file_name,
		disabled       = self.m_disabled,
		state          = self:GetStateStr(),
		key_states     = self.m_key_states,
		default_config = self.m_default_config,
		runtime_vars   = _ENV.GVars or {},
	}

	print(out)
	self:notify("Dumped to console.")
end

return Serializer
