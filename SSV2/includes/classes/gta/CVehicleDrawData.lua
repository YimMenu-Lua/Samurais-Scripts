-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local fwDrawData = require("includes.classes.gta.fwDrawData")

---@class CWheelDrawData
---@field m_ptr pointer
---@field m_wheel_size pointer<float> // 0x008 -- this seems to hold a float value equal to `CWheel.m_tire_radius * 2` and affects all 4 wheels
---@field m_wheel_width pointer<float> // 0xBA0 -- this one is weird. the value is a little less that `CWheel.m_tire_width * 2` on 5 different cars and a little more on the Adder. Also affects all 4 wheels
local CWheelDrawData = {}
CWheelDrawData.__index = CWheelDrawData

---@param ptr pointer
---@return CWheelDrawData
function CWheelDrawData.new(ptr)
	return setmetatable({
		m_ptr = ptr,
		m_wheel_size = ptr:add(0x008),
		m_wheel_width = ptr:add(0xBA0),
	}, CWheelDrawData)
end

function CWheelDrawData:IsValid()
	return self.m_ptr and self.m_ptr:is_valid()
end

---@class CVehicleDrawData : fwDrawData
---@field m_wheel_draw_data CWheelDrawData
---@overload fun(ptr: pointer): CVehicleDrawData
local CVehicleDrawData = Class("CVehicleDrawData", fwDrawData)

---@param ptr pointer
---@return CVehicleDrawData
function CVehicleDrawData:init(ptr)
	self.m_ptr = ptr
	-- This will be null if the vehicle has stock wheels.
	self.m_wheel_draw_data = CWheelDrawData.new(ptr:add(0x370):deref())
	return self
end

---@param refresh? boolean
function CVehicleDrawData:GetWheelDrawData(refresh)
	if (refresh) then
		self.m_wheel_draw_data = nil
	end

	if not (self.m_wheel_draw_data and self.m_wheel_draw_data:IsValid()) then
		self.m_wheel_draw_data = CWheelDrawData.new(self.m_ptr:add(0x370):deref())
	end

	-- cached pointer gets invalidated when you change wheels?
	return self.m_wheel_draw_data
end

---@return float -- Wheel width or 0.f if invalid
function CVehicleDrawData:GetWheelWidth()
	local cwdd = self:GetWheelDrawData()
	if (not cwdd:IsValid()) then
		return 0.0
	end

	return cwdd.m_wheel_width:get_float()
end

---@return float -- Wheel size or 0.f if invalid
function CVehicleDrawData:GetWheelSize()
	local cwdd = self:GetWheelDrawData()
	if (not cwdd:IsValid()) then
		return 0.0
	end

	return cwdd.m_wheel_size:get_float()
end

---@param fValue float
function CVehicleDrawData:SetWheelWidth(fValue)
	local cwdd = self:GetWheelDrawData()
	if (not cwdd:IsValid()) then
		return
	end

	cwdd.m_wheel_width:set_float(fValue)
end

---@param fValue float
function CVehicleDrawData:SetWheelSize(fValue)
	local cwdd = self:GetWheelDrawData()
	if (not cwdd:IsValid()) then
		return
	end

	cwdd.m_wheel_size:set_float(fValue)
end

return CVehicleDrawData
