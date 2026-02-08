-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class PreviewService
---@field m_current handle
---@field m_current_model hash
---@field m_current_pos vec3
---@field lastHovered handle
local PreviewService = {}
PreviewService.__index = PreviewService
PreviewService.hoverStartTime = 0
PreviewService.m_delay = 200 -- feels janky but prevents immediate spawn when hovering over an item
PreviewService.awaitSpawn = false


---@param modelHash integer
---@param entityType eEntityType
function PreviewService:Preview(modelHash, entityType)
	script.run_in_fiber(function()
		if self.m_current then
			Game.DeleteEntity(self.m_current)
			self.m_current = nil
			self.m_current_pos = nil
		end

		TaskWait(Game.RequestModel, modelHash)
		local handle
		local coords = vec3:zero()
		local groundZ = 0.0
		local offset = Self:GetOffsetInWorldCoords(1, 5, 0)

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
				Self:GetHeading()
			)
		elseif entityType == Enums.eEntityType.Vehicle then
			handle = Game.CreateVehicle(
				modelHash,
				coords,
				Self:GetHeading(),
				false,
				false
			)
		elseif entityType == Enums.eEntityType.Ped then
			handle = Game.CreatePed(
				modelHash,
				coords,
				Self:GetHeading(),
				false,
				false
			)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
			TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
		end

		ENTITY.SET_ENTITY_ALPHA(handle, 127, false)
		ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
		ENTITY.FREEZE_ENTITY_POSITION(handle, true)
		ENTITY.SET_ENTITY_COLLISION(handle, false, false)

		if (Game.IsOnline() and ENTITY.DOES_ENTITY_EXIST(handle)) then
			entities.take_control_of(handle, 250)
			Game.DesyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(handle))
		end

		self.m_current = handle
		self.current_model = modelHash
		self.m_current_pos = coords
	end)
end

function PreviewService:Rotate()
	script.run_in_fiber(function()
		if not self.m_current or not ENTITY.DOES_ENTITY_EXIST(self.m_current) then
			return
		end

		local heading = ENTITY.GET_ENTITY_HEADING(self.m_current)
		ENTITY.SET_ENTITY_HEADING(self.m_current, (heading - 0.3) % 360)

		if Self:IsMoving() then
			local groundZ = 0
			local vec_Offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Self:GetHandle(), 1, 5, 0)
			_, groundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(
				vec_Offset.x,
				vec_Offset.y,
				vec_Offset.z,
				groundZ,
				false,
				false
			)

			self.m_current_pos = vec3:new(vec_Offset.x, vec_Offset.y, groundZ + 0.5)
			ENTITY.SET_ENTITY_COORDS(
				self.m_current,
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

---@param hoveredModel integer
---@param entityType eEntityType
function PreviewService:OnTick(hoveredModel, entityType)
	local now = Time.millis()
	if (hoveredModel ~= self.lastHovered) then
		self.lastHovered = hoveredModel
		self.hoverStartTime = now
		self.awaitSpawn = true
	end

	if (self.awaitSpawn and (now - self.hoverStartTime >= self.m_delay)) then
		self.awaitSpawn = false
		self:Preview(hoveredModel, entityType)
	end

	if (self.m_current) then
		self:Rotate()
	end
end

function PreviewService:Clear()
	ThreadManager:Run(function()
		if (self.m_current and ENTITY.DOES_ENTITY_EXIST(self.m_current)) then
			Game.DeleteEntity(self.m_current)
		end

		self.m_current = nil
		self.current_model = nil
		self.m_current_pos = nil
		self.lastHovered = nil
		self.awaitSpawn = false
		self.hoverStartTime = 0
	end)
end

function PreviewService:Update()
	if (self.m_current and not GUI:IsOpen()) then
		self:Clear()
	end
end

return PreviewService
