---@class GroupManager
---@field relationshipGroup integer
---@field globalTick number
GroupManager = {}
GroupManager.Bodyguards = {}
GroupManager.Escorts = {}
GroupManager.__index = GroupManager

function GroupManager:Init()
    if not self.relationshipGroup then
        if PED.DOES_RELATIONSHIP_GROUP_EXIST(joaat("WOMPUS_SPECIAL")) then
            self.relationshipGroup = joaat("WOMPUS_SPECIAL")
        else
            _, self.relationshipGroup = PED.ADD_RELATIONSHIP_GROUP("WOMPUS_SPECIAL", joaat("WOMPUS_SPECIAL"))
        end

        PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.relationshipGroup, Self.GetRelationshipGroupHash())
        PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, Self.GetRelationshipGroupHash(), self.relationshipGroup)
        PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.relationshipGroup, self.relationshipGroup)
    end
end

---@param handle integer
function GroupManager:AddPedToGroup(handle)
    if not self.relationshipGroup then
        self:Init()
    end

    if ENTITY.DOES_ENTITY_EXIST(handle) and ENTITY.IS_ENTITY_A_PED(handle) then
        PED.SET_PED_RELATIONSHIP_GROUP_HASH(handle, self.relationshipGroup)
        ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(handle, false, self.relationshipGroup)
    end
end

---@param bodyguard Bodyguard
function GroupManager:AddBodyguard(bodyguard)
    if not self.relationshipGroup then
        self:Init()
    end

    if ENTITY.DOES_ENTITY_EXIST(bodyguard.handle) and ENTITY.IS_ENTITY_A_PED(bodyguard.handle) then
        PED.SET_PED_RELATIONSHIP_GROUP_HASH(bodyguard.handle, self.relationshipGroup)
        ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(bodyguard.handle, false, self.relationshipGroup)

        bodyguard.tickOffset = (#self.Bodyguards % 4) -- 4 frames? this is getting out of hand... someone please help 😢
        self.Bodyguards[bodyguard.handle] = {
            member = bodyguard,
            lastTaskTime = Time.now()
        }
    end
end

---@param group EscortGroup
function GroupManager:AddEscortGroup(group)
    if not self.relationshipGroup then
        self:Init()
    end

    for _, member in pairs(group.members) do
        if ENTITY.DOES_ENTITY_EXIST(member.handle) and ENTITY.IS_ENTITY_A_PED(member.handle) then
            PED.SET_PED_RELATIONSHIP_GROUP_HASH(member.handle, self.relationshipGroup)
            ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(member.handle, false, self.relationshipGroup)

            member.tickOffset = (#self.Escorts % 4)
        end
    end

    self.Escorts[group.name] = {
        group = group,
        lastTaskTime = Time.now()
    }
end

---@param pedHandle integer
function GroupManager:GetBodyguardByHandle(pedHandle)
    return self.Bodyguards[pedHandle] ~= nil
end

---@param pedHandle integer
function GroupManager:RemoveBodyguard(pedHandle)
    self.Bodyguards[pedHandle] = nil
end

function GroupManager:Cleanup()
    self.Bodyguards = {}
    self.Escorts = {}
end

---@param s script_util
function GroupManager:HandleBodyuards(s)
    if next(self.Bodyguards) == nil then
        return
    end

    local playerCoords = Self.GetPos()

    for ped, data in pairs(self.Bodyguards) do
        if data and ped and SS.IsScriptEntity(ped) then
            ---@type Bodyguard
            local guard = data.member

            if guard and guard.tickOffset and (self.globalTick % 4 == guard.tickOffset) then
                if (data.lastTaskTime < Time.now()) then
                    local guardPos = guard:GetPos()
                    local distance = guardPos:distance(playerCoords)

                    if guard:IsOnFoot() and Self.IsOnFoot() and distance > 5 then
                        guard:QueueTask(guard.TASK.FOLLOW, guard:TaskGoToEntity())
                    end

                    guard:UpdateTasks()
                    guard:UpdatePosition(false)
                    guard:HandleVehicleTransitions()
                    guard:TickCombat()
                    guard:TickVehicleEscort(s)
                    guard:StateEval()

                    data.lastTaskTime = Time.now() + 1
                end
            end
        else
            self.Bodyguards[ped] = nil
        end
    end
end

---@param s script_util
function GroupManager:HandleEscorts(s)
    if next(self.Escorts) == nil then
        return
    end

    for _, data in pairs(self.Escorts) do
        if data and (data.lastTaskTime < Time.now()) then
            ---@type EscortGroup
            local group = data.group
            if group then
                group:BackgroundWorker(s, self.globalTick)
            end
            data.lastTaskTime = Time.now() + 1
        end
    end
    s:sleep(1)
end

---@param s script_util
function GroupManager:OnTick(s)
    self.globalTick = (self.globalTick + 1) % 1e6
    self:HandleBodyuards(s)
    self:HandleEscorts(s)

    if BillionaireServices.ActiveServices.limo then
        BillionaireServices.ActiveServices.limo:StateEval()
    end

    if BillionaireServices.ActiveServices.heli then
        BillionaireServices.ActiveServices.heli:StateEval()
    end

    if BillionaireServices.ActiveServices.jet then
        BillionaireServices.ActiveServices.jet:StateEval()
    end
end