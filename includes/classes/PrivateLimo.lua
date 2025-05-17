-----------------------------------------------------
-- Private Limo Struct
-----------------------------------------------------
---@class PrivateLimo
---@field limoData table
---@field handle integer
---@field driver integer
---@field name string
---@field driverName string
---@field blip table<string, integer> -- {handle = handle, alpha = alpha}
---@field playerClone integer
---@field limoClone integer
---@field lastTaskCoords vec3
---@field lastCheckTime integer
PrivateLimo = {}
PrivateLimo.__index = PrivateLimo

PrivateLimo.isRemoteControlled = false
PrivateLimo.wasDismissed = false
PrivateLimo.playerSeat = nil
PrivateLimo.driverModel = 0xE75B4B1C
PrivateLimo.currentDrivingMode = 1
PrivateLimo.task = eVehicleTask.NONE or -1
PrivateLimo.radio = {
    isOn = false,
    stationName = "OFF"
}
PrivateLimo.drivingModes = {
    { drivingFlags = 786603,  speed = 19 }, -- chill
    { drivingFlags = 2886204, speed = 60 } -- aggressive
}

---@param t_Data table
---@param vehicleHandle integer
---@param driverHandle integer
function PrivateLimo.new(t_Data, vehicleHandle, driverHandle)
    return setmetatable(
        {
            limoData = t_Data,
            handle = vehicleHandle,
            name = Game.Vehicle.Name(vehicleHandle) or "Private Limousine",
            driver = driverHandle,
            driverName = BillionaireServices:GetRandomPedName("male"),
            lastCheckTime = Time.now() + 3
        },
        PrivateLimo
    )
end

---@param t_Data table
---@param spawnPos? vec3
function PrivateLimo:CreateVehicle(t_Data, spawnPos)
    if not t_Data then
        return 0
    end

    if not spawnPos then
        local spawnPoint = Game.FindSpawnPointNearPlayer(10)
        spawnPos = spawnPoint and spawnPoint
            or ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                Self.GetPedID(),
                0,
                15,
                0.1
            )
    end

    local limo = Game.CreateVehicle(t_Data.model, spawnPos)

    if not Game.IsScriptHandle(limo) then
        return 0
    end

    ENTITY.SET_ENTITY_PROOFS(limo, true, false, false, false, false, false, false, false)
    VEHICLE.SET_VEHICLE_CAN_BE_TARGETTED(limo, false)
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(limo, false)
    VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(limo, false, false)
    VEHICLE.SET_VEHICLE_MOD_KIT(limo, 0)
    VEHICLE.SET_VEHICLE_WINDOW_TINT(limo, t_Data.window_tint or 1)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(limo, "OMW2FYB")
    VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(limo, true)
    Game.Vehicle.MaxPerformance(limo)

    for i = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(limo) do
        VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(limo, i, false)
    end

    if t_Data.wheelType then
        VEHICLE.SET_VEHICLE_WHEEL_TYPE(limo, t_Data.wheelType)
    end

    if t_Data.mods then
        for slot, modIndex in pairs(t_Data.mods) do
            local modType = slot - 1
            VEHICLE.SET_VEHICLE_MOD(limo, modType, modIndex, false)
        end
    end

    if t_Data.color then
        local col1 = t_Data.color.primary
        local col2 = t_Data.color.secondary
        local interior = t_Data.color.interior

        if col1 then
            Game.Vehicle.SetCustomPaint(
                limo,
                col1.hex,
                col1.p,
                col1.m,
                true,
                false
            )
        end

        if col2 then
            Game.Vehicle.SetCustomPaint(
                limo,
                col2.hex,
                0,
                col2.m,
                false,
                true
            )
        end

        if interior then
            VEHICLE.SET_VEHICLE_EXTRA_COLOUR_5(limo, interior)
        end
    end

    if t_Data.wheelColor then
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(
            limo,
            t_Data.color.primary.p,
            t_Data.wheelColor
        )
    end

    return limo
end

---@param t_Data table
---@param spawnPos? vec3
function PrivateLimo:Spawn(t_Data, spawnPos)
    if not t_Data then
        SS.debug("Invalid data.")
        return
    end

    local driver = Game.CreatePed(self.driverModel, vec3:zero())

    if not Game.IsScriptHandle(driver) then
        SS.debug("Failed to create ped.")
        return
    end

    ENTITY.FREEZE_ENTITY_POSITION(driver, true)
    local limo = self:CreateVehicle(t_Data, spawnPos)

    if not Game.IsScriptHandle(limo) then
        SS.debug("Failed to create vehicle.")
        return
    end

    entities.take_control_of(driver, 300)
    entities.take_control_of(limo, 300)
    Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(driver))
    Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(limo))

    ENTITY.FREEZE_ENTITY_POSITION(driver, false)
    ENTITY.SET_ENTITY_INVINCIBLE(driver, true)

    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(driver, 1)
    PED.SET_PED_INTO_VEHICLE(driver, limo, -1)
    PED.SET_PED_CAN_BE_DRAGGED_OUT(driver, false)
    PED.SET_PED_CAN_BE_TARGETTED(driver, false)
    PED.SET_PED_CAN_BE_SHOT_IN_VEHICLE(driver, false)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
    PED.SET_PED_CONFIG_FLAG(driver, 251, true)
    PED.SET_PED_CONFIG_FLAG(driver, 255, true)
    PED.SET_PED_COMBAT_ATTRIBUTES(driver, 3, false)
    PED.SET_PED_COMBAT_ATTRIBUTES(driver, 17, false)
    PED.SET_PED_COMBAT_ATTRIBUTES(driver, 20, true)
    PED.SET_PED_CAN_EVASIVE_DIVE(driver, true)

    VEHICLE.SET_VEHICLE_INDIVIDUAL_DOORS_LOCKED(limo, 0, 2)
    VEHICLE.SET_VEHICLE_INDIVIDUAL_DOORS_LOCKED(limo, 1, 2)
    VEHICLE.SET_VEHICLE_ENGINE_ON(limo, true, true, false)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(limo, 0)
    Game.FadeInEntity(limo)

    local timer1 = Timer.new(1000)
    while not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(limo) do
        if timer1:isDone() then
            break
        end
        yield()
    end

    Sleep(1000)
    AUDIO.SET_VEH_RADIO_STATION(limo, "RADIO_22_DLC_BATTLE_MIX1_RADIO")
    AUDIO.SET_VEHICLE_RADIO_LOUD(limo, true)
    self.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(limo)
    self.radio.stationName = AUDIO.GET_PLAYER_RADIO_STATION_NAME()

    local blip = Game.AddBlipForEntity(limo, 1.0)
    Game.SetBlipName(blip, "Private Limousine")
    Game.SetBlipSprite(blip, 724)
    self.blip = {
        handle = blip,
        alpha = 255
    }

    Game.FadeInEntity(driver)
    Game.FadeInEntity(limo)
    return PrivateLimo.new(t_Data, limo, driver)
end

function PrivateLimo:GetPos()
    return Game.GetEntityCoords(self.handle, false)
end

function PrivateLimo:IsIdle()
    return self.task == eVehicleTask.NONE
end

function PrivateLimo:Exists()
    return self.handle ~= 0
    and self.driver ~= 0
    and SS.IsScriptEntity(self.handle)
    and SS.IsScriptEntity(self.driver)
end

---@param i_DrivingStyle number
function PrivateLimo:SetDrivingStyle(i_DrivingStyle)
    if type(i_DrivingStyle) ~= "number" or i_DrivingStyle > 2 then
        return
    end

    if (i_DrivingStyle == self.currentDrivingMode) then
        return
    end

    self.currentDrivingMode = i_DrivingStyle

    script.run_in_fiber(function(s)
        if (self.task == eVehicleTask.GOTO) and self.lastTaskCoords then
            self:GoTo(self.lastTaskCoords, s)
        elseif (self.task == eVehicleTask.WANDER) then
            self:CancelAnyTasks()
            self:Wander(s)
        end
    end)
end

function PrivateLimo:GetDrivingStyle()
    return {
        speed = self.drivingModes[self.currentDrivingMode].speed or 20,
        drivingFlags = self.drivingModes[self.currentDrivingMode].drivingFlags or 786603
    }
end

function PrivateLimo:GetTaskAsString()
    return eVehicleTaskToString[self.task or -1]
end

---@param toggle boolean
function PrivateLimo:ToggleBlip(toggle)
    if not self.blip or not self.blip.handle then
        return
    end

    local targetAlpha = toggle and 255 or 0
    local cond = toggle and self.blip.alpha < targetAlpha or self.blip.alpha > targetAlpha

    if cond then
        self.blip.alpha = targetAlpha
        if HUD.DOES_BLIP_EXIST(self.blip.handle) then
            HUD.SET_BLIP_ALPHA(self.blip.handle, targetAlpha)
        end
    end
end

function PrivateLimo:Repair()
    Game.Vehicle.RepairVehicle(self.handle)
end

---@param step integer 1 | -1
function PrivateLimo:ShuffleSeats(step)
    script.run_in_fiber(function()
        if not self:IsPlayerInLimo() then
            return
        end

        if not Game.Vehicle.IsAnySeatFree(self.handle) then
            return
        end

        local maxSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(self.handle)
        local currentSeat = self.playerSeat or Game.GetPedVehicleSeat(Self.GetPedID())

        if not currentSeat then
            return
        end

        local attempts = 0
        local seatIndex = currentSeat

        while attempts < maxSeats do
            seatIndex = seatIndex + step

            if seatIndex > maxSeats then
                seatIndex = 1
            elseif seatIndex < 1 then
                seatIndex = maxSeats
            end

            if VEHICLE.IS_VEHICLE_SEAT_FREE(self.handle, seatIndex, true) then
                PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), self.handle, seatIndex)
                self.playerSeat = seatIndex
                return
            end

            attempts = attempts + 1
            yield()
        end
    end)
end

---@param coords vec3
---@param s script_util
function PrivateLimo:GoTo(coords, s)
    if not self:Exists() or self.isRemoteControlled then
        return
    end

    if not self:IsIdle() then
        self:CancelAnyTasks()
        s:sleep(500)
    end

    TASK.CLEAR_PED_TASKS(self.driver)
    TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(
        self.driver,
        self.handle,
        coords.x,
        coords.y,
        coords.z,
        self:GetDrivingStyle().speed,
        self:GetDrivingStyle().drivingFlags,
        25
    )

    self.lastTaskCoords = coords
    self.task = eVehicleTask.GOTO
end

---@param s script_util
function PrivateLimo:Wander(s)
    if not self:Exists() or self.isRemoteControlled then
        return
    end

    if not self:IsIdle() then
        self:CancelAnyTasks()
        s:sleep(500)
    end

    TASK.CLEAR_PED_TASKS(self.driver)
    TASK.TASK_VEHICLE_DRIVE_WANDER(
        self.driver,
        self.handle,
        self:GetDrivingStyle().speed,
        self:GetDrivingStyle().drivingFlags
    )

    self.task = eVehicleTask.WANDER
    self.lastTaskCoords = nil
end

function PrivateLimo:Stop()
    if not self:Exists() or self.isRemoteControlled then
        return
    end

    if not ENTITY.IS_ENTITY_A_VEHICLE(self.handle) or not ENTITY.IS_ENTITY_A_PED(self.driver) then
        return
    end

    self:CancelAnyTasks()
    TASK.TASK_VEHICLE_TEMP_ACTION(self.driver, self.handle, 1, -1)
end

function PrivateLimo:EmergencyStop()
    if not self:Exists() or self.isRemoteControlled then
        return
    end

    if not ENTITY.IS_ENTITY_A_VEHICLE(self.handle) or not ENTITY.IS_ENTITY_A_PED(self.driver) then
        return
    end

    if self:IsIdle() and VEHICLE.IS_VEHICLE_STOPPED(self.handle) then
        return
    end

    self:CancelAnyTasks()
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.handle, 0)
end

function PrivateLimo:Park()
    if not self.driver then
        return
    end

    local area = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        self.handle,
        2,
        10,
        0
    )

    self:CancelAnyTasks()
    TASK.TASK_VEHICLE_PARK(
        self.driver,
        self.handle,
        area.x,
        area.y,
        area.z,
        Game.GetHeading(self.handle),
        0,
        100,
        true
    )
end

function PrivateLimo:CancelAnyTasks()
    if not Game.IsScriptHandle(self.handle)
        or not Game.IsScriptHandle(self.driver)
        or self:IsIdle()
        or self.isRemoteControlled then
        return
    end

    TASK.CLEAR_PED_TASKS(self.driver)
    TASK.CLEAR_PED_SECONDARY_TASK(self.driver)
    TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.handle)
    TASK.TASK_VEHICLE_TEMP_ACTION(self.driver, self.handle, 1, 2000)

    self.task = eVehicleTask.NONE
    self.lastTaskCoords = nil
end

function PrivateLimo:TakeControl()
    if not Game.IsScriptHandle(self.handle)
        or not Game.IsScriptHandle(self.driver)
        or (Self.GetVehicle() ~= self.handle) then
        return
    end

    script.run_in_fiber(function(s)
        local limoClone = self:CreateVehicle(self.limoData, vec3:zero())
        local playerClone = Game.CreatePed(Self.GetPedModel(), vec3:zero())

        if not Game.IsScriptHandle(limoClone) or not Game.IsScriptHandle(playerClone) then
            YimToast:ShowError(
                "Private Limo",
                "Unable to remotely control the limousine. Please try again later."
            )
            return
        end

        self.limoClone = limoClone
        self.playerClone = playerClone
        self.playerSeat = Game.GetPedVehicleSeat(Self.GetPedID())
        self:CancelAnyTasks()

        ENTITY.SET_ENTITY_COLLISION(self.limoClone, false, false)
        ENTITY.FREEZE_ENTITY_POSITION(self.limoClone, true)
        ENTITY.FREEZE_ENTITY_POSITION(self.playerClone, true)
        ENTITY.FREEZE_ENTITY_POSITION(self.handle, true)
        ENTITY.SET_ENTITY_INVINCIBLE(self.limoClone, true)
        ENTITY.SET_ENTITY_INVINCIBLE(self.playerClone, true)
        PED.SET_PED_CAN_BE_DRAGGED_OUT(self.playerClone, false)
        PED.SET_PED_CAN_BE_TARGETTED(self.playerClone, false)
        PED.CLONE_PED_TO_TARGET(Self.GetPedID(), self.playerClone)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(self.playerClone, true)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(self.playerClone, true)

        Game.SetEntityCoordsNoOffset(self.limoClone, Game.GetEntityCoords(self.handle, false))
        ENTITY.SET_ENTITY_HEADING(self.limoClone, Game.GetHeading(self.handle))
        TASK.TASK_WARP_PED_INTO_VEHICLE(Self.GetPedID(), self.limoClone, -1)
        VEHICLE.SET_VEHICLE_ENGINE_ON(self.limoClone, true, true, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(self.limoClone, 2)
        VEHICLE.SET_VEHICLE_DIRT_LEVEL(self.limoClone, VEHICLE.GET_VEHICLE_DIRT_LEVEL(self.handle))
        AUDIO.SET_VEH_RADIO_STATION(self.limoClone, self.radio.stationName)

        s:sleep(10)
        ENTITY.FREEZE_ENTITY_POSITION(self.playerClone, false)
        TASK.TASK_WARP_PED_INTO_VEHICLE(self.playerClone, self.handle, self.playerSeat or -2)
        ENTITY.SET_ENTITY_VISIBLE(self.handle, false, false)
        ENTITY.SET_ENTITY_ALPHA(self.handle, 10.0, false)
        ENTITY.SET_ENTITY_VISIBLE(Self.GetPedID(), false, false)
        ENTITY.SET_ENTITY_ALPHA(Self.GetPedID(), 0.0, false)

        local prevSpeed = ENTITY.GET_ENTITY_SPEED(self.handle)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(
            self.handle,
            self.limoClone,
            0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            false,
            true,
            false,
            false,
            2,
            true,
            1
        )

        ENTITY.FREEZE_ENTITY_POSITION(self.handle, false)
        ENTITY.FREEZE_ENTITY_POSITION(self.limoClone, false)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.limoClone, prevSpeed or 0.1)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(self.limoClone)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(self.playerClone)
        ENTITY.SET_ENTITY_VISIBLE(self.driver, true, true)
        ENTITY.SET_ENTITY_ALPHA(self.driver, 255, false)

        self.isRemoteControlled = true
    end)
end

function PrivateLimo:ReleaseControl()
    if not self.isRemoteControlled then
        return
    end

    script.run_in_fiber(function(s)
        local abyss = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
            self.limoClone,
            0,
            0,
            -100
        )

        ENTITY.SET_ENTITY_VISIBLE(self.handle, true, true)
        ENTITY.SET_ENTITY_ALPHA(self.handle, 255, false)
        ENTITY.SET_ENTITY_VISIBLE(self.limoClone, false, true)
        ENTITY.SET_ENTITY_ALPHA(self.limoClone, 0, false)
        Game.DeleteEntity(self.playerClone, "peds")

        local timer = Timer.new(2000)
        while Game.IsScriptHandle(self.playerClone) do
            if timer:isDone()
                or (self.playerSeat and VEHICLE.IS_VEHICLE_SEAT_FREE(self.handle, self.playerSeat, true)) then
                break
            end
            yield()
        end

        local speed = ENTITY.GET_ENTITY_SPEED(Self.GetPedID())
        ENTITY.DETACH_ENTITY(self.handle, false, false)
        ENTITY.SET_ENTITY_COLLISION(self.handle, false, false)
        ENTITY.SET_ENTITY_COLLISION(self.limoClone, false, false)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.handle, speed or 0)
        Game.SetEntityCoords(self.limoClone, abyss)
        s:sleep(10)

        ENTITY.SET_ENTITY_COLLISION(self.handle, true, true)
        TASK.TASK_WARP_PED_INTO_VEHICLE(Self.GetPedID(), self.handle, self.playerSeat or -2)
        ENTITY.SET_ENTITY_VISIBLE(self.handle, true, true)
        ENTITY.SET_ENTITY_ALPHA(self.handle, 255, false)
        ENTITY.SET_ENTITY_VISIBLE(Self.GetPedID(), true, true)
        ENTITY.SET_ENTITY_ALPHA(Self.GetPedID(), 255, false)

        for _, ped in ipairs(Game.Vehicle.GetOccupants(self.handle)) do
            if ped and Game.IsScriptHandle(ped) then
                ENTITY.SET_ENTITY_VISIBLE(ped, true, true)
                ENTITY.SET_ENTITY_ALPHA(ped, 255, false)
            end
        end

        Game.DeleteEntity(self.limoClone, "vehicles")

        self.isRemoteControlled = false
        self.playerClone = nil
        self.limoClone = nil
        s:sleep(250)
    end)
end

function PrivateLimo:IsPlayerInLimo()
    if not self.handle then
        return false
    end

    local playerVeh = Self.GetVehicle()
    return (playerVeh ~= 0) and (self.handle == playerVeh)
end

function PrivateLimo:WarpPlayer()
    if self:IsPlayerInLimo() or self.isRemoteControlled then
        return
    end

    script.run_in_fiber(function()
        local seatIndex = VEHICLE.IS_VEHICLE_SEAT_FREE(self.handle, 2, true) and 2 or -2
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
        TASK.TASK_WARP_PED_INTO_VEHICLE(Self.GetPedID(), self.handle, seatIndex)
    end)
end

function PrivateLimo:Dismiss()
    script.run_in_fiber(function(s)
        self:ReleaseControl()
        self:CancelAnyTasks()
        self.task = eVehicleTask.GO_HOME
        self.wasDismissed = true

        if self:IsPlayerInLimo() then
            self:Stop()

            while not VEHICLE.IS_VEHICLE_STOPPED(self.handle) do
                if not self:IsPlayerInLimo() then
                    break
                end
                yield()
            end

            for _, ped in ipairs(Game.Vehicle.GetOccupants(self.handle)) do
                if ped and Game.IsScriptHandle(ped) and (ped ~= self.driver) then
                    TASK.TASK_LEAVE_VEHICLE(ped, self.handle, 0)
                    repeat
                        s:sleep(100)
                    until not PED.IS_PED_IN_VEHICLE(ped, self.handle, false)
                end
            end
            s:sleep(500)
        end

        if self:GetPos():distance(Self.GetPos()) <= 10 then
            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(
                self.driver,
                "GENERIC_BYE",
                "SPEECH_PARAMS_FORCE",
                0
            )
        end

        TASK.TASK_VEHICLE_DRIVE_WANDER(
            self.driver,
            self.handle,
            self.drivingModes[1].speed,
            self.drivingModes[1].drivingFlags
        )

        s:sleep(9000)
        Game.FadeOutEntity({ self.handle, self.driver })
        s:sleep(1000)
        self:Cleanup()
    end)
end

function PrivateLimo:Cleanup()
    if self.isRemoteControlled then
        self:ReleaseControl()
    end

    Game.DeleteEntity(self.driver, "peds")
    Game.DeleteEntity(self.handle, "vehicles")

    if self.limoClone then
        Game.DeleteEntity(self.limoClone, "vehicles")
    end

    if self.playerClone then
        Game.DeleteEntity(self.playerClone, "vehicles")
    end

    ENTITY.SET_ENTITY_VISIBLE(Self.GetPedID(), true, true)
    ENTITY.SET_ENTITY_ALPHA(Self.GetPedID(), 255, false)

    self.driver = nil
    self.handle = nil
end

function PrivateLimo:ForceCleanup()
    ENTITY.DELETE_ENTITY(self.driver)
    ENTITY.DELETE_ENTITY(self.handle)

    if self.limoClone then
        ENTITY.DELETE_ENTITY(self.limoClone)
    end

    if self.playerClone then
        ENTITY.DELETE_ENTITY(self.playerClone)
    end

    if self.isRemoteControlled then
        ENTITY.SET_ENTITY_VISIBLE(Self.GetPedID(), true, true)
        ENTITY.SET_ENTITY_ALPHA(Self.GetPedID(), 255, false)
    end
end

function PrivateLimo:StateEval()
    if self.lastCheckTime and self.lastCheckTime > Time.now() then
        return
    end

    if not Game.IsScriptHandle(self.handle)
        or not ENTITY.IS_ENTITY_A_VEHICLE(self.handle) then
        BillionaireServices:RemoveLimo()
    end

    if not Game.IsScriptHandle(self.driver)
        or ENTITY.IS_ENTITY_DEAD(self.driver, false)
        or not ENTITY.IS_ENTITY_A_PED(self.driver) then
        BillionaireServices:RemoveLimo()
    end

    if self.limoClone
        and self.isRemoteControlled
        and not Game.IsScriptHandle(self.limoClone) then
        self.isRemoteControlled = false
        self:Cleanup()
        BillionaireServices.ActiveServices.limo = nil
        ENTITY.SET_ENTITY_VISIBLE(Self.GetPedID(), true, true)
        ENTITY.SET_ENTITY_ALPHA(Self.GetPedID(), 255, false)
    end

    if not VEHICLE.IS_VEHICLE_DRIVEABLE(self.handle, false) and not ENTITY.IS_ENTITY_IN_WATER(self.handle) then
        Game.Vehicle.RepairVehicle(self.handle)
    end

    if ENTITY.IS_ENTITY_IN_WATER(self.handle) then
        local roadNode, roadHeading = Game.GetClosestVehicleNodeWithHeading(
            Self.GetPos(),
            0
        )

        if not roadNode:is_zero() then
            Game.SetEntityHeading(self.handle, roadHeading)
            Game.SetEntityCoords(self.handle, roadNode)
            Game.Vehicle.RepairVehicle(self.handle)
        end
    end

    if PED.IS_PED_SITTING_IN_ANY_VEHICLE(Self.GetPedID())
        and (self:IsPlayerInLimo()
            and PED.IS_PED_STOPPED(Self.GetPedID())) then
        local playerDoor = Game.GetPedVehicleSeat(Self.GetPedID()) + 1

        if VEHICLE.GET_IS_DOOR_VALID(self.handle, playerDoor)
            and not VEHICLE.IS_VEHICLE_DOOR_DAMAGED(self.handle, playerDoor)
            and VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(self.handle, playerDoor) > 0 then
            VEHICLE.SET_VEHICLE_DOOR_SHUT(self.handle, playerDoor, false)
        end
    else
        if (PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(Self.GetPedID()) == self.handle)
            and PED.IS_PED_TRYING_TO_ENTER_A_LOCKED_VEHICLE(Self.GetPedID()) then
            VEHICLE.SET_VEHICLE_DOORS_SHUT(self.handle, false)
            VEHICLE.SET_VEHICLE_DOOR_OPEN(self.handle, 3, false, false)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
            PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), self.handle, 2)
        end
    end

    if self.isRemoteControlled
    and self.limoClone
    and not PED.IS_PED_IN_VEHICLE(Self.GetPedID(), self.limoClone, true) then
        if ENTITY.DOES_ENTITY_EXIST(self.limoClone)
        and (self:GetPos():distance(Self.GetPos()) <= 5) then
            VEHICLE.BRING_VEHICLE_TO_HALT(self.limoClone, 1.0, 1, false)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
            PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), self.limoClone, -1)
            VEHICLE.SET_VEHICLE_DOORS_SHUT(self.limoClone, true)
        end

        self:ReleaseControl()

        local timer = Timer.new(2000)
        while not timer:isDone() do
            if self:IsPlayerInLimo() then
                break
            end
            yield()
        end

        TASK.TASK_LEAVE_VEHICLE(Self.GetPedID(), self.handle, 0)
    end

    if not self:IsIdle() then
        if not self:IsPlayerInLimo() then
            self:Stop()
            return
        end

        if (self.task == eVehicleTask.GOTO) and self.lastTaskCoords then
            local speed = ENTITY.GET_ENTITY_SPEED(self.handle)
            local threshold = math.max(50, speed * 2.5)

            if self:GetPos():distance(self.lastTaskCoords) <= threshold then
                YimToast:ShowMessage(
                    "Samurai's Scripts",
                    "[Private Limo]: You have reached your destination."
                )
                -- self:Stop()
                self:Park()
            end
        end
    end

    if self:IsPlayerInLimo() then
        self.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(self.handle)
        self.radio.stationName = self.radio.isOn
        and HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
        or "Off"
    end

    self:ToggleBlip(not self:IsPlayerInLimo() and not self.isRemoteControlled)
    self.lastCheckTime = Time.now() + 1
end

PrivateLimo.Limos = {
    ["Patriot Stretch"] = {
        model = 0xE6E967F8,
        color = {
            primary = t_CustomPaints[18],
            secondary = t_CustomPaints[18]
        },
        mods = {
            [2] = 0,
            [3] = 0,
            [5] = 1,
            [8] = 7,
            [12] = 3,
            [13] = 2,
            [16] = 2,
            [17] = 4,
            [24] = 22
        },
        wheelType = 9,
        window_tint = 1,
        description = "The perfect choice for flashy arrivals."
    },
    ["Cognoscenti LWB"] = {
        model = 0x86FE0B60,
        color = {
            primary = t_CustomPaints[11],
            secondary = t_CustomPaints[22]
        },
        mods = {
            [12] = 3,
            [13] = 2,
            [16] = 3,
            [17] = 4,
            [24] = 8,
        },
        wheelType = 3,
        wheelColor = 0,
        window_tint = 1,
        description = "Understated class."
    },
    ["Stretch Limo"] = {
        model = 0x8B13F083,
        color = {
            primary = t_CustomPaints[11],
            secondary = t_CustomPaints[11]
        },
        window_tint = 1,
        description = "The classic limousine."
    },
    ["Turreted Limo"] = {
        model = 0xF92AEC4D,
        color = {
            primary = t_CustomPaints[11],
            secondary = t_CustomPaints[11]
        },
        window_tint = 1,
        description = "The perfect choice for billionaires under siege."
    },
    ["Roosevelt Valor"] = {
        model = 0xDC19D101,
        color = {
            primary = t_CustomPaints[18],
            secondary = t_CustomPaints[11]
        },
        window_tint = 0,
        description = "A vintage icon from the prohibition era: When business was booming and rivals were bleeding."
    },
    ["Windsor Drop"] = {
        model = 0x8CF5CAE1,
        mods = {
            [12] = 3,
            [13] = 2,
            [14] = 2,
            [16] = 3,
            [17] = 4,
            [24] = 27,
        },
        color = {
            primary = t_CustomPaints[18],
            secondary = t_CustomPaints[22],
            interior = 106
        },
        wheelType = 3,
        window_tint = 1,
        description = "Arab money."
    },
}
