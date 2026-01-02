PatternScanner = require("includes.services.PatternScanner"):init()

--- A place to store callable naems returned from `memory.dynamic_call`
---@class DynamicFuncNames
---@field dfn_IsVehicleWheelBrokenOff? string

-- ### A place to store pointers globally.
--
-- You can add new indexes to this global table from any other file
--
-- as long as it's loaded before `GPointers:Init()` is called *(bottom of init.lua)*.
--
-- **NOTE:** Please make sure no modules/files try to use a pointer before the scan is complete.
--
-- You can call `PatternScanner:IsDone()` to double check.
---@class GPointers
---@field ScriptGlobals pointer
---@field GameState pointer<byte>
---@field GameTime pointer<uint32_t>
---@field GameVersion { _build: string, _online: string }
---@field ScreenResolution vec2
---@field IsVehicleWheelBrokenOff pointer<function>
---@field DynamicFuncNames DynamicFuncNames
local GPointers = {
	Init                    = function() PatternScanner:Scan() end,
	Retry                   = function() PatternScanner:RetryScan() end,
	ScriptGlobals           = nullptr,
	GameState               = nullptr,
	GameTime                = nullptr,
	IsVehicleWheelBrokenOff = nullptr,
	GameVersion             = { _build = "nil", _online = "nil" },
	ScreenResolution        = vec2:zero(),
}

GPointers.DynamicFuncNames = {}


---@class MemoryBatch
---@field m_name string
---@field m_pattern string
---@field m_callback fun(ptr: pointer)
local MemoryBatch <const> = {}
MemoryBatch.__index = MemoryBatch
---@param name string
---@param ida_sig string
---@param callback fun(ptr: pointer)
function MemoryBatch.new(name, ida_sig, callback)
	return {
		m_name     = name,
		m_pattern  = ida_sig,
		m_callback = callback
	}
end

---@type table<eAPIVersion, array<MemoryBatch>>
local mem_batches <const> = {
	[Enums.eAPIVersion.V1] = {
		MemoryBatch.new("ScriptGlobals", "48 8D 15 ? ? ? ? 4C 8B C0 E8 ? ? ? ? 48 85 FF 48 89 1D", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.ScriptGlobals = ptr:add(0x3):rip()
		end),
		MemoryBatch.new("GameVersion", "8B C3 33 D2 C6 44 24 20", function(ptr)
			if ptr:is_null() then
				return
			end

			local pGameBuild = ptr:add(0x24):rip()
			local pOnlineVersion = pGameBuild:add(0x20)
			GPointers.GameVersion = {
				_build  = pGameBuild:get_string(),
				_online = pOnlineVersion:get_string()
			}
		end),
		MemoryBatch.new("GameState", "83 3D ? ? ? ? ? 75 17 8B 43 20 25", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.GameState = ptr:add(0x2):rip():add(0x1)
		end),
		MemoryBatch.new("GameTime", "8B 05 ? ? ? ? 89 ? 48 8D 4D C8", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.GameTime = ptr:add(0x2):rip()
		end),
		MemoryBatch.new("ScreenResolution", "66 0F 6E 0D ? ? ? ? 0F B7 3D", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.ScreenResolution = vec2:new(
				ptr:sub(0x4):rip():get_word(),
				ptr:add(0x4):rip():get_word()
			)
		end),
		-- MemoryBatch.new("IsVehicleWheelBrokenOff", "E8 ? ? ? ? 48 8B CD 41 88 84 1F", function(ptr)
		-- 	if ptr:is_null() then
		-- 		return
		-- 	end

		-- 	local func_ptr = ptr:add(0x1):rip()
		-- 	GPointers.IsVehicleWheelBrokenOff = func_ptr -- not needed for this but we'll just go ahead and store it
		-- 	GPointers.DynamicFuncNames.dfn_IsVehicleWheelBrokenOff = memory.dynamic_call(
		-- 		"bool",
		-- 		{ "void*", "int" },
		-- 		func_ptr
		-- 	)
		-- end),
	},
	[Enums.eAPIVersion.V2] = {
		MemoryBatch.new("ScriptGlobals", "48 8B 8E B8 00 00 00 48 8D 15 ? ? ? ? 49 89 D8", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.ScriptGlobals = ptr:add(0x7):add(0x3):rip()
		end),
		MemoryBatch.new("GameVersion", "4C 8D 0D ? ? ? ? 48 8D 5C 24 ? 48 89 D9 48 89 FA", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.GameVersion = {
				_build  = ptr:add(0x3):rip():get_string(),
				_online = ptr:add(0x47):add(0x3):rip():get_string()
			}
		end),
		MemoryBatch.new("GameState", "83 3D ? ? ? ? ? 0F 85 ? ? ? ? BA ? 00", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.GameState = ptr:add(0x2):rip():add(0x1)
		end),
		MemoryBatch.new("ScreenResolution", "75 39 0F 57 C0 F3 0F 2A 05", function(ptr)
			if ptr:is_null() then
				return
			end

			GPointers.ScreenResolution = vec2:new(
				ptr:add(0x5):add(0x4):rip():get_word(),
				ptr:add(0x1E):add(0x4):rip():get_word()
			)
		end),
	},
	[Enums.eAPIVersion.L54] = {
		-- dummy
	},
}

local API_VERSON <const> = Backend:GetAPIVersion()
local batches = mem_batches[API_VERSON]
for _, batch in ipairs(batches) do
	PatternScanner:Add(batch.m_name, batch.m_pattern, batch.m_callback)
end

return GPointers
