-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eWheelConfigFlags
local eWheelConfigFlags <const> = {
	BIKE_WHEEL                   = 0,
	LEFT_WHEEL                   = 1,
	REAR_WHEEL                   = 2,
	STEERED                      = 3, -- this can be used to immediately render steering when changing steering mode in the handling editor. We need to refactor handling editor to reflect vehicle memory instead of GVars
	POWERED                      = 4,
	TILT_INDEPENDENT             = 5,
	TILT_SOLID                   = 6,
	BIKE_CONSTRAINED_COLLIDER    = 7,
	BIKE_FALLEN_COLLIDER         = 8,
	INSTANCED                    = 9,
	DONT_RENDER_STEER            = 10, -- // somewhat similar
	UPDATE_SUSPENSION            = 11,
	QUAD_WHEEL                   = 12,
	HIGH_FRICTION_WHEEL          = 13,
	DONT_REDUCE_GRIP_ON_BURNOUT  = 14,
	IS_PHYSICAL                  = 15,
	BICYCLE_WHEEL                = 16,
	TRACKED_WHEEL                = 17,
	PLANE_WHEEL                  = 18,
	DONT_RENDER_HUB              = 19,
	SPOILER_MOD                  = 20, -- vehicle has a spoiler mod (increased grip)
	ROTATE_BOUNDS                = 21,
	EXTEND_ON_SUSPENSION_UPDATE  = 22, -- force wheels to extend on suspension update
	CENTER_WHEEL                 = 23, -- for three wheeled cars
	AMPHIBIOUS_WHEEL             = 24,
	RENDER_WITH_ZERO_COMPRESSION = 25
}

return eWheelConfigFlags
