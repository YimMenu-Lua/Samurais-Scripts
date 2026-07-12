-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.
--
-- Converted from Yimura's C++ GTA V Classes: https://github.com/Yimura/GTAV-Classes (forked here: https://github.com/Mr-X-GTA/GTAV-Classes-1)


local atArray           = require("includes.classes.gta.atArray")
local CHandlingData     = require("includes.classes.gta.CHandlingData")
local CEntity           = require("includes.classes.gta.CEntity")
local CVehicleDrawData  = require("includes.classes.gta.CVehicleDrawData")
local CVehicleModelInfo = require("includes.classes.gta.CVehicleModelInfo")
local CTransmission     = require("includes.classes.gta.CTransmission")
local CWheel            = require("includes.classes.gta.CWheel")
local fMatrix44         = require("includes.classes.gta.fMatrix44")
local phFragInst        = require("includes.classes.gta.phFragInst")


---@class CAdvancedData
---@class CVehicleDamage


--------------------------------------
-- Class: CVehicle
--------------------------------------
---@ignore
---@class CVehicle : CEntity
---@field protected m_ptr pointer
---@field public m_draw_data CVehicleDrawData
---@field public m_handling_data CHandlingData
---@field public m_model_info CVehicleModelInfo
---@field public m_vehicle_damage pointer<CVehicleDamage>
---@field public m_can_boost_jump pointer<byte> `bool`
---@field public m_velocity pointer<vec3>
---@field public m_transmission CTransmission
---@field public m_deform_god pointer<uint8_t>
---@field public m_frag_inst phFragInst 0x09C0 `fragInstGTA`
---@field public m_turbo pointer<float>
---@field public m_water_damage pointer<uint32_t>
---@field public m_engine_health pointer<float>
---@field public m_steering_input pointer<float> 0x00D4 name might not correctly reflect what this actually is but this seems to store controller input (value is between 1.0 (left) .. -1.0 (right))
---@field public m_steering_angle pointer<float> 0x00DC // steering angle? // the same max value that this member can reach is the same value that YimMenu shows in the handling editor tab so yes, this is indeed the current steering angle.
---@field public m_throttle_power pointer<float> m_steering_angle + 0x8
---@field public m_brake_power pointer<float>
---@field public m_is_targetable pointer<byte> `bool`
---@field public m_door_lock_status pointer<uint32_t>
---@field public m_wheels atArray<CWheel> 0x0C30
---@field public m_num_wheels integer array start + 8 so atArray.m_size
---@field public m_ride_height pointer<float>
---@field private DumpFlags fun(self: CVehicle, enum_flags: Enum, get_func: fun(self: CVehicle, flag: integer): boolean): nil
---@overload fun(vehicle: integer): CVehicle|nil
local CVehicle = Class("CVehicle", { parent = CEntity, symbolic_size = 0xC40 })

---@param vehicle handle
---@return CVehicle
function CVehicle:init(vehicle)
	if (not ENTITY.IS_ENTITY_A_VEHICLE(vehicle)) then
		error("Invalid entity!")
	end

	local base                  = CEntity(vehicle)
	local ptr                   = base:GetPointer()
	local instance              = setmetatable(base, self) ---@cast instance CVehicle
	instance.m_model_info       = CVehicleModelInfo(ptr:add(0x0020):deref())
	instance.m_draw_data        = CVehicleDrawData(ptr:add(0x0048):deref())
	instance.m_turbo            = ptr:add(0x007C)
	instance.m_water_damage     = ptr:add(0x00D8)
	instance.m_can_boost_jump   = ptr:add(0x03A4)
	instance.m_vehicle_damage   = ptr:add(0x0420)
	instance.m_velocity         = ptr:add(0x07D0)
	instance.m_transmission     = CTransmission(ptr:add(0x0880))
	instance.m_engine_health    = ptr:add(0x0910)
	instance.m_handling_data    = CHandlingData(ptr:add(0x0960):deref(), instance.m_model_info:GetVehicleType())
	instance.m_deform_god       = ptr:add(0x096C)
	instance.m_frag_inst        = phFragInst(ptr:add(0x09C0):deref())
	instance.m_steering_input   = ptr:add(0x09D4)
	instance.m_steering_angle   = ptr:add(0x09DC)
	instance.m_throttle_power   = ptr:add(0x09E4)
	instance.m_brake_power      = ptr:add(0x09E8)
	instance.m_is_targetable    = ptr:add(0x0AEE)

	local array_ptr             = ptr:add(0x0C30)
	instance.m_wheels           = atArray(array_ptr, CWheel)
	instance.m_num_wheels       = array_ptr:add(0x8):get_int()
	instance.m_ride_height      = array_ptr:deref():add(0x007C)

	instance.m_door_lock_status = ptr:add(0x13D0)

	return instance
end

---@return eVehicleType
function CVehicle:GetVehicleType()
	return self:__safecall(Enums.eVehicleType.VEHICLE_TYPE_NONE, function()
		return self.m_model_info:GetVehicleType()
	end)
end

---@return float
function CVehicle:GetAcceleration()
	return self:__safecall(0, function()
		return self.m_handling_data:GetAcceleration()
	end)
end

---@return float
function CVehicle:GetDeformMultiplier()
	return self:__safecall(0.0, function()
		return self.m_handling_data:GetDeformMultiplier()
	end)
end

---@return pointer<(CCarHandlingData|CBikeHandlingData|CFlyingHandlingData)?>
function CVehicle:GetSubHandlingData()
	return self.m_handling_data:GetSubHandlingData()
end

function CVehicle:GetHandlingFlags()
	return self.m_handling_data:GetHandlingFlags()
end

---@param flag eVehicleHandlingFlags
---@return boolean
function CVehicle:GetHandlingFlag(flag)
	return self:__safecall(false, function()
		return self.m_handling_data:GetHandlingFlag(flag)
	end)
end

---@return uint32_t
function CVehicle:GetModelFlags()
	return self.m_handling_data:GetModelFlags()
end

---@param flag eVehicleModelFlags
---@return boolean
function CVehicle:GetModelFlag(flag)
	return self.m_handling_data:GetModelFlag(flag)
end

---@return { [1]: uint32_t, [2]: uint32_t, [3]: uint32_t, [4]: uint32_t, [5]: uint32_t, [6]: uint32_t, [7]: uint32_t }
function CVehicle:GetModelInfoFlags()
	return self.m_model_info:GetModelInfoFlags()
end

---@param flag eVehicleModelInfoFlags
---@return boolean
function CVehicle:GetModelInfoFlag(flag)
	return self.m_model_info:GetModelInfoFlag(flag)
end

---@return uint32_t
function CVehicle:GetAdvancedFlags()
	if (not self:IsValid()) then return 0 end

	if (self:GetVehicleType() ~= Enums.eVehicleType.VEHICLE_TYPE_CAR) then
		return 0
	end

	---@type CCarHandlingData?
	local cchd = self:GetSubHandlingData()
	if (not cchd or not cchd:IsValid()) then
		return 0
	end

	return cchd.m_advanced_flags:get_dword()
end

---@param flag eVehicleAdvancedFlags
---@return boolean
function CVehicle:GetAdvancedFlag(flag)
	return Bit.IsBitSet(self:GetAdvancedFlags(), flag)
end

---@param flags uint32_t
---@return boolean
function CVehicle:SetHandlingFlags(flags)
	return self:__safecall(false, function()
		return self.m_handling_data:SetHandlingFlags(flags)
	end)
end

---@param flag eVehicleHandlingFlags
---@param toggle boolean
function CVehicle:SetHandlingFlag(flag, toggle)
	return self:__safecall(false, function()
		return self.m_handling_data:SetHandlingFlag(flag, toggle)
	end)
end

---@param value float
---@return boolean success
function CVehicle:SetAcceleration(value)
	return self.m_handling_data:SetAcceleration(value)
end

---@param value float
---@return boolean success
function CVehicle:SetDeformMultiplier(value)
	return self.m_handling_data:SetDeformMultiplier(value)
end

---@param flags uint32_t
---@return boolean success
function CVehicle:SetModelFlags(flags)
	return self.m_handling_data:SetModelFlags(flags)
end

---@param flag eVehicleModelInfoFlags
---@param toggle boolean
---@return boolean success
function CVehicle:SetModelFlag(flag, toggle)
	return self.m_handling_data:SetModelFlag(flag, toggle)
end

---@param flags uint32_t
function CVehicle:SetModelInfoFlags(flags)
	self.m_model_info:SetModelInfoFlags(flags)
end

---@param flag eVehicleModelInfoFlags
---@param toggle boolean
function CVehicle:SetModelInfoFlag(flag, toggle)
	self.m_model_info:SetModelInfoFlag(flag, toggle)
end

---@param flags uint32_t
function CVehicle:SetAdvancedFlags(flags)
	if (not self:IsValid()) then
		return
	end

	if (self:GetVehicleType() ~= Enums.eVehicleType.VEHICLE_TYPE_CAR) then
		return
	end

	---@type CCarHandlingData?
	local cchd = self:GetSubHandlingData()
	if (not cchd or not cchd:IsValid()) then
		return false
	end

	cchd.m_advanced_flags:set_dword(flags)
end

---@param flag eVehicleAdvancedFlags
---@param toggle boolean
function CVehicle:SetAdvancedFlag(flag, toggle)
	if (not self:IsValid()) then return end

	if (self:GetVehicleType() ~= Enums.eVehicleType.VEHICLE_TYPE_CAR) then
		return
	end

	---@type CCarHandlingData?
	local cchd = self:GetSubHandlingData()
	if (not cchd or not cchd:IsValid()) then
		return
	end

	local new_bits = Bit.Toggle(self:GetAdvancedFlags(), flag, toggle)
	cchd.m_advanced_flags:set_dword(new_bits)
end

---@private
---@param enum_flags Enum
---@param get_func fun(self: CVehicle, flag: integer): boolean
function CVehicle:DumpFlags(enum_flags, get_func)
	if (not self:IsValid()) then
		log.warning("Invalid vehicle pointer!")
		return
	end

	---@type array<string>
	local out = {}
	for name, flag in pairs(enum_flags) do
		if (get_func(self, flag)) then
			out[#out + 1] = _F("%s (1 << %d)", name, flag)
		end
	end

	if (#out == 0) then
		out[1] = "No enabled flags."
	end

	print(out)
end

-- Prints all enabled handling flags to console.
function CVehicle:DumpHandlingFlags()
	self:DumpFlags(Enums.eVehicleHandlingFlags, self.GetHandlingFlag)
end

-- Prints all enabled model flags to console.
function CVehicle:DumpModelFlags()
	self:DumpFlags(Enums.eVehicleModelFlags, self.GetModelFlag)
end

-- Prints all enabled model info flags to console.
function CVehicle:DumpModelInfoFlags()
	self:DumpFlags(Enums.eVehicleModelInfoFlags, self.GetModelInfoFlag)
end

-- Prints all enabled advanced flags to console.
function CVehicle:DumpAdvancedFlags()
	self:DumpFlags(Enums.eVehicleAdvancedFlags, self.GetAdvancedFlag)
end

---@param boneIndex integer
---@return fMatrix44
function CVehicle:GetBoneMatrix(boneIndex)
	local ph_frag_inst = self.m_frag_inst
	if not ph_frag_inst then
		return fMatrix44:zero()
	end

	local ptr = ph_frag_inst:GetMatrixPtr(boneIndex)
	if not (ptr and ptr:is_valid()) then
		return fMatrix44:zero()
	end

	return ptr:get_matrix44()
end

---@param boneIndex integer
---@param matrix fMatrix44
function CVehicle:SetBoneMatrix(boneIndex, matrix)
	local ph_frag_inst = self.m_frag_inst
	if not ph_frag_inst then
		return
	end

	local ptr = ph_frag_inst:GetMatrixPtr(boneIndex)
	if not (ptr and ptr:is_valid()) then
		return
	end

	ptr:set_matrix44(matrix)
end

---@param boneIndex integer
---@param scalar vec3
function CVehicle:ScaleBoneMatrix(boneIndex, scalar)
	local matrix = self:GetBoneMatrix(boneIndex)
	local new_matrix = fMatrix44:scale(scalar) * matrix
	Backend:debug("new matrix %s", new_matrix)

	self:SetBoneMatrix(boneIndex, new_matrix)
end

---@param boneIndex integer
---@param axis vec3
---@param angle float
function CVehicle:RotateBoneMatrix(boneIndex, axis, angle)
	local matrix = self:GetBoneMatrix(boneIndex)
	local scale = vec3:new(1, 1, 1)
	local new_matrix = fMatrix44:scale(scale) * fMatrix44:rotate(axis, angle) * matrix

	self:SetBoneMatrix(boneIndex, new_matrix)
end

---@param wheelIndex integer
---@return boolean
function CVehicle:IsWheelBrokenOff(wheelIndex)
	-- if (not self:IsValid()) then
	-- 	return false
	-- end

	-- local cwheel = self:GetWheel(wheelIndex)
	-- if (not cwheel) then
	-- 	return false
	-- end

	-- return cwheel:GetDynamicFlag(Enums.eWheelDynamicFlags.BROKEN_OFF)
	return self:__safecall(false, function()
		-- Thanks tupoy-ya
		return (self.m_ptr:add(0xA98):get_dword() >> (wheelIndex & 0x1F) & 1) ~= 0
	end)
end

---@return CWheel?
function CVehicle:GetWheel(index)
	if (not self:IsValid() or index > self.m_num_wheels) then
		return
	end

	local ptr = self.m_wheels:At(index)
	if (not ptr or ptr:is_null()) then
		return
	end

	return CWheel(ptr:deref())
end

---@return CWheelDrawData
function CVehicle:GetWheelDrawData()
	return self.m_draw_data:GetWheelDrawData()
end

---@return float -- Wheel width or 0.f if invalid
function CVehicle:GetWheelWidth()
	return self.m_draw_data:GetWheelWidth()
end

---@return float -- Wheel size or 0.f if invalid
function CVehicle:GetWheelSize()
	return self.m_draw_data:GetWheelSize()
end

---@param fValue float
function CVehicle:SetWheelWidth(fValue)
	self.m_draw_data:SetWheelWidth(fValue)
end

---@param fValue float
function CVehicle:SetWheelSize(fValue)
	self.m_draw_data:SetWheelSize(fValue)
end

function CVehicle:HasWheelDrawData()
	return self.m_draw_data:GetWheelDrawData():IsValid()
end

---@param fHeight float positive = lower, negative = higher. should use values between `-0.1` and `0.1`
---@return boolean
function CVehicle:SetRideHeight(fHeight)
	return self:__safecall(false, function()
		if (type(fHeight) ~= "number") then
			return false
		end

		self.m_ride_height:set_float(fHeight)
		return true
	end)
end

return CVehicle
