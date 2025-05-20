---@diagnostic disable: lowercase-global


---@alias ServiceType integer
---| -1 # ALL
---| 0 # Bodyguard Service
---| 1 # Escort Service
---| 2 # Limo Service
---| 3 # Helicoper Service
---| 4 # Private Jet Service


---@alias GuardTask integer
---| -1 # NONE
---| 0  # FOLLOW
---| 1  # VEH_FOLLOW
---| 2  # JACK_VEHICLE
---| 3  # ENTER_VEHICLE
---| 4  # LEAVE_VEHICLE
---| 5  # COMBAT
---| 6  # STAND_GUARD
---| 7  # WANDER
---| 8  # SIT_IN_VEH
---| 9  # GO_HOME
---| 10 # PRACHUTE
---| 11 # RAPPELL_DOWN
---| ...
---| 99 # OVERRIDE


---@alias GuardRole integer 
---| 0 # BODYGUARD
---| 1 # ESCORT_DRIVER
---| 2 # ESCORT_PASSENGER


---@alias VehicleTask integer
---| -1 # NONE
---| 0  # GOTO
---| 1  # WANDER
---| 2  # PLANE_TAXI
---| 3  # TAKE_OFF
---| 4  # LAND
---| 5  # HOVER_IN_PLACE
---| 6  # GO_HOME
---| 99  # OVERRIDE


-----------------------------------------------------
-- Billionaire Services Class
-----------------------------------------------------
---@class BillionaireServices
---@field Bodyguards Bodyguard[]
---@field EscortGroups EscortGroup[]
---@field EscortVehicles EscortVehicle[]
BillionaireServices = {}
BillionaireServices.__index = BillionaireServices

BillionaireServices.Bodyguards = {}
BillionaireServices.EscortGroups = {}
BillionaireServices.EscortVehicles = {}
BillionaireServices.GroupManager = GroupManager
BillionaireServices.GroupManager.globalTick = GroupManager.globalTick or 0
BillionaireServices.SERVICE_TYPE = {
    ALL = -1,
    BODYGUARD = 0,
    ESCORT = 1,
    LIMO = 2,
    HELI = 3,
    JET = 4,
}
BillionaireServices.ActiveServices = {
    ---@type PrivateLimo
    limo = nil,
    ---@type PrivateHeli
    heli = nil,
    ---@type PrivateJet
    jet = nil,
}


---@param entity integer
function BillionaireServices:RegisterEntity(entity)
    Decorator:RegisterEntity(entity, "BillionaireServices", true)
end

---@param entity integer
function BillionaireServices:UnregisterEntity(entity)
    Decorator:RemoveEntity(entity, "BillionaireServices")
end

function BillionaireServices:GetServiceCount()
    local count = 0

    if next(self.Bodyguards) ~= nil then
        count = count + 1
    end

    if next(self.EscortGroups) ~= nil then
        count = count + 1
    end

    for _, service in pairs(self.ActiveServices) do
        if service then
            count = count + 1
        end
    end

    return count
end

---@param gender string male | female
---@return string
function BillionaireServices:GetRandomPedName(gender)
    local eRandomNames = t_RandomPedNames[gender]
    return eRandomNames[math.random(1, #eRandomNames)] or "NULL"
end

---@param modelHash integer
---@param name? string
---@param spawnPos? vec3
---@param weapon? integer|boolean
---@param godmode? boolean
---@param disableRagdoll? boolean
---@param behavior? integer
function BillionaireServices:SpawnBodyguard(modelHash, name, spawnPos, weapon, godmode, disableRagdoll, behavior)
    script.run_in_fiber(function()
        local count = table.GetLength(self.Bodyguards)
        if count > 1 and (count % 10 == 0) then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "[Warning] You're spawning too many bodyguards!"
            )
        end

        local guard = Bodyguard.new(
            modelHash,
            name,
            spawnPos,
            weapon,
            godmode,
            disableRagdoll,
            behavior
        )

        if not guard then
            YimToast:ShowError(
                "Samurai's Scripts",
                "[ERROR] Failed to summon a bodyguard!"
            )
            return
        end

        guard.role = guard.ROLE.BODYGUARD

        self:RegisterEntity(guard.handle)
        self.GroupManager:AddBodyguard(guard)
        self.Bodyguards[guard.handle] = guard
    end)
end

---@param handle integer
function BillionaireServices:GetBodyguardByHandle(handle)
    return self.Bodyguards[handle]
end

---@param bodyguard Bodyguard
function BillionaireServices:DismissBodyguard(bodyguard)
    script.run_in_fiber(function(s)
        self.GroupManager:RemoveBodyguard(bodyguard.handle)

        if table.GetLength(self.Bodyguards) == 1 then
            bodyguard:Speak("GENERIC_BYE", "SPEECH_PARAMS_FORCE_SHOUTED")
        end

        if bodyguard:Dismiss(s) then
            self:RemoveBodyguard(bodyguard)
        end
    end)
end

function BillionaireServices:DismissAllBodyguards()
    local closest_bodyguard = self:GetClosestBodyguard()

    if closest_bodyguard and closest_bodyguard:IsAlive() then
        closest_bodyguard:Speak("GENERIC_BYE", "SPEECH_PARAMS_FORCE_SHOUTED")
    end

    for _, bodyguard in pairs(self.Bodyguards) do
        self:DismissBodyguard(bodyguard)
    end
end

---@param bodyguard Bodyguard
function BillionaireServices:RemoveBodyguard(bodyguard)
    bodyguard:ClearCombatTask()
    Game.DeleteEntity(bodyguard.handle, "peds")

    self:UnregisterEntity(bodyguard.handle)
    self.GroupManager:RemoveBodyguard(bodyguard.handle)
    self.Bodyguards[bodyguard.handle] = nil
end

---@return Bodyguard|nil
function BillionaireServices:GetClosestBodyguard()
    if next(self.Bodyguards) == nil then
        return
    end

    local allGuardDist = {}

    for _, guard in pairs(self.Bodyguards) do
        if guard:IsAlive() then
            local guardPos = guard:GetPos()

            table.insert(
                allGuardDist,
                {
                    guard = guard,
                    distance = guardPos:distance(Self.GetPos())
                }
            )
        end
    end

    table.sort(allGuardDist, function(a, b)
        return a.distance < b.distance
    end)

    return allGuardDist[1].guard
end

---@param t_Data table
---@param godMode? boolean
---@param noRagdoll? boolean
---@param spawnPos? vec3
function BillionaireServices:SpawnEscortGroup(t_Data, godMode, noRagdoll, spawnPos)
    script.run_in_fiber(function()
        if not Self.IsOutside() then
            YimToast:ShowError(
                "Samurai's Scripts",
                "You can not summon an escort group indoors. Please go outside!"
            )
            return
        end

        if Self.IsInWater() then
            YimToast:ShowError(
                "Samurai's Scripts",
                "You can not summon an escort group while swimming. Please go to a suitable location first!"
            )
            return
        end

        local count = table.GetLength(self.EscortGroups)

        if count > 1 and (count % 4 == 0) then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "[Warning] You're spawning too many escort groups!"
            )
        end

        local group = EscortGroup:Spawn(
            t_Data,
            godMode,
            noRagdoll,
            spawnPos
        )

        if not group then
            YimToast:ShowError(
                "Samurai's Scripts",
                "[ERROR] Failed to summon an escort group!"
            )
            return
        end

        for _, member in ipairs(group.members) do
            self:RegisterEntity(member.handle)
        end

        self:RegisterEntity(group.vehicle.handle)
        self.GroupManager:AddEscortGroup(group)
        self.EscortGroups[group.name] = group
        self.EscortVehicles[group.vehicle.handle] = group.vehicle
    end)
end

---@param group EscortGroup
---@param godMode? boolean
---@param noRagdoll? boolean
function BillionaireServices:RespawnEscortGroup(group, godMode, noRagdoll)
    if not group.members or (table.GetLength(group.members) == 0) then
        return
    end

    if not Self.IsOutside() then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Please go outside!"
        )
        return
    end

    script.run_in_fiber(function(s)
        local t_Data = group:ToTable()
        local spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
            Self.GetPedID(),
            math.random(-2, 2),
            -10,
            0.1
        )

        self:RemoveEscortGroup(group.name)
        s:sleep(250)
        self:SpawnEscortGroup(
            t_Data,
            godMode or false,
            noRagdoll or false,
            spawnPos
        )
    end)
end

---@param vehicleHandle integer
function BillionaireServices:GetEscortVehicleByHandle(vehicleHandle)
    return self.EscortVehicles[vehicleHandle] ~= nil
end

function BillionaireServices:IsPlayerInEscortVehicle()
    local playerVeh = Self.GetVehicle()
    return (playerVeh ~= 0)
    and self:GetEscortVehicleByHandle(playerVeh)
end

---@param groupName string
function BillionaireServices:DismissEscortGroup(groupName)
    script.run_in_fiber(function(s)
        local group = self.EscortGroups[groupName]

        if group then
            self.GroupManager.Escorts[group.name].group = nil
            s:sleep(250)
            group:Dismiss(s)
        end

        self:RemoveEscortGroup(groupName)
    end)
end

function BillionaireServices:RemoveEscortGroup(groupName)
    local group = self.EscortGroups[groupName]

    if not group then
        return
    end

    for _, guard in ipairs(group.members) do
        Game.DeleteEntity(guard.handle, "peds")
    end

    Game.DeleteEntity(group.vehicle.handle, "vehicles")
    self.GroupManager.Escorts[group.name] = nil
    self.EscortGroups[groupName] = nil
    self.EscortVehicles[group.vehicle.handle] = nil
end

function BillionaireServices:DismissAllEscortGroups()
    for _, group in pairs(self.EscortGroups) do
        self:DismissEscortGroup(group.name)
    end
end

---@param t_Data table
---@param spawnPos? vec3
function BillionaireServices:CallPrivateLimo(t_Data, spawnPos)
    script.run_in_fiber(function()
        if not Self.IsOutside() then
            YimToast:ShowError(
                "Samurai's Scripts",
                "You can not call a limousine while staying indoors. Please go outside first!"
            )
            return
        end

        if Self.IsInWater() then
            YimToast:ShowError(
                "Samurai's Scripts",
                "You can not call a limousine while swimming. Please go to a suitable location first!"
            )
            return
        end

        local limo = PrivateLimo:Spawn(t_Data, spawnPos)

        if not limo then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "Unable to summon your private limousine at the moment."
            )
            return
        end

        self.ActiveServices.limo = limo
        self.GroupManager:AddPedToGroup(limo.driver)

        self:RegisterEntity(limo.handle)
        self:RegisterEntity(limo.driver)
    end)
end

function BillionaireServices:PrepareLimoForCleanup()
    if not self.ActiveServices.limo then
        return
    end

    local limo = self.ActiveServices.limo
    self:UnregisterEntity(limo.handle)
    self:UnregisterEntity(limo.driver)
end

function BillionaireServices:DismissLimo()
    if not self.ActiveServices.limo then
        return
    end

    self:PrepareLimoForCleanup()
    self.ActiveServices.limo:Dismiss()
    self.ActiveServices.limo = nil
end

function BillionaireServices:RemoveLimo()
    if not self.ActiveServices.limo then
        return
    end

    self:PrepareLimoForCleanup()
    self.ActiveServices.limo:Cleanup()
    self.ActiveServices.limo = nil
end

---@param model integer
---@param godmode? boolean
function BillionaireServices:CallPrivateHeli(model, godmode)
    script.run_in_fiber(function(s)
        if not Self.IsOutside() then
            YimToast:ShowError(
                "Samurai's Scripts",
                "You can not call a helicopter while staying indoors. Please go outside first!"
            )
            return
        end

        local spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Self.GetPedID(), 0.0, 30.0, 50.0)
        local heli = PrivateHeli.new(model, spawnPos, godmode)
        local isPlayerInWater = (Self.GetVehicle() == 0) and Self.IsInWater() or Self.Vehicle.IsBoat

        if not heli then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "Unable to summon your private heli at the moment."
            )
            return
        end

        self.ActiveServices.heli = heli
        self.GroupManager:AddPedToGroup(heli.pilot)

        self:RegisterEntity(heli.handle)
        self:RegisterEntity(heli.pilot)

        if not isPlayerInWater then
            local timer = Timer.new(3e4)
            TASK.TASK_HELI_MISSION(
                heli.pilot,
                heli.handle,
                0,
                0,
                spawnPos.x,
                spawnPos.y,
                spawnPos.z,
                19,
                8,
                1.0,
                0,
                -1,
                3,
                10.0,
                32
            )

            repeat
                s:sleep(1000)
            until ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(heli.handle) <= 3 or timer:isDone()
        else
            YimToast:ShowMessage(
                "Private Heli",
                "Your helicopter will not land because you're in the water."
            )
        end

        AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(
            heli.pilot,
            "GENERIC_HOWS_IT_GOING",
            "SPEECH_PARAMS_FORCE_HELI",
            0
        )
        heli.isReady = true
    end)
end

function BillionaireServices:PrepareHeliForCleanup()
    if not self.ActiveServices.heli then
        return
    end

    local heli = self.ActiveServices.heli
    self:UnregisterEntity(heli.handle)
    self:UnregisterEntity(heli.pilot)
end

function BillionaireServices:DismissHeli()
    if not self.ActiveServices.heli then
        return
    end

    self:PrepareHeliForCleanup()
    self.ActiveServices.heli:Dismiss()
    self.ActiveServices.heli = nil
end

function BillionaireServices:RemoveHeli()
    if not self.ActiveServices.heli then
        return
    end

    self:PrepareHeliForCleanup()
    self.ActiveServices.heli:Cleanup()
    self.ActiveServices.heli = nil
end

---@param model integer
---@param airportData table
function BillionaireServices:CallPrivateJet(model, airportData)
    script.run_in_fiber(function()
        if not airportData or not airportData.hangar then
            YimToast:ShowError(
                "Samurai's Scripts",
                "Failed to call a private jet! Invalid airport data."
            )
            return
        end

        local jet = PrivateJet.new(model, airportData)

        if not jet then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "Unable to summon your private jet at the moment."
            )
            return
        end

        jet.departureAirport = airportData
        self.ActiveServices.jet = jet
        self.GroupManager:AddPedToGroup(jet.pilot)
        self.GroupManager:AddPedToGroup(jet.copilot)

        self:RegisterEntity(jet.handle)
        self:RegisterEntity(jet.pilot)
        self:RegisterEntity(jet.copilot)

        YimToast:ShowMessage(
            "Private Jet",
            string.format(
                "Your %s is waiting for you at %s",
                jet.name,
                airportData.name
            )
        )
    end)
end

function BillionaireServices:PrepareJetForCleanup()
    if not self.ActiveServices.jet then
        return
    end

    local jet = self.ActiveServices.jet
    self:UnregisterEntity(jet.handle)
    self:UnregisterEntity(jet.pilot)
    self:UnregisterEntity(jet.copilot)
end

function BillionaireServices:DismissJet()
    if not self.ActiveServices.jet then
        return
    end

    if self.ActiveServices.jet:IsCruising() then
        if self.ActiveServices.jet:IsPlayerInJet() then
            YimToast:ShowError(
                "Private Jet",
                "You can not dismiss your jet mid-air! Jump out or ask your pilot to land at an airport first."
            )
            return
        end

        self:RemoveJet()
        return
    end

    self:PrepareJetForCleanup()
    self.ActiveServices.jet:Dismiss()
    self.ActiveServices.jet = nil
end

function BillionaireServices:RemoveJet()
    if not self.ActiveServices.jet then
        return
    end

    self:PrepareJetForCleanup()
    self.ActiveServices.jet:Cleanup()
    self.ActiveServices.jet = nil
end

---@param serviceType ServiceType
function BillionaireServices:Dismiss(serviceType)
    if serviceType == self.SERVICE_TYPE.ALL then
        self:DismissAllBodyguards()
        self:DismissAllEscortGroups()
        self:DismissLimo()
        self:DismissHeli()
        self:DismissJet()
        return
    end

    if (serviceType == self.SERVICE_TYPE.BODYGUARD) then
        self:DismissAllBodyguards()
        return
    end

    if (serviceType == self.SERVICE_TYPE.ESCORT) then
        self:DismissAllEscortGroups()
        return
    end

    if (serviceType == self.SERVICE_TYPE.LIMO) then
        self:DismissLimo()
        return
    end

    if (serviceType == self.SERVICE_TYPE.HELI) then
        self:DismissHeli()
        return
    end

    if (serviceType == self.SERVICE_TYPE.JET) then
        self:DismissJet()
        return
    end
end

function BillionaireServices:RemoveEntityByHandle(handle)
    if next(self.Bodyguards) ~= nil then
        for _, guard in pairs(self.Bodyguards) do
            if (handle == guard.handle) then
                self:RemoveBodyguard(guard)
                return
            end
        end
    end

    if next(self.EscortGroups) ~= nil then
        for _, group in pairs(self.EscortGroups) do
            if (handle == group.vehicle.handle) then
                self:UnregisterEntity(group.vehicle.handle)
                Game.DeleteEntity(group.vehicle.handle, "vehicles")
            end

            for _, escort in pairs(group.members) do
                if (handle == escort.handle) then
                    escort:ClearCombatTask()
                    self:UnregisterEntity(escort.handle)
                    Game.DeleteEntity(escort.handle, "peds")
                end
            end
        end
    end

    if self.ActiveServices.limo then
        if (handle == self.ActiveServices.limo.handle)
        or (handle == self.ActiveServices.limo.driver) then
            self:RemoveLimo()
        end
    end
end

function BillionaireServices:Cleanup()
    self.GroupManager:Cleanup()
    self:RemoveLimo()

    if next(self.Bodyguards) ~= nil then
        for handle, guard in pairs(self.Bodyguards) do
            guard:ClearCombatTask()
            Game.DeleteEntity(handle, "peds")
        end
    end

    if next(self.EscortGroups) ~= nil then
        for _, group in pairs(self.EscortGroups) do
            for _, escort in pairs(group.members) do
                escort:ClearCombatTask()
                Game.DeleteEntity(escort.handle, "peds")
            end
        end
    end

    if next(self.EscortVehicles) ~= nil then
        for handle, _ in pairs(self.EscortVehicles) do
            Game.DeleteEntity(handle, "vehicles")
        end
    end

    self.Bodyguards = {}
    self.EscortGroups = {}
    self.EscortVehicles = {}
end

function BillionaireServices:ForceCleanup()
    self.GroupManager:Cleanup()

    if self.ActiveServices.limo then
        self.ActiveServices.limo:ForceCleanup()
    end

    if self.ActiveServices.heli then
        self.ActiveServices.heli:ForceCleanup()
    end

    if next(self.Bodyguards) ~= nil then
        for handle, guard in pairs(self.Bodyguards) do
            guard:ClearCombatTask()
            ENTITY.DELETE_ENTITY(handle)
        end
    end

    if next(self.EscortVehicles) ~= nil then
        for handle, _ in pairs(self.EscortVehicles) do
            ENTITY.DELETE_ENTITY(handle)
        end
    end

    if next(self.EscortGroups) ~= nil then
        for _, group in pairs(self.EscortGroups) do
            for _, escort in pairs(group.members) do
                escort:ClearCombatTask()
                ENTITY.DELETE_ENTITY(escort.handle)
            end
        end
    end

    self.Bodyguards = {}
    self.EscortGroups = {}
    self.EscortVehicles = {}
end

BillionaireServices.EscortCreatorTutorialText = [[
[1] - Choose a group name.

[2] - Select a vehicle model.

[3] - Select 3 ped models (has to be exactly 3 in order to leave a free vehicle seat for yourself but also keep the original logic intact).

[4] - Optional: Add names for each ped or leave empty to assign a random name.

[5] - Optional: Choose a weapon for each ped or leave empty to automatically give them a Tactical SMG (you can always spawn escorts with all weapons later).
]]
