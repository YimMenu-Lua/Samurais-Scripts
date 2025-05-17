---@class PrivateJet
---@field model integer
---@field handle integer
---@field pilot integer
---@field copilot integer
---@field name string
---@field pilotName string
---@field copilotName string
---@field blip table<string, integer> -- {handle = handle, alpha = alpha}
---@field task VehicleTask
---@field departureAirport table
---@field arrivalAirport table
---@field lastTaskCoords vec3
---@field lastCheckTime integer
---@field canWarpPlayer boolean
PrivateJet = {}
PrivateJet.__index = PrivateJet

PrivateJet.wasDismissed = false
PrivateJet.pilotModel = 0xE75B4B1C -- S_M_M_Pilot_01
PrivateJet.copilotModel = 0x864ED68E -- IG_Pilot
PrivateJet.task = eVehicleTask.NONE or -1
PrivateJet.radio = { isOn = false, stationName = "OFF" }


---@param model integer
---@param airportData table
function PrivateJet.new(model, airportData)
    local pilot = Game.CreatePed(PrivateJet.pilotModel, vec3:zero())

    if not Game.IsScriptHandle(pilot) then
        SS.debug("Failed to create ped.")
        return
    end

    ENTITY.FREEZE_ENTITY_POSITION(pilot, true)

    local copilot = Game.CreatePed(PrivateJet.copilotModel, vec3:zero())

    if not Game.IsScriptHandle(copilot) then
        Game.DeleteEntity(pilot, "peds")
        SS.debug("Failed to create ped.")
        return
    end

    ENTITY.FREEZE_ENTITY_POSITION(copilot, true)

    local jet = Game.CreateVehicle(model, vec3:zero(), airportData.hangar.heading)
    ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(jet, true, true)

    if not Game.IsScriptHandle(jet) then
        Game.DeleteEntity(pilot, "peds")
        Game.DeleteEntity(copilot, "peds")
        SS.debug("Failed to create vehicle.")
        return
    end

    ENTITY.FREEZE_ENTITY_POSITION(jet, true)
    VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(jet, false)
    VEHICLE.SET_VEHICLE_STRONG(jet, true)
    VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(jet, false, false)
    VEHICLE.SET_VEHICLE_OCCUPANTS_TAKE_EXPLOSIVE_DAMAGE(jet, false)
    ENTITY.SET_ENTITY_INVINCIBLE(jet, true)
    ENTITY.SET_ENTITY_INVINCIBLE(pilot, true)
    ENTITY.SET_ENTITY_INVINCIBLE(copilot, true)
    STREAMING.REQUEST_COLLISION_AT_COORD(
        airportData.hangar.pos.x,
        airportData.hangar.pos.y,
        airportData.hangar.pos.z
    )

    entities.take_control_of(pilot, 300)
    entities.take_control_of(copilot, 300)
    entities.take_control_of(jet, 300)

    if Game.IsOnline() then
        Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(pilot))
        Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(copilot))
        Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(jet))
    end


    ENTITY.FREEZE_ENTITY_POSITION(pilot, false)
    ENTITY.FREEZE_ENTITY_POSITION(copilot, false)
    PED.SET_PED_INTO_VEHICLE(pilot, jet, -1)
    PED.SET_PED_INTO_VEHICLE(copilot, jet, 0)
    ENTITY.FREEZE_ENTITY_POSITION(jet, false)

    Game.SetEntityCoordsNoOffset(jet, airportData.hangar.pos)
    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(jet, 5.0)
    VEHICLE.SET_VEHICLE_ENGINE_ON(jet, true, true, false)

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

    while not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(jet) do
        yield()
    end

    Sleep(1000)
    Game.Vehicle.RepairVehicle(jet)
    AUDIO.SET_VEHICLE_RADIO_ENABLED(jet, true)
    AUDIO.SET_VEH_RADIO_STATION(jet, "RADIO_22_DLC_BATTLE_MIX1_RADIO")
    AUDIO.SET_VEHICLE_RADIO_LOUD(jet, true)
    VEHICLE.SET_VEHICLE_DOOR_OPEN(jet, 0, false, false)

    Game.FadeInEntity(pilot)
    Game.FadeInEntity(copilot)
    Game.FadeInEntity(jet)

    local blip = Game.AddBlipForEntity(jet)
    Game.SetBlipSprite(blip, 423)
    Game.SetBlipName(blip, "Private Jet")

    return setmetatable(
        {
            model = model,
            handle = jet,
            name = Game.Vehicle.Name(jet) or "Private Jet",
            pilot = pilot,
            copilot = copilot,
            pilotName = BillionaireServices:GetRandomPedName("male"),
            copilotName = BillionaireServices:GetRandomPedName("male"),
            blip = {
                handle = blip,
                alpha = 255
            },
            radio = {
                isOn = true,
                stationName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
            },
            wasDismissed = false,
            task = eVehicleTask.NONE,
            lastCheckTime = Time.now() + 3
        },
        PrivateJet
    )
end

function PrivateJet:Exists()
    return self.handle ~= 0
    and self.pilot ~= 0
    and SS.IsScriptEntity(self.handle)
    and SS.IsScriptEntity(self.pilot)
end

function PrivateJet:GetPos()
    return Game.GetEntityCoords(self.handle, false)
end

function PrivateJet:GetElevation()
    return ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(self.handle)
end

function PrivateJet:GetSpeed()
    return ENTITY.GET_ENTITY_SPEED(self.handle)
end

function PrivateJet:GetCruiseAltitude()
    return not self.arrivalAirport and 600 or 0
end

function PrivateJet:IsIdle()
    return self.task == eVehicleTask.NONE
end

function PrivateJet:IsCruising()
    return self.task == eVehicleTask.GOTO
    and self:GetElevation() > 20
    and self:GetSpeed() > 20
end

---@param altitude number
function PrivateJet:IsCruisingAtAltitude(altitude)
    return self.task == eVehicleTask.GOTO
    and self:GetElevation() >= altitude
    and self:GetSpeed() > 20
end

function PrivateJet:IsPlayerInJet()
    if not Game.IsScriptHandle(self.handle) then
        return false
    end

    local playerVeh = Self.GetVehicle()
    return (playerVeh ~= 0) and (self.handle == playerVeh)
end

function PrivateJet:IsFarAwayFromBoss()
    return not self:IsPlayerInJet()
    and Self.GetPos():distance(self:GetPos()) > 500
end

function PrivateJet:GetTaskAsString()
    return eVehicleTaskToString[self.task or -1]
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

function PrivateJet:Repair()
    script.run_in_fiber(function()
        Game.Vehicle.RepairVehicle(self.handle)
    end)
end

function PrivateJet:WarpPlayer()
    script.run_in_fiber(function()
        if self:IsPlayerInJet() then
            return
        end

        local seatIndex = VEHICLE.IS_VEHICLE_SEAT_FREE(self.handle, 2, true) and 2 or -2
        local jetCoords = self:GetPos()

        STREAMING.REQUEST_COLLISION_AT_COORD(jetCoords.x, jetCoords.y, jetCoords.z)
        STREAMING.REQUEST_ADDITIONAL_COLLISION_AT_COORD(jetCoords.x, jetCoords.y, jetCoords.z)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
        TASK.TASK_WARP_PED_INTO_VEHICLE(Self.GetPedID(), self.handle, seatIndex)
        ENTITY.SET_ENTITY_VISIBLE(self.handle, true, true)
        ENTITY.SET_ENTITY_ALPHA(self.handle, 255, false)
    end)
end

function PrivateJet:ShuffleSeats(step)
    script.run_in_fiber(function()
        if not self:IsPlayerInJet() then
            return
        end

        if not Game.Vehicle.IsAnySeatFree(self.handle) then
            return
        end

        local maxSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(self.handle)
        local currentSeat = Game.GetPedVehicleSeat(Self.GetPedID())

        if not currentSeat then
            return
        end

        local attempts = 0
        local seatIndex = currentSeat

        while attempts < maxSeats do
            seatIndex = seatIndex + step

            if seatIndex > maxSeats then
                seatIndex = 0
            elseif seatIndex <= 0 then
                seatIndex = maxSeats
            end

            if VEHICLE.IS_VEHICLE_SEAT_FREE(self.handle, seatIndex, true) then
                PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), self.handle, seatIndex)
                return
            end

            attempts = attempts + 1
            yield()
        end
    end)
end

function PrivateJet:CheckFlightCoords(v_Pos)
    return self:GetPos():distance(v_Pos) > 500
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
            self.handle,
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
            self.task = eVehicleTask.WANDER
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
            ENTITY.SET_ENTITY_HEADING(limo.handle, limoHeading)
            ENTITY.SET_ENTITY_COORDS(
                limo.handle,
                limoPos.x,
                limoPos.y,
                limoPos.z,
                true,
                true,
                true,
                true
            )
            VEHICLE.SET_VEHICLE_DOOR_OPEN(limo.handle, 2, false, true)
            YimToast:ShowMessage(
                "Private Jet",
                string.format(
                    "Your limousine is waiting for you at %s.",
                    self.arrivalAirport.name
                )
            )
        end

        CAM.DO_SCREEN_FADE_OUT(1000)
        s:sleep(1000)
        self:ClearTasks()
        VEHICLE.CONTROL_LANDING_GEAR(self.handle, 0)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.handle, 0.0)
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
            self.handle,
            coords.x,
            coords.y,
            coords.z,
            true,
            true,
            true,
            true
        )

        ENTITY.SET_ENTITY_HEADING(self.handle, heading)
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.handle, 5.0)
        s:sleep(200)
        CAM.DO_SCREEN_FADE_IN(1000)
        VEHICLE.SET_VEHICLE_ENGINE_ON(self.handle, false, false, false)
        s:sleep(500)
        VEHICLE.SET_VEHICLE_DOOR_OPEN(self.handle, 0, false, false)
        YimToast:ShowMessage(
            "Private Jet",
            string.format(
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

    self.task = eVehicleTask.TAKE_OFF
    VEHICLE.SET_VEHICLE_DOORS_SHUT(self.handle, false)
    TASK.TASK_VEHICLE_DRIVE_TO_COORD(
        self.pilot,
        self.handle,
        self.departureAirport.taxiPos.x,
        self.departureAirport.taxiPos.y,
        self.departureAirport.taxiPos.z,
        5.0,
        0,
        ENTITY.GET_ENTITY_MODEL(self.handle),
        8388614,
        10.0,
        10.0
    )
    s:sleep(6000)
    CAM.DO_SCREEN_FADE_OUT(1000)
    s:sleep(1000)

    local climbPos = self.departureAirport.cutPos
    Game.SetEntityCoords(self.handle, climbPos, true, true, true, true)
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.handle, 100.0)
    VEHICLE.CONTROL_LANDING_GEAR(self.handle, 1)
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
        YimToast:ShowError(
            "Private Jet",
            "The selected destination is too close."
        )
        return
    end

    self:PilotSpeak("CHAT_RESP")
    TASK.TASK_PLANE_MISSION(
        self.pilot,
        self.handle,
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
    self.task = eVehicleTask.GOTO
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
            self.handle,
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
        self.task = eVehicleTask.GOTO
        return
    end

    if dist <= 1000 and dist > 200 and self.task ~= eVehicleTask.LAND then
        TASK.TASK_PLANE_LAND(
            self.pilot,
            self.handle,
            self.arrivalAirport.runwayStart.x,
            self.arrivalAirport.runwayStart.y,
            self.arrivalAirport.runwayStart.z,
            self.arrivalAirport.runwayEnd.x,
            self.arrivalAirport.runwayEnd.y,
            self.arrivalAirport.runwayEnd.z
        )
        self.task = eVehicleTask.LAND
        return
    end
end

function PrivateJet:ClearTasks()
    TASK.CLEAR_PED_TASKS(self.pilot)
    TASK.CLEAR_PED_SECONDARY_TASK(self.pilot)
    TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.handle)

    if self:IsCruising() then
        self.task = eVehicleTask.WANDER
    else
        self.task = eVehicleTask.NONE
    end
end

function PrivateJet:Cleanup()
    Game.DeleteEntity(self.pilot, "peds")
    Game.DeleteEntity(self.copilot, "peds")
    Game.DeleteEntity(self.handle, "vehicles")
    Decorator:RemoveEntity(self.pilot, "BillionaireServices")
    Decorator:RemoveEntity(self.copilot, "BillionaireServices")
    Decorator:RemoveEntity(self.handle, "BillionaireServices")

    self.pilot = nil
    self.copilot = nil
    self.handle = nil
end

function PrivateJet:ForceCleanup()
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.pilot, true, true)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.copilot, true, true)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.handle, true, true)
    ENTITY.DELETE_ENTITY(self.pilot)
    ENTITY.DELETE_ENTITY(self.copilot)
    ENTITY.DELETE_ENTITY(self.handle)
end

function PrivateJet:Dismiss()
    script.run_in_fiber(function(s)
        self.task = eVehicleTask.GO_HOME
        self.wasDismissed = true
        TASK.TASK_EVERYONE_LEAVE_VEHICLE(self.handle)
        s:sleep(1000)
        self:PilotSpeak("GENERIC_BYE")
        TASK.TASK_WANDER_STANDARD(self.pilot, 0, 0)
        TASK.TASK_WANDER_STANDARD(self.copilot, 0, 0)
        s:sleep(9e3)
        Game.FadeOutEntity(self.handle)
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

    if not Game.IsScriptHandle(self.handle)
    or not ENTITY.IS_ENTITY_A_VEHICLE(self.handle)
    or ENTITY.IS_ENTITY_IN_WATER(self.handle) then
        BillionaireServices:RemoveJet()
    end

    if not Game.IsScriptHandle(self.pilot)
    or ENTITY.IS_ENTITY_DEAD(self.pilot, false)
    or not ENTITY.IS_ENTITY_A_PED(self.pilot) then
        BillionaireServices:RemoveJet()
    end

    if not VEHICLE.IS_VEHICLE_DRIVEABLE(self.handle, false) then
        Game.Vehicle.RepairVehicle(self.handle)
    end

    if not self:IsIdle() then
        if self:IsCruising() then
            local parachuteState = PED.GET_PED_PARACHUTE_STATE(Self.GetPedID())
            if PED.IS_PED_IN_PARACHUTE_FREE_FALL(Self.GetPedID())
            or parachuteState > 0
            or Self.IsFalling() then
                self:PilotSpeak("GENERIC_SHOCKED_HIGH", "SPEECH_PARAMS_FORCE_HELI")
                YimToast:ShowMessage(
                    "Private Jet",
                    "Since you've decided to go for a skydive, your jet have been dismissed."
                )
                BillionaireServices:RemoveJet()
                return
            end
        end

        if (self.task == eVehicleTask.GOTO) and self.lastTaskCoords then
            if not self.arrivalAirport then
                local jetCoords = self:GetPos()
                local normalizedJetCoords = vec3:new(jetCoords.x, jetCoords.y, 0)
                local normalizedTaskCoords = vec3:new(self.lastTaskCoords.x, self.lastTaskCoords.y, 0)

                if normalizedJetCoords:distance(normalizedTaskCoords) <= 50 then
                    YimToast:ShowMessage(
                        "Samurai's Scripts",
                        "[Private Jet]: You have reached your destination."
                    )
                    self:ClearTasks()
                end
            else
                self:HandleLanding()
            end
        end

        if self.task == eVehicleTask.LAND and (self:GetSpeed() <= 5 and self:GetElevation() <= 2) then
            self:FinishLanding()
        end
    end

    if self:IsPlayerInJet() then
        self.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(self.handle)
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
        description = "Now that the private jet market is open to every middle-class American willing to harvest their children's organs for cash, you need a new way to stand out. Forget standard light-weight, high-malleability, flame retardant aeronautical construction materials, yours are solid gold! It's time to tell the world exactly who you are. Besides, all your passengers will be too wasted on the complimentary champagne and cigars to care if you melt and fall out the sky during the next solar storm."
    },
    ["Nimbus"] = {
        model = 0xB2CF7250,
        description = "The cutting edge has always had its naysayers. 'Why is the toilet made of rhino horn?' Fortunately the enemies of progress are completely inaudible when you and the other board members are daisy chaining at 40,000 feet."
    },
}

PrivateJet.Airports = {
    [1] = {
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
    [2] = {
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
    [3] = {
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
