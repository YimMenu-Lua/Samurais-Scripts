-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Decorator  = require("includes.modules.Decorator")

---@alias ptr_read fun(w: CWheel, veh?: PlayerVehicle): float

---@enum eWheelAxle
Enums.eWheelAxle = {
	FRONT = 1,
	REAR  = 2,
}

---@class StanceItem
---@field key string
---@field axle eWheelAxle
---@field read fun(w: CWheel, veh?: PlayerVehicle): float
---@field write fun(w: CWheel, v: float, veh?: PlayerVehicle)
---@field side_dont_care? boolean


return {
	---@type array<StanceItem>
	items = {
		{
			key   = "m_toe",
			axle  = Enums.eWheelAxle.FRONT,
			read  = function(w) return w.m_rotation_axis.y end,
			write = function(w, v) w.m_rotation_axis.y = v end
		},
		{
			key   = "m_camber",
			axle  = Enums.eWheelAxle.FRONT,
			read  = function(w) return w.m_rotation_axis.y end,
			write = function(w, v)
				w.m_rotation_axis.z = v
				w.m_constraint_axis.y = -v
			end
		},
		{
			key   = "m_track_width",
			axle  = Enums.eWheelAxle.FRONT,
			read  = function(w) return w.m_x_offset:get_float() end,
			write = function(w, v) w.m_x_offset:set_float(v) end
		},
		{
			key            = "m_susp_comp",
			axle           = Enums.eWheelAxle.FRONT,
			side_dont_care = true,
			read           = function(w) return w.m_rest_position_2:get_float() end,
			write          = function(w, v) w.m_rest_position_2:set_float(v) end
		},
		{
			key            = "m_wheel_width",
			axle           = Enums.eWheelAxle.FRONT, -- doesn't matter
			side_dont_care = true,
			read           = function() return 0 end,
			write          = function(_, v, veh)
				---@type float?
				local cached = Decorator:GetDecor(veh:GetHandle(), "m_visual_width")
				if (cached and cached > 0 and veh:GetVisualWheelWidth() ~= cached + v) then
					veh:SetVisualWheelWidth(cached + v)
				end
			end
		},
		{
			key            = "m_wheel_size",
			axle           = Enums.eWheelAxle.FRONT, -- doesn't matter
			side_dont_care = true,
			read           = function() return 0 end,
			write          = function(_, v, veh)
				---@type float?
				local cached = Decorator:GetDecor(veh:GetHandle(), "m_visual_size")
				if (cached and cached > 0 and veh:GetVisualWheelSize() ~= cached + v) then
					veh:SetVisualWheelSize(cached + v)
				end
			end
		},
		{
			key   = "m_toe",
			axle  = Enums.eWheelAxle.REAR,
			read  = function(w) return w.m_rotation_axis.y end,
			write = function(w, v) w.m_rotation_axis.y = v end
		},
		{
			key   = "m_camber",
			axle  = Enums.eWheelAxle.REAR,
			read  = function(w) return w.m_rotation_axis.z end,
			write = function(w, v)
				w.m_rotation_axis.z   = v
				w.m_constraint_axis.y = -v
			end
		},
		{
			key   = "m_track_width",
			axle  = Enums.eWheelAxle.REAR,
			read  = function(w) return w.m_x_offset:get_float() end,
			write = function(w, v) w.m_x_offset:set_float(v) end
		},
		{
			key            = "m_susp_comp",
			axle           = Enums.eWheelAxle.REAR,
			side_dont_care = true,
			read           = function(w) return w.m_rest_position_2:get_float() end,
			write          = function(w, v) w.m_rest_position_2:set_float(v) end
		},
	}
}
