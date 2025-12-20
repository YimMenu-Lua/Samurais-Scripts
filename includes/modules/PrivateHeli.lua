require("includes.modules.Vehicle")

-----------------------------------------------------
-- Private Heli Class
-----------------------------------------------------
---@class PrivateHeli : Vehicle
---@field model table
---@field m_handle integer
---@field name string
---@field pilot integer
---@field pilotName string
---@field blip table<string, integer> -- {handle = handle, alpha = alpha}
---@field allowsRappelling boolean
---@field lastTaskCoords vec3
---@field lastCheckTime integer
---@field isFarAway boolean
---@field radio { isOn: boolean, stationName: string }
---@field isReady boolean
local PrivateHeli = Class("PrivateHeli", Vehicle)
PrivateHeli.pilotModel = 0xE75B4B1C -- S_M_M_Pilot_01

---@param model integer
---@param spawnPos vec3
---@param godmode? boolean
function PrivateHeli.spawn(model, spawnPos, godmode)
	local pilot = Game.CreatePed(PrivateHeli.pilotModel, vec3:zero())

	if not Game.IsScriptHandle(pilot) then
		Backend:debug("Failed to create ped.")
		return
	end

	ENTITY.FREEZE_ENTITY_POSITION(pilot, true)

	local vehicle = Vehicle:Create(
		model,
		eEntityType.Vehicle,
		vec3:zero(),
		Self:GetHeading(-90),
		Game.IsOnline(),
		false
	)

	local handle = vehicle:GetHandle()
	if (not Game.IsScriptHandle(handle)) then
		Backend:debug("Failed to create heli.")
		return
	end

	ENTITY.FREEZE_ENTITY_POSITION(handle, true)
	ENTITY.SET_ENTITY_INVINCIBLE(handle, godmode or false)
	ENTITY.SET_ENTITY_INVINCIBLE(pilot, godmode or false)

	if (Game.IsOnline()) then
		entities.take_control_of(pilot, 300)
		entities.take_control_of(handle, 300)
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(pilot))
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(handle))
	end

	ENTITY.FREEZE_ENTITY_POSITION(pilot, false)
	PED.SET_PED_INTO_VEHICLE(pilot, handle, -1)
	PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(pilot, 1)
	PED.SET_PED_CAN_BE_SHOT_IN_VEHICLE(pilot, false)
	PED.SET_PED_CAN_BE_DRAGGED_OUT(pilot, false)
	PED.SET_PED_CAN_BE_TARGETTED(pilot, false)
	PED.SET_PED_CONFIG_FLAG(pilot, 251, true)
	PED.SET_PED_CONFIG_FLAG(pilot, 255, true)
	PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 3, false)
	PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 17, false)
	PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 20, true)
	PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pilot, true)

	VEHICLE.SET_VEHICLE_INDIVIDUAL_DOORS_LOCKED(handle, 0, 2)
	VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(handle, false)
	VEHICLE.SET_VEHICLE_STRONG(handle, true)
	VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(handle, false, false)
	VEHICLE.SET_VEHICLE_OCCUPANTS_TAKE_EXPLOSIVE_DAMAGE(handle, false)
	VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, false, false)
	sleep(500)

	ENTITY.FREEZE_ENTITY_POSITION(handle, false)
	VEHICLE.SET_HELI_BLADES_SPEED(handle, 1.0)
	Game.SetEntityCoords(handle, spawnPos, true, true, true, true)
	Game.FadeInEntity(pilot)
	Game.FadeInEntity(handle)

	local heliBlip = Game.AddBlipForEntity(handle)
	Game.SetBlipSprite(heliBlip, 422)
	Game.SetBlipName(heliBlip, "Private Heli")

	AUDIO.SET_VEH_RADIO_STATION(handle, "RADIO_22_DLC_BATTLE_MIX1_RADIO")

	local heli = setmetatable(
		{
			m_modelhash = model,
			m_handle = handle,
			name = Vehicle(handle):GetName() or "Private Helicopter",
			pilot = pilot,
			pilotName = BillionaireServices:GetRandomPedName(Enums.ePedGender.MALE),
			allowsRappelling = VEHICLE.DOES_VEHICLE_ALLOW_RAPPEL(handle),
			isReady = false,
			isPlayerRappelling = false,
			wasDismissed = false,
			altitude = vehicle:GetHeightAboveGround(),
			task = Enums.eVehicleTask.NONE,
			blip = {
				handle = heliBlip,
				alpha = 255
			},
			radio = {
				isOn = true,
				stationName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
			},
			lastCheckTime = Time.now() + 3
		},
		PrivateHeli
	)

	return heli
end

function PrivateHeli:Exists()
	return self.m_handle ~= 0
		and self.pilot ~= 0
		and Backend:IsScriptEntity(self.m_handle)
		and Backend:IsScriptEntity(self.pilot)
end

function PrivateHeli:IsIdle()
	return self.task == Enums.eVehicleTask.NONE
		or self.task == Enums.eVehicleTask.HOVER_IN_PLACE
end

function PrivateHeli:IsPlayerInHeli()
	if (not self.m_handle) then
		return false
	end

	if (self.isPlayerRappelling) then
		return false
	end

	local PV = Self:GetVehicleNative()
	return (PV ~= 0 and self.m_handle == PV)
end

function PrivateHeli:IsFarAwayFromBoss()
	return not self:IsPlayerInHeli()
		and Self:GetPos():distance(self:GetPos()) > 50
end

function PrivateHeli:GetTaskAsString()
	return BillionaireServices.VehicleTaskToString[self.task or -1]
end

---@param toggle boolean
function PrivateHeli:ToggleBlip(toggle)
	if not self.blip or not self.blip.handle then
		return
	end

	local targetAlpha = toggle and 255 or 0
	local cond = toggle and (self.blip.alpha < targetAlpha) or (self.blip.alpha > targetAlpha)

	if cond then
		self.blip.alpha = targetAlpha
		if HUD.DOES_BLIP_EXIST(self.blip.handle) then
			HUD.SET_BLIP_ALPHA(self.blip.handle, targetAlpha)
		end
	end
end

---@param speechName string
---@param speechParams? string
function PrivateHeli:PilotSpeak(speechName, speechParams)
	AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(
		self.pilot,
		speechName,
		speechParams or "SPEECH_PARAMS_FORCE_SHOUTED",
		0
	)
end

function PrivateHeli:WarpPlayer()
	script.run_in_fiber(function()
		if self:IsPlayerInHeli() or self.isPlayerRappelling then
			return
		end
		local seatIndex = VEHICLE.IS_VEHICLE_SEAT_FREE(self.m_handle, 2, true) and 2 or -2
		Self:ClearTasksImmediately()
		self:WarpPed(Self:GetHandle(), seatIndex)
	end)
end

---@param s script_util
function PrivateHeli:Bring(s)
	if not Self:IsOutside() then
		Toast:ShowError(
			"Private Heli",
			"You can not bring your private helicopter indoors."
		)
		return
	end

	local playerPos = Self:GetPos()
	if (self.altitude < 3) then
		if playerPos:distance(self:GetPos()) < 10 then
			Toast:ShowWarning(
				"Private Heli",
				"Your helicopter is already closeby."
			)
			return
		end
	end

	local tpPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		Self:GetHandle(),
		0.0,
		10.0,
		20.0
	)

	Game.SetEntityHeading(self.m_handle, Self:GetHeading(-90))
	Game.SetEntityCoords(self.m_handle, tpPos, true, true, true, true)
	s:sleep(100)
	self:LandHere()
end

function PrivateHeli:HoverInPlace()
	if not self:Exists() or self.isPlayerRappelling then
		return
	end

	self:PilotSpeak("GENERIC_YES")
	TASK.CLEAR_PED_TASKS(self.pilot)
	TASK.CLEAR_PED_SECONDARY_TASK(self.pilot)
	TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.m_handle)
	TASK.TASK_VEHICLE_TEMP_ACTION(self.pilot, self.m_handle, 1, 2000)
	self.task = Enums.eVehicleTask.HOVER_IN_PLACE
end

function PrivateHeli:CancelAnyTasks()
	self:HoverInPlace()
	self.lastTaskCoords = nil
end

---@param s script_util
function PrivateHeli:SkipTrip(s)
	if not self:Exists()
		or self.isPlayerRappelling
		or self.task ~= Enums.eVehicleTask.GOTO
		or not self.lastTaskCoords then
		return
	end

	local heading = Game.GetHeading(self.m_handle)
	CAM.DO_SCREEN_FADE_OUT(1000)
	s:sleep(1000)
	VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.m_handle, 0)
	s:sleep(500)
	ENTITY.SET_ENTITY_COORDS(
		self.m_handle,
		self.lastTaskCoords.x,
		self.lastTaskCoords.y,
		self.lastTaskCoords.z + 8.0,
		true,
		true,
		true,
		true
	)

	MISC.CLEAR_AREA_OF_VEHICLES(
		self.lastTaskCoords.x,
		self.lastTaskCoords.y,
		self.lastTaskCoords.z,
		5.0,
		false,
		false,
		false,
		false,
		false,
		false,
		0
	)

	ENTITY.SET_ENTITY_HEADING(self.m_handle, heading)
	s:sleep(50)
	self:LandHere()
	s:sleep(1000)
	CAM.DO_SCREEN_FADE_IN(1000)

	self.task = Enums.eVehicleTask.NONE
	self.lastTaskCoords = nil
end

---@param v_Pos vec3
---@param landOnArrival? boolean
function PrivateHeli:FlyTo(v_Pos, landOnArrival)
	self:CancelAnyTasks()
	self.task = Enums.eVehicleTask.GOTO
	self.lastTaskCoords = v_Pos
	self:PilotSpeak("CHAT_RESP")

	TASK.TASK_HELI_MISSION(
		self.pilot,
		self.m_handle,
		0,
		0,
		v_Pos.x,
		v_Pos.y,
		v_Pos.z,
		4,
		50.0,
		4.0,
		-1,
		-1,
		100,
		100.0,
		landOnArrival and 32 or 0
	)
end

function PrivateHeli:LandHere()
	self:CancelAnyTasks()
	self.task = Enums.eVehicleTask.LAND

	local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		self.m_handle,
		0.0,
		0.0,
		-0.1
	)

	self:PilotSpeak("GENERIC_YES")
	TASK.TASK_HELI_MISSION(
		self.pilot,
		self.m_handle,
		0,
		0,
		pos.x,
		pos.y,
		pos.z,
		19,
		8,
		1.0,
		0,
		-1,
		3,
		10.0,
		32
	)
end

function PrivateHeli:Cleanup()
	Game.DeleteEntity(self.pilot)
	Game.DeleteEntity(self.m_handle)
	Decorator:RemoveEntity(self.pilot, "BillionaireServices")
	Decorator:RemoveEntity(self.m_handle, "BillionaireServices")

	self.pilot = nil
	self.m_handle = nil
end

function PrivateHeli:ForceCleanup()
	ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.pilot, true, true)
	ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.m_handle, true, true)
	ENTITY.DELETE_ENTITY(self.pilot)
	ENTITY.DELETE_ENTITY(self.m_handle)
end

function PrivateHeli:Dismiss()
	if (self.isPlayerRappelling) then
		return
	end

	script.run_in_fiber(function(s)
		self.wasDismissed = true
		if self:IsPlayerInHeli() then
			if self.altitude > 5 then
				self:LandHere()
				Toast:ShowMessage(
					"Samurai's Scripts",
					"[Heli Service]: Please wait for your pilot to land. Or just jump off..."
				)
				repeat
					s:sleep(100)
				until self.altitude <= 3 or not self:IsPlayerInHeli()
			end

			for _, ped in ipairs(self:GetOccupants()) do
				if ped and Game.IsScriptHandle(ped) and (ped ~= self.pilot) then
					TASK.TASK_LEAVE_VEHICLE(ped, self.m_handle, 1)
					repeat
						s:sleep(100)
					until not PED.IS_PED_IN_VEHICLE(ped, self.m_handle, false)
				end
			end
			s:sleep(1000)
		end

		local v_DummyDestination = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			self.m_handle,
			math.random(-1000, 1000),
			math.random(-1000, 1000),
			500
		)

		self:PilotSpeak("GENERIC_BYE")
		self:FlyTo(v_DummyDestination)
		self.task = Enums.eVehicleTask.GO_HOME

		s:sleep(9e3)
		Game.FadeOutEntity(self.m_handle)
		Game.FadeOutEntity(self.pilot)
		s:sleep(1e3)
		self:Cleanup()
	end)
end

function PrivateHeli:StateEval()
	if self.lastCheckTime and self.lastCheckTime > Time.now() then
		return
	end

	if not Game.IsScriptHandle(self.m_handle)
		or not ENTITY.IS_ENTITY_A_VEHICLE(self.m_handle) then
		BillionaireServices:RemoveHeli()
	end

	if not Game.IsScriptHandle(self.pilot)
		or ENTITY.IS_ENTITY_DEAD(self.pilot, false)
		or not ENTITY.IS_ENTITY_A_PED(self.pilot) then
		BillionaireServices:RemoveHeli()
	end

	if not VEHICLE.IS_VEHICLE_DRIVEABLE(self.m_handle, false) then
		self:Repair(true)
	end

	if ENTITY.IS_ENTITY_IN_WATER(self.m_handle) then
		local roadNode, roadHeading = Game.GetClosestVehicleNodeWithHeading(
			Self:GetPos(),
			0
		)

		if (not roadNode:is_zero()) then
			Game.SetEntityHeading(self.m_handle, roadHeading)
			Game.SetEntityCoords(self.m_handle, roadNode)
		end
	end

	if not self:IsIdle() then
		if self.altitude >= 5 then
			local parachuteState = PED.GET_PED_PARACHUTE_STATE(Self:GetHandle())
			if PED.IS_PED_IN_PARACHUTE_FREE_FALL(Self:GetHandle())
				or parachuteState > 0
				or Self:IsFalling() then
				self:PilotSpeak("GENERIC_SHOCKED_HIGH", "SPEECH_PARAMS_FORCE_HELI")
				Toast:ShowMessage(
					"Private Heli",
					"Ayo! Is bro okay?"
				)
				self:HoverInPlace()
				return
			end
		end

		if (self.task == Enums.eVehicleTask.GOTO) and self.lastTaskCoords then
			local heliCoords = self:GetPos()
			local normalizedHeliCoords = vec3:new(heliCoords.x, heliCoords.y, 0)
			local normalizedTaskCoords = vec3:new(self.lastTaskCoords.x, self.lastTaskCoords.y, 0)

			if normalizedHeliCoords:distance(normalizedTaskCoords) <= 50 then
				Toast:ShowMessage(
					"Samurai's Scripts",
					"[Private Heli]: You have reached your destination."
				)
				self.task = Enums.eVehicleTask.NONE
			end
		end

		if self.task == Enums.eVehicleTask.LAND and self.altitude <= 3 then
			self.task = Enums.eVehicleTask.NONE
		end
	end

	if self:IsPlayerInHeli() then
		self.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(self.m_handle)
		self.radio.stationName = self.radio.isOn
			and HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
			or "Off"
	end

	self:ToggleBlip(not self:IsPlayerInHeli())
	self.altitude = self:GetHeightAboveGround()
	self.isFarAway = self:IsFarAwayFromBoss()
	self.isPlayerRappelling = self.allowsRappelling and (self.altitude > 3) and
		VEHICLE.IS_ANY_PED_RAPPELLING_FROM_HELI(self.m_handle)
	self.lastCheckTime = Time.now() + 2
end

------------------------------------------------------------------------
--- Data
------------------------------------------------------------------------

PrivateHeli.Models = {
	Pair.new("Annihilator", 837858166),
	Pair.new("Annihilator Stealth", 295054921),
	Pair.new("Maverick", 2634305738),
	Pair.new("Police Maverick", 353883353),
	Pair.new("Savage", 4212341271),
	Pair.new("SuperVolito", 710198397),
	Pair.new("SuperVolito Carbon", 2623428164),
	Pair.new("Swift Flying Bravo", 3955379698),
	Pair.new("Swift Deluxe", 1075432268),
	Pair.new("Valkyrie", 2694714877),
	Pair.new("Volatus", 2449479409),
}

PrivateHeli.PresetDestinations = {
	Pair.new("Sandy Shores Helipad", vec3:new(1770.17, 3239.85, 42.1217)),
	Pair.new("Paleto Bay Sheriff's Office", vec3:new(-475.02, 5988.46, 31.3367)),
	Pair.new("Fort Zancudo Helipad", vec3:new(-1859.4, 2795.65, 32.8066)),
	Pair.new("The Diamond Casino Helipad", vec3:new(967.052, 42.1343, 123.127)),
	Pair.new("Vinewood Police Station", vec3:new(579.992, 12.3636, 103.234)),
	Pair.new("Hawick Agency Helipad", vec3:new(393.284, -66.3109, 124.376)),
	Pair.new("Richard's Majestic Helipad", vec3:new(-913.493, -378.444, 137.906)),
	Pair.new("Rockford Hills Agency Helipad", vec3:new(-1007.68, -415.99, 80.1686)),
	Pair.new("Vespucci Canals Agency Helipad", vec3:new(-1010.76, -756.875, 81.7484)),
	Pair.new("Little Seoul Agency Helipad", vec3:new(-597.602, -716.92, 131.04)),
	Pair.new("Lombank Office Helipad", vec3:new(-1581.9, -569.51, 116.328)),
	Pair.new("Mazebank West Office Helipad", vec3:new(-1391.7, -477.587, 91.2508)),
	Pair.new("Mazebank Tower Helipad", vec3:new(-75.2834, -819.323, 326.175)),
	Pair.new("Arcadius Office Helipad", vec3:new(-144.582, -593.811, 211.775)),
}

return PrivateHeli
