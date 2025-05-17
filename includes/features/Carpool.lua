---@class Carpool
---@field vehicle integer
---@field lastTaskCoords vec3
Carpool = {}
Carpool.__index = Carpool
Carpool.task = eVehicleTask.NONE
Carpool.isCarpooling = false
Carpool.driver = 0
Carpool.lastCheckTime = 0
Carpool.currentDrivingMode = 1
Carpool.taskForceStop = 99
Carpool.vehicleData = {
    speed = 0,
    isConvertible = false,
    roofState = nil,
    maxSeats = 0,
    occupants = {},
    radio = {
        isOn = false,
        station = "Off"
    }
}
Carpool.drivingModes = {
    { drivingFlags = 786603,  speed = 20 },
    { drivingFlags = 2886204, speed = 60 }
}

function Carpool:FindCarpoolVehicle()
    if PED.IS_PED_IN_ANY_VEHICLE(Self.GetPedID(), false) then
        return
    end

    if not self.vehicle or (self.vehicle == 0) then
        self.vehicle = Game.GetClosestVehicle(Self.GetPedID(), 15, nil, true, 3)
    else
        if ENTITY.IS_ENTITY_A_VEHICLE(self.vehicle) then
            if SS.IsScriptEntity(self.vehicle) then
                self.vehicle = nil
                return
            end

            if Self.GetPos():distance(Game.GetEntityCoords(self.vehicle, false)) >= 20 then
                self.vehicle = nil
                return
            end

            if VEHICLE.IS_VEHICLE_SEAT_FREE(self.vehicle, -1, false)
            or not Game.Vehicle.IsAnySeatFree(self.vehicle) then
                self.vehicle = nil
                return
            end

            self.vehicleData.occupants = Game.Vehicle.GetOccupants(self.vehicle)

            for _, occupant in ipairs(self.vehicleData.occupants) do
                if occupant
                and entities.take_control_of(occupant, 200)
                and ENTITY.IS_ENTITY_A_PED(occupant)
                and not PED.IS_PED_A_PLAYER(occupant)
                and not PED.IS_PED_GROUP_MEMBER(occupant, Self.GetGroupIndex())
                and not SS.IsScriptEntity(occupant) then
                    TASK.CLEAR_PED_TASKS(occupant)
                    PED.SET_PED_CONFIG_FLAG(occupant, 251, true)
                    PED.SET_PED_CONFIG_FLAG(occupant, 255, true)
                    PED.SET_PED_CONFIG_FLAG(occupant, 398, true)
                    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(occupant, true)
                end
            end
        end
    end
end

function Carpool:OnExit()
    if not self.vehicle or not ENTITY.IS_ENTITY_A_VEHICLE(self.vehicle) then
        return
    end

    if self.isCarpooling and
    (not PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), self.vehicle) or not PED.IS_PED_SITTING_IN_VEHICLE(self.driver, self.vehicle)) then
        self:EmergencyStop()

        for _, occupant in ipairs(self.vehicleData.occupants) do
            if occupant and ENTITY.IS_ENTITY_A_PED(occupant)
            and not PED.IS_PED_A_PLAYER(occupant)
            and not PED.IS_PED_GROUP_MEMBER(occupant, Self.GetGroupIndex())
            and not SS.IsScriptEntity(occupant) then
                PED.SET_PED_CONFIG_FLAG(occupant, 251, false)
                PED.SET_PED_CONFIG_FLAG(occupant, 255, false)
                PED.SET_PED_CONFIG_FLAG(occupant, 398, false)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(occupant, false)
            end
        end

        self.isCarpooling = false
        self.vehicle = nil
        self.driver = 0
        self.vehicleData = {
            speed = 0,
            isConvertible = false,
            roofState = nil,
            maxSeats = 0,
            occupants = {},
            radio = {
                isOn = false,
                station = "Off"
            }
        }
    end
end

function Carpool:GetDrivingStyle()
    return {
        speed = self.drivingModes[self.currentDrivingMode].speed or 20,
        drivingFlags = self.drivingModes[self.currentDrivingMode].drivingFlags or 786603
    }
end

---@param i_DrivingStyle number
function Carpool:SetDrivingStyle(i_DrivingStyle)
    if (type(i_DrivingStyle) ~= "number") or i_DrivingStyle < 1 or i_DrivingStyle > 2 then
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

function Carpool:CancelAnyTasks()
    if not Game.IsScriptHandle(self.vehicle) or not Game.IsScriptHandle(self.driver)  then
        return
    end

    entities.take_control_of(self.driver, 250)
    TASK.CLEAR_PED_TASKS(self.driver)
    TASK.CLEAR_PED_SECONDARY_TASK(self.driver)
    TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.vehicle)
    TASK.TASK_VEHICLE_TEMP_ACTION(self.driver, self.vehicle, 1, 2000)

    self.task = eVehicleTask.NONE
    self.lastTaskCoords = nil
end

---@param coords vec3
---@param s script_util
function Carpool:GoTo(coords, s)
    if not Game.IsScriptHandle(self.vehicle) or not Game.IsScriptHandle(self.driver)  then
        return
    end

    self:CancelAnyTasks()
    s:sleep(10)

    TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(
        self.driver,
        self.vehicle,
        coords.x,
        coords.y,
        coords.z,
        self:GetDrivingStyle().speed,
        self:GetDrivingStyle().drivingFlags,
        30
    )

    self.lastTaskCoords = coords
    self.task = eVehicleTask.GOTO
end

---@param s script_util
function Carpool:Wander(s)
    if not Game.IsScriptHandle(self.vehicle) or not Game.IsScriptHandle(self.driver)  then
        return
    end

    self:CancelAnyTasks()
    s:sleep(10)

    TASK.TASK_VEHICLE_DRIVE_WANDER(
        self.driver,
        self.vehicle,
        self:GetDrivingStyle().speed,
        self:GetDrivingStyle().drivingFlags
    )

    self.task = eVehicleTask.WANDER
    self.lastTaskCoords = nil
end

function Carpool:Stop()
    if not Game.IsScriptHandle(self.vehicle) or not Game.IsScriptHandle(self.driver)  then
        return
    end

    self:CancelAnyTasks()
    self.task = self.taskForceStop
end

function Carpool:EmergencyStop()
    if not Game.IsScriptHandle(self.vehicle) or not Game.IsScriptHandle(self.driver)  then
        return
    end

    self:CancelAnyTasks()
    self.task = self.taskForceStop
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.vehicle, 0)
end

---@param s script_util
function Carpool:Resume(s)
    if not Game.IsScriptHandle(self.vehicle) or not Game.IsScriptHandle(self.driver)  then
        return
    end

    if self.task ~= self.taskForceStop then
        return
    end

    if self.lastTaskCoords then
        self:GoTo(self.lastTaskCoords, s)
    else
        self.task = eVehicleTask.NONE
    end
end

---@param step integer 1 | -1
function Carpool:ShuffleSeats(step)
    script.run_in_fiber(function()
        if not self.isCarpooling or self.vehicleData.maxSeats <= 1 then
            return
        end

        if not Game.Vehicle.IsAnySeatFree(self.vehicle) then
            return
        end

        local maxSeats = self.vehicleData.maxSeats
        local currentSeat = Game.GetPedVehicleSeat(Self.GetPedID())

        if not currentSeat or (maxSeats < 1) then
            return
        end

        local attempts = 0
        local seatIndex = currentSeat

        while attempts < maxSeats do
            seatIndex = seatIndex + step

            if seatIndex > maxSeats then
                seatIndex = 0
            elseif seatIndex < 0 then
                seatIndex = maxSeats
            end

            if VEHICLE.IS_VEHICLE_SEAT_FREE(self.vehicle, seatIndex, true) then
                PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), self.vehicle, seatIndex)
                self.playerSeat = seatIndex
                return
            end

            attempts = attempts + 1
            yield()
        end
    end)
end

function Carpool:Main(s)
    if not Self.IsOutside() then
        return
    end

    if Self.IsOnFoot() then
        if not self.isCarpooling then
            self:FindCarpoolVehicle()
        else
            self:OnExit()
        end
    elseif PED.IS_PED_IN_VEHICLE(Self.GetPedID(), self.vehicle, false)
    and not Self.IsDriving() then
        self.isCarpooling = true
        self.vehicleData.maxSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(self.vehicle)
        self.driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.vehicle, -1, true)
        self.vehicleData.isConvertible = VEHICLE.IS_VEHICLE_A_CONVERTIBLE(self.vehicle, false)
        self.vehicleData.speed = ENTITY.GET_ENTITY_SPEED(self.vehicle)
        self.vehicleData.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(self.vehicle)
        self.vehicleData.radio.station = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME()) or "Off"

        if self.vehicleData.isConvertible then
            self.vehicleData.roofState = VEHICLE.GET_CONVERTIBLE_ROOF_STATE(self.vehicle)
        end
    end

    if self.isCarpooling then
        if not ENTITY.DOES_ENTITY_EXIST(self.vehicle)
        or not ENTITY.DOES_ENTITY_EXIST(self.driver)
        or (VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.vehicle, -1, true) ~= self.driver) then
            self:OnExit()
        end

        if PAD.IS_CONTROL_PRESSED(0, 75) then
            self:EmergencyStop()
        end

        if self.task == self.taskForceStop then
            while not VEHICLE.IS_VEHICLE_STOPPED(self.vehicle) do
                if not ENTITY.DOES_ENTITY_EXIST(self.vehicle) or not VEHICLE.IS_VEHICLE_DRIVEABLE(self.vehicle, true) then
                    break
                end

                if not PED.IS_PED_SITTING_IN_VEHICLE(self.driver, self.vehicle) then
                    break
                end

                if not PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), self.vehicle) then
                    break
                end

                TASK.TASK_VEHICLE_TEMP_ACTION(self.driver, self.vehicle, 1, 1)
                yield()
            end
        end
    end

    if (self.task ~= self.taskForceStop) then
        s:sleep(50)
    end
end
