-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class PreviewService
---@field private m_current_entity? handle
---@field private m_current_model? hash
---@field private m_current_pos? vec3
---@field private m_last_hovered_entity? handle
---@field private m_hover_start_time integer
---@field private m_delay integer
---@field private m_await_spawn boolean
---@field private m_failed_models set<hash>
local PreviewService   = {}
PreviewService.__index = PreviewService

---@param delay? integer
function PreviewService.new(delay)
	if (_G.PreviewService) then return _G.PreviewService end

	return setmetatable({
		m_hover_start_time = 0,
		m_delay            = delay or 200,
		m_await_spawn      = false,
		m_failed_models    = {},
	}, PreviewService)
end

---@param modelHash integer
---@param entityType eEntityType
function PreviewService:Preview(modelHash, entityType)
	if (self.m_failed_models[modelHash]) then
		return
	end

	ThreadManager:Run(function()
		if (self.m_current_entity) then
			Game.DeleteEntity(self.m_current_entity)
			self.m_current_entity = nil
			self.m_current_pos    = nil
		end

		local loaded = pcall(TaskWait, Game.RequestModel, modelHash)
		if (not loaded) then
			log.fwarning("[PreviewService]: Failed to load model (%d). Model could be blacklisted or online-only.", modelHash)
			self.m_failed_models[modelHash] = true
			return
		end

		local handle
		local coords = vec3:zero()
		local groundZ = 0.0
		local offset = LocalPlayer:GetOffsetInWorldCoords(1, 5, 0)

		_, groundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(
			offset.x,
			offset.y,
			offset.z,
			groundZ,
			false,
			false
		)

		coords = vec3:new(offset.x, offset.y, groundZ + 0.5)

		if (entityType == Enums.eEntityType.Object) then
			handle = Game.CreateObject(
				modelHash,
				coords,
				false,
				false,
				false,
				false,
				LocalPlayer:GetHeading()
			)
		elseif entityType == Enums.eEntityType.Vehicle then
			handle = Game.CreateVehicle(
				modelHash,
				coords,
				LocalPlayer:GetHeading(),
				false,
				false
			)
		elseif entityType == Enums.eEntityType.Ped then
			handle = Game.CreatePed(
				modelHash,
				coords,
				LocalPlayer:GetHeading(),
				false,
				false
			)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
			TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
		end

		if (not handle) then
			log.warning("[PreviewService]: Failed to create entity!")
			return
		end

		ENTITY.SET_ENTITY_ALPHA(handle, 127, false)
		ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
		ENTITY.FREEZE_ENTITY_POSITION(handle, true)
		ENTITY.SET_ENTITY_COLLISION(handle, false, false)

		if (Game.IsOnline() and ENTITY.DOES_ENTITY_EXIST(handle)) then
			entities.take_control_of(handle, 250)
			Game.DesyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(handle))
		end

		self.m_current_entity = handle
		self.current_model    = modelHash
		self.m_current_pos    = coords
	end)
end

---@private
function PreviewService:Rotate()
	ThreadManager:Run(function()
		if not self.m_current_entity or not ENTITY.DOES_ENTITY_EXIST(self.m_current_entity) then
			return
		end

		local heading = ENTITY.GET_ENTITY_HEADING(self.m_current_entity)
		ENTITY.SET_ENTITY_HEADING(self.m_current_entity, (heading - 0.3) % 360)

		if (LocalPlayer:IsMoving()) then
			local groundZ      = 0
			local vec_Offset   = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(LocalPlayer:GetHandle(), 1, 5, 0)
			_, groundZ         = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(
				vec_Offset.x,
				vec_Offset.y,
				vec_Offset.z,
				groundZ,
				false,
				false
			)

			self.m_current_pos = vec3:new(vec_Offset.x, vec_Offset.y, groundZ + 0.5)
			ENTITY.SET_ENTITY_COORDS(
				self.m_current_entity,
				self.m_current_pos.x,
				self.m_current_pos.y,
				self.m_current_pos.z,
				false,
				false,
				false,
				false
			)
		end
	end)
end

---@public
---@return hash?
function PreviewService:GetCurrentModel()
	return self.m_current_model
end

---@public
---@return handle?
function PreviewService:GetCurrentEntity()
	return self.m_current_entity
end

---@public
---@return vec3?
function PreviewService:GetCurrentPosition()
	return self.m_current_pos
end

---@public
function PreviewService:Clear()
	ThreadManager:Run(function()
		if (self.m_current_entity and ENTITY.DOES_ENTITY_EXIST(self.m_current_entity)) then
			Game.DeleteEntity(self.m_current_entity)
		end

		self.m_current_entity      = nil
		self.current_model         = nil
		self.m_current_pos         = nil
		self.m_last_hovered_entity = nil
		self.m_await_spawn         = false
		self.m_hover_start_time    = 0
	end)
end

---@param hoveredModel integer
---@param entityType eEntityType
function PreviewService:OnTick(hoveredModel, entityType)
	local now = Time.Millis()
	if (hoveredModel ~= self.m_last_hovered_entity) then
		self.m_last_hovered_entity = hoveredModel
		self.m_hover_start_time    = now
		self.m_await_spawn         = true
	end

	if (self.m_await_spawn and (now - self.m_hover_start_time >= self.m_delay)) then
		self.m_await_spawn = false
		self:Preview(hoveredModel, entityType)
	end

	if (self.m_current_entity) then
		self:Rotate()
	end
end

function PreviewService:Update()
	if (self.m_current_entity and not GUI:IsOpen()) then
		self:Clear()
	end
end

local singleInstance = PreviewService.new()
_G.PreviewService    = singleInstance
return singleInstance
