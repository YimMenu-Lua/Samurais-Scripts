---@diagnostic disable: param-type-mismatch

local CPed        = require("includes.classes.CPed")
local CVehicle    = require("includes.classes.CVehicle")
local MemoryPatch = require("includes.structs.MemoryPatch")


---@class PatchData
---@field name string
---@field onEnable fun(patch: MemoryPatch, ...): any
---@field onDisable fun(patch: MemoryPatch, ...): any

--------------------------------------
-- Class: Memory
--------------------------------------
---
--**Global Singleton.**
--
-- Handles most interactions with the game's memory.
---@class Memory : ClassMeta<Memory>
---@field private m_patches table<Obj, table<string, MemoryPatch>>
---@overload fun(_: any): Memory
local Memory = Class("Memory")

---@return Memory
function Memory:init()
	---@type Memory
	local instance = setmetatable({ m_patches = {} }, Memory)

	Backend:RegisterEventCallbackAll(function()
		instance:RestoreAllPatches()
	end)

	return instance
end

-- Since PatternScanner runs in a fiber, we can't get pointer values on file load.
local function SafeGetVersion()
	if (not GPointers.GameVersion) then
		local ptr = memory.scan_pattern("8B C3 33 D2 C6 44 24 20")
		local b = ptr:add(0x24):rip()
		local o = b:add(0x20)
		GPointers.GameVersion = {
			_build  = b:get_string(),
			_online = o:get_string()
		}
	end

	return GPointers.GameVersion
end

---@return { _build: string, _online: string }
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

---@param obj Obj
---@param data PatchData
---@param apply? boolean
function Memory:AddPatch(obj, data, apply)
	local patch = MemoryPatch.new(data.name, data.onEnable, data.onDisable)
	if (not self.m_patches[obj]) then
		self.m_patches[obj] = {}
	end

	if (self.m_patches[obj][data.name]) then
		self:RestorePatch(obj, data.name, true)
	end

	self.m_patches[obj][data.name] = patch

	if (apply) then
		patch:Apply()
	end
end

---@param obj Obj
---@param patchName string
function Memory:RemovePatch(obj, patchName)
	local _t = self.m_patches[obj]
	if (_t and _t[patchName]) then
		_t[patchName]:Restore()
		_t[patchName] = nil
	end
end

---@generic T
---@param obj Obj The object that owns the patch
---@param patchName string
---@return T
function Memory:ApplyPatch(obj, patchName)
	local _t = self.m_patches[obj]
	local res = nil

	if (_t and _t[patchName]) then
		res = _t[patchName]:Apply()
	end

	return res
end

---@generic T
---@param obj Obj The object that owns the patch
---@param patchName string
---@param remove? boolean Optional: remove after restoring
---@return T
function Memory:RestorePatch(obj, patchName, remove)
	local _t = self.m_patches[obj]
	local res = nil

	if (_t and _t[patchName]) then
		res = _t[patchName]:Restore()

		if (remove) then
			_t[patchName] = nil
		end
	end

	return res
end

---@param obj Obj
---@param remove? boolean
function Memory:RestoreAllPatchesByRef(obj, remove)
	local batch = self.m_patches[obj]
	if (not batch) then
		return
	end

	if (remove) then
		local names = {}
		for name, patch in pairs(batch) do
			patch:Restore()
			names[#names + 1] = name
		end

		for _, name in ipairs(names) do
			batch[name] = nil
		end
	else
		for _, patch in pairs(batch) do
			patch:Restore()
		end
	end
end

function Memory:RestoreAllPatches()
	for _, batch in pairs(self.m_patches) do
		for _, patch in pairs(batch) do
			patch:Restore()
		end
	end

	self.m_patches = {}
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
function Memory:GetVehicleInfo(vehicle)
	return CVehicle(vehicle)
end

---@param ped handle A Ped ID, not a Player ID.
---@return CPed|nil
function Memory:GetPedInfo(ped)
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

	local CVehicle = self:GetVehicleInfo(vehicle)
	if not CVehicle then
		return false
	end

	local m_handling_flags = CVehicle.m_handling_flags
	if m_handling_flags:is_null() then
		return false
	end

	return Bit.is_set(m_handling_flags:get_dword(), flag)
end

-- Checks if a vehicle's model info flag is set. It is recommended to use the `Vehicle` module instead since it caches the CVehicle instance.
--
-- This is only useful if you want to quickly get/set a flag once and don't need a `Vehicle` instance.
---@param vehicle handle
---@param flag eVehicleModelFlags
---@return boolean
function Memory:GetVehicleModelInfoFlag(vehicle, flag)
	local CVehicle = self:GetVehicleInfo(vehicle)
	if not CVehicle then
		return false
	end

	local base_ptr = CVehicle.m_model_info_flags
	if base_ptr:is_null() then
		return false
	end

	local index    = math.floor(flag / 32)
	local bitPos   = flag % 32
	local flag_ptr = base_ptr:add(index * 4)
	local dword    = flag_ptr:get_dword()

	return Bit.is_set(dword, bitPos)
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
		return m_model_type:get_word()
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
-- inline
return Memory()
