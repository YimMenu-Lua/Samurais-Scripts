-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ForgeEntity = require("includes.structs.ForgeEntity")
local World = require("includes.modules.World")

-----------------------------------------------------
-- EntityForge Class
-----------------------------------------------------
-- Spawn, merge, and create abominations.
---@class EntityForge
---@field PlayerEntity ForgeEntity
---@field AllEntities ForgeEntity[]
---@field EntityMap ForgeEntity[]
---@field SpawnedObjects ForgeEntity[]
---@field SpawnedVehicles ForgeEntity[]
---@field SpawnedPeds ForgeEntity[]
---@field WorldEntities ForgeEntity[]
---@field childCandidates ForgeEntity[]
---@field parentCandidates ForgeEntity[]
---@field currentParent ForgeEntity?
---@field lastParent ForgeEntity?
---@field GrabbedEntity ForgeEntity
---@field EntityGunEnabled boolean
---@field EntityGunDistance integer
---@field EntityGunRotMult integer EntityGun's rotation multiplier
---@overload fun(): EntityForge
local EntityForge = {}
EntityForge.__index = EntityForge
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(EntityForge, {
	__call = function(cls, ...)
		return cls:init()
	end
})

---@return EntityForge
function EntityForge:init()
	local instance = setmetatable({
		EntityGunEnabled  = false,
		EntityGunDistance = 7,
		EntityGunRotMult  = 1,
		AllEntities       = {},
		EntityMap         = {},
		SpawnedObjects    = {},
		SpawnedVehicles   = {},
		SpawnedPeds       = {},
		WorldEntities     = {},
		childCandidates   = {},
		parentCandidates  = {},
	}, self)

	Backend:RegisterEventCallbackAll(function()
		instance:ForceCleanup()
	end)

	ThreadManager:RegisterLooped("SS_ENTITY_FORGE", function()
		if (not instance.EntityGunEnabled or not WEAPON.IS_PED_ARMED(LocalPlayer:GetHandle(), 4)) then
			return
		end

		PLAYER.DISABLE_PLAYER_FIRING(LocalPlayer:GetPlayerID(), true)
		instance:EntityGun()
	end)

	return instance
end

---@param entity handle
function EntityForge:RegisterEntity(entity)
	Decorator:Register(entity, "EntityForge", true)
end

---@param entity handle
function EntityForge:UnregisterEntity(entity)
	Decorator:RemoveEntity(entity)
end

---@return ForgeEntity
function EntityForge:GetPlayerInstance()
	local p = ForgeEntity.new(
		LocalPlayer:GetHandle(),
		"You",
		-1, Enums.eEntityType.Ped,
		255,
		LocalPlayer:GetPos(),
		LocalPlayer:GetRotation()
	)
	p.m_is_player = true
	return p
end

---@return boolean
function EntityForge:IsEmpty()
	return next(self.EntityMap) == nil
end

---@param handle integer
---@return ForgeEntity | nil
function EntityForge:FindEntity(handle)
	if (not handle) then
		return nil
	end

	return self.EntityMap[handle]
end

---@param entity ForgeEntity
function EntityForge:GetCategoryFromType(entity)
	if (entity.m_type == Enums.eEntityType.Object) then
		return "objects"
	elseif entity.m_type == Enums.eEntityType.Ped then
		return "peds"
	elseif entity.m_type == Enums.eEntityType.Vehicle then
		return "vehicles"
	else
		return "Unknown"
	end
end

---@param entity ForgeEntity
---@param isWorldEntity? boolean
function EntityForge:AddEntity(entity, isWorldEntity)
	if (not self:FindEntity(entity.m_handle)) then
		if (not entity.m_is_forged
				and not entity.m_is_player
				and entity.m_handle ~= LocalPlayer:GetHandle()
			) then
			if (entity.m_type == Enums.eEntityType.Object) then
				table.insert(self.SpawnedObjects, entity)
			end

			if (entity.m_type == Enums.eEntityType.Vehicle) then
				table.insert(self.SpawnedVehicles, entity)
			end

			if (entity.m_type == Enums.eEntityType.Ped) then
				table.insert(self.SpawnedPeds, entity)
			end

			if (isWorldEntity) then
				table.insert(self.WorldEntities, entity)
				entity.m_is_world_entity = true
			end
		end

		table.insert(self.AllEntities, entity)
		self.EntityMap[entity.m_handle] = entity
		if (not isWorldEntity) then
			self:RegisterEntity(entity.m_handle)
		end
		self:UpdateAttachmentCandidates()
	end
end

---@param handle handle
function EntityForge:RemoveEntityByHandle(handle)
	for _, list in pairs({ self.AllEntities, self.SpawnedObjects, self.SpawnedVehicles, self.SpawnedPeds }) do
		for i = #list, 1, -1 do
			if (list[i].m_handle == handle or list[i].m_model_hash == -1) then
				table.remove(list, i)
			end
		end
	end

	if (handle == LocalPlayer:GetHandle()) then
		self.PlayerEntity = nil
	end

	self:UnregisterEntity(handle)
	self:UpdateAttachmentCandidates()
	self.EntityMap[handle] = nil
end

---@param entity ForgeEntity
---@param deltaTime integer
function EntityForge:MoveEntityWithGun(entity, deltaTime)
	local camRot        = CAM.GET_GAMEPLAY_CAM_ROT(2)
	local camPos        = CAM.GET_GAMEPLAY_CAM_COORD()
	local direction     = camRot:to_direction()
	local selfPos       = LocalPlayer:GetPos()
	local camHeading    = CAM.GET_GAMEPLAY_CAM_ROT(2).z
	local entityHeading = ENTITY.GET_ENTITY_HEADING(entity.m_handle)
	local headingDiff   = math.abs(camHeading - entityHeading)
	local mvmtSpeed     = 10
	local yawMultiplier = 1
	local timedelta     = math.min(1, deltaTime * mvmtSpeed)
	local groundZ       = 0

	local targetPos     = vec3:new(
		camPos.x + direction.x * self.EntityGunDistance,
		camPos.y + direction.y * self.EntityGunDistance,
		camPos.z + direction.z * self.EntityGunDistance
	)

	_, groundZ          = MISC.GET_GROUND_Z_FOR_3D_COORD(
		selfPos.x,
		selfPos.y,
		selfPos.z,
		groundZ,
		false,
		false
	)

	if (not entity.m_last_pos) then
		entity.m_last_pos = Game.GetEntityCoords(entity.m_handle, false)
	end

	entity.m_last_pos      = entity.m_last_pos:lerp(targetPos, timedelta)
	entity.m_position      = entity.m_last_pos
	entity.m_target_pos    = targetPos
	self.EntityGunDistance = math.max(1.0, math.min(self.EntityGunDistance, 50.0))

	if (entity.m_last_pos.z < groundZ + 0.5) then
		entity.m_last_pos.z = groundZ + 0.5
	end

	Game.SetEntityCoordsNoOffset(entity.m_handle, entity.m_last_pos)
	World:MarkSelectedEntity(entity.m_handle, -0.1)

	if (headingDiff > 180) then
		headingDiff = 360 - headingDiff
	end

	if (headingDiff > 90) then
		yawMultiplier = -1
	end

	if KeyManager:IsKeyPressed(eVirtualKeyCodes.PAGEUP) then
		self.EntityGunDistance = self.EntityGunDistance + 0.1
	end

	if KeyManager:IsKeyPressed(eVirtualKeyCodes.PAGEDOWN) then
		self.EntityGunDistance = self.EntityGunDistance - 0.1
	end

	if KeyManager:IsKeyJustPressed(eVirtualKeyCodes.ADD) or KeyManager:IsKeyJustPressed(eVirtualKeyCodes.MOUSE5) then
		self.EntityGunRotMult = (self.EntityGunRotMult == 1) and 10 or self.EntityGunRotMult + 10
		Notifier:ShowMessage(
			"EntityForge",
			_F("Rotation multiplier set to %d", self.EntityGunRotMult)
		)
	end

	if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.SUBTRACT) or KeyManager:IsKeyJustPressed(eVirtualKeyCodes.MOUSE4)) then
		self.EntityGunRotMult = self.EntityGunRotMult <= 10 and 1 or self.EntityGunRotMult - 10
		Notifier:ShowMessage(
			"EntityForge",
			_F("Rotation multiplier set to %d", self.EntityGunRotMult)
		)
	end

	if (KeyManager:IsKeyPressed(eVirtualKeyCodes.NUMPAD4)) then
		self:RotateEntity(
			entity,
			0.0,
			-0.1 * yawMultiplier * self.EntityGunRotMult,
			0.0
		)
	end

	if (KeyManager:IsKeyPressed(eVirtualKeyCodes.NUMPAD6)) then
		self:RotateEntity(
			entity,
			0.0,
			0.1 * yawMultiplier * self.EntityGunRotMult,
			0.0
		)
	end

	if (KeyManager:IsKeyPressed(eVirtualKeyCodes.NUMPAD8)) then
		self:RotateEntity(entity, 0.1 * self.EntityGunRotMult, 0.0, 0.0)
	end

	if (KeyManager:IsKeyPressed(eVirtualKeyCodes.NUMPAD2)) then
		self:RotateEntity(entity, -0.1 * self.EntityGunRotMult, 0.0, 0.0)
	end

	if (KeyManager:IsKeyPressed(eVirtualKeyCodes.NUMPAD1)) then
		self:RotateEntity(entity, 0.0, 0.0, -0.1 * self.EntityGunRotMult)
	end

	if (KeyManager:IsKeyPressed(eVirtualKeyCodes.NUMPAD3)) then
		self:RotateEntity(entity, 0.0, 0.0, 0.1 * self.EntityGunRotMult)
	end
end

-- Grabs and manipulates world entities.
function EntityForge:EntityGun()
	if (not PLAYER.IS_PLAYER_FREE_AIMING(LocalPlayer:GetPlayerID())) then
		if (self.GrabbedEntity) then
			ENTITY.SET_ENTITY_COLLISION(self.GrabbedEntity.m_handle, true, true)
		end
		return
	end

	local aimedAtEntity = LocalPlayer:GetEntityInCrosshairs(true)
	local existing_entity

	if (aimedAtEntity and (ENTITY.IS_ENTITY_DEAD(aimedAtEntity, false) or Backend:IsScriptEntity(aimedAtEntity))) then
		aimedAtEntity = nil
	end

	if (aimedAtEntity and ENTITY.DOES_ENTITY_EXIST(aimedAtEntity) and not Backend:IsScriptEntity(aimedAtEntity)) then
		existing_entity = self:FindEntity(aimedAtEntity)
	end

	if (self.GrabbedEntity and PAD.IS_DISABLED_CONTROL_PRESSED(0, 24)) then
		local screenX = 0.61
		local screenY = 0.40
		if (self.GrabbedEntity.m_is_world_entity and not self.GrabbedEntity.m_is_forged) then
			Game.DrawText(
				vec2:new(0.61, screenY + 0.23),
				"- Press [E] to release the entity from the pool.",
				Color(255, 255, 255, 220),
				vec2:new(0.2, 0.38),
				4
			)
		end

		Game.DrawText(
			vec2:new(screenX, screenY + 0.2),
			"- Use [Numpad 1 - 3  |  4 - 6  |  2 - 8] to rotate.",
			Color(255, 255, 255, 220),
			vec2:new(0.2, 0.38),
			4
		)

		Game.DrawText(
			vec2:new(screenX, screenY + 0.17),
			"- Use [Numpad +] and [Numpad -] to adjust rotation speed.",
			Color(255, 255, 255, 220),
			vec2:new(0.2, 0.38),
			4
		)

		Game.DrawText(
			vec2:new(screenX, screenY + 0.14),
			"- Use [Page Up] and [Page Down] to adjust distance.",
			Color(255, 255, 255, 220),
			vec2:new(0.2, 0.38),
			4
		)

		Game.DrawText(
			vec2:new(screenX, screenY + 0.11),
			"- Press [F] to save this entity's model to favorites.",
			Color(255, 255, 255, 220),
			vec2:new(0.2, 0.38),
			4
		)

		Game.DrawText(
			vec2:new(screenX, screenY + 0.08),
			"- Press [Back Space] to delete this entity.",
			Color(255, 255, 255, 220),
			vec2:new(0.2, 0.38),
			4
		)

		self:MoveEntityWithGun(self.GrabbedEntity, Game.GetFrameTime())
	end

	if (self.GrabbedEntity) then
		if (self.GrabbedEntity.m_is_world_entity and KeyManager:IsKeyJustPressed(eVirtualKeyCodes.E) and not self.GrabbedEntity.m_is_forged) then
			Notifier:ShowMessage(
				"EntityForge",
				_F("%s [%d] was removed from the entity pool.",
					self.GrabbedEntity.m_name,
					self.GrabbedEntity.m_handle
				)
			)

			self:ReleaseWorldEntity(self.GrabbedEntity)
			self.GrabbedEntity = nil
		end

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.BACKSPACE)
				and not self.GrabbedEntity.m_is_forged
				and not Backend:IsScriptEntity(self.GrabbedEntity.m_handle)
			) then
			self:DeleteEntity(self.GrabbedEntity)
			self.GrabbedEntity = nil
		end

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.F)) then
			if (self:IsModelInFavorites(self.GrabbedEntity.m_model_hash)) then
				Notifier:ShowError("EntityForge", "This model is already saved. Please choose a different one!")
			else
				local name = _F("%s [%s]",
					self.GrabbedEntity.m_name,
					self.GrabbedEntity.m_handle
				)
				GVars.features.entity_forge.favorites[self.GrabbedEntity.m_model_hash] = {
					{
						name       = name,
						entityType = self.GrabbedEntity.m_type
					}
				}

				Notifier:ShowSuccess("EntityForge",
					_F("Added %s [%s] to favorites.", name, self.GrabbedEntity.m_handle)
				)
			end
		end

		if (PAD.IS_DISABLED_CONTROL_JUST_RELEASED(0, 24)) then
			ENTITY.FREEZE_ENTITY_POSITION(self.GrabbedEntity.m_handle, false)
			ENTITY.SET_ENTITY_COLLISION(self.GrabbedEntity.m_handle, true, true)
			PHYSICS.ACTIVATE_PHYSICS(self.GrabbedEntity.m_handle)

			if self.GrabbedEntity.m_type == Enums.eEntityType.Object then
				OBJECT.SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(self.GrabbedEntity.m_handle, true)
			end

			self.GrabbedEntity = nil
		end
	end

	if (existing_entity) then
		if (not existing_entity.m_is_forged) then
			if (not PAD.IS_DISABLED_CONTROL_PRESSED(0, 24)) then
				Game.ShowButtonPrompt("Hold ~INPUT_ATTACK~ to move the entity with your mouse.")
			end

			if (PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 24)) then
				self.GrabbedEntity     = existing_entity
				local v_SelfPos        = LocalPlayer:GetPos()
				local v_EntityPos      = Game.GetEntityCoords(self.GrabbedEntity.m_handle, false)
				self.EntityGunDistance = v_SelfPos:distance(v_EntityPos)

				ENTITY.SET_ENTITY_COLLISION(self.GrabbedEntity.m_handle, false, true)

				if (self.GrabbedEntity and self.GrabbedEntity.m_last_pos) then
					self.GrabbedEntity.m_last_pos = nil -- prevent the entity from jumping back to the last position we dropped/released it from when we try to move it again
				end
			end
		end
	else
		if (aimedAtEntity and not self.GrabbedEntity) then
			Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to add the entity to the forge pool.")
		end

		if (aimedAtEntity and KeyManager:IsKeyJustPressed(eVirtualKeyCodes.E)) then
			local entityType = ENTITY.GET_ENTITY_TYPE(aimedAtEntity)
			local modelHash  = Game.GetEntityModel(aimedAtEntity)
			local entityName

			if (entityType == Enums.eEntityType.Object) then
				entityName = "World Object"
			end

			if (entityType == Enums.eEntityType.Ped) then
				entityName = "World Ped"
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(aimedAtEntity)
				TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(aimedAtEntity, true)
				PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(aimedAtEntity, true)
				PED.SET_PED_KEEP_TASK(aimedAtEntity, false)
				TASK.TASK_STAND_STILL(aimedAtEntity, -1)
			end

			if (entityType == Enums.eEntityType.Vehicle) then
				entityName = _F("World Vehicle (%s)", vehicles.get_vehicle_display_name(modelHash))
				local t_Occupants = Vehicle(aimedAtEntity):GetOccupants()
				if (#t_Occupants > 0) then
					for _, ped in ipairs(t_Occupants) do
						if not PED.IS_PED_A_PLAYER(ped) then
							TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
						end
					end
				end
			end

			ENTITY.SET_ENTITY_INVINCIBLE(aimedAtEntity, true)

			local world_entity = ForgeEntity.new(
				aimedAtEntity,
				entityName,
				modelHash,
				entityType,
				ENTITY.GET_ENTITY_ALPHA(aimedAtEntity),
				Game.GetEntityCoords(aimedAtEntity, false),
				Game.GetEntityRotation(aimedAtEntity)
			)

			self:ResetEntityPosition(
				world_entity,
				ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
					LocalPlayer:GetHandle(),
					0,
					5,
					0
				)
			)

			self:AddEntity(world_entity, true)
			Notifier:ShowMessage(
				"EntityForge",
				_F(
					"Added '%s' [%d] to the entity pool.",
					entityName,
					aimedAtEntity
				)
			)
		end
	end
end

---@param entity ForgeEntity
function EntityForge:ReleaseWorldEntity(entity)
	if (not entity) then
		return
	end

	ENTITY.SET_ENTITY_COLLISION(entity.m_handle, true, true)
	ENTITY.SET_ENTITY_INVINCIBLE(entity.m_handle, false)
	PHYSICS.ACTIVATE_PHYSICS(entity.m_handle)

	if (entity.m_type == Enums.eEntityType.Ped) then
		TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity.m_handle, false)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity.m_handle, false)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(entity.m_handle)
		ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(entity.m_handle)
	end

	if (entity.m_type == Enums.eEntityType.Object) then
		OBJECT.SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(entity.m_handle, true)
	end

	self:RemoveEntityByHandle(entity.m_handle)
end

---@param modelHash integer
---@param name string
---@param entityType eEntityType
---@param coords vec3
---@param pedType? integer
---@param alpha? integer
---@param isForged? boolean
---@return integer | nil
function EntityForge:CreateEntity(modelHash, name, entityType, coords, pedType, alpha, isForged)
	local handle
	local groundZ = 0
	_, groundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(
		coords.x,
		coords.y,
		coords.z,
		groundZ,
		false,
		false
	)

	local spawnPos = vec3:new(coords.x, coords.y, groundZ)
	if (entityType == Enums.eEntityType.Object) then
		handle = Game.CreateObject(
			modelHash,
			spawnPos,
			true,
			false,
			true,
			true,
			LocalPlayer:GetHeading()
		)
	elseif (entityType == Enums.eEntityType.Vehicle) then
		handle = Game.CreateVehicle(
			modelHash,
			spawnPos,
			LocalPlayer:GetHeading(-90),
			true,
			false
		)
	elseif (entityType == Enums.eEntityType.Ped) then
		handle = Game.CreatePed(
			modelHash,
			spawnPos,
			LocalPlayer:GetHeading(-90),
			true,
			false
		)

		TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
		PED.SET_PED_KEEP_TASK(handle, false)
		TASK.TASK_STAND_STILL(handle, -1)
	end

	if (not handle or (handle <= 0) or not ENTITY.DOES_ENTITY_EXIST(handle)) then
		Notifier:ShowError(
			"EntityForge",
			_F("Failed to create entity:\n[%s]", name)
		)
		return
	end

	if (alpha) then
		ENTITY.SET_ENTITY_ALPHA(handle, alpha, false)
	end

	if (not isForged) then
		self:AddEntity(
			ForgeEntity.new(
				handle,
				name,
				modelHash,
				entityType,
				alpha,
				Game.GetEntityCoords(handle, false),
				Game.GetEntityRotation(handle, 2)
			)
		)
	end

	self:RegisterEntity(handle)
	return handle
end

---@param entity ForgeEntity
function EntityForge:DeleteEntity(entity)
	if (entity.m_children and #entity.m_children > 0) then
		for i = #entity.m_children, 1, -1 do
			self:DetachEntity(entity, entity.m_children[i])
			self:UnregisterEntity(entity.m_handle)
			table.remove(entity.m_children, i)
		end
	end

	if (entity.m_parent and (entity.m_parent.modelHash == -1)) then
		for i = #self.PlayerEntity.m_children, 1, -1 do
			if entity.m_handle == self.PlayerEntity.m_children[i].m_handle then
				self:UnregisterEntity(entity.m_handle)
				table.remove(self.PlayerEntity.m_children, i)
			end
		end
	end

	Game.DeleteEntity(entity.m_handle, entity.m_type)
	self:UnregisterEntity(entity.m_handle)
	self:RemoveEntityByHandle(entity.m_handle)

	if (self.currentParent) then
		if (self.currentParent.m_handle ~= self.lastParent.m_handle) then
			self.currentParent = self.lastParent
		elseif (#self.currentParent.m_children == 0) then
			self.currentParent = nil
			self.lastParent = nil
		end
	end
end

---@param abomination table | ForgeEntity
function EntityForge:SpawnSavedAbomination(abomination)
	script.run_in_fiber(function()
		local function recurse(entityData, parent)
			local entity

			if (not entityData.isPlayer and entityData.modelHash ~= -1) then
				local handle = self:CreateEntity(
					entityData.modelHash,
					entityData.name,
					entityData.type,
					LocalPlayer:GetOffsetInWorldCoords(
						math.random(1, 30),
						math.random(1, 30),
						-50
					),
					nil,
					entityData.alpha,
					true
				)

				if (handle) then
					if (entityData.properties) then
						if (entityData.type == Enums.eEntityType.Vehicle) then
							Vehicle(handle):ApplyMods(entityData.properties)
						end

						if (entityData.type == Enums.eEntityType.Ped) then
							if (entityData.properties.components) then
								Game.ApplyPedComponents(
									handle,
									entityData.properties.components
								)
							end

							if (entityData.properties.action) then
								if (entityData.properties.action.scenario) then
									while not PED.IS_PED_USING_ANY_SCENARIO(handle) do
										TASK.TASK_START_SCENARIO_IN_PLACE(
											handle,
											entityData.properties.action.scenario,
											-1,
											false
										)
										yield()
									end
								end
							end
						end
					end

					entity = ForgeEntity.new(
						handle,
						entityData.name,
						entityData.modelHash,
						entityData.type,
						entityData.alpha,
						ENTITY.GET_ENTITY_COORDS(handle, false),
						ENTITY.GET_ENTITY_ROTATION(handle, 2)
					)

					ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(handle)
				end
			else
				entity = self:GetPlayerInstance()
				entity.m_name = entityData.name
			end

			entity.m_properties = entityData.properties or {}
			entity.m_is_forged = true

			if (parent and not entity.m_is_player) then
				self:AttachEntity(
					entity,
					parent,
					entityData.parent_bone,
					entityData.attach_pos,
					entityData.attach_rot
				)
			end

			for _, childData in ipairs(entityData.children or {}) do
				recurse(childData, entity)
			end

			return entity
		end

		local rootEntity = recurse(abomination, nil)
		if (not rootEntity.m_is_player) then
			Game.SetEntityCoords(
				rootEntity.m_handle,
				LocalPlayer:GetOffsetInWorldCoords(1, 5, 0)
			)
		end

		table.insert(self.AllEntities, rootEntity)
		self.EntityMap[rootEntity.m_handle] = rootEntity
	end)
end

---@param abomination ForgeEntity
function EntityForge:DeleteAbomination(abomination)
	if (abomination.m_children) then
		for _, child in ipairs(abomination.m_children) do
			Game.DeleteEntity(child.m_handle, child.m_type)
			self:RemoveEntityByHandle(child.m_handle)
		end
	end

	if (self.currentParent and (self.currentParent.m_handle == abomination.m_handle)) then
		if (self.currentParent.m_handle ~= self.lastParent.m_handle) then
			self.currentParent = self.lastParent
		else
			self.currentParent = nil
			self.lastParent = nil
		end
	end

	self:RemoveEntityByHandle(abomination.m_handle)
	Game.DeleteEntity(abomination.m_handle, abomination.m_type)
end

---@param selectedChild? any
function EntityForge:UpdateAttachmentCandidates(selectedChild)
	self.parentCandidates = {}
	self.childCandidates = {}

	if (self:IsEmpty()) then
		return
	end

	for _, entity in ipairs(self.AllEntities) do
		if (not entity.m_is_forged and not entity.m_is_player) then
			local isParentless = not entity.m_parent or not entity.m_parent[1]
			if (not entity.m_is_attached) then
				table.insert(self.childCandidates, entity)
			end

			if (isParentless and (entity ~= selectedChild) and not entity.m_is_attached) then
				table.insert(self.parentCandidates, entity)
			end
		end
	end

	if (selectedChild and (#self.parentCandidates > 0)) then
		for i = #self.parentCandidates, 1, -1 do
			if self.parentCandidates[i].m_handle == selectedChild.handle then
				table.remove(self.parentCandidates, i)
			end
		end
	end
end

---@param parent ForgeEntity
---@param child ForgeEntity
---@param unk_bone string | number
---@param attachPos vec3
---@param attachRot vec3
function EntityForge:AttachEntity(child, parent, unk_bone, attachPos, attachRot)
	if ((child.m_handle == parent.m_handle) or child.m_is_player) then
		return
	end

	if (not ENTITY.DOES_ENTITY_EXIST(child.m_handle)) then
		Notifier:ShowError(
			"EntityForge",
			"This entity no longer exists in the game world and will be removed from the forge."
		)
		self:DeleteEntity(child)
		return
	end

	if (not ENTITY.DOES_ENTITY_EXIST(parent.m_handle)) then
		Notifier:ShowError(
			"EntityForge",
			"The parent entity no longer exists in the game world and will be removed from the forge."
		)
		self:DeleteEntity(parent)
		return
	end

	local boneIndex = 0
	local parent_handle

	if (parent.m_is_player) then
		parent_handle = LocalPlayer:GetHandle()
	else
		parent_handle = parent.m_handle
	end

	if (parent.m_type == Enums.eEntityType.Object) then
		boneIndex = 0
	elseif (parent.m_type == Enums.eEntityType.Vehicle and type(unk_bone) == "string") then
		boneIndex = Game.GetEntityBoneIndexByName(parent_handle, unk_bone)
	elseif (parent.m_type == Enums.eEntityType.Ped and type(unk_bone) == "number") then
		boneIndex = Game.GetPedBoneIndex(parent_handle, unk_bone)
	end

	ENTITY.ATTACH_ENTITY_TO_ENTITY(
		child.m_handle,
		parent_handle,
		boneIndex,
		attachPos.x,
		attachPos.y,
		attachPos.z,
		attachRot.x,
		attachRot.y,
		attachRot.z,
		false,
		true,
		false,
		ENTITY.IS_ENTITY_A_PED(child.m_handle),
		2,
		true,
		1
	)

	if (child.m_type == Enums.eEntityType.Ped) then
		ENTITY.SET_ENTITY_INVINCIBLE(child.m_handle, true)
		TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.m_handle, true)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.m_handle, true)
		PED.SET_PED_KEEP_TASK(child.m_handle, false)
		TASK.TASK_STAND_STILL(child.m_handle, -1)
	end

	child.m_parent      = parent
	child.m_parent_bone = unk_bone
	child.m_attach_pos  = attachPos
	child.m_attach_rot  = attachRot

	if (not child.m_is_attached) then
		child.m_is_attached = true
		table.insert(parent.m_children, child)
	end

	self.currentParent = parent

	if (not self.lastParent) then
		self.lastParent = parent
	end

	self:UpdateAttachmentCandidates(child)
end

---@param attachment? ForgeEntity
---@param x float
---@param y float
---@param z float
function EntityForge:MoveAttachment(attachment, x, y, z)
	if (not attachment) then
		return
	end

	if (not attachment.m_is_attached or not attachment.m_parent) then
		return
	end

	local parent_handle
	local boneIndex = 0

	if (attachment.m_parent.m_is_player) then
		parent_handle = LocalPlayer:GetHandle()
	else
		parent_handle = attachment.m_parent.m_handle
	end

	if (attachment.m_parent.m_type == Enums.eEntityType.Object) then
		boneIndex = 0
	elseif (attachment.m_parent.m_type == Enums.eEntityType.Vehicle and type(attachment.m_parent_bone) == "string") then
		---@diagnostic disable-next-line
		boneIndex = Game.GetEntityBoneIndexByName(parent_handle, attachment.m_parent_bone)
	elseif (attachment.m_parent.m_type == Enums.eEntityType.Ped and type(attachment.m_parent_bone) == "number") then
		---@diagnostic disable-next-line
		boneIndex = Game.GetPedBoneIndex(parent_handle, attachment.m_parent_bone)
	end

	if (boneIndex == -1) then
		return
	end

	attachment.m_attach_pos.x = attachment.m_attach_pos.x + x
	attachment.m_attach_pos.y = attachment.m_attach_pos.y + y
	attachment.m_attach_pos.z = attachment.m_attach_pos.z + z

	ENTITY.ATTACH_ENTITY_TO_ENTITY(
		attachment.m_handle,
		parent_handle,
		boneIndex,
		attachment.m_attach_pos.x,
		attachment.m_attach_pos.y,
		attachment.m_attach_pos.z,
		attachment.m_attach_rot.x,
		attachment.m_attach_rot.y,
		attachment.m_attach_rot.z,
		false,
		false,
		false,
		attachment.m_type == Enums.eEntityType.Ped,
		2,
		true,
		1
	)
end

---@param attachment ForgeEntity
---@param x float
---@param y float
---@param z float
function EntityForge:RotateAttachment(attachment, x, y, z)
	if (not attachment) then
		return
	end

	if (not attachment.m_is_attached or not attachment.m_parent) then
		return
	end

	local parent_handle
	local boneIndex = 0

	if (attachment.m_parent.m_is_player) then
		parent_handle = LocalPlayer:GetHandle()
	else
		parent_handle = attachment.m_parent.m_handle
	end

	if (attachment.m_parent.m_type == Enums.eEntityType.Object) then
		boneIndex = 0
	elseif (attachment.m_parent.m_type == Enums.eEntityType.Vehicle and type(attachment.m_parent_bone) == "string") then
		---@diagnostic disable-next-line
		boneIndex = Game.GetEntityBoneIndexByName(parent_handle, attachment.m_parent_bone)
	elseif (attachment.m_parent.m_type == Enums.eEntityType.Ped and type(attachment.m_parent_bone) == "number") then
		---@diagnostic disable-next-line
		boneIndex = Game.GetPedBoneIndex(parent_handle, attachment.m_parent_bone)
	end

	attachment.m_attach_rot.x = attachment.m_attach_rot.x + x
	attachment.m_attach_rot.y = attachment.m_attach_rot.y + y
	attachment.m_attach_rot.z = attachment.m_attach_rot.z + z

	ENTITY.ATTACH_ENTITY_TO_ENTITY(
		attachment.m_handle,
		parent_handle,
		boneIndex,
		attachment.m_attach_pos.x,
		attachment.m_attach_pos.y,
		attachment.m_attach_pos.z,
		attachment.m_attach_rot.x,
		attachment.m_attach_rot.y,
		attachment.m_attach_rot.z,
		false,
		false,
		false,
		attachment.m_type == Enums.eEntityType.Ped,
		2,
		true,
		1
	)
end

---@param entity ForgeEntity
---@param x float
---@param y float
---@param z float
function EntityForge:MoveEntity(entity, x, y, z)
	if not entity or ENTITY.IS_ENTITY_ATTACHED(entity.m_handle) then
		return
	end

	entity.m_position.x = entity.m_position.x + x
	entity.m_position.y = entity.m_position.y + y
	entity.m_position.z = entity.m_position.z + z

	Game.SetEntityCoords(entity.m_handle, entity.m_position)
end

---@param entity ForgeEntity
---@param x float
---@param y float
---@param z float
function EntityForge:RotateEntity(entity, x, y, z)
	if (not entity or ENTITY.IS_ENTITY_ATTACHED(entity.m_handle)) then
		return
	end

	entity.m_rotation.x = (entity.m_rotation.x + x) % 360
	entity.m_rotation.y = math.max(-85.0, math.min(entity.m_rotation.y + y, 85.0)) -- fuck you. roll on deez nutts
	entity.m_rotation.z = (entity.m_rotation.z + z) % 360

	if (entity.m_rotation.x < 0) then
		entity.m_rotation.x = entity.m_rotation.x + 360
	end

	if (entity.m_rotation.z < 0) then
		entity.m_rotation.z = entity.m_rotation.z + 360
	end

	ENTITY.SET_ENTITY_ROTATION(
		entity.m_handle,
		entity.m_rotation.x,
		entity.m_rotation.y,
		entity.m_rotation.z,
		2,
		true
	)
end

---@param entity ForgeEntity
---@param position? vec3
function EntityForge:ResetEntityPosition(entity, position)
	script.run_in_fiber(function()
		if (not position) then
			position = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity.m_handle, 1, 2, 0)
		end

		Game.SetEntityCoordsNoOffset(entity.m_handle, position)
		entity.m_position = position
		entity.m_rotation = ENTITY.GET_ENTITY_ROTATION(entity.m_handle, 2)

		if (entity.m_type == Enums.eEntityType.Object) then
			OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(entity.m_handle)
		elseif (entity.m_type == Enums.eEntityType.Vehicle) then
			VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(entity.m_handle, 5.0)
		end
	end)
end

---@param parent ForgeEntity
---@param child ForgeEntity
function EntityForge:DetachEntity(parent, child)
	script.run_in_fiber(function(detach)
		if (ENTITY.DOES_ENTITY_EXIST(child.m_handle) and ENTITY.IS_ENTITY_ATTACHED(child.m_handle)) then
			ENTITY.DETACH_ENTITY(child.m_handle, true, false)
			self:ResetEntityPosition(child)
			detach:sleep(200)
		end

		if (child.m_type == Enums.eEntityType.Ped) then
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(child.m_handle)
			TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.m_handle, true)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.m_handle, true)
			PED.SET_PED_KEEP_TASK(child.m_handle, false)
			TASK.TASK_STAND_STILL(child.m_handle, -1)
		end

		for i, c in ipairs(parent.m_children or {}) do
			if c == child then
				table.remove(parent.m_children, i)
				break
			end
		end

		if (not parent.m_children or #parent.m_children == 0) then
			parent.m_children = {}
			parent.m_is_forged = false
		end

		child.m_is_attached = false
		child.m_attach_pos = nil
		child.m_attach_rot = nil
		child.m_parent = nil
		child.m_parent_bone = nil
		child.m_is_forged = false
		self:AddEntity(child)

		if (parent.m_handle ~= LocalPlayer:GetHandle() and not parent.m_is_player) then
			if (self.currentParent ~= parent) then
				parent.m_is_forged = false
				self:AddEntity(parent)
			end
		end

		if (self.currentParent and #self.currentParent.m_children == 0) then
			if (parent.m_model_hash == -1 and (#parent.m_children == 0)) then
				self:RemoveEntityByHandle(parent.m_handle)
				self.PlayerEntity = nil
			end
			self.currentParent = #self.lastParent.m_children > 0 and self.lastParent or nil
		end

		self:UpdateAttachmentCandidates(child)
	end)
end

---@param parent? ForgeEntity
function EntityForge:DetachAllEntities(parent)
	if (not parent) then
		if (self.currentParent) then
			parent = self.currentParent
		elseif (self.lastParent) then
			parent = self.lastParent
		end
	end

	if (not parent) then
		return
	end

	script.run_in_fiber(function(detachall)
		if (not parent.m_children or #parent.m_children == 0) then
			parent.m_children = {}
			parent.m_is_forged = false
		else
			local initialOffset = 2.0

			for i = #parent.m_children, 1, -1 do
				if (ENTITY.IS_ENTITY_ATTACHED(parent.m_children[i].m_handle)) then
					ENTITY.DETACH_ENTITY(parent.m_children[i].m_handle, true, false)
				end

				detachall:sleep(50)
				self:ResetEntityPosition(
					parent.m_children[i],
					ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
						parent.m_children[i].m_handle,
						1,
						initialOffset,
						0
					)
				)
				initialOffset = initialOffset + 1.0

				parent.m_children[i].m_is_attached = false
				parent.m_children[i].m_attach_pos = nil
				parent.m_children[i].m_attach_rot = nil
				parent.m_children[i].m_parent = nil
				parent.m_children[i].m_parent_bone = nil
				parent.m_children[i].m_is_forged = false

				self:AddEntity(parent.m_children[i])
				table.remove(parent.m_children, i)
			end
		end

		if (parent.m_handle ~= LocalPlayer:GetHandle() and not parent.m_is_player) then
			if (self.currentParent ~= parent) then
				parent.m_is_forged = false
				self:AddEntity(parent)
			end
		end

		if (parent.m_model_hash == -1 and (#parent.m_children == 0)) then
			self:RemoveEntityByHandle(parent.m_handle)
			self.PlayerEntity = nil
		end

		if (self.currentParent) then
			if (self.currentParent.m_handle ~= self.lastParent.m_handle) then
				self.currentParent = self.lastParent
			elseif (#self.currentParent.m_children == 0) then
				self.currentParent = nil
				self.lastParent = nil
			end
		end

		self:UpdateAttachmentCandidates()
	end)
end

function EntityForge:Cleanup()
	if (self:IsEmpty()) then
		return
	end

	local to_remove = {}
	for _, entity in pairs(self.EntityMap) do
		if (entity.m_is_forged) then
			self:DeleteAbomination(entity)
		elseif (entity.m_is_world_entity) then
			self:ReleaseWorldEntity(entity)
		else
			self:DeleteEntity(entity)
		end
		table.insert(to_remove, entity)
	end

	script.run_in_fiber(function(cleanup)
		cleanup:sleep(200)

		for _, entity in ipairs(to_remove) do
			self:RemoveEntityByHandle(entity.m_handle)
		end

		self:UpdateAttachmentCandidates()
	end)
end

---@param reference? table
function EntityForge:ForceCleanup(reference)
	reference = reference or self.EntityMap

	if (#self.WorldEntities > 0) then
		for _, entity in pairs(self.WorldEntities) do
			if ENTITY.IS_ENTITY_ATTACHED(entity.m_handle) then
				ENTITY.DETACH_ENTITY(entity.m_handle, true, false)
			end
			self:ReleaseWorldEntity(entity)
		end
	end

	for _, entity in pairs(reference) do
		if (entity.m_handle and (entity.m_handle ~= LocalPlayer:GetHandle()) and not entity.m_is_player) then
			self:UnregisterEntity(entity.m_handle)
			ENTITY.DELETE_ENTITY(entity.m_handle)
		end

		if (entity.m_children) then
			self:ForceCleanup(entity.m_children)
		end
	end
	self.PlayerEntity = nil
end

---@param input string | number | table | ForgeEntity
---@return boolean
function EntityForge:IsModelInFavorites(input)
	if (not input) then
		return false
	end

	local hash = 0
	if (type(input) == "number" or type(input) == "string") then
		hash = Game.EnsureModelHash(input)
	elseif (type(input) == "table" or IsInstance(input, ForgeEntity)) then
		hash = Game.EnsureModelHash(input.m_model_hash)
	end

	return GVars.features.entity_forge.favorites[hash] ~= nil
end

---@param input ForgeEntity
function EntityForge:RemoveFromFavorites(input)
	if (not input) then
		return
	end

	GVars.features.entity_forge.favorites[input.m_model_hash] = nil
end

function EntityForge:RemoveAllFavorites()
	GVars.features.entity_forge.favorites = {}
end

function EntityForge:OverwriteSavedAbomination()
	local name = EntityForge.currentParent.m_name
	if (not GVars.features.entity_forge.forged_entities[name]) then
		return
	end

	GVars.features.entity_forge.forged_entities[name] = EntityForge.currentParent:serialize()
	Notifier:ShowMessage("EntityForge", "Changes saved.")
end

---@param abomination ForgeEntity
function EntityForge:RemoveSavedAbomination(abomination)
	if (not abomination) then
		return
	end

	GVars.features.entity_forge.forged_entities[abomination.m_name] = nil
end

function EntityForge:RemoveAllSavedAbominations()
	GVars.features.entity_forge.forged_entities = {}
end

---@param data any Base64 XOR-encrypted json
function EntityForge:ImportCreation(data)
	if (not data or not Serializer:IsBase64(data)) then
		Notifier:ShowError(
			"EntityForge",
			"Import Error: Incorrect data type!",
			true,
			5.0
		)
		return
	end

	local abomination = Serializer:Decode(Serializer:XOR(Serializer:B64Decode(data)))
	if (type(abomination) ~= "table") then
		Notifier:ShowError(
			"EntityForge",
			"Import Error: Incorrect data type!",
			true,
			5.0
		)
		return
	end

	return ForgeEntity.deserialize(abomination)
end

return EntityForge
