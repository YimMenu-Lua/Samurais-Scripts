-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureMgr     = require("includes.services.FeatureManager")
local MiscWorld      = require("includes.features.world.misc_world")
local PublicEnemy    = require("includes.features.world.public_enemy")

---@class World
---@field public m_public_enemy PublicEnemy
local World          = {}
World.__index        = World
World.m_feat_mgr     = FeatureMgr.new(World)
World.m_public_enemy = World.m_feat_mgr:Add(PublicEnemy.new())
World.m_feat_mgr:Add(MiscWorld.new(World))

function World:Cleanup()
	self.m_feat_mgr:Cleanup()
end

function World:ExtendBounds()
	PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(-42069420.0, -42069420.0, -42069420.0)
	PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(42069420.0, 42069420.0, 42069420.0)
end

function World:ResetBounds()
	PLAYER.RESET_WORLD_BOUNDARY_FOR_PLAYER()
end

function World:DisableOceanWaves()
	MISC.WATER_OVERRIDE_SET_STRENGTH(1.0)
end

function World:ResetOceanWaves()
	MISC.WATER_OVERRIDE_SET_STRENGTH(-1)
end

-- Draws a green chevron down element on top of an entity in the game world.
--
-- This runs in a fiber so you can safely call it in your UI thread.
---@param entity integer
---@param offset? float
function World:MarkSelectedEntity(entity, offset)
	ThreadManager:Run(function()
		local entity_hash  = ENTITY.GET_ENTITY_MODEL(entity)
		local entity_pos   = ENTITY.GET_ENTITY_COORDS(entity, false)
		local min, max     = Game.GetModelDimensions(entity_hash)
		local entityHeight = max.z - min.z

		if not offset then
			offset = 0.4
		end

		GRAPHICS.DRAW_MARKER(
			2,
			entity_pos.x,
			entity_pos.y,
			entity_pos.z + entityHeight + offset,
			0,
			0,
			0,
			0,
			180,
			0,
			0.3,
			0.3,
			0.3,
			0,
			255,
			0,
			100,
			true,
			true,
			1,
			false,
			---@diagnostic disable-next-line
			0, 0,
			false
		)
	end)
end

-- Starts a Line Of Sight world probe shape test.
---@param src vec3
---@param dest vec3
---@param traceFlags integer
---@param entityToExclude handle
---@return boolean, vec3, integer
function World:RayCast(src, dest, traceFlags, entityToExclude)
	local rayHandle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
		src.x,
		src.y,
		src.z,
		dest.x,
		dest.y,
		dest.z,
		traceFlags,
		entityToExclude,
		7
	)

	local endCoords = vec3:zero()
	local surfaceNormal = vec3:zero()
	local entityHit = 0
	local hit = false

	_, hit, endCoords, _, entityHit = SHAPETEST.GET_SHAPE_TEST_RESULT(
		rayHandle,
		hit,
		endCoords,
		surfaceNormal,
		entityHit
	)

	return hit, endCoords, entityHit
end

Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
	World:Cleanup()
end)

Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
	World:Cleanup()
end)

ThreadManager:RegisterLooped("SS_WORLD", function()
	World.m_feat_mgr:Update()
end)

return World
