-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-----------------------------------------------------
-- PropManager Subclass
-----------------------------------------------------
-- Handles props.
---@class PropManager
---@field protected m_owner_ref YimActions
---@field private m_props table<handle, array<handle>>
local PropManager <const> = { m_props = {} }
PropManager.__index = PropManager

---@param yimactions YimActions
---@return PropManager
function PropManager.new(yimactions)
	return setmetatable({ m_owner_ref = yimactions }, PropManager)
end

---@return table<handle, array<handle>>
function PropManager:GetProps()
	return self.m_props
end

---@return array<handle>?
function PropManager:GetPropsForPed(ped)
	return self.m_props[ped]
end

---@param owner integer
---@param propData table
---@param isPed? boolean
---@param coords? vec3
---@param faceOwner? boolean
---@param isDynamic? boolean
---@param placeOnGround? boolean
function PropManager:SpawnProp(owner, propData, isPed, coords, faceOwner, isDynamic, placeOnGround)
	if (not propData or not propData.model or not Game.EnsureModelHash(propData.model)) then
		return
	end

	if (not coords) then coords = vec3:zero() end

	if (propData.model == 2767137151 or propData.model == 976772591) then
		Audio:PartyMode(true, owner)
	end

	local loaded = pcall(TaskWait, Game.RequestModel, propData.model)
	if (not loaded) then
		log.fwarning("[PropManager]: Failed to load model (%d). Model could be blacklisted or online-only.", propData.model)
		return
	end

	local prop
	if (not isPed) then
		prop = Game.CreateObject(
			propData.model,
			coords,
			Game.IsOnline(),
			false,
			isDynamic,
			placeOnGround,
			faceOwner and (Game.GetHeading(owner) - 180) or 0
		)
	else
		prop = Game.CreatePed(
			propData.model,
			vec3:zero(),
			0,
			Game.IsOnline(),
			false
		)
	end

	if (not prop) then
		log.warning("[PropManager]: Failed to spawn animation prop!")
		return
	end

	entities.take_control_of(prop, 300)

	if (isPed) then
		PED.SET_PED_CONFIG_FLAG(prop, 179, true)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(prop, true)
		PED.SET_PED_KEEP_TASK(prop, false)
		TASK.TASK_STAND_STILL(prop, -1)
	end

	ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(prop)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(propData.model)

	self.m_props[owner] = self.m_props[owner] or {}
	table.insert(self.m_props[owner], prop)
	return prop
end

---@param ped integer
---@param propData array<AnimProps|AnimPropPeds>
---@param isPed? boolean
function PropManager:AttachProp(ped, propData, isPed)
	if (not Game.IsScriptHandle(ped)
			or not ENTITY.DOES_ENTITY_EXIST(ped)
			or not propData
			or (next(propData) == nil)
		) then
		return
	end

	for _, prop in ipairs(propData) do
		local boneIdx = Game.GetPedBoneIndex(ped, prop.parentBone)
		local handle  = self:SpawnProp(ped, prop, isPed)
		if (not handle) then
			Notifier:ShowError(
				"Samurai's Scripts",
				"Failed to spawn animation prop! Please try again later."
			)
			goto continue
		end

		if (prop.parentBone ~= -1) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(
				handle,
				ped,
				boneIdx,
				prop.pos.x,
				prop.pos.y,
				prop.pos.z,
				prop.rot.x,
				prop.rot.y,
				prop.rot.z,
				false,
				false,
				false,
				false,
				2,
				true,
				1
			)
		else
			local placePos   = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.7, 0.0)
			local _, groundZ = false, 0
			_, groundZ       = MISC.GET_GROUND_Z_FOR_3D_COORD(
				placePos.x,
				placePos.y,
				placePos.z,
				groundZ,
				false,
				false
			)

			ENTITY.SET_ENTITY_HEADING(handle, Game.GetHeading(ped))
			ENTITY.SET_ENTITY_COORDS(
				handle,
				placePos.x,
				placePos.y,
				groundZ,
				false,
				false,
				false,
				false
			)
			PHYSICS.ACTIVATE_PHYSICS(handle)
			OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(handle)
			ENTITY.SET_CAN_CLIMB_ON_ENTITY(handle, false)
		end

		if (ENTITY.IS_ENTITY_A_PED(handle) and prop.dict) then
			TaskWait(Game.RequestAnimDict, prop.dict)
			TASK.TASK_PLAY_ANIM(
				handle,
				prop.dict,
				prop.name,
				4.0,
				-4.0,
				-1,
				1,
				1.0,
				false,
				false,
				false
			)
		end

		if (prop.ptfx and prop.ptfx.name) then
			local fxMgr = self.m_owner_ref:GetFxManager()
			if (fxMgr) then
				fxMgr:StartPTFX(handle, prop.ptfx)
			end
		end

		::continue::
	end
end

function PropManager:Cleanup(ped)
	ped = self.m_owner_ref:GetPed(ped)
	local array = self.m_props[ped]

	if (array) then
		for _, prop in ipairs(array) do
			Game.DeleteEntity(prop)
		end
	end

	Audio:PartyMode(false)
	self.m_props[ped] = nil
end

function PropManager:Wipe()
	if (next(self.m_props) == nil) then return end

	for _, array in pairs(self.m_props) do
		for _, prop in ipairs(array) do
			Game.DeleteEntity(prop, Enums.eEntityType.Object)
		end
	end

	self.m_props = {}
end

return PropManager
