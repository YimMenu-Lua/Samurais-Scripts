-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: param-type-mismatch

local CPed        = require("includes.classes.gta.CPed")
local CVehicle    = require("includes.classes.gta.CVehicle")
local MemoryPatch = require("includes.structs.MemoryPatch")


---@class PatchData
---@field name string
---@field onEnable fun(patch: MemoryPatch, ...): any
---@field onDisable fun(patch: MemoryPatch, ...): any

--------------------------------------
-- Class: Memory
--------------------------------------
---@class Memory : ClassMeta<Memory>
---@field private m_patches table<Obj, table<string, MemoryPatch>>
---@field protected m_initialized boolean
---@overload fun(): Memory
local Memory = Class("Memory")

---@return Memory
function Memory:init()
	if (self.m_initialized) then
		log.warning("Attempt to create a second instance of a singleton (Memory)")
		return self
	end

	self.m_patches = {}

	Backend:RegisterEventCallbackAll(function()
		self:RestoreAllPatches()
	end)

	self.m_initialized = true
	return self
end

-- Since PatternScanner runs in a fiber, we can't get pointer values on file load.
local function SafeGetVersion()
	if (GPointers.GameVersion.build:isempty()) then
		local ptr, b, o
		if (Backend:GetAPIVersion() == Enums.eAPIVersion.V1) then
			ptr = memory.scan_pattern("8B C3 33 D2 C6 44 24 20")
			b = ptr:add(0x24):rip()
			o = b:add(0x20)
		else
			ptr = memory.scan_pattern("4C 8D 0D ? ? ? ? 48 8D 5C 24 ? 48 89 D9 48 89 FA")
			b = ptr:add(0x3):rip()
			o = ptr:add(0x47):add(0x3):rip()
		end

		GPointers.GameVersion = {
			build  = b:get_string(),
			online = o:get_string()
		}
	end

	return GPointers.GameVersion
end

---@return VersionInfo
function Memory:GetGameVersion()
	return SafeGetVersion()
end

---@return byte
function Memory:GetGameState()
	if GPointers.GameState:is_null() then
		return 0
	end

	return GPointers.GameState:get_byte()
end

---@return uint32_t
function Memory:GetGameTime()
	if GPointers.GameTime:is_null() then
		return 0
	end

	return GPointers.GameTime:get_dword()
end

---@return vec2
function Memory:GetScreenResolution()
	return GPointers.ScreenResolution
end

---@param owner Obj
---@param data PatchData
---@param apply? boolean
function Memory:AddPatch(owner, data, apply)
	if (not self.m_patches[owner]) then
		self.m_patches[owner] = {}
	end

	if (self.m_patches[owner][data.name]) then
		return
	end

	local patch = MemoryPatch.new(data.name, data.onEnable, data.onDisable)
	self.m_patches[owner][data.name] = patch

	if (apply) then
		patch:Apply()
	end
end

---@param owner Obj
---@param patchName string
function Memory:RemovePatch(owner, patchName)
	local _t = self.m_patches[owner]
	if (_t and _t[patchName]) then
		_t[patchName]:Restore()
		_t[patchName] = nil
	end
end

---@generic T
---@param owner Obj
---@param patchName string
---@return T
function Memory:ApplyPatch(owner, patchName)
	local _t = self.m_patches[owner]
	if (not _t) then
		return nil
	end

	local patch = _t[patchName]
	if (not patch or patch:IsEnabled()) then
		return nil
	end

	return patch:Apply()
end

---@generic T
---@param owner Obj
---@param patchName string
---@param clear? boolean Optional: remove after restoring
---@return T
function Memory:RestorePatch(owner, patchName, clear)
	local _t = self.m_patches[owner]
	if (not _t) then
		return nil
	end

	local patch = _t[patchName]
	if (not patch) then
		return nil
	end

	local res = patch:Restore()

	if (clear) then
		_t[patchName] = nil
	end

	return res
end

---@param owner Obj
---@param clear? boolean
function Memory:RestoreAllPatchesByRef(owner, clear)
	local batch = self.m_patches[owner]
	if (not batch) then
		return
	end

	for _, patch in pairs(batch) do
		patch:Restore()
	end

	if (clear) then
		table.erase_if(batch, function(_, v)
			return v:IsDisabled()
		end)
	end
end

---@param clear? boolean
function Memory:RestoreAllPatches(clear)
	for _, batch in pairs(self.m_patches) do
		for _, patch in pairs(batch) do
			patch:Restore()
		end
	end

	if (clear) then
		self.m_patches = {}
	end
end

---@return table<Obj, table<string, MemoryPatch>>
function Memory:ListPatches()
	return self.m_patches
end

-- Theory: Get a pattern for a script global -> scan it -> get the address and pass it to this function -> get the index.
--
-- We can even directly wrap the return in a `ScriptGlobal` instance, essentially no longer needing to update script globals after game updates.
--
-- Useful if I figure out a way to make strong patterns for script globals.
---@param addr integer
---@return integer -- Script global index. Example: 262145
function Memory:GlobalIndexFromAddress(addr)
	local sg_base = GPointers.ScriptGlobals
	if (sg_base:is_null()) then
		log.warning("Script Globals base pointer is null!")
		return 0
	end

	for page = 0, 63 do
		local page_ptr = sg_base:add(page * 0x8):get_qword()
		if (page_ptr ~= 0) then
			local offset = addr - page_ptr
			if (offset >= 0 and offset < 0x3FFFF * 0x8 and offset % 0x8 == 0) then
				return (page << 0x12) | (offset // 8)
			end
		end
	end

	return 0
end

---@param vehicle integer vehicle handle
---@return CVehicle|nil
function Memory:GetVehicleInternal(vehicle)
	return CVehicle(vehicle)
end

---@param ped handle A Ped ID, not a Player ID.
---@return CPed|nil
function Memory:GetPedInternal(ped)
	return CPed(ped)
end

-- Checks if a vehicle's handling flag is set. It is recommended to use the `Vehicle` module instead since it caches the CVehicle instance.
--
-- This is only useful if you want to quickly get/set a flag once and don't need a `Vehicle` instance.
---@param vehicle handle
---@param flag eVehicleHandlingFlags
---@return boolean
function Memory:GetVehicleHandlingFlag(vehicle, flag)
	if not (ENTITY.DOES_ENTITY_EXIST(vehicle) or ENTITY.IS_ENTITY_A_VEHICLE(vehicle)) then
		return false
	end

	local cvehicle = self:GetVehicleInternal(vehicle)
	if (not cvehicle) then
		return false
	end

	local m_handling_flags = cvehicle.m_handling_flags
	if m_handling_flags:is_null() then
		return false
	end

	return Bit.IsBitSet(m_handling_flags:get_dword(), flag)
end

-- Checks if a vehicle's model info flag is set. It is recommended to use the `Vehicle` module instead since it caches the CVehicle instance.
--
-- This is only useful if you want to quickly get/set a flag once and don't need a `Vehicle` instance.
---@param vehicle handle
---@param flag eVehicleModelFlags
---@return boolean
function Memory:GetVehicleModelInfoFlag(vehicle, flag)
	local cvehicle = self:GetVehicleInternal(vehicle)
	if (not cvehicle) then
		return false
	end

	local base_ptr = cvehicle.m_model_info_flags
	if base_ptr:is_null() then
		return false
	end

	local index    = math.floor(flag / 32)
	local bitPos   = flag % 32
	local flag_ptr = base_ptr:add(index * 4)
	local dword    = flag_ptr:get_dword()

	return Bit.IsBitSet(dword, bitPos)
end

-- Unsafe for non-scripted entities.
--
-- Returns the model type of an entity (ped, object, vehicle, MLO, time, etc...)
---@param entity handle
---@return eModelType
function Memory:GetEntityModelType(entity)
	if (not ENTITY.DOES_ENTITY_EXIST(entity)) then
		return Enums.eModelType.Invalid
	end

	local isMemSafe, entityType = pcall(function()
		local pEntity = memory.handle_to_ptr(entity)
		if (pEntity:is_null()) then
			return Enums.eModelType.Invalid
		end

		local m_model_info = pEntity:add(0x0020):deref()
		local m_model_type = m_model_info:add(0x009D)
		return m_model_type:get_word() & 0x1F
	end)

	return isMemSafe and entityType or Enums.eModelType.Invalid
end

--[[
---@ignore
---@unused
---@param dword integer
function Memory:SetWeaponEffectGroup(dword)
	local pedPtr = memory.handle_to_ptr(self.get_ped())
	if pedPtr:is_valid() then
	    local CPedWeaponManager = pedPtr:add(0x10B8):deref()
	    local CWeaponInfo       = CPedWeaponManager:add(0x0020):deref()
	    local sWeaponFx         = CWeaponInfo:add(0x0170)
	    local eEffectGroup      = sWeaponFx:add(0x00) -- int32_t
	    eEffectGroup:set_dword(dword)
	end
end
--]]

require("includes.modules.Game")
return Memory()
