-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: CTransmission
--------------------------------------
---@class CTransmission
---@field public m_current_gear pointer<uint8_t>
---@field public m_previous_gear pointer<uint8_t>
---@field public m_top_gear pointer<uint8_t>
---@field public m_gear_ratios array<pointer<float>>
---@field public m_drive_force pointer<float>
---@field public m_drive_max_flat_velocity pointer<float>
---@field public m_drive_max_velocity pointer<float>
---@field public m_throttle_unk pointer<float> -- not sure what this does but I managed to force revs using only this offset. it worked once then stopped doing anything
---@field public m_rpm pointer<float>
---@field public m_rpm_2 pointer<float>
---@field public m_clutch pointer<float> cvehicle + 0x08D4
---@field public m_throttle pointer<float> these two might be flipped
---@field public m_throttle_input pointer<float> //
---@field public m_boost_pressure pointer<float> m_throttle_input + 16 ? TODO: fix this it's wrong. this keeps incrementing when throttle is held and resets to 0 when released. pressure does not infinitely accumulate but this does
---@overload fun(ptr: pointer): CTransmission
local CTransmission = CStructView("CTransmission")

---@param ptr pointer
---@return CTransmission
function CTransmission.new(ptr)
	---@diagnostic disable-next-line
	local instance                     = setmetatable({ m_ptr = ptr, }, CTransmission)
	instance.m_current_gear            = ptr:add(0x0000)
	instance.m_previous_gear           = ptr:add(0x0002)
	instance.m_top_gear                = ptr:add(0x0006)
	instance.m_drive_force             = ptr:add(0x0038)
	instance.m_drive_max_flat_velocity = ptr:add(0x003C)
	instance.m_drive_max_velocity      = ptr:add(0x0040)
	instance.m_throttle_unk            = ptr:add(0x0044)
	instance.m_rpm                     = ptr:add(0x0048)
	instance.m_rpm_2                   = ptr:add(0x004C)
	instance.m_clutch                  = ptr:add(0x0054)
	instance.m_throttle                = ptr:add(0x0058)
	instance.m_throttle_input          = ptr:add(0x0060)
	instance.m_boost_pressure          = ptr:add(0x0070)


	local gearRatios  = {} ---@type array<pointer<float>>
	local pArrayStart = ptr:add(0x000C)
	for i = 0, 10 do -- reverse + 10 fwd gears
		gearRatios[i + 1] = pArrayStart:add(i * 0x4)
	end
	instance.m_gear_ratios = gearRatios

	return instance
end

---@param gear uint8_t
---@return float
function CTransmission:GetRatioForGear(gear)
	local ptr = self.m_gear_ratios[gear + 1]
	if (not ptr or ptr:is_null()) then
		return 0.0
	end

	return ptr:get_float()
end

---@param gear uint8_t
---@param ratio float
function CTransmission:SetRatioForGear(gear, ratio)
	local ptr = self.m_gear_ratios[gear + 1]
	if (not ptr or ptr:is_null()) then return end
	ptr:set_float(ratio)
end

---@param gear uint8_t
---@return float
function CTransmission:GetMaxSpeedForGear(gear)
	local max_drive_vel = self.m_drive_max_velocity:get_float()
	local gear_ratio    = math.abs(self:GetRatioForGear(gear))
	if (gear_ratio == 0) then
		return 0.0
	end
	return max_drive_vel / gear_ratio
end

return CTransmission
