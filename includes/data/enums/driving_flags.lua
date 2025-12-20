---@enum eDrivingFlags
-- https://forge.plebmasters.de/vehicleflags?category=DrivingStyleFlags
local eDrivingFlags <const> = {
	STOP_FOR_VEHICLES                            = 0, -- Stop before vehicles.
	STOP_FOR_PEDS                                = 1, -- Stop before peds.
	SWERVE_AROUND_ALL_VEHICLES                   = 2, -- Avoid vehicles.
	STEER_AROUND_STATIONARY_VEHICLES             = 3, -- Avoid stationary vehicles.
	STEER_AROUND_PEDS                            = 4, -- Avoid peds.
	STEER_AROUND_OBJECTS                         = 5, -- Avoid objects.
	DONT_STEER_AROUND_PLAYER_PED                 = 6, -- Do not avoid player ped.
	STOP_AT_TRAFFIC_LIGHTS                       = 7, -- Stop at red lights.
	GO_OFF_ROAD_WHEN_AVOIDING                    = 8, -- Allow going offroad when avoiding obstacles.
	DRIVE_INTO_ONCOMING_TRAFFIC                  = 9, -- Allow going in the opposite lane when the current lane is obstructed.
	DRIVE_IN_REVERSE                             = 10, -- Drive in reverse only.
	USE_WANDER_FALLBACK_INSTEAD_OF_STRAIGHT_LINE = 11, -- If pathfinding fails, cruise randomly instead of going on a straight line.
	AVOID_RESTRICTED_AREAS                       = 12, -- Avoid restricted areas (ex: Fort Zancudo).
	PREVENT_BACKGROUND_PATHFINDING               = 13, -- Prevent background pathfinding. Works only with `TASK_WANDER*`
	ADJUST_CRUISE_SPEED_BASED_ON_ROAD_SPEED      = 14, -- Follow road speed limit.
	PREVENT_JOIN_IN_ROAD_DIRECTION_WHEN_MOVING   = 15, -- Unknown
	DONT_AVOID_TARGET                            = 16, -- Unknown
	TARGET_POSITION_OVERRIDES_ENTITY             = 17, -- Unknown
	USE_SHORT_CUT_LINKS                          = 18, -- Take the shortest path. Removes most pathing limits, the driver even goes on dirt roads. Use if you're going to be primarily driving off road.
	CHANGE_LANES_AROUND_OBSTRUCTIONS             = 19, -- Change lanes to drive around obstructions. Previously named: Allow overtaking vehicles if possible.
	AVOID_TARGET_COORDS                          = 20, -- Unkown
	USE_SWITCHED_OFF_NODES                       = 21, -- Allow using switched off street nodes. `WANDER` tasks ignore this. Only used in `TASK_GO_TO*`.
	PREFER_NAVMESH_ROUTE                         = 22, -- Prefer navmesh route when available.
	PLANE_TAXI_MODE                              = 23, -- Only works for planes using `TASK_GOTO`. Causes the pilot to drive along the ground instead of fly.
	FORCE_STRAIGHT_LINE                          = 24, -- Ignore pathfinding and go in a straight line.
	USE_STRING_PULLING_AT_JUNCTIONS              = 25, -- Unkown
	AVOID_ADVERSE_CONDITIONS                     = 26, -- Unkown
	AVOID_TURNS                                  = 27, -- Avoid all turns. Simlar-ish to `FORCE_STRAIGHT_LINE`.
	EXTEND_ROUTE_WITH_WANDERS_RESULTS            = 28, -- Extends the current route with the result of `TASK_WANDER*`.
	TRY_TO_AVOID_HIGHWAYS                        = 29, -- Avoid highways when possible. Will still use the highway if there is no other way to get to the destination.
	FORCE_JOIN_IN_ROAD_DIRECTION                 = 30, -- Unknown. Opposite of `1 << 15` ?
	STOP_AT_DESTINATION                          = 31, -- Stop the vehicle when reaching the destination. This is important if you want the driver to stop. Otherwise, they will keep moving. Forever.
}

return eDrivingFlags
