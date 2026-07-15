-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


PatternScanner = require("includes.services.PatternScanner")


local BRANCH_LEGACY <const>   = Enums.eGameBranch.LEGACY
local BRANCH_ENHANCED <const> = Enums.eGameBranch.ENHANCED

---@return pointer
local function zero_ptr()
	return memory.pointer:new(0x0)
end

---@param this pointer
---@param ptr pointer
local function assign(this, ptr)
	this:set_address(ptr:get_address())
end

--- A place to store functions returned from `memory.dynamic_call`
---@class DynamicFuncs
---@field BreakOffVehicleWheel? fun(pVehicleDamage: pointer<CVehicleDamage>, wheelIdx: integer, ptfxChance: float, deleteChance: float, burstChance: float, setOnFire: bool, isNetwork: bool)

-- ### A place to store pointers globally.
--
-- You can add new indices to this global table from any other file
--
-- as long as it's loaded before `GPointers:Init()` is called.
--___
-- **[Note]:** All objects are not reassigned during memory scans but mutated in-place
--
-- so it's safe to hold references to them before `PatternScanner` is done.
---@class GPointers
---@field ScriptGlobals pointer
---@field GameState pointer<uint8_t>
---@field GameTime pointer<uint32_t>
---@field GameVersion VersionInfo
---@field ScreenResolution vec2
---@field DynamicFuncs DynamicFuncs
local GPointers = {
	Init             = function() PatternScanner:Scan() end,
	Retry            = function() PatternScanner:RetryScan() end,
	ScriptGlobals    = zero_ptr(),
	GameState        = zero_ptr(),
	GameTime         = zero_ptr(),
	ScreenResolution = vec2:zero(),
	GameVersion      = { build = "", online = "" },
	DynamicFuncs     = {}
}

---@generic P0: string, P1: string
---@param name P0
---@param ida_sig P1
---@param callback fun(ptr: pointer)
---@return { name: P0, sig: P1, callback: fun(ptr: pointer) }
local function make_batch(name, ida_sig, callback)
	return { name = name, sig = ida_sig, callback = callback }
end

local mem_batches <const> = {
	[BRANCH_LEGACY] = {
		make_batch("GameVersion", "8B C3 33 D2 C6 44 24 20", function(ptr)
			local pGameBuild             = ptr:add(0x24):rip()
			local pOnlineVersion         = pGameBuild:add(0x20)
			GPointers.GameVersion.build  = pGameBuild:get_string()
			GPointers.GameVersion.online = pOnlineVersion:get_string()
		end),
		make_batch("ScreenResolution", "66 0F 6E 0D ? ? ? ? 0F B7 3D", function(ptr)
			GPointers.ScreenResolution.x = ptr:sub(0x4):rip():get_word()
			GPointers.ScreenResolution.y = ptr:add(0x4):rip():get_word()
		end),
		make_batch("ScriptGlobals", "48 8D 15 ? ? ? ? 4C 8B C0 E8 ? ? ? ? 48 85 FF 48 89 1D", function(ptr)
			assign(GPointers.ScriptGlobals, ptr:add(0x3):rip())
		end),
		make_batch("GameState", "81 39 5D 6D FF AF 75 20", function(ptr)
			assign(GPointers.GameState, ptr:add(0xA):rip():add(0x1))
		end),
		make_batch("GameTime", "8B 05 ? ? ? ? 89 ? 48 8D 4D C8", function(ptr)
			assign(GPointers.GameTime, ptr:add(0x2):rip())
		end),

		-- TODO: enable once dynamic calls become stable. For now either the JIT compiler is broken or I'm just outright stupid.
		-- MakeBatch("BreakOffVehicleWheel", "F3 44 0F 11 4C 24 ? E8 ? ? ? ? EB 7A", function(ptr)
		-- 	local func_ptr = ptr:add(0x7)
		-- 	local func_name = memory.dynamic_call(
		-- 		"void",
		-- 		{ "void*", "uint32_t", "float", "float", "float", "bool", "bool" },
		-- 		func_ptr
		-- 	)

		-- 	GPointers.DynamicFuncs.BreakOffVehicleWheel = _G[func_name]
		-- end),
	},
	[BRANCH_ENHANCED] = {
		make_batch("ScreenResolution", "75 39 0F 57 C0 F3 0F 2A 05", function(ptr)
			GPointers.ScreenResolution.x = ptr:add(0x5):add(0x4):rip():get_word()
			GPointers.ScreenResolution.y = ptr:add(0x1E):add(0x4):rip():get_word()
		end),
		make_batch("GameVersion", "4C 8D 0D ? ? ? ? 48 8D 5C 24 ? 48 89 D9 48 89 FA", function(ptr)
			GPointers.GameVersion.build  = ptr:add(0x3):rip():get_string()
			GPointers.GameVersion.online = ptr:add(0x47):add(0x3):rip():get_string()
		end),
		make_batch("ScriptGlobals", "48 8B 8E B8 00 00 00 48 8D 15 ? ? ? ? 49 89 D8", function(ptr)
			assign(GPointers.ScriptGlobals, ptr:add(0x7):add(0x3):rip())
		end),
		make_batch("GameState", "83 3D ? ? ? ? ? 0F 85 ? ? ? ? BA ? 00", function(ptr)
			assign(GPointers.GameState, ptr:add(0x2):rip():add(0x1))
		end),
	},
}

local branch = Backend:GetGameBranch()
if (branch < BRANCH_LEGACY or branch > BRANCH_ENHANCED) then -- should never happen but who knows? sometimes I sabotage myself
	return
end

for _, batch in ipairs(mem_batches[branch]) do
	PatternScanner:Add(batch.name, batch.sig, batch.callback)
end

return GPointers
