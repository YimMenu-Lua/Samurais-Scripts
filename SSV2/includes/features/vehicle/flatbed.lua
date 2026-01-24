---@class TowedVehicle
---@field m_handle handle
---@field m_model hash
---@field m_name string
---@field m_min_size vec3
---@field m_max_size vec3
---@field m_tow_pos vec3
---@field m_has_passenggers boolean
---@field m_passengers table
local TowedVehicle <const> = {}
TowedVehicle.__index = TowedVehicle

function TowedVehicle.new(handle, modelHash, name, towpos)
	local instance             = setmetatable({}, TowedVehicle)
	instance.m_handle          = handle
	instance.m_model           = modelHash
	instance.m_name            = name
	instance.m_tow_pos         = towpos
	instance.m_passengers      = Vehicle(handle):GetOccupants()
	instance.m_has_passenggers = (instance.m_passengers and #instance.m_passengers > 0) or false
	return instance
end

---@class Flatbed
---@field private m_handle number
---@field private m_previous_handle number
---@field private m_heading number
---@field private m_bone_index number
---@field private m_coords vec3
---@field private m_fwd_vec vec3
---@field private m_search_pos vec3
---@field public m_towed_vehicle TowedVehicle
local Flatbed = {}
Flatbed.__index = Flatbed

---@public
Flatbed.modelHash = 1353720154
Flatbed.m_handle = 0
Flatbed.m_previous_handle = 0
Flatbed.towOffset = vec3:new(0.0, 1.0, 0.69)
Flatbed.displayText = ""
Flatbed.shouldPause = false
Flatbed.closestVehicle = {
	isTowable = false,
	isCar = false,
	isBike = false,
	modelHash = 0,
	handle = 0,
	name = "",
}

function Flatbed:Spawn()
	if (not Self:IsOutside()) then
		Notifier:ShowError(
			"Samurais Scripts",
			_T("GENERIC_INTERIOR_ACTION_ERR")
		)
		return
	end

	if (not Self:IsOnFoot()) then
		Notifier:ShowError(
			"Samurais Scripts",
			_T("FLTBD_EXIT_VEH_ERR")
		)
		return
	end

	ThreadManager:Run(function()
		TaskWait(Game.RequestModel, self.modelHash)
		local spawnPos = Self:GetSpawnPosInFront()
		self.m_handle = Game.CreateVehicle(
			self.modelHash,
			spawnPos,
			Self:GetHeading(),
			Game.IsOnline(),
			false
		)

		-- adding a delay because this failed several times to put the player inside the flatbed
		for _ = 1, 50 do
			if (self.m_handle) then
				break
			end

			sleep(1)
		end

		if (not ENTITY.DOES_ENTITY_EXIST(self.m_handle)) then
			Notifier:ShowError(
				"Samurai's Scripts",
				"Failed to spawn a flatbed truck! Please try again later."
			)

			self.m_handle = 0
			return
		end

		Decorator:Register(self.m_handle, "Flatbed", true)
		PED.SET_PED_INTO_VEHICLE(Self:GetHandle(), self.m_handle, -1)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(self.modelHash)
		ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(self.m_handle)
	end)
end

function Flatbed:GetClosestVehicleName()
	if (self.closestVehicle.handle == 0 or self.closestVehicle.modelHash == 0) then
		return ""
	end

	local wrapper = Vehicle(self.closestVehicle.handle)
	return _F("%s %s",
		wrapper:GetManufacturerName(),
		wrapper:GetName()
	)
end

function Flatbed:SetDisplayText()
	if (self.m_towed_vehicle) then
		self.displayText = _F("%s %s.",
			_T("FLTBD_TOWING_TXT"),
			self.m_towed_vehicle.m_name)
	else
		if self.closestVehicle.handle == 0 or self.closestVehicle.name == "" then
			self.displayText = _T("FLTBD_NO_VEH_TXT")
		elseif self.closestVehicle.modelHash == self.modelHash then
			self.displayText = _T("FLTBD_NOT_ALLOWED_TXT")
		else
			self.displayText = _F(
				"%s %s",
				_T("FLTBD_NEARBY_VEH_TXT"),
				self.closestVehicle.name
			)
		end
	end
end

function Flatbed:IsClosestVehicleTowable()
	if (self.closestVehicle.handle == 0 or self.closestVehicle.modelHash == 0) then
		return false
	end

	return GVars.features.flatbed.tow_everything
		or (self.closestVehicle.modelHash == 745926877)
		or not VEHICLE.IS_THIS_MODEL_A_PLANE(self.closestVehicle.handle)
		or not VEHICLE.IS_THIS_MODEL_A_HELI(self.closestVehicle.handle)
end

function Flatbed:Attach()
	if (self.closestVehicle.handle == 0) then
		return
	end

	if (not self.closestVehicle.isTowable) then
		Notifier:ShowWarning("Samurais Scripts", _T("FLTBD_CARS_ONLY_TXT"))
		return
	end

	if (self.closestVehicle.modelHash == self.modelHash) then
		Notifier:ShowWarning("Samurais Scripts", _T("FLTBD_NOT_ALLOWED_TXT"))
		return
	end

	if (not entities.take_control_of(self.closestVehicle.handle, 350)) then
		Notifier:ShowError("Samurais Scripts", _T("GENERIC_ENTITY_CTRL_FAIL"))
		return
	end

	local target = self.closestVehicle
	local minSize, maxSize = Game.GetModelDimensions(
		target.modelHash or
		Game.GetEntityModel(target.handle)
	)

	local centerOffset = vec3:new(
		(minSize.x + maxSize.x) / 2,
		(minSize.y - maxSize.y) / 2,
		(maxSize.z + minSize.z) / 2
	)

	local z_offset = centerOffset.z + self.towOffset.z
	local maxLift = 3.0
	local step = 0.05
	local tries = 0
	local final_z = z_offset
	local success = false

	ENTITY.SET_ENTITY_HEADING(target.handle, self.m_heading)
	ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(target.handle, self.m_handle)
	ENTITY.ATTACH_ENTITY_TO_ENTITY(
		target.handle,
		self.m_handle,
		self.m_bone_index,
		centerOffset.x + self.towOffset.x,
		centerOffset.y + self.towOffset.y,
		z_offset,
		0.0,
		0.0,
		0.0,
		false,
		true,
		true,
		false,
		1,
		true,
		1
	)
	self.m_towed_vehicle = TowedVehicle.new(
		target.handle,
		target.modelHash,
		target.name,
		vec3:new(
			centerOffset.x + self.towOffset.x,
			centerOffset.y + self.towOffset.y,
			z_offset
		)
	)

	sleep(50)
	repeat
		ENTITY.ATTACH_ENTITY_TO_ENTITY(
			self.m_towed_vehicle.m_handle,
			self.m_handle,
			self.m_bone_index,
			centerOffset.x + self.towOffset.x,
			centerOffset.y + self.towOffset.y,
			final_z,
			0.0,
			0.0,
			0.0,
			false,
			true,
			true,
			false,
			1,
			true,
			1
		)
		sleep(1)

		if (not ENTITY.IS_ENTITY_TOUCHING_ENTITY(self.m_handle, self.m_towed_vehicle.m_handle)) then
			success = true
			ENTITY.ATTACH_ENTITY_TO_ENTITY(
				self.m_towed_vehicle.m_handle,
				self.m_handle,
				self.m_bone_index,
				centerOffset.x + self.towOffset.x,
				centerOffset.y + self.towOffset.y,
				final_z - 0.2,
				0.0,
				0.0,
				0.0,
				false,
				true,
				true,
				false,
				1,
				true,
				1
			)
			self.m_towed_vehicle.m_tow_pos.z = final_z - 0.2
			break
		end

		tries = tries + 1
		final_z = final_z + step
	until success or tries > (maxLift / step)
	Decorator:Register(self.m_towed_vehicle.m_handle, "Flatbed", true)
end

---@param x float
---@param y float
---@param z float
function Flatbed:MoveAttachment(x, y, z)
	if (not self.m_towed_vehicle) then
		return
	end

	local modifier = 1

	if (KeyManager:IsKeyPressed(eVirtualKeyCodes.SHIFT)) then
		modifier = 10
	end

	self.m_towed_vehicle.m_tow_pos.x = self.m_towed_vehicle.m_tow_pos.x + x * modifier
	self.m_towed_vehicle.m_tow_pos.y = self.m_towed_vehicle.m_tow_pos.y + y * modifier
	self.m_towed_vehicle.m_tow_pos.z = self.m_towed_vehicle.m_tow_pos.z + z * modifier

	ENTITY.ATTACH_ENTITY_TO_ENTITY(
		self.m_towed_vehicle.m_handle,
		self.m_handle,
		self.m_bone_index,
		self.m_towed_vehicle.m_tow_pos.x,
		self.m_towed_vehicle.m_tow_pos.y,
		self.m_towed_vehicle.m_tow_pos.z,
		0.0,
		0.0,
		0.0,
		false,
		false,
		false,
		false,
		2,
		true,
		1
	)
end

function Flatbed:AttachPhysically()
	if (self.closestVehicle.handle == 0) then
		return
	end

	if (not self.closestVehicle.isTowable) then
		Notifier:ShowWarning(
			"Samurais Scripts",
			_T("FLTBD_CARS_ONLY_ERR")
		)
		return
	end

	if (self.closestVehicle.modelHash == self.modelHash) then
		Notifier:ShowWarning(
			"Samurais Scripts",
			_T("FLTBD_SAME_NOT_ALLOWED_ERR")
		)
		return
	end

	if (not entities.take_control_of(self.closestVehicle.handle, 350)) then
		Notifier:ShowError(
			"Samurais Scripts",
			_T("GENERIC_ENTITY_CTRL_FAIL")
		)
		return
	end

	local target = self.closestVehicle
	local minSize, maxSize = Game.GetModelDimensions(
		target.modelHash or
		Game.GetEntityModel(target.handle)
	)

	local centerOffset = vec3:new(
		(minSize.x + maxSize.x) / 2,
		(minSize.y - maxSize.y),
		(maxSize.z + minSize.z) / 2
	)

	local z_offset = centerOffset.z + self.towOffset.z
	sleep(100)
	ENTITY.SET_ENTITY_HEADING(target.handle, self.m_heading)
	ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(
		target.handle,
		self.m_handle,
		-1,
		self.m_bone_index,
		centerOffset.x + self.towOffset.x,
		centerOffset.y + self.towOffset.y,
		z_offset,
		centerOffset.x + self.towOffset.x,
		centerOffset.y + self.towOffset.y + 2,
		z_offset - 1.1,
		0.0,
		0.0,
		0.0,
		999.9,
		true,
		false,
		false,
		false,
		2
	)

	self.m_towed_vehicle = TowedVehicle.new(
		target.handle,
		target.modelHash,
		target.name,
		vec3:new(
			centerOffset.x + self.towOffset.x,
			centerOffset.y + self.towOffset.y + 2,
			z_offset - 1.1
		)
	)
end

function Flatbed:Detach()
	if (Self:GetVehicle():IsFlatbedTruck()
			and self.m_towed_vehicle
			and (self.m_towed_vehicle.m_handle ~= 0)
			and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(self.m_towed_vehicle.m_handle, self.m_previous_handle)
		) then
		local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(self.m_towed_vehicle.m_handle, false)
		if (entities.take_control_of(self.m_towed_vehicle.m_handle, 350)) then
			ENTITY.DETACH_ENTITY(self.m_towed_vehicle.m_handle, true, true)
			ENTITY.SET_ENTITY_COORDS(
				self.m_towed_vehicle.m_handle,
				attachedVehcoords.x - (self.m_fwd_vec.x * 10),
				attachedVehcoords.y - (self.m_fwd_vec.y * 10),
				self.m_coords.z,
				false,
				false,
				false,
				false
			)
			VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.m_towed_vehicle.m_handle, 5.0)
		end

		Decorator:RemoveEntity(self.m_towed_vehicle.m_handle)
		self.m_towed_vehicle = nil
	end
end

function Flatbed:ForceCleanup()
	for _, v in ipairs(entities.get_all_vehicles_as_handles()) do
		local modelHash = ENTITY.GET_ENTITY_MODEL(v)
		local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(self.m_previous_handle, modelHash)

		if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) and entities.take_control_of(attachedVehicle, 350) then
			local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attachedVehicle, false)
			ENTITY.DETACH_ENTITY(attachedVehicle, true, true)
			ENTITY.SET_ENTITY_COORDS(
				attachedVehicle,
				attachedVehcoords.x - (self.m_fwd_vec.x * 10),
				attachedVehcoords.y - (self.m_fwd_vec.y * 10),
				attachedVehcoords.z,
				false,
				false,
				false,
				false
			)
			VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attachedVehicle, 5.0)
			Decorator:RemoveEntity(self.m_towed_vehicle.m_handle)
			self.m_towed_vehicle = nil
		end
	end
end

function Flatbed:OnKeyPress()
	if self.m_towed_vehicle then
		self:Detach()
	else
		self:Attach()
	end
end

function Flatbed:Reset()
	self.closestVehicle = {
		isTowable = false,
		modelHash = 0,
		handle = 0,
		name = "",
	}

	if self.m_towed_vehicle then
		Decorator:RemoveEntity(self.m_towed_vehicle.m_handle)
	end

	Decorator:RemoveEntity(self.m_handle)
	self.m_previous_handle = 0
	self.m_search_pos = vec3:zero()
	self.m_fwd_vec = vec3:zero()
	self.m_towed_vehicle = nil
	self.m_bone_index = -1
	self.m_heading = 0
	self.m_coords = vec3:zero()
	self.m_handle = 0
end

function Flatbed:OnTick()
	if (not Self:GetVehicle():IsFlatbedTruck()) then
		if (self.m_handle ~= 0 and not ENTITY.DOES_ENTITY_EXIST(self.m_handle)) then
			self:Reset()
		end

		sleep(1000)
		return
	end

	if (self.m_previous_handle == 0) then
		self.m_previous_handle = self.m_handle
	elseif (self.m_previous_handle ~= self.m_handle) then
		self:Detach()
		sleep(50)
		self:Reset()
	end

	self.m_handle = Self:GetVehicleNative()
	self.m_heading = Game.GetHeading(self.m_handle)
	self.m_coords = Game.GetEntityCoords(self.m_handle, false)
	self.m_fwd_vec = Game.GetForwardVector(self.m_previous_handle or self.m_handle)
	self.m_bone_index = Game.GetEntityBoneIndexByName(self.m_handle, "chassis")
	self.m_search_pos = vec3:new(
		self.m_coords.x - (self.m_fwd_vec.x * 10),
		self.m_coords.y - (self.m_fwd_vec.y * 10),
		self.m_coords.z
	)

	self.closestVehicle.handle = Game.GetClosestVehicle(self.m_search_pos, 5, self.m_handle)
	self.closestVehicle.modelHash = self.closestVehicle.handle ~= 0 and
		Game.GetEntityModel(self.closestVehicle.handle) or 0
	self.closestVehicle.name = self:GetClosestVehicleName()
	self.closestVehicle.isTowable = self:IsClosestVehicleTowable()

	self:SetDisplayText()

	if (not self.m_towed_vehicle and Self:IsDriving()) then
		if (GVars.features.flatbed.show_towing_position) then
			GRAPHICS.DRAW_MARKER_SPHERE(
				self.m_search_pos.x,
				self.m_search_pos.y,
				self.m_search_pos.z,
				3.0,
				180,
				128,
				0,
				0.115
			)
		end

		if (GVars.features.flatbed.show_esp and self.closestVehicle.handle) ~= 0 then
			Game.DrawBoundingBox(self.closestVehicle.handle, Color("yellow"))
		end
	end

	if KeyManager:IsKeybindJustPressed("flatbed") then
		self:OnKeyPress()
	end
end

Backend:RegisterEventCallbackAll(function()
	Flatbed:ForceCleanup()
end)

return Flatbed
