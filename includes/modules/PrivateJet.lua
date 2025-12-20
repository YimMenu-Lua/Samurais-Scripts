require("includes.modules.Vehicle")

-----------------------------------------------------
-- Private Jet Class
-----------------------------------------------------
---@class PrivateJet : Vehicle
---@field private m_modelhash integer
---@field private m_handle integer
---@field pilot integer
---@field copilot integer
---@field name string
---@field pilotName string
---@field copilotName string
---@field blip { handle: handle, alpha: integer }
---@field radio { isOn: boolean, stationName: string }
---@field task VehicleTask
---@field departureAirport table
---@field arrivalAirport table
---@field lastTaskCoords vec3
---@field lastCheckTime integer
---@field canWarpPlayer boolean
local PrivateJet = Class("PrivateJet", Vehicle)
PrivateJet.wasDismissed = false
PrivateJet.pilotModel = 0xE75B4B1C   -- S_M_M_Pilot_01
PrivateJet.copilotModel = 0x864ED68E -- IG_Pilot
PrivateJet.task = Enums.eVehicleTask.NONE or -1
PrivateJet.radio = { isOn = false, stationName = "OFF" }


---@param model integer
---@param airportData table
function PrivateJet.spawn(model, airportData)
	local pilot = Game.CreatePed(PrivateJet.pilotModel, vec3:zero())

	if not Game.IsScriptHandle(pilot) then
		Backend:debug("Failed to create ped.")
		return
	end

	ENTITY.FREEZE_ENTITY_POSITION(pilot, true)

	local copilot = Game.CreatePed(PrivateJet.copilotModel, vec3:zero())

	if not Game.IsScriptHandle(copilot) then
		Game.DeleteEntity(pilot)
		Backend:debug("Failed to create ped.")
		return
	end

	ENTITY.FREEZE_ENTITY_POSITION(copilot, true)

	local vehicle = Vehicle:Create(model, eEntityType.Vehicle, vec3:zero(), airportData.hangar.heading)
	local handle = vehicle:GetHandle()
	if (not Game.IsScriptHandle(handle)) then
		Game.DeleteEntity(pilot)
		Game.DeleteEntity(copilot)
		Backend:debug("Failed to create vehicle.")
		return
	end

	ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(handle, true, true)
	ENTITY.FREEZE_ENTITY_POSITION(handle, true)
	VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(handle, false)
	VEHICLE.SET_VEHICLE_STRONG(handle, true)
	VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(handle, false, false)
	VEHICLE.SET_VEHICLE_OCCUPANTS_TAKE_EXPLOSIVE_DAMAGE(handle, false)
	ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
	ENTITY.SET_ENTITY_INVINCIBLE(pilot, true)
	ENTITY.SET_ENTITY_INVINCIBLE(copilot, true)
	STREAMING.REQUEST_COLLISION_AT_COORD(
		airportData.hangar.pos.x,
		airportData.hangar.pos.y,
		airportData.hangar.pos.z
	)

	if (Game.IsOnline()) then
		entities.take_control_of(pilot, 300)
		entities.take_control_of(copilot, 300)
		entities.take_control_of(handle, 300)
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(pilot))
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(copilot))
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(handle))
	end

	ENTITY.FREEZE_ENTITY_POSITION(pilot, false)
	ENTITY.FREEZE_ENTITY_POSITION(copilot, false)
	PED.SET_PED_INTO_VEHICLE(pilot, handle, -1)
	PED.SET_PED_INTO_VEHICLE(copilot, handle, 0)
	ENTITY.FREEZE_ENTITY_POSITION(handle, false)

	Game.SetEntityCoordsNoOffset(handle, airportData.hangar.pos)
	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(handle, 5.0)
	VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, false)

	PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(pilot, 1)
	PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(copilot, 1)
	PED.SET_PED_CAN_BE_SHOT_IN_VEHICLE(pilot, false)
	PED.SET_PED_CAN_BE_SHOT_IN_VEHICLE(copilot, false)
	PED.SET_PED_CAN_BE_DRAGGED_OUT(pilot, false)
	PED.SET_PED_CAN_BE_DRAGGED_OUT(copilot, false)
	PED.SET_PED_CAN_BE_TARGETTED(pilot, false)
	PED.SET_PED_CAN_BE_TARGETTED(copilot, false)
	PED.SET_PED_CONFIG_FLAG(pilot, 177, true)
	PED.SET_PED_CONFIG_FLAG(copilot, 177, true)
	PED.SET_PED_CONFIG_FLAG(pilot, 251, true)
	PED.SET_PED_CONFIG_FLAG(copilot, 251, true)
	PED.SET_PED_CONFIG_FLAG(pilot, 255, true)
	PED.SET_PED_CONFIG_FLAG(copilot, 255, true)
	PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 3, false)
	PED.SET_PED_COMBAT_ATTRIBUTES(copilot, 3, false)
	PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 17, false)
	PED.SET_PED_COMBAT_ATTRIBUTES(copilot, 17, false)
	PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 20, true)
	PED.SET_PED_COMBAT_ATTRIBUTES(copilot, 20, true)
	PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pilot, true)
	PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(copilot, true)

	while (not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)) do
		yield()
	end

	sleep(1000)
	vehicle:Repair(true)
	AUDIO.SET_VEHICLE_RADIO_ENABLED(handle, true)
	AUDIO.SET_VEH_RADIO_STATION(handle, "RADIO_22_DLC_BATTLE_MIX1_RADIO")
	AUDIO.SET_VEHICLE_RADIO_LOUD(handle, true)
	VEHICLE.SET_VEHICLE_DOOR_OPEN(handle, 0, false, false)

	Game.FadeInEntity(pilot)
	Game.FadeInEntity(copilot)
	Game.FadeInEntity(handle)

	local blip = Game.AddBlipForEntity(handle)
	Game.SetBlipSprite(blip, 423)
	Game.SetBlipName(blip, "Private Jet")

	local jet = setmetatable(
		{
			m_modelhash = model,
			m_handle = handle,
			name = vehicle:GetName() or "Private Jet",
			pilot = pilot,
			copilot = copilot,
			pilotName = BillionaireServices:GetRandomPedName(Enums.ePedGender.MALE),
			copilotName = BillionaireServices:GetRandomPedName(Enums.ePedGender.MALE),
			blip = {
				handle = blip,
				alpha = 255
			},
			radio = {
				isOn = true,
				stationName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
			},
			wasDismissed = false,
			task = Enums.eVehicleTask.NONE,
			lastCheckTime = Time.now() + 3
		},
		PrivateJet
	)

	return jet
end

function PrivateJet:Exists()
	return self.m_handle ~= 0
		and self.pilot ~= 0
		and Backend:IsScriptEntity(self.m_handle)
		and Backend:IsScriptEntity(self.pilot)
end

function PrivateJet:GetCruiseAltitude()
	return not self.arrivalAirport and 600 or 0
end

function PrivateJet:IsIdle()
	return self.task == Enums.eVehicleTask.NONE
end

function PrivateJet:IsCruising()
	return self.task == Enums.eVehicleTask.GOTO
		and self:GetHeightAboveGround() > 20
		and self:GetSpeed() > 20
end

---@param altitude number
function PrivateJet:IsCruisingAtAltitude(altitude)
	return self.task == Enums.eVehicleTask.GOTO
		and self:GetHeightAboveGround() >= altitude
		and self:GetSpeed() > 20
end

function PrivateJet:IsPlayerInJet()
	if not Game.IsScriptHandle(self.m_handle) then
		return false
	end

	local playerVeh = Self:GetVehicleNative()
	return (playerVeh ~= 0 and self.m_handle == playerVeh)
end

function PrivateJet:IsFarAwayFromBoss()
	return not self:IsPlayerInJet()
		and Self:GetPos():distance(self:GetPos()) > 500
end

function PrivateJet:GetTaskAsString()
	return BillionaireServices.VehicleTaskToString[self.task or -1]
end

---@param toggle boolean
function PrivateJet:ToggleBlip(toggle)
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
function PrivateJet:PilotSpeak(speechName, speechParams)
	AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(
		self.pilot,
		speechName,
		speechParams or "SPEECH_PARAMS_FORCE_SHOUTED",
		0
	)
end

function PrivateJet:WarpPlayer()
	script.run_in_fiber(function()
		if self:IsPlayerInJet() then
			return
		end

		local seatIndex = VEHICLE.IS_VEHICLE_SEAT_FREE(self.m_handle, 2, true) and 2 or -2
		local jetCoords = self:GetPos()

		STREAMING.REQUEST_COLLISION_AT_COORD(jetCoords.x, jetCoords.y, jetCoords.z)
		STREAMING.REQUEST_ADDITIONAL_COLLISION_AT_COORD(jetCoords.x, jetCoords.y, jetCoords.z)
		Self:ClearTasksImmediately()
		self:WarpPed(Self:GetHandle(), seatIndex)
		ENTITY.SET_ENTITY_VISIBLE(self.m_handle, true, true)
		ENTITY.SET_ENTITY_ALPHA(self.m_handle, 255, false)
	end)
end

---@param coords vec3
function PrivateJet:CheckFlightCoords(coords)
	return self:GetPos():distance(coords) > 500
end

function PrivateJet:SkipTrip()
	script.run_in_fiber(function(s)
		if not self:Exists()
			or self:IsIdle()
			or not self.lastTaskCoords then
			return
		end

		CAM.DO_SCREEN_FADE_OUT(1000)
		s:sleep(1000)
		ENTITY.SET_ENTITY_COORDS(
			self.m_handle,
			self.lastTaskCoords.x,
			self.lastTaskCoords.y,
			self.lastTaskCoords.z + self:GetCruiseAltitude(),
			true,
			true,
			true,
			true
		)
		s:sleep(1000)
		CAM.DO_SCREEN_FADE_IN(1000)

		if not self.arrivalAirport then
			self.task = Enums.eVehicleTask.WANDER
		end

		self.lastTaskCoords = nil
	end)
end

function PrivateJet:FinishLanding()
	if not self.arrivalAirport then
		return
	end

	local coords = self.arrivalAirport.hangar.pos
	local heading = self.arrivalAirport.hangar.heading

	if not coords or not heading then
		return
	end

	script.run_in_fiber(function(s)
		if BillionaireServices.ActiveServices.limo then
			local limo = BillionaireServices.ActiveServices.limo
			local limoPos = self.arrivalAirport.limoTeleport.pos
			local limoHeading = self.arrivalAirport.limoTeleport.heading

			if not limo or not limoPos or not limoHeading then
				return
			end

			MISC.CLEAR_AREA_OF_VEHICLES(
				limoPos.x,
				limoPos.y,
				limoPos.z,
				5.0,
				false,
				false,
				false,
				false,
				false,
				false,
				0
			)
			local limoHandle = limo:GetHandle()
			ENTITY.SET_ENTITY_HEADING(limoHandle, limoHeading)
			ENTITY.SET_ENTITY_COORDS(
				limoHandle,
				limoPos.x,
				limoPos.y,
				limoPos.z,
				true,
				true,
				true,
				true
			)
			VEHICLE.SET_VEHICLE_DOOR_OPEN(limoHandle, 2, false, true)
			Toast:ShowMessage(
				"Private Jet",
				_F("Your limousine is waiting for you at %s.", self.arrivalAirport.name)
			)
		end

		CAM.DO_SCREEN_FADE_OUT(1000)
		s:sleep(1000)
		self:ClearTasks()
		VEHICLE.CONTROL_LANDING_GEAR(self.m_handle, 0)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.m_handle, 0.0)
		s:sleep(1000)

		MISC.CLEAR_AREA_OF_VEHICLES(
			coords.x,
			coords.y,
			coords.z,
			5.0,
			false,
			false,
			false,
			false,
			false,
			false,
			0
		)

		ENTITY.SET_ENTITY_COORDS(
			self.m_handle,
			coords.x,
			coords.y,
			coords.z,
			true,
			true,
			true,
			true
		)

		ENTITY.SET_ENTITY_HEADING(self.m_handle, heading)
		VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.m_handle, 5.0)
		s:sleep(200)
		CAM.DO_SCREEN_FADE_IN(1000)
		VEHICLE.SET_VEHICLE_ENGINE_ON(self.m_handle, false, false, false)
		s:sleep(500)
		VEHICLE.SET_VEHICLE_DOOR_OPEN(self.m_handle, 0, false, false)
		Toast:ShowMessage(
			"Private Jet",
			_F(
				"Welcome to %s. We hope you had a good time!",
				self.arrivalAirport.name
			)
		)

		self.departureAirport = self.arrivalAirport
		self.lastTaskCoords = nil
		self.arrivalAirport = nil
	end)
end

---@param s script_util
function PrivateJet:TakeOff(s)
	if not self.departureAirport then
		return
	end

	self.task = Enums.eVehicleTask.TAKE_OFF
	VEHICLE.SET_VEHICLE_DOORS_SHUT(self.m_handle, false)
	TASK.TASK_VEHICLE_DRIVE_TO_COORD(
		self.pilot,
		self.m_handle,
		self.departureAirport.taxiPos.x,
		self.departureAirport.taxiPos.y,
		self.departureAirport.taxiPos.z,
		5.0,
		0,
		ENTITY.GET_ENTITY_MODEL(self.m_handle),
		8388614,
		10.0,
		10.0
	)
	s:sleep(6000)
	CAM.DO_SCREEN_FADE_OUT(1000)
	s:sleep(1000)

	local climbPos = self.departureAirport.cutPos
	Game.SetEntityCoords(self.m_handle, climbPos, true, true, true, true)
	VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.m_handle, 100.0)
	VEHICLE.CONTROL_LANDING_GEAR(self.m_handle, 1)
	CAM.DO_SCREEN_FADE_IN(1000)
	self.departureAirport = nil
end

---@param v_Pos vec3
---@param s script_util
function PrivateJet:FlyTo(v_Pos, s)
	if not self:Exists() then
		return
	end

	if self.departureAirport and not self:IsCruising() then
		if self.arrivalAirport and not self:CheckFlightCoords(self.arrivalAirport.hangar.pos) then
			return
		end

		self:TakeOff(s)
	end

	if not self:CheckFlightCoords(v_Pos) then
		Toast:ShowError(
			"Private Jet",
			"The selected destination is too close."
		)
		return
	end

	self:PilotSpeak("CHAT_RESP")
	TASK.TASK_PLANE_MISSION(
		self.pilot,
		self.m_handle,
		0,
		0,
		v_Pos.x,
		v_Pos.y,
		v_Pos.z + self:GetCruiseAltitude(),
		4,
		100.0,
		0.0,
		90.0,
		5000,
		200.0,
		true
	)
	self.lastTaskCoords = v_Pos
	self.task = Enums.eVehicleTask.GOTO
end

function PrivateJet:HandleLanding()
	if self:IsIdle() then
		return
	end

	if not self.arrivalAirport then
		return
	end

	local target = self.arrivalAirport.landingApproach
	local jetPos = self:GetPos()
	local dist = jetPos:distance(target.pos)

	if dist > 1000 then
		TASK.TASK_PLANE_MISSION(
			self.pilot,
			self.m_handle,
			0,
			0,
			target.pos.x,
			target.pos.y,
			target.pos.z,
			4,
			100.0,
			0.0,
			target.heading,
			2000,
			300,
			true
		)
		self.task = Enums.eVehicleTask.GOTO
		return
	end

	if dist <= 1000 and dist > 200 and self.task ~= Enums.eVehicleTask.LAND then
		TASK.TASK_PLANE_LAND(
			self.pilot,
			self.m_handle,
			self.arrivalAirport.runwayStart.x,
			self.arrivalAirport.runwayStart.y,
			self.arrivalAirport.runwayStart.z,
			self.arrivalAirport.runwayEnd.x,
			self.arrivalAirport.runwayEnd.y,
			self.arrivalAirport.runwayEnd.z
		)
		self.task = Enums.eVehicleTask.LAND
		return
	end
end

function PrivateJet:ClearTasks()
	TASK.CLEAR_PED_TASKS(self.pilot)
	TASK.CLEAR_PED_SECONDARY_TASK(self.pilot)
	TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.m_handle)

	if self:IsCruising() then
		self.task = Enums.eVehicleTask.WANDER
	else
		self.task = Enums.eVehicleTask.NONE
	end
end

function PrivateJet:Cleanup()
	Game.DeleteEntity(self.pilot)
	Game.DeleteEntity(self.copilot)
	Game.DeleteEntity(self.m_handle)
	Decorator:RemoveEntity(self.pilot, "BillionaireServices")
	Decorator:RemoveEntity(self.copilot, "BillionaireServices")
	Decorator:RemoveEntity(self.m_handle, "BillionaireServices")

	self.pilot = nil
	self.copilot = nil
	self.m_handle = nil
end

function PrivateJet:ForceCleanup()
	ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.pilot, true, true)
	ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.copilot, true, true)
	ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.m_handle, true, true)
	ENTITY.DELETE_ENTITY(self.pilot)
	ENTITY.DELETE_ENTITY(self.copilot)
	ENTITY.DELETE_ENTITY(self.m_handle)
end

function PrivateJet:Dismiss()
	script.run_in_fiber(function(s)
		self.task = Enums.eVehicleTask.GO_HOME
		self.wasDismissed = true
		TASK.TASK_EVERYONE_LEAVE_VEHICLE(self.m_handle)
		s:sleep(1000)
		self:PilotSpeak("GENERIC_BYE")
		TASK.TASK_WANDER_STANDARD(self.pilot, 0, 0)
		TASK.TASK_WANDER_STANDARD(self.copilot, 0, 0)
		s:sleep(9e3)
		Game.FadeOutEntity(self.m_handle)
		Game.FadeOutEntity(self.pilot)
		Game.FadeOutEntity(self.copilot)
		s:sleep(1e3)
		self:Cleanup()
	end)
end

function PrivateJet:StateEval()
	if self.lastCheckTime and self.lastCheckTime > Time.now() then
		return
	end

	if not Game.IsScriptHandle(self.m_handle)
		or not ENTITY.IS_ENTITY_A_VEHICLE(self.m_handle)
		or ENTITY.IS_ENTITY_IN_WATER(self.m_handle) then
		BillionaireServices:RemoveJet()
	end

	if not Game.IsScriptHandle(self.pilot)
		or ENTITY.IS_ENTITY_DEAD(self.pilot, false)
		or not ENTITY.IS_ENTITY_A_PED(self.pilot) then
		BillionaireServices:RemoveJet()
	end

	if not VEHICLE.IS_VEHICLE_DRIVEABLE(self.m_handle, false) then
		self:Repair(true)
	end

	if not self:IsIdle() then
		if self:IsCruising() then
			local parachuteState = PED.GET_PED_PARACHUTE_STATE(Self:GetHandle())
			if PED.IS_PED_IN_PARACHUTE_FREE_FALL(Self:GetHandle())
				or parachuteState > 0
				or Self:IsFalling() then
				self:PilotSpeak("GENERIC_SHOCKED_HIGH", "SPEECH_PARAMS_FORCE_HELI")
				Toast:ShowMessage(
					"Private Jet",
					"Since you've decided to go for a skydive, your jet have been dismissed."
				)
				BillionaireServices:RemoveJet()
				return
			end
		end

		if (self.task == Enums.eVehicleTask.GOTO) and self.lastTaskCoords then
			if not self.arrivalAirport then
				local jetCoords = self:GetPos()
				local normalizedJetCoords = vec3:new(jetCoords.x, jetCoords.y, 0)
				local normalizedTaskCoords = vec3:new(self.lastTaskCoords.x, self.lastTaskCoords.y, 0)

				if normalizedJetCoords:distance(normalizedTaskCoords) <= 50 then
					Toast:ShowMessage(
						"Samurai's Scripts",
						"[Private Jet]: You have reached your destination."
					)
					self:ClearTasks()
				end
			else
				self:HandleLanding()
			end
		end

		if self.task == Enums.eVehicleTask.LAND and (self:GetSpeed() <= 5 and self:GetHeightAboveGround() <= 2) then
			self:FinishLanding()
		end
	end

	if self:IsPlayerInJet() then
		self.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(self.m_handle)
		self.radio.stationName = self.radio.isOn
			and HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
			or "Off"
	end

	self:ToggleBlip(not self:IsPlayerInJet())
	self.lastCheckTime = Time.now() + 2
	self.canWarpPlayer = self:IsFarAwayFromBoss()
end

------------------------------------------------------------------------
--- Data
------------------------------------------------------------------------

PrivateJet.Jets = {
	["Luxor Deluxe"] = {
		model = 0xB79F589E,
		description =
		"Now that the private jet market is open to every middle-class American willing to harvest their children's organs for cash, you need a new way to stand out. Forget standard light-weight, high-malleability, flame retardant aeronautical construction materials, yours are solid gold! It's time to tell the world exactly who you are. Besides, all your passengers will be too wasted on the complimentary champagne and cigars to care if you melt and fall out the sky during the next solar storm."
	},
	["Nimbus"] = {
		model = 0xB2CF7250,
		description =
		"The cutting edge has always had its naysayers. 'Why is the toilet made of rhino horn?' Fortunately the enemies of progress are completely inaudible when you and the other board members are daisy chaining at 40,000 feet."
	},
}

PrivateJet.Airports = {
	{
		name = "Los Santos International Airport",
		runwayStart = vec3:new(-1305.79, -2148.72, 13.9446),
		runwayEnd = vec3:new(-1663.04, -2775.99, 13.9447),
		taxiPos = vec3:new(-1046.74, -2971.01, 13.9487),
		cutPos = vec3:new(-2204.82, -2554.53, 678.723),
		hangar = {
			pos = vec3:new(-979.294, -2993.9, 13.9451),
			heading = 50
		},
		landingApproach = {
			pos = vec3:new(-860.534, -1476.28, 286.833),
			heading = 143.321
		},
		limoTeleport = {
			pos = vec3:new(-991.083, -3005.92, 13.9451),
			heading = 15.427
		},
	},
	{
		name = "Fort Zancudo",
		runwayStart = vec3:new(-1972.55, 2842.36, 32.8104),
		runwayEnd = vec3:new(-2598.1, 3199.13, 32.8118),
		taxiPos = vec3:new(-2166.8, 3203.57, 32.8049),
		cutPos = vec3:new(-3341.66, 3578.68, 595.203),
		hangar = {
			pos = vec3:new(-2140.81, 3255.64, 32.8103),
			heading = 132
		},
		landingApproach = {
			pos = vec3:new(-1487.91, 2553.82, 266.253),
			heading = 55.7258
		},
		limoTeleport = {
			pos = vec3:new(-2134.02, 3241.4, 32.8103),
			heading = 97.989
		},
	},
	{
		name = "Sandy Shores Airfield",
		runwayStart = vec3:new(1052.2, 3068.35, 41.6282),
		runwayEnd = vec3:new(1718.24, 3254.43, 41.1363),
		taxiPos = vec3:new(1705.72, 3254.61, 41.0139),
		cutPos = vec3:new(-164.118, 1830.04, 996.586),
		hangar = {
			pos = vec3:new(1744.21, 3276.24, 41.1191),
			heading = 150
		},
		landingApproach = {
			pos = vec3:new(633.196, 2975.52, 263.214),
			heading = 277.875
		},
		limoTeleport = {
			pos = vec3:new(1755.6, 3261.15, 41.3516),
			heading = 83.893
		},
	},
}

return PrivateJet
