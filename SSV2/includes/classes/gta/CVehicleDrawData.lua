-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: CWheelDrawData
--------------------------------------
---@class CWheelDrawData : CStructBase<CWheelDrawData>
---@field m_ptr pointer
---@field m_wheel_size pointer<float> // 0x008 -- this seems to hold a float value equal to `CWheel.m_tire_radius * 2` and affects all 4 wheels
---@field m_wheel_width pointer<float> // 0xBA0 -- this one is weird. the value is a little less that `CWheel.m_tire_width * 2` on 5 different cars and a little more on the Adder. Also affects all 4 wheels
local CWheelDrawData = CStructView("CWheelDrawData", 0xBA4)

---@param ptr pointer
---@return CWheelDrawData
function CWheelDrawData.new(ptr)
	return setmetatable({
		m_ptr         = ptr,
		m_wheel_size  = ptr:add(0x008),
		m_wheel_width = ptr:add(0xBA0),
	}, CWheelDrawData)
end

---@return float
function CWheelDrawData:GetWheelSize()
	return self:__safecall(0.0, function()
		return self.m_wheel_size:get_float()
	end)
end

---@return float
function CWheelDrawData:GetWheelWidth()
	return self:__safecall(0.0, function()
		return self.m_wheel_width:get_float()
	end)
end

---@param v float
---@return boolean
function CWheelDrawData:SetWheelSize(v)
	return self:__safecall(false, function()
		if (type(v) ~= "number") then
			return false
		end

		self.m_wheel_size:set_float(v)
		return true
	end)
end

---@param v float
---@return boolean
function CWheelDrawData:SetWheelWidth(v)
	return self:__safecall(false, function()
		if (type(v) ~= "number") then
			return false
		end

		self.m_wheel_width:set_float(v)
		return true
	end)
end

--------------------------------------
-- Class: CVehicleDrawData
--------------------------------------
---@class CVehicleDrawData
---@field m_wheel_draw_data pointer_ref<CWheelDrawData>
---@overload fun(ptr: pointer): CVehicleDrawData
local CVehicleDrawData = Class("CVehicleDrawData", { pointer_ctor = true })

---@param ptr pointer
---@return CVehicleDrawData
function CVehicleDrawData:init(ptr)
	return setmetatable({
		m_ptr = ptr,
		m_wheel_draw_data = ptr:add(0x370)
		---@diagnostic disable-next-line: param-type-mismatch
	}, CVehicleDrawData)
end

---@return CWheelDrawData
function CVehicleDrawData:GetWheelDrawData()
	return CWheelDrawData(self.m_wheel_draw_data:deref())
end

---@return float -- Wheel width or 0.f if invalid
function CVehicleDrawData:GetWheelWidth()
	return self:GetWheelDrawData():GetWheelWidth()
end

---@return float -- Wheel size or 0.f if invalid
function CVehicleDrawData:GetWheelSize()
	return self:GetWheelDrawData():GetWheelSize()
end

---@param fValue float
---@return boolean
function CVehicleDrawData:SetWheelWidth(fValue)
	return self:GetWheelDrawData():SetWheelWidth(fValue)
end

---@param fValue float
---@return boolean
function CVehicleDrawData:SetWheelSize(fValue)
	return self:GetWheelDrawData():SetWheelSize(fValue)
end

return CVehicleDrawData
