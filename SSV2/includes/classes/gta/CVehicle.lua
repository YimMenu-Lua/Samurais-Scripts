-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local atArray           = require("includes.classes.gta.atArray")
local CHandlingData     = require("includes.classes.gta.CHandlingData")
local CEntity           = require("includes.classes.gta.CEntity")
local CVehicleDrawData  = require("includes.classes.gta.CVehicleDrawData")
local CVehicleModelInfo = require("includes.classes.gta.CVehicleModelInfo")
local CWheel            = require("includes.classes.gta.CWheel")
local fMatrix44         = require("includes.classes.gta.fMatrix44")
local phFragInst        = require("includes.classes.gta.phFragInst")
local CCarHandlingData  = require("includes.classes.gta.CCarHandlingData")


---@class CAdvancedData
---@class CVehicleDamage


--------------------------------------
-- Class: CVehicle
--------------------------------------
---@ignore
---@class CVehicle : CEntity
---@field protected m_ptr pointer
---@field public m_physics_fragments phFragInst //0x30 `struct rage::phFragInst`
---@field public m_draw_data CVehicleDrawData
---@field public m_handling_data CHandlingData
---@field public m_model_info CVehicleModelInfo
---@field public m_vehicle_damage pointer<CVehicleDamage>
---@field public m_car_handling_data pointer<CCarHandlingData>?
---@field public m_can_boost_jump pointer<byte> `bool`
---@field public m_velocity pointer<vec3>
---@field public m_deform_god pointer<uint8_t>
---@field public m_water_damage pointer<uint32_t>
---@field public m_next_gear pointer<int16_t>
---@field public m_current_gear pointer<int16_t>
---@field public m_top_gear pointer<int8_t>
---@field public m_engine_health pointer<float>
---@field public m_steering_input pointer<float> // 0xD4 name might not correctly reflect what this actually is but this seems to store controller input (value is between 0.99 (left) .. -0.99 (right))
---@field public m_current_steering pointer<float> 0xDC // actual wheel steer. Wr'll use it to rewrite last known wheel steer after exiting a vehicle in IV-Style Exit so we'll no longer need to teleport outside or patch CTaskVehicleExit
---@field public m_is_targetable pointer<byte> `bool`
---@field public m_door_lock_status pointer<uint32_t>
---@field public m_wheels atArray<CWheel> -- 0xC30
---@field public m_num_wheels number -- 0xC38
---@field public m_ride_height pointer<float>
---@field private DumpFlags fun(self: CVehicle, enum_flags: Enum, get_func: fun(self: CVehicle, flag: integer): boolean): nil
---@overload fun(vehicle: integer): CVehicle|nil
local CVehicle = Class("CVehicle", { parent = CEntity, symbolic_size = 0xC40 })

---@param vehicle handle
---@return CVehicle
function CVehicle:init(vehicle)
	if (not Game.IsScriptHandle(vehicle) or not ENTITY.IS_ENTITY_A_VEHICLE(vehicle)) then
		error("Invalid entity!")
	end

	---@type CVehicle
	---@diagnostic disable-next-line: param-type-mismatch
	local instance = setmetatable({}, CVehicle)
	instance:super().init(instance, vehicle)

	local ptr                    = memory.handle_to_ptr(vehicle)
	instance.m_ptr               = ptr
	instance.m_model_info        = CVehicleModelInfo(ptr:add(0x20):deref())
	instance.m_vehicle_damage    = ptr:add(0x0420)
	instance.m_handling_data     = CHandlingData(ptr:add(0x0960):deref())
	instance.m_physics_fragments = phFragInst(ptr:add(0x0030):deref())
	instance.m_draw_data         = CVehicleDrawData(ptr:add(0x0048):deref())
	instance.m_can_boost_jump    = ptr:add(0x03A4)
	instance.m_velocity          = ptr:add(0x07D0)
	instance.m_deform_god        = ptr:add(0x096C)
	instance.m_is_targetable     = ptr:add(0x0AEE)
	instance.m_door_lock_status  = ptr:add(0x13D0)
	instance.m_water_damage      = ptr:add(0x00D8)
	instance.m_next_gear         = ptr:add(0x0880)
	instance.m_current_gear      = ptr:add(0x0882)
	instance.m_top_gear          = ptr:add(0x0886)
	instance.m_engine_health     = ptr:add(0x0910)
	instance.m_steering_input    = ptr:add(0x09D4)
	instance.m_current_steering  = ptr:add(0x09DC)

	local array_ptr              = ptr:add(0x0C30)
	instance.m_wheels            = atArray(array_ptr, CWheel)
	instance.m_num_wheels        = array_ptr:add(0x8):get_int()
	instance.m_ride_height       = array_ptr:deref():add(0x007C)

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

-- ---@param handlingType eHandlingType
-- ---@return CCarHandlingData|CBikeHandlingData|CFlyingHandlingData|any
-- function CVehicle:GetSubHandlingData(handlingType)
-- 	return self:__safecall(nil, function()
-- 		return self.m_handling_data:GetSubHandlingData(handlingType)
-- 	end)
-- end

---@return pointer<(CCarHandlingData|CBikeHandlingData|CFlyingHandlingData)?>
function CVehicle:GetSubHandlingData()
	return self:__safecall(nil, function()
		return self.m_handling_data:GetSubHandlingData()
	end)
end

---@param flag eVehicleHandlingFlags
---@return boolean
function CVehicle:GetHandlingFlag(flag)
	return self:__safecall(false, function()
		return self.m_handling_data:GetHandlingFlag(flag)
	end)
end

---@param flag eVehicleModelFlags
---@return boolean
function CVehicle:GetModelFlag(flag)
	return self:__safecall(false, function()
		return self.m_handling_data:GetModelFlag(flag)
	end)
end

---@param flag eVehicleModelInfoFlags
---@return boolean
function CVehicle:GetModelInfoFlag(flag)
	return self:__safecall(false, function()
		return self.m_model_info:GetModelInfoFlag(flag)
	end)
end

---@param flag eVehicleAdvancedFlags
---@return boolean
function CVehicle:GetAdvancedFlag(flag)
	if (not self:IsValid()) then
		return false
	end

	if (self:GetVehicleType() ~= Enums.eVehicleType.VEHICLE_TYPE_CAR) then
		return false
	end

	local ptr = self:GetSubHandlingData()
	if (not ptr or ptr:is_null()) then
		return false
	end

	---@type CCarHandlingData?
	local cchd = CCarHandlingData(ptr)
	if (not cchd or not cchd:IsValid()) then
		return false
	end

	local dword_flags = cchd.m_advanced_flags:get_dword()
	return Bit.IsBitSet(dword_flags, flag)
end

---@param flag eVehicleHandlingFlags
---@param toggle boolean
function CVehicle:SetHandlingFlag(flag, toggle)
	return self:__safecall(false, function()
		return self.m_handling_data:SetHandlingFlag(flag, toggle)
	end)
end

---@param value float
---@return boolean
function CVehicle:SetAcceleration(value)
	return self:__safecall(false, function()
		return self.m_handling_data:SetAcceleration(value)
	end)
end

---@param value float
---@return boolean
function CVehicle:SetDeformMultiplier(value)
	return self:__safecall(false, function()
		return self.m_handling_data:SetDeformMultiplier(value)
	end)
end

---@param flag eVehicleModelInfoFlags
---@param toggle boolean
function CVehicle:SetModelInfoFlag(flag, toggle)
	self.m_model_info:SetModelInfoFlag(flag, toggle)
end

---@param flag eVehicleAdvancedFlags
---@param toggle boolean
function CVehicle:SetAdvancedFlag(flag, toggle)
	if (not self:IsValid()) then
		return
	end

	if (self:GetVehicleType() ~= Enums.eVehicleType.VEHICLE_TYPE_CAR) then
		return
	end

	local ptr = self:GetSubHandlingData()
	if (not ptr or ptr:is_null()) then
		return
	end

	---@type CCarHandlingData?
	local cchd = CCarHandlingData(ptr)
	if (not cchd or not cchd:IsValid()) then
		return
	end

	local dword_flags = cchd.m_advanced_flags:get_dword()
	local new_bits    = Bit.Toggle(dword_flags, flag, toggle)
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
	local ph_frag_inst = self.m_physics_fragments
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
	local ph_frag_inst = self.m_physics_fragments
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

	return CWheel(ptr)
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
