--------------------------------------
-- Class: Ped
--------------------------------------
-- **Global.**
--
-- **Parent:** `Entity`.
--
-- Class representing a GTA V Ped.
---@class Ped : Entity
---@field private m_internal CPed
---@field Create fun(_, modelHash: hash, entityType: eEntityType, pos?: vec3, heading?: number, isNetwork?: boolean, isScriptHostPed?: boolean): Ped
---@overload fun(handle: handle): Ped
Ped = Class("Ped", Entity)

---@return boolean
function Ped:IsValid()
    return self:Exists() and ENTITY.IS_ENTITY_A_PED(self:GetHandle())
end

---@return boolean
function Ped:IsAlive()
    return self:IsValid() and not ENTITY.IS_ENTITY_DEAD(self:GetHandle(), false)
end

---@return boolean
function Ped:IsOnFoot()
    return self:IsValid() and PED.IS_PED_ON_FOOT(self:GetHandle())
end

---@return boolean
function Ped:IsRagdoll()
    return PED.IS_PED_RAGDOLL(self:GetHandle())
end

---@return boolean
function Ped:IsInCombat()
    if not self:IsValid() or not self:IsAlive() then
        return false
    end

    local handle = self:GetHandle()
    local pos = self:GetPos()

    return PED.IS_PED_IN_COMBAT(handle, 0)
    or PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(
        handle,
        pos.x,
        pos.y,
        pos.z,
        100
    ) > 0
end

---@return boolean
function Ped:IsInWater()
    return self:IsValid() and ENTITY.IS_ENTITY_IN_WATER(self:GetHandle())
end

---@return boolean
function Ped:IsSwimming()
    if not self:IsValid() then
        return false
    end

    local handle = self:GetHandle()
    return PED.IS_PED_SWIMMING(handle) or PED.IS_PED_SWIMMING_UNDER_WATER(handle)
end

---@return boolean
function Ped:IsOutside()
    return INTERIOR.GET_INTERIOR_FROM_ENTITY(self:GetHandle()) == 0
end

---@return boolean
function Ped:IsMoving()
    return self:IsValid() and not PED.IS_PED_STOPPED(self:GetHandle())
end

---@return boolean
function Ped:IsFalling()
    return self:IsValid() and PED.IS_PED_FALLING(self:GetHandle())
end

---@return boolean
function Ped:IsDriving()
    local veh = self:GetVehicle()

    if not veh then
        return false
    end

    return (VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh:GetHandle(), -1, false) == self:GetHandle())
end

---@return boolean
function Ped:IsEnemy()
    if (not self:IsValid()) then
        return false
    end

    local pedHandle = self:GetHandle()
    local localPlayer = Self:GetHandle()

    if (pedHandle == localPlayer) then
        return false
    end

    local relationship = PED.GET_RELATIONSHIP_BETWEEN_PEDS(pedHandle, localPlayer)
    local pedCoords = self:GetPos(true)

    return (
        PED.IS_PED_IN_COMBAT(pedHandle, localPlayer)
        or (relationship > 2 and relationship <= 5)
        or PED.IS_ANY_HOSTILE_PED_NEAR_POINT(
            pedHandle,
            pedCoords.x,
            pedCoords.y,
            pedCoords.z,
            1
        )
    )
end

---@return hash -- weapon hash or 0.
function Ped:GetCurrentWeapon()
    if not self:IsValid() then
        return 0
    end

    local armed, weapon = false, 0
    armed, weapon = WEAPON.GET_CURRENT_PED_WEAPON(self:GetHandle(), weapon, false)
    return armed and weapon or 0
end

-- Bypasses `Vehicle` instance creation and directly returns the handle of the ped's vehicle or 0.
---@return handle
function Ped:GetVehicleNative()
    return PED.GET_VEHICLE_PED_IS_IN(self:GetHandle(), false)
end

---@return Vehicle|nil -- A `Vehicle` instance or `nil`, not a vehicle handle.
function Ped:GetVehicle()
    if not self:IsValid() or self:IsOnFoot() then
        return
    end

    return Vehicle(self:GetVehicleNative())
end

---@return hash -- weapon hash or 0.
function Ped:GetVehicleWeapon()
    if not self:IsValid() or self:IsOnFoot() then
        return 0
    end

    local weapon = 0
    _, weapon = WEAPON.GET_CURRENT_PED_VEHICLE_WEAPON(self:GetHandle(), weapon)
    return weapon
end

---@return number
function Ped:GetRelationshipGroupHash()
    return self:IsValid() and PED.GET_PED_RELATIONSHIP_GROUP_HASH(self:GetHandle()) or 0
end

function Ped:GetGroupIndex()
    return self:IsValid() and PED.GET_PED_GROUP_INDEX(self:GetHandle()) or 0
end

---@return integer
function Ped:GetArmour()
    return self:IsValid() and PED.GET_PED_ARMOUR(self:GetHandle()) or 0
end

---@param cloneSpawnPos? vec3
---@param isNetwork? boolean
---@param isScriptHost? boolean
---@param copyHeadBlend? boolean
function Ped:Clone(cloneSpawnPos, isNetwork, isScriptHost, copyHeadBlend)
    if not self:IsValid() then
        return
    end

    if (isNetwork == nil) then
        isNetwork = Game.IsOnline()
    end

    if (isScriptHost == nil) then
        isScriptHost = false
    end

    if (copyHeadBlend == nil) then
        copyHeadBlend = true
    end

    cloneSpawnPos = cloneSpawnPos or self:GetOffsetInWorldCoords(math.random(-2, 2), math.random(2, 5), 0.1)
    local clone = Ped(PED.CLONE_PED(self:GetHandle(), isNetwork, isScriptHost, copyHeadBlend))
    Ped:SetCoords(cloneSpawnPos)

    return clone
end

---@param targetPed number
function Ped:CloneToTarget(targetPed)
    if not self:IsValid() then
        return
    end

    PED.CLONE_PED_TO_TARGET(self:GetHandle(), targetPed)
end

---@param boneID number
function Ped:GetBoneIndex(boneID)
    if not self:IsValid() then
        return
    end

    return Game.GetPedBoneIndex(self:GetHandle(), boneID)
end

---@param boneID number
function Ped:GetBoneCoords(boneID)
    if not self:IsValid() then
        return vec3:zero()
    end

    return Game.GetPedBoneCoords(self:GetHandle(), boneID)
end

---@return number|nil
function Ped:GetVehicleSeat()
    if (not self:IsValid() or not self:IsAlive() or self:IsOnFoot()) then
        return
    end

    return Game.GetPedVehicleSeat(self:GetHandle())
end

---@return table
function Ped:GetComponentVariations()
    if not self:IsValid() then
        return {}
    end

    return Game.GetPedComponents(self:GetHandle())
end

---@param components? table
function Ped:SetComponenVariations(components)
    components = components or self:GetComponentVariations()
    Game.ApplyPedComponents(self:GetHandle(), components)
end

---@param vehicle_handle handle
---@param seatIndex? number
function Ped:WarpIntoVehicle(vehicle_handle, seatIndex)
    if not (self:IsValid() or self:IsAlive() or ENTITY.DOES_ENTITY_EXIST(vehicle_handle)) then
        return
    end

    seatIndex = seatIndex or -1
    if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle_handle, seatIndex, true) then
        seatIndex = -2
    end

    PED.SET_PED_INTO_VEHICLE(self:GetHandle(), vehicle_handle, seatIndex)
end

function Ped:Clean()
    if not (self:IsValid() and self:IsAlive()) then
        return
    end

    local hndl = self:GetHandle()

    PED.CLEAR_PED_BLOOD_DAMAGE(hndl)
    PED.CLEAR_PED_WETNESS(hndl)
    PED.CLEAR_PED_ENV_DIRT(hndl)
    PED.RESET_PED_VISIBLE_DAMAGE(hndl)

    for i = 0, 5, 1 do
        PED.CLEAR_PED_DAMAGE_DECAL_BY_ZONE(hndl, i, "ALL")
    end
end
