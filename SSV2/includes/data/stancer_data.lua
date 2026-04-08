-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@alias ptr_read fun(w: CWheel): anyval

---@enum eWheelAxle
Enums.eWheelAxle = {
	FRONT = 1,
	REAR  = 2,
}

return {
	---@type array<{ key: string, wheel_side: eWheelAxle, read_func: ptr_read, write_func: fun(w: CWheel, v: anyval, veh?: PlayerVehicle), side_dont_care?: boolean}>
	decorators = {
		{
			key        = "m_camber",
			wheel_side = Enums.eWheelAxle.FRONT,
			read_func  = function(w) return w.m_y_rotation:get_float() end,
			write_func = function(w, v)
				w.m_y_rotation:set_float(v)
				w.m_y_rotation_inv:set_float(-v)
			end
		},
		{
			key        = "m_track_width",
			wheel_side = Enums.eWheelAxle.FRONT,
			read_func  = function(w) return w.m_x_offset:get_float() end,
			write_func = function(w, v) w.m_x_offset:set_float(v) end
		},
		{
			key            = "m_susp_comp",
			wheel_side     = Enums.eWheelAxle.FRONT,
			side_dont_care = true,
			read_func      = function(w) return w.m_suspension_forward_offset:get_float() end,
			write_func     = function(w, v) w.m_suspension_forward_offset:set_float(v) end
		},
		{
			key            = "m_wheel_width",
			wheel_side     = Enums.eWheelAxle.FRONT, -- doesn't matter
			side_dont_care = true,
			read_func      = function(w) return w.m_tyre_width:get_float() end,
			write_func     = function(w, v, veh)
				w.m_tyre_width:set_float(v)
				local cached = Decorator:GetDecor(veh:GetHandle(), "m_visual_width")
				if (cached and cached > 0 and veh:GetVisualWheelWidth() ~= cached + v) then
					veh:SetVisualWheelWidth(cached + v)
				end
			end
		},
		{
			key            = "m_wheel_size",
			wheel_side     = Enums.eWheelAxle.FRONT, -- doesn't matter
			side_dont_care = true,
			read_func      = function(w) return w.m_tyre_radius:get_float() end,
			write_func     = function(w, v, veh)
				w.m_tyre_radius:set_float(v)
				local cached = Decorator:GetDecor(veh:GetHandle(), "m_visual_size")
				if (cached and cached > 0 and veh:GetVisualWheelSize() ~= cached + v) then
					veh:SetVisualWheelSize(cached + v)
				end
			end
		},
		{
			key        = "m_camber",
			wheel_side = Enums.eWheelAxle.REAR,
			read_func  = function(w) return w.m_y_rotation:get_float() end,
			write_func = function(w, v)
				w.m_y_rotation:set_float(v)
				w.m_y_rotation_inv:set_float(-v)
			end
		},
		{
			key        = "m_track_width",
			wheel_side = Enums.eWheelAxle.REAR,
			read_func  = function(w) return w.m_x_offset:get_float() end,
			write_func = function(w, v) w.m_x_offset:set_float(v) end
		},
		{
			key            = "m_susp_comp",
			wheel_side     = Enums.eWheelAxle.REAR,
			side_dont_care = true,
			read_func      = function(w) return w.m_suspension_forward_offset:get_float() end,
			write_func     = function(w, v) w.m_suspension_forward_offset:set_float(v) end
		},
	}
}
