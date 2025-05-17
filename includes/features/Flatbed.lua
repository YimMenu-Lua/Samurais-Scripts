---@class TowedVehicle
---@field handle integer
---@field modelHash integer
---@field name string
---@field minSize vec3
---@field maxSize vec3
---@field towpos vec3
---@field hasPassenggers boolean
---@field passengers table
TowedVehicle = {}
TowedVehicle.__index = TowedVehicle

function TowedVehicle:New(handle, modelHash, name, towpos)
    local instance = setmetatable({}, TowedVehicle)
    instance.handle = handle
    instance.modelHash = modelHash
    instance.name = name
    instance.towpos = towpos
    instance.passengers = Game.Vehicle.GetOccupants(handle)
    instance.hasPassenggers = (instance.passengers and #instance.passengers > 0) or false
    return instance
end

---@class Flatbed
---@field handle number
---@field previousHandle number
---@field heading number
---@field boneIndex number
---@field coords vec3
---@field forwardVector vec3
---@field searchPosition vec3
---@field towedVehicle TowedVehicle
Flatbed = {}
Flatbed.__index = Flatbed
Flatbed.modelHash = 1353720154
Flatbed.handle = 0
Flatbed.previousHandle = 0
Flatbed.towOffset = vec3:new(0.0, 1.0, 0.69)
Flatbed.displayText = ""
Flatbed.shouldPause = false
Flatbed.closestVehicle = {
    isTowable = false,
    modelHash = 0,
    handle = 0,
    name = "",
}

function Flatbed:Spawn()
    if not Self.IsOutside() then
        YimToast:ShowError(
            "Samurais Scripts",
            _T("FLTBD_INTERIOR_ERROR_")
        )
        return
    end

    if not Self.IsOnFoot() then
        YimToast:ShowError(
            "Samurais Scripts",
            _T("FLTBD_EXIT_VEH_ERROR_")
        )
        return
    end

    script.run_in_fiber(function(spawn)
        Await(Game.RequestModel, self.modelHash)
        local v_SpawnPos = Self.GetPos()

        self.handle = Game.CreateVehicle(
            self.modelHash,
            v_SpawnPos,
            Self.GetHeading(),
            Game.IsOnline(),
            false
        )

        -- adding a delay because this failed several times to put the player inside the flatbed
        for _ = 1, 50 do
            if self.handle then
                break
            end

            spawn:sleep(1)
        end

        if not ENTITY.DOES_ENTITY_EXIST(self.handle) then
            YimToast:ShowError(
                "Samurai's Scripts",
                "Failed to spawn a flatbed truck! Please try again later."
            )

            self.handle = 0
            return
        end

        Decorator:RegisterEntity(self.handle, "Flatbed", true)
        PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), self.handle, -1)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(self.handle)
    end)
end

function Flatbed:GetClosestVehicleName()
    if (self.closestVehicle.handle == 0) or (self.closestVehicle.modelHash == 0) then
        return ""
    end

    return string.format(
        "%s %s",
        Game.Vehicle.Manufacturer(self.closestVehicle.handle),
        Game.Vehicle.Name(self.closestVehicle.handle)
    )
end

function Flatbed:SetDisplayText()
    if self.towedVehicle then
        self.displayText = string.format(
            "%s %s.", _T("FLTBD_TOWING_TXT_"),
            self.towedVehicle.name)
    else
        if self.closestVehicle.handle == 0 or self.closestVehicle.name == "" then
            self.displayText = _T("FLTBD_NO_VEH_TXT_")
        elseif self.closestVehicle.modelHash == self.modelHash then
            self.displayText = _T("FLTBD_NOT_ALLOWED_TXT_")
        else
            self.displayText = string.format(
                "%s %s",
                _T("FLTBD_NEARBY_VEH_TXT_"),
                self.closestVehicle.name
            )
        end
    end
end

function Flatbed:IsClosestVehicleTowable()
    if (self.closestVehicle.handle == 0) or (self.closestVehicle.modelHash == 0) then
        return false
    end

    return towEverything or
    self.closestVehicle.isCar or
    self.closestVehicle.isBike or
    (self.closestVehicle.modelHash == 745926877)
end

---@param s script_util
function Flatbed:Attach(s)
    if self.closestVehicle.handle == 0 then
        return
    end

    if not self.closestVehicle.isTowable then
        YimToast:ShowWarning("Samurais Scripts", _T("FLTBD_CARS_ONLY_TXT_"))
        return
    end

    if self.closestVehicle.modelHash == self.modelHash then
        YimToast:ShowWarning("Samurais Scripts", _T("FLTBD_NOT_ALLOWED_TXT_"))
        return
    end

    if not entities.take_control_of(self.closestVehicle.handle, 350) then
        YimToast:ShowError("Samurais Scripts", _T("VEH_CTRL_FAIL_"))
        return
    end

    local target = self.closestVehicle
    local v_MinSize, v_MaxSize = Game.GetModelDimensions(
        target.modelHash or
        Game.GetEntityModel(target.handle)
    )

    local v_CenterOffset = vec3:new(
        (v_MinSize.x + v_MaxSize.x) / 2,
        (v_MinSize.y - v_MaxSize.y) / 2,
        (v_MaxSize.z + v_MinSize.z) / 2
    )

    local z_offset = v_CenterOffset.z + self.towOffset.z
    local maxLift = 3.0
    local step = 0.05
    local tries = 0
    local final_z = z_offset
    local success = false

    ENTITY.SET_ENTITY_HEADING(target.handle, self.heading)
    ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(target.handle, self.handle)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(
        target.handle,
        self.handle,
        self.boneIndex,
        v_CenterOffset.x + self.towOffset.x,
        v_CenterOffset.y + self.towOffset.y,
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
    self.towedVehicle = TowedVehicle:New(
        target.handle,
        target.modelHash,
        target.name,
        vec3:new(
            v_CenterOffset.x + self.towOffset.x,
            v_CenterOffset.y + self.towOffset.y,
            z_offset
        )
    )

    s:sleep(50)
    repeat
        ENTITY.ATTACH_ENTITY_TO_ENTITY(
            self.towedVehicle.handle,
            self.handle,
            self.boneIndex,
            v_CenterOffset.x + self.towOffset.x,
            v_CenterOffset.y + self.towOffset.y,
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
        s:sleep(1)

        if not ENTITY.IS_ENTITY_TOUCHING_ENTITY(self.handle, self.towedVehicle.handle) then
            success = true
            ENTITY.ATTACH_ENTITY_TO_ENTITY(
                self.towedVehicle.handle,
                self.handle,
                self.boneIndex,
                v_CenterOffset.x + self.towOffset.x,
                v_CenterOffset.y + self.towOffset.y,
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
            self.towedVehicle.towpos.z = final_z - 0.2
            break
        end

        tries = tries + 1
        final_z = final_z + step
    until success or tries > (maxLift / step)
    Decorator:RegisterEntity(self.towedVehicle.handle, "Flatbed", true)
end

---@param x float
---@param y float
---@param z float
function Flatbed:MoveAttachment(x, y, z)
    if not self.towedVehicle then
        return
    end

    local modifier = 1

    if SS.IsKeyPressed("SHIFT") then
        modifier = 10
    end

    self.towedVehicle.towpos.x = self.towedVehicle.towpos.x + x * modifier
    self.towedVehicle.towpos.y = self.towedVehicle.towpos.y + y * modifier
    self.towedVehicle.towpos.z = self.towedVehicle.towpos.z + z * modifier

    ENTITY.ATTACH_ENTITY_TO_ENTITY(
        self.towedVehicle.handle,
        self.handle,
        self.boneIndex,
        self.towedVehicle.towpos.x,
        self.towedVehicle.towpos.y,
        self.towedVehicle.towpos.z,
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

---@param s script_util
function Flatbed:AttachPhysically(s)
    if self.closestVehicle.handle == 0 then
        return
    end

    if not self.closestVehicle.isTowable then
        YimToast:ShowWarning(
            "Samurais Scripts",
            _T("FLTBD_CARS_ONLY_TXT_")
        )
        return
    end

    if self.closestVehicle.modelHash == self.modelHash then
        YimToast:ShowWarning(
            "Samurais Scripts",
            _T("FLTBD_NOT_ALLOWED_TXT_")
        )
        return
    end

    if not entities.take_control_of(self.closestVehicle.handle, 350) then
        YimToast:ShowError(
            "Samurais Scripts",
            _T("VEH_CTRL_FAIL_")
        )
        return
    end

    local target = self.closestVehicle
    local v_MinSize, v_MaxSize = Game.GetModelDimensions(
        target.modelHash or
        Game.GetEntityModel(target.handle)
    )

    local v_CenterOffset = vec3:new(
        (v_MinSize.x + v_MaxSize.x) / 2,
        (v_MinSize.y - v_MaxSize.y),
        (v_MaxSize.z + v_MinSize.z) / 2
    )

    local z_offset = v_CenterOffset.z + self.towOffset.z
    s:sleep(100)
    ENTITY.SET_ENTITY_HEADING(target.handle, self.heading)
    ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(
        target.handle,
        self.handle,
        -1,
        self.boneIndex,
        v_CenterOffset.x + self.towOffset.x,
        v_CenterOffset.y + self.towOffset.y,
        z_offset,
        v_CenterOffset.x + self.towOffset.x,
        v_CenterOffset.y + self.towOffset.y + 2,
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

    self.towedVehicle = TowedVehicle:New(
        target.handle,
        target.modelHash,
        target.name,
        vec3:new(
            v_CenterOffset.x + self.towOffset.x,
            v_CenterOffset.y + self.towOffset.y + 2,
            z_offset - 1.1
        )
    )
end

function Flatbed:Detach()
    if (
        Self.Vehicle.IsFlatbed and
        self.towedVehicle and
        (self.towedVehicle.handle ~= 0) and
        ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(self.towedVehicle.handle, self.previousHandle)
    ) then
        local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(self.towedVehicle.handle, false)

        if entities.take_control_of(self.towedVehicle.handle, 350) then
            ENTITY.DETACH_ENTITY(self.towedVehicle.handle, true, true)
            ENTITY.SET_ENTITY_COORDS(
                self.towedVehicle.handle,
                attachedVehcoords.x - (self.forwardVector.x * 10),
                attachedVehcoords.y - (self.forwardVector.y * 10),
                self.coords.z,
                false,
                false,
                false,
                false
            )
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.towedVehicle.handle, 5.0)
            self.towedVehicle = nil
        end

        Decorator:RemoveEntity(self.towedVehicle.handle, "Flatbed")
    end
end

function Flatbed:ForceCleanup()
    for _, v in ipairs(entities.get_all_vehicles_as_handles()) do
        local modelHash = ENTITY.GET_ENTITY_MODEL(v)
        local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(self.previousHandle, modelHash)

        if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) and entities.take_control_of(attachedVehicle, 350) then
            local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attachedVehicle, false)

            ENTITY.DETACH_ENTITY(attachedVehicle, true, true)
            ENTITY.SET_ENTITY_COORDS(
                attachedVehicle,
                attachedVehcoords.x - (self.forwardVector.x * 10),
                attachedVehcoords.y - (self.forwardVector.y * 10),
                attachedVehcoords.z,
                false,
                false,
                false,
                false
            )
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attachedVehicle, 5.0)
            Decorator:RemoveEntity(self.towedVehicle.handle, "Flatbed")
            self.towedVehicle = nil
        end
    end
end

---@param s script_util
function Flatbed:OnKeyPress(s)
    if self.towedVehicle then
        self:Detach()
    else
        self:Attach(s)
    end
end

---@param s script_util
function Flatbed:BackgroundWorker(s)
    if Self.Vehicle.IsFlatbed then
        if self.previousHandle == 0 then
            self.previousHandle = self.handle
        else
            if self.previousHandle ~= self.handle then
                self:Detach()
                s:sleep(50)
                self:Reset()
            end
        end

        self.handle = Self.Vehicle.Current
        self.heading = Game.GetHeading(self.handle)
        self.coords = Game.GetEntityCoords(self.handle, false)
        self.forwardVector = Game.GetForwardVector(self.previousHandle or self.handle)
        self.boneIndex = Game.GetEntityBoneIndexByName(self.handle, "chassis")
        self.searchPosition = vec3:new(
            self.coords.x - (self.forwardVector.x * 10),
            self.coords.y - (self.forwardVector.y * 10),
            self.coords.z
        )

        self.closestVehicle.handle = Game.GetClosestVehicle(self.searchPosition, 5, self.handle)
        self.closestVehicle.modelHash = self.closestVehicle.handle ~= 0 and Game.GetEntityModel(self.closestVehicle.handle) or 0
        self.closestVehicle.name = self:GetClosestVehicleName()
        self.closestVehicle.isTowable = self:IsClosestVehicleTowable()

        self:SetDisplayText()

        if self.towedVehicle == nil and Self.IsDriving() then
            if towPos then
                GRAPHICS.DRAW_MARKER_SPHERE(
                    self.searchPosition.x,
                    self.searchPosition.y,
                    self.searchPosition.z,
                    3.0,
                    180,
                    128,
                    0,
                    0.115
                )
            end

            if towBox and self.closestVehicle.handle ~= 0 then
                Game.DrawBoundingBox(self.closestVehicle.handle, Col("yellow"))
            end
        end

        if pressing_fltbd_button then
            self:OnKeyPress(s)
        end
    else
        if self.handle ~= 0 and not ENTITY.DOES_ENTITY_EXIST(self.handle) then
            self:Reset()
        end
    end
end

function Flatbed:Reset()
    self.closestVehicle = {
        isTowable = false,
        modelHash = 0,
        handle = 0,
        name = "",
    }

    if self.towedVehicle then
        Decorator:RemoveEntity(self.towedVehicle.handle, "Flatbed")
    end

    Decorator:RemoveEntity(self.handle, "Flatbed")
    self.previousHandle = 0
    self.searchPosition = vec3:zero()
    self.forwardVector = vec3:zero()
    self.towedVehicle = nil
    self.boneIndex = -1
    self.heading = 0
    self.coords = vec3:zero()
    self.handle = 0
end
