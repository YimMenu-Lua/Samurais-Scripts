---@diagnostic disable: param-type-mismatch

-- Optional parameters struct.
---@ignore
---@class SerializerOptionals
---@field pretty? boolean Pretty Encoding
---@field indent? number Number of indentations for pretty encoding.
---@field strict_parsing? boolean -- Refer to the Json package
---@field encryption_key? string -- Optional key for XOR encryption
---@field force_reset? boolean

--------------------------------------
-- Class: Serializer
--------------------------------------
--[[**¤ Universal Config System For YimMenu-Lua ¤**

  - Author: [SAMURAI (xesdoog)](https://github.com/xesdoog).

  - Uses [JSON.lua package by Jeffrey Friedl](http://regex.info/blog/lua/json).
]]
---@class Serializer : ClassMeta<Serializer>
---@field file_name string
---@field default_config table
---@field m_key_states table
---@field m_dirty boolean
---@field private parsing_options SerializerOptionals
---@field private m_disabled boolean
---@field private xor_key string
---@field private m_last_write_time Time.TimePoint
---@field protected __schema_hash joaat_t
---@field class_types table<string, {serializer:fun(), constructor:fun()}>
---@overload fun(scrname?: string, default_config?: table, runtime_vars?: table, varargs?: SerializerOptionals): Serializer
local Serializer = Class("Serializer")
Serializer.class_types = {}
Serializer.deferred_objects = {}
Serializer.json = require("includes.lib.json")()
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
	varargs = varargs or {}
	local timestamp = tostring(os.date("%H_%M_%S"))
	script_name = script_name or (Backend and Backend.script_name or ("unk_cfg_%s"):format(timestamp))

	---@type Serializer
	local instance = setmetatable(
		{
			default_config  = default_config or { __version = Backend and Backend.__version or self.__version },
			file_name       = _F("%s.json", script_name:lower():gsub("%s+", "_")),
			xor_key         = varargs.encryption_key or self.default_xor_key,
			m_disabled      = false,
			m_dirty         = false,
			m_key_states    = {},
			parsing_options = {
				pretty         = (varargs.pretty ~= nil) and varargs.pretty or true,
				indent         = string.rep(" ", varargs.indent or 4),
				strict_parsing = varargs.strict_parsing or false,
				force_reset    = varargs.force_reset or false,
			}
		},
		self
	)

	if (not io.exists(instance.file_name)) then
		instance:Parse(instance.default_config)
	end

	if (instance.parsing_options.force_reset) then
		self:notify("Your saved config has been force-reset due to a config mismatch.")
		instance:Parse(instance.default_config)
	end

	local config_data = instance:Read()
	if type(config_data) ~= "table" then
		log.warning("[Serializer]: Failed to read data. Persistent config will be disabled for this session.")
		instance.m_disabled = true
		return instance
	end

	if (not runtime_vars) then
		runtime_vars = _ENV.GVars or {}
		_ENV.GVars = runtime_vars
	end

	setmetatable(
		runtime_vars,
		{
			__index = function(_, k)
				local value = instance.m_key_states[k]
				if (value ~= nil) then
					return value
				end

				value = config_data[k]
				local saved = instance.default_config[value]
				if (value ~= nil) then
					runtime_vars[k] = value
					instance.m_key_states[k] = value
					instance.m_dirty = true
					return value
				elseif (saved ~= nil) then
					runtime_vars[k] = saved
					instance.m_key_states[k] = saved
					instance.m_dirty = true
				end

				return nil
			end,
			__newindex = function(_, k, v)
				if (type(v) == "table" and getmetatable(v) == nil and type(v.serialize) ~= "function") then
					v = table.copy(v)
				end

				if (instance.default_config[k] == nil) then
					local value = config_data[k] ~= nil and config_data[k] or v
					instance.m_key_states[k] = value
				end

				if (instance.m_key_states[k] ~= v) then
					instance.m_key_states[k] = v
					instance.m_dirty = true
				end
			end
		}
	)

	for key, default_value in pairs(instance.default_config) do
		local saved_value = config_data[key]
		runtime_vars[key] = saved_value ~= nil and saved_value or default_value
	end

	for key, saved_value in pairs(config_data) do
		runtime_vars[key] = saved_value
	end

	local ignored_set = Set.new("__schema_hash", "__dev_reset", "__version")
	instance.__schema_hash = joaat(table.snapshot(instance.default_config, { ignored_keys = ignored_set }))
	instance:SyncKeys()
	instance.m_last_write_time = TimePoint.new()

	ThreadManager:RegisterLooped("SS_SERIALIZER", function()
		instance:OnTick()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		instance:OnShutdown()
	end)

	return instance
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
	local default_cfg = self.default_config
	runtime_vars      = runtime_vars or _ENV.GVars or {}

	if (not saved["__schema_hash"] or saved["__schema_hash"] ~= self.__schema_hash) then
		local function deep_merge(default, target, path, visited)
			if (visited[default]) then
				return
			end
			visited[default] = true

			for k, v in pairs(default) do
				local current_path = path and (path .. "." .. tostring(k)) or tostring(k)

				if (target[k] == nil) then
					Backend:debug("[Serializer]: Added missing config key %s", current_path)
					target[k] = v
				elseif (type(v) == "table" and type(target[k]) == "table") then
					deep_merge(v, target[k], current_path, visited)
				end
			end
		end

		deep_merge(default_cfg, runtime_vars, nil, {})
		saved["__schema_hash"] = self.__schema_hash
		runtime_vars["__schema_hash"] = self.__schema_hash
		self:Parse(saved)
	end
end

---@param typename string
---@param serializer function
---@param deserializer function
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
	return not self.m_disabled
end

---@return milliseconds
function Serializer:GetLastWriteTime()
	return self.m_last_write_time and self.m_last_write_time.value or 0
end

---@return milliseconds
function Serializer:GetTimeSinceLastFlush()
	return self.m_last_write_time and self.m_last_write_time:elapsed() or 0
end

function Serializer:IsBase64(data)
	return (#data % 4 == 0 and data:match("^[A-Za-z0-9+/]+=?=?$") ~= nil)
end

---@param value any
---@return any
function Serializer:Preprocess(value, seen)
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local t = type(value)
	if (t == "table" or t == "userdata") then
		seen[value] = {}

		local type_name = value.__type
		if type_name then
			local name = tostring(type_name):lower():trim()
			local fallback = self.class_types[name] and self.class_types[name].serializer

			if (type(fallback) == "function") then
				local ok, result = pcall(fallback, value)
				if (ok and type(result) == "table") then
					seen[value] = result
					return result
				end
			end
		end

		if (type(value.serialize) == "function") then
			local ok, result = pcall(value.serialize, value)
			if ok and (type(result) == "table") then
				seen[value] = result
				return result
			end
		end

		local out = {}
		seen[value] = out
		for k, v in pairs(value) do
			out[k] = self:Preprocess(v, seen)
		end

		return out
	end

	return value
end

---@param value any
---@return any
function Serializer:Postprocess(value)
	if (type(value) == "table") then
		local type_name = rawget(value, "__type")
		if type_name then
			local name = tostring(type_name):lower():trim()
			local ctor = self.class_types[name] and self.class_types[name].constructor

			if (type(ctor) == "function") then
				local ok, result = pcall(ctor, value)
				if ok then
					return result
				end
			else
				table.insert(self.deferred_objects, value)
				return value
			end
		end

		local out = {}
		for k, v in pairs(value) do
			out[self:Postprocess(k)] = self:Postprocess(v)
		end

		return out
	end

	return value
end

---@param data any
---@param etc? any
function Serializer:Encode(data, etc)
	return self.json:encode(
		self:Preprocess(data),
		etc,
		{
			pretty = self.parsing_options.pretty,
			indent = self.parsing_options.indent
		}
	)
end

---@param data any
---@param etc? any
---@return any
function Serializer:Decode(data, etc)
	local parsed = self.json:decode(
		data,
		etc,
		{ strictParsing = self.parsing_options.strict_parsing or false }
	)

	return self:Postprocess(parsed)
end

---@param data any
function Serializer:Parse(data)
	if not self:CanAccess() then
		return
	end

	local file, _ = io.open(self.file_name, "w")
	if not file then
		log.warning("[Serializer]: Failed to write config file!")
		self.m_disabled = true
		return
	end

	file:write(self:Encode(data))
	file:flush()
	file:close()
end

---@return table
function Serializer:Read()
	if not self:CanAccess() then
		return table.copy(self.default_config)
	end

	local file, _ = io.open(self.file_name, "r")
	if not file then
		log.warning("[Serializer]: Failed to read config file!")
		self.m_disabled = true
		return table.copy(self.default_config)
	end

	local data = file:read("a")
	file:close()

	if (not data or #data == 0) then
		log.warning("[Serializer]: Config data is empty or unreadable.")
		return table.copy(self.default_config)
	end

	if self:IsBase64(data) then
		self:Decrypt()
		local decrypted_data = self:Read()
		self:Encrypt()
		return decrypted_data
	end

	return self:Decode(data)
end

---@param item_name string
---@return any
function Serializer:ReadItem(item_name)
	local data = self:Read()

	if (type(data) ~= "table") then
		log.warning("[Serializer]: Invalid data type! Returning default value.")
		return self.default_config[item_name]
	end

	return data[item_name]
end

---@param item_name string
---@param value any
function Serializer:SaveItem(item_name, value)
	local data = self:Read()

	if (type(data) ~= "table") then
		log.warning("[Serializer]: Invalid data type!")
		return
	end

	data[item_name] = value
	self:Parse(data)
end

---@param defaults table
---@param current table
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
	if not self:CanAccess() then
		self:notify(_T("GENERIC_UNAVAILABLE"))
		return
	end

	exceptions = exceptions or Set.new()
	local data = self:Read()
	if type(data) ~= "table" then
		log.warning("[Serializer]: Invalid data type!")
		return
	end

	-- local threads = ThreadManager:ListThreads()
	-- local running_threads = Set.new()
	-- for _, thread in pairs(threads) do
	-- 	if (thread:IsRunning()) then
	-- 		thread:Suspend()
	-- 		running_threads:Push(thread)
	-- 	end
	-- end

	GUI:Close()
	local temp = {}
	self:DeepReset(self.default_config, data, temp, exceptions, nil)
	self:notify("Settings reset. Restarting user interface...")
	self:Parse(temp)

	for k, v in pairs(temp) do
		self.m_key_states[k] = self:Reconstruct(v)
	end

	self:FlushObjectQueue()
	ThreadManager:Run(function()
		sleep(500)

		require("includes.services.ThemeManager"):Load()

		-- for _, thread in pairs(threads) do
		-- 	if (running_threads:Contains(thread)) then
		-- 		thread:Resume()
		-- 		running_threads:Pop(thread)
		-- 	end
		-- end

		if (exceptions) then
			exceptions:Clear()
		end

		sleep(500)
		GUI:Toggle()
	end)
end

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

function Serializer:B64Decode(input)
	local b64lookup = {}

	for i = 1, #self.b64_chars do
		b64lookup[self.b64_chars:sub(i, i)] = i - 1
	end

	input = input:gsub("%s", ""):gsub("=", "")
	local output = {}

	for i = 1, #input, 4 do
		local a = b64lookup[input:sub(i, i)] or 0
		local b = b64lookup[input:sub(i + 1, i + 1)] or 0
		local c = b64lookup[input:sub(i + 2, i + 2)] or 0
		local d = b64lookup[input:sub(i + 3, i + 3)] or 0
		local triple = (a << 18) | (b << 12) | (c << 6) | d
		output[#output + 1] = string.char((triple >> 16) & 255)
		if i + 2 <= #input then
			output[#output + 1] = string.char((triple >> 8) & 255)
		end
		if i + 3 <= #input then
			output[#output + 1] = string.char(triple & 255)
		end
	end

	return table.concat(output)
end

function Serializer:XOR(input)
	local output = {}
	local key_len = #self.xor_key
	for i = 1, #input do
		local input_byte = input:byte(i)
		local key_byte = self.xor_key:byte((i - 1) % key_len + 1)
		output[i] = string.char(input_byte ~ key_byte)
	end
	return table.concat(output)
end

function Serializer:Encrypt()
	local file, _ = io.open(self.file_name, "r")
	if not file then
		log.warning("[ERROR] (Serializer): Failed to encrypt data! Unable to read config file.")
		return
	end

	local data = file:read("a")
	file:close()
	if not data or #data == 0 then
		log.warning("[ERROR] (Serializer): Failed to encrypt config! Data is unreadable.")
		return
	end

	local xord = self:XOR(data)
	local b64 = self:B64Encode(xord)

	file, _ = io.open(self.file_name, "w")

	if file then
		file:write(b64)
		file:flush()
		file:close()
	end
end

function Serializer:Decrypt()
	local file, _ = io.open(self.file_name, "r")
	if not file then
		log.warning("[ERROR] (Serializer): Failed to decrypt data! Unable to read config file.")
		return
	end

	local data = file:read("a")
	file:close()
	if not data or #data == 0 then
		log.warning("[ERROR] (Serializer): Failed to decrypt config! Data is unreadable.")
		return
	end

	if not self:IsBase64(data) then
		log.warning("(Serializer:Decrypt): Data is not encrypted!")
		return
	end

	local decoded = self:B64Decode(data)
	local decrypted = self:XOR(decoded)
	self:Parse(self:Decode(decrypted))
end

-- A separate write function that doesn't rely on any setup or state flags.
--
-- Do not use it to write to the Serializer's config file.
---@param data any
---@param filename string
function Serializer:WriteToFile(data, filename)
	if (type(filename) ~= "string" or not filename:endswith(".json")) then
		log.warning("Invalid file name.")
		return
	end

	if (filename == self.file_name) then
		log.warning("Attempt to overwrite the Serializer's config file!")
		return
	end

	if (not data) then
		log.warning("Invalid data type.")
		return
	end

	local f, err = io.open(filename, "w")
	if not f then
		log.fwarning("Failed to open file!\n%s", err)
		return
	end

	f:write(self:Encode(data))
	f:flush()
	f:close()
end

-- A separate read function that doesn't rely on any setup or state flags.
---@param filename string
function Serializer:ReadFromFile(filename)
	if (type(filename) ~= "string" or not filename:endswith(".json")) then
		log.warning("Invalid file name.")
		return
	end

	if (filename == self.file_name) then
		log.warning("Use Serializer:Read() instead to read the Serializer's config file.")
		return
	end

	local f, err = io.open(filename, "r")
	if not f then
		log.fwarning("Failed to open file!\n%s", err)
		return
	end

	local data = f:read("a")
	f:flush()
	f:close()

	return self:Decode(data)
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

	if (table.isarray(object)) then
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
	for _, t in ipairs(self.deferred_objects) do
		for k, v in pairs(self.m_key_states) do
			if ((type(v == "table") and (type(t) == "table"))) then
				self.m_key_states[k] = self:Reconstruct(v)
			end
		end
	end

	self.deferred_objects = {}
end

function Serializer:Flush()
	if (not self:CanAccess()) then
		return
	end

	self:Parse(self.m_key_states)
	self.m_dirty = false
	self.m_last_write_time:reset()
end

function Serializer:OnTick()
	if (not self.m_dirty and not self.m_last_write_time:has_elapsed(5e3)) then
		yield()
		return
	end

	self:Flush()
	sleep(1e3)
end

function Serializer:OnShutdown()
	if (not self.m_last_write_time:has_elapsed(2e3)) then
		return
	end

	self:Flush()
end

function Serializer:DebugDump()
	local out = {
		script_name    = Backend and Backend.script_name or "Samurai's Scripts",
		file_name      = self.file_name,
		is_disabled    = self.m_disabled,
		key_states     = self.m_key_states,
		default_config = self.default_config,
		runtime_vars   = _ENV.GVars or {},
	}

	print(out)
	self:notify("Dumped to console.")
end

return Serializer
