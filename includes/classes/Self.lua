---@diagnostic disable

---@class Self
-- LocalPlayer
Self = {}
Self.__index = Self

---@return number
Self.GetPedID = function()
   return self.get_ped()
end

---@return number
Self.GetPlayerID = function()
    return self.get_id()
end

Self.GetPedModel = function()
    return ENTITY.GET_ENTITY_MODEL(self.get_ped())
end

---@return number
Self.GetVehicle = function()
    return self.get_veh()
end

---@return vec3
Self.GetPos = function()
   return vec3(self.get_pos())
end

---@param rotationOrder? integer
Self.GetRot = function(rotationOrder)
    return vec3(ENTITY.GET_ENTITY_ROTATION(self.get_ped(), rotationOrder or 2))
end

---@param offset? integer
---@return integer
Self.GetHeading = function(offset)
    if not offset then
        offset = 0
    end

    return ENTITY.GET_ENTITY_HEADING(self.get_ped() + offset)
end

---@return vec3
Self.GetForwardVector = function()
    return vec3(ENTITY.GET_ENTITY_FORWARD_VECTOR(Self.GetPedID()))
end

---@return number
Self.GetForwardX = function()
    return ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
end

---@return number
Self.GetForwardY = function()
    return ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
end

---@return number
Self.GetElevation = function()
    return ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(Self.GetPedID())
end

-- Returns the entity localPlayer is aiming at.
---@param skipPlayers? boolean
---@return integer | nil
Self.GetEntityInCrosshairs = function(skipPlayers)
    local bIsAiming, Entity = false, 0

    if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) then
        bIsAiming, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(self.get_id(), Entity)
    end

    if bIsAiming and ENTITY.DOES_ENTITY_EXIST(Entity) then
        if ENTITY.IS_ENTITY_A_PED(Entity) then
            if PED.IS_PED_A_PLAYER(Entity) and skipPlayers then
                return
            end

            if PED.IS_PED_IN_ANY_VEHICLE(Entity, false) then
                return PED.GET_VEHICLE_PED_IS_IN(Entity, false)
            end
        end
    end

    return bIsAiming and Entity or nil
end

---@return integer
Self.GetDeltaTime = function()
    return MISC.GET_FRAME_TIME()
end

Self.GetRelationshipGroupHash = function()
    return PED.GET_PED_RELATIONSHIP_GROUP_HASH(self.get_ped())
end

Self.GetGroupIndex = function()
    local iGroupIndex = PED.GET_PED_GROUP_INDEX(self.get_ped())
    if not PED.DOES_GROUP_EXIST(iGroupIndex) then
        iGroupIndex = PED.CREATE_GROUP(0)
    end

    PED.SET_PED_AS_GROUP_LEADER(self.get_ped(), iGroupIndex)
    PED.SET_GROUP_SEPARATION_RANGE(iGroupIndex, 16960)
    return iGroupIndex
end

-- Returns localPlayer's maximum health.
---@return integer
Self.MaxHealth = function()
    return ENTITY.GET_ENTITY_MAX_HEALTH(Self.GetPedID())
end

-- Returns localPlayer's current health.
---@return integer
Self.Health = function()
    return ENTITY.GET_ENTITY_HEALTH(Self.GetPedID())
end

-- Returns localPlayer's maximum armour.
---@return integer
Self.MaxArmour = function()
    return PLAYER.GET_PLAYER_MAX_ARMOUR(self.get_id())
end

-- Returns localPlayer's current armour
---@return integer
Self.Armour = function()
    return PED.GET_PED_ARMOUR(Self.GetPedID())
end

-- Checks if localPlayer is alive.
Self.IsAlive = function()
    return not ENTITY.IS_ENTITY_DEAD(Self.GetPedID(), false)
end

-- Checks if localPlayer is on foot.
---@return boolean
Self.IsOnFoot = function()
    return PED.IS_PED_ON_FOOT(Self.GetPedID())
end

-- Checks if localPlayer is in combat.
---@return boolean
Self.IsInCombat = function()
    local pos = self.get_pos()
    return PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(
        self.get_ped(),
        pos.x,
        pos.y,
        pos.z,
        100
    ) > 0
end

-- Checks if localPlayer is in water.
---@return boolean
Self.IsInWater = function()
    return ENTITY.IS_ENTITY_IN_WATER(Self.GetPedID())
end

Self.IsSwimming = function()
    return PED.IS_PED_SWIMMING(Self.GetPedID()) or PED.IS_PED_SWIMMING_UNDER_WATER(Self.GetPedID())
end

-- Checks if localPlayer is outside.
Self.IsOutside = function()
    return INTERIOR.GET_INTERIOR_FROM_ENTITY(Self.GetPedID()) == 0
end

Self.IsMoving = function()
    return not PED.IS_PED_STOPPED(Self.GetPedID())
end

---@return boolean
Self.IsRagdolling = function()
    return PED.IS_PED_RAGDOLL(Self.GetPedID())
end

---@return boolean
Self.IsFalling = function()
    return PED.IS_PED_FALLING(Self.GetPedID())
end

Self.IsDriving = function()
    if self.get_veh() == 0 then
        return false
    end

    return (VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.get_veh(), -1, false) == Self.GetPedID())
end

Self.IsUsingAirctaftMG = function()
    if Self.IsDriving() and (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and Game.Vehicle.IsWeaponized(self.get_veh()) then
        local armed, weapon = WEAPON.GET_CURRENT_PED_VEHICLE_WEAPON(Self.GetPedID(), weapon)
        if armed then
            for _, v in ipairs(eAircraftMGs) do
                if weapon == joaat(v) then
                    return true, weapon
                end
            end
        end
    end
    return false, 0
end

-- Returns the hash of localPlayer's selected weapon.
---@return integer
Self.Weapon = function()
    local weaponHash = 0

    _, weaponHash = WEAPON.GET_CURRENT_PED_WEAPON(Self.GetPedID(), weaponHash, false)
    return weaponHash
end

-- Teleports localPlayer to the provided coordinates.
---@param where integer|vec3 -- blip or coordinates
---@param keepVehicle? boolean
Self.Teleport = function(where, keepVehicle)
    script.run_in_fiber(function(selftp)
        local coords

        if not keepVehicle and not Self.IsOnFoot() then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
            selftp:sleep(50)
        end

        if (type(where) == "number") then
            local blip = HUD.GET_FIRST_BLIP_INFO_ID(where)

            if not HUD.DOES_BLIP_EXIST(blip) then
                YimToast:ShowError(
                    "Samurai's Scripts",
                    "Invalid teleport coordinates!"
                )
                return
            end

            coords = HUD.GET_BLIP_COORDS(blip)
        elseif ((type(where) == "table") or (type(where) == "userdata")) and where.x then
            coords = where
        else
            YimToast:ShowError(
                "Samurai's Scripts",
                "Invalid teleport coordinates!"
            )
            return
        end

        STREAMING.REQUEST_COLLISION_AT_COORD(coords.x, coords.y, coords.z)
        selftp:sleep(200)
        PED.SET_PED_COORDS_KEEP_VEHICLE(Self.GetPedID(), coords.x, coords.y, coords.z)
    end)
end

---Enables or disables physical phone intercations in GTA Online
---@param toggle boolean
Self.TogglePhoneAnims = function(toggle)
    for i = 242, 244 do -- PCF_PhoneDisableTextingAnimations, PCF_PhoneDisableTalkingAnimations, PCF_PhoneDisableCameraAnimations
        if PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), i, true) == toggle then
            PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), i, not toggle)
        end
    end
end

---Enables phone gestures in GTA Online.
---@param s script_util
Self.PlayPhoneGestures = function(s)
    local is_phone_in_hand   = script.is_active("CELLPHONE_FLASHHAND")
    local is_browsing_email  = script.is_active("APPMPEMAIL")
    local call_anim_dict     = "anim@scripted@freemode@ig19_mobile_phone@male@"
    local call_anim          = "base"
    local call_anim_boneMask = "BONEMASK_HEAD_NECK_AND_R_ARM"

    if AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
        Await(Game.RequestAnimDict, call_anim_dict)
        TASK.TASK_PLAY_PHONE_GESTURE_ANIMATION(
            Self.GetPedID(), call_anim_dict, call_anim,
            call_anim_boneMask, 0.25, 0.25, true, false
        )
        repeat
            s:sleep(10)
        until not AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() or not Self.CanUsePhoneAnims()
        TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(Self.GetPedID(), 0.25)
    end

    if is_phone_in_hand then
        MOBILE.CELL_HORIZONTAL_MODE_TOGGLE(is_browsing_email)
        for _, v in ipairs(t_CellInputs) do
            if PAD.IS_CONTROL_JUST_PRESSED(0, v.control) then
                MOBILE.CELL_SET_INPUT(v.input)
            end
        end
    end
end

Self.CantTouchThis = function()
    local toggle = noJacking

    if PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 26, false) ~= toggle then
        PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 26, toggle)
    end
    if PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 177, false) ~= toggle then
        PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 177, toggle)
    end
    if PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 398, false) ~= toggle then
        PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 398, toggle)
    end
end

Self.DisableActionMode = function()
    if not PED.GET_PED_RESET_FLAG(Self.GetPedID(), 200) then -- PRF_DisableActionMode
        PED.SET_PED_RESET_FLAG(Self.GetPedID(), 200, true)
    end
end

Self.AllowHatsInVehicles = function()
    if not PED.GET_PED_RESET_FLAG(Self.GetPedID(), 337) then -- PRF_AllowHeadPropInVehicle
        PED.SET_PED_RESET_FLAG(Self.GetPedID(), 337, true)
    end
end

Self.NoRagdollOnVehRoof = function()
    if not PED.GET_PED_RESET_FLAG(Self.GetPedID(), 274) then -- PRF_BlockRagdollFromVehicleFallOff
        PED.SET_PED_RESET_FLAG(Self.GetPedID(), 274, true)
    end
end

Self.IsSwitchingPlayers = function()
    return STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()
end

-- Returns whether the player is currently using any mobile or computer app.
Self.IsBrowsingApps = function()
    for _, v in ipairs(eAppScriptNames) do
        if script.is_active(v) then
            return true
        end
    end

    return false
end

-- Returns whether the player is inside a modshop.
Self.IsInCarModShop = function()
    if not Self.IsOutside() then
        for _, v in ipairs(eModshopScriptNames) do
            if script.is_active(v) then
                return true
            end
        end
    end

    return false
end

---@param ped integer
Self.IsPedMyEnemy = function(ped)
    local relationship = PED.GET_RELATIONSHIP_BETWEEN_PEDS(ped, Self.GetPedID())
    local pedCoords = Game.GetEntityCoords(ped, true)
    return (
        PED.IS_PED_IN_COMBAT(ped, Self.GetPedID()) or
        (relationship > 2 and relationship <= 5) or
        PED.IS_ANY_HOSTILE_PED_NEAR_POINT(
            Self.GetPedID(),
            pedCoords.x,
            pedCoords.y,
            pedCoords.z,
            1
        )
    )
end

-- Checks if localPlayer is near any vehicle's trunk
--
-- and returns the vehicle handle if true.
Self.IsNearCarTrunk = function()
    if Self.IsOnFoot() 
    and not YimActions:IsPedPlaying(self.get_ped())
    and not b_IsPlayingAmbientScenario then
        local selfPos = self.get_pos()
        local selfFwd = Game.GetForwardVector(Self.GetPedID())
        local fwdPos = vec3:new(selfPos.x + (selfFwd.x * 1.3), selfPos.y + (selfFwd.y * 1.3), selfPos.z)
        local veh = Game.GetClosestVehicle(fwdPos, 20, nil, false, 2)

        if veh ~= nil and veh > 0 then
            if not VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(veh)) then
                return false, 0, false
            end

            local bootBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "boot")

            if bootBone ~= -1 then
                local vehCoords = ENTITY.GET_ENTITY_COORDS(veh, false)
                local vehFwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)

                -- create a search area based on the vehicle's length and engine placement
                local engineBone    = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "engine")
                local lfwheelBone   = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "wheel_lf")
                local engBoneCoords = vec3(ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(veh, engineBone))
                local lfwBoneCoords = vec3(ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(veh, lfwheelBone))
                local bonedistance  = lfwBoneCoords:distance(engBoneCoords)
                local isRearEngined = bonedistance > 2 -- Can also read vehicle model flag FRONT_BOOT
                local vmin, vmax    = Game.GetModelDimensions(ENTITY.GET_ENTITY_MODEL(veh))
                local veh_length    = vmax.y - vmin.y

                local tempPos = isRearEngined
                and vec2:new(
                    vehCoords.x + (vehFwdVec.x * (veh_length / 1.6)),
                    vehCoords.y + (vehFwdVec.y * (veh_length / 1.6))
                )
                or vec2:new(
                    vehCoords.x - (vehFwdVec.x * (veh_length / 1.6)),
                    vehCoords.y - (vehFwdVec.y * (veh_length / 1.6))
                )

                local search_area = vec3:new(tempPos.x, tempPos.y, vehCoords.z)

                if search_area:distance(Self.GetPos()) <= 1.5 then
                    return true, veh, isRearEngined
                end
            end
        end
        yield()
    end

    return false, 0, false
end

-- Checks if localPlayer is near a trash bin
--
-- and returns the entity handle of the bin if true.
Self.IsNearTrashBin = function()
    local binPos = vec3:zero()
    local myCoords = Self.GetPos()
    local myFwdVec = Self.GetForwardVector()
    local searchPos = vec3:new(
        myCoords.x + myFwdVec.x * 1.2,
        myCoords.y + myFwdVec.y * 1.2,
        myCoords.z + myFwdVec.z * 1.2
    )

    for _, trash in ipairs(eTrashBins) do
        local bin = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(
            searchPos.x,
            searchPos.y,
            searchPos.z,
            1.5,
            joaat(trash),
            false,
            false,
            false
        )

        if ENTITY.DOES_ENTITY_EXIST(bin) then
            binPos = Game.GetEntityCoords(bin, false)
            if searchPos:distance(binPos) <= 1.3 then
                return true, bin
            end
        end
    end

    return false, 0
end

-- Checks if localPlayer is standing near a public seat
--
-- and returns its handle and position offsets (x, z).
---@param s script_util
Self.IsNearPublicSeat = function(s)
    local retBool  = false
    local prop     = 0
    local x_offset = 0.0
    local z_offset = 1.0
    local seatPos  = vec3:zero()
    local myCoords = Self.GetPos()

    for _, seat in ipairs(eWorldSeats) do
        prop = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(
            myCoords.x,
            myCoords.y,
            myCoords.z,
            1.5,
            joaat(seat),
            false,
            false,
            false
        )

        if ENTITY.DOES_ENTITY_EXIST(prop) then
            seatPos = Game.GetEntityCoords(prop, false)
            if ambient_scenarios and Game.DoesHumanScenarioExistInArea(seatPos, 1, true) then
                return false, 0, 0, 0
            end

            if myCoords:distance(seatPos) <= 2 then
                retBool = true
                if string.find(string.lower(seat), "bench") and seat ~= "prop_bench_07" then
                    x_offset = -0.5
                end

                if seat == "prop_hobo_seat_01" then
                    z_offset = 0.8
                end

                if string.find(string.lower(seat), "skid_chair") then
                    z_offset = 0.6
                end
                break
            end
        end

        s:sleep(1)
    end

    return retBool, prop, x_offset, z_offset
end

Self.CanUsePhoneAnims = function()
    return (
        not ENTITY.IS_ENTITY_DEAD(Self.GetPedID(), false) and not
        YimActions:IsPedPlaying(self.get_ped()) and not
        YimActions:IsPlayerBusy() and
        (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET(Self.GetPedID()) == 0)
    )
end

Self.CanCrouch = function()
    return Self.IsOnFoot()
        and not gui.is_open()
        and not YimActions:IsPlayerBusy()
        and not YimActions:IsPedPlaying(self.get_ped())
        and not b_IsTyping
end

Self.CanUseHandsUp = function()
    return(Self.IsOnFoot() or Self.Vehicle.IsCar)
        and not gui.is_open()
        and not YimActions:IsPlayerBusy()
        and not YimActions:IsPedPlaying(self.get_ped())
        and not b_IsTyping
end

Self.CanSit = function()
    return Self.IsAlive()
    and not PLAYER.IS_PLAYER_FREE_AIMING(self.get_id())
    and not TASK.PED_HAS_USE_SCENARIO_TASK(Self.GetPedID())
    and not YimActions:IsPedPlaying(self.get_ped())
    and not YimActions:IsPedPlaying(self.get_ped())
    and not b_IsTyping
end

Self.PlayKeyfobAnim = function()
    if (YimActions:IsPedPlaying(self.get_ped()) or YimActions:IsPlayerBusy() or Self.IsSwimming() or not Self.IsAlive()) then
        return
    end


    Await(Game.RequestAnimDict, "anim@mp_player_intmenu@key_fob@")
    TASK.TASK_PLAY_ANIM(
        Self.GetPedID(),
        "anim@mp_player_intmenu@key_fob@",
        "fob_click",
        4.0,
        -4.0,
        -1,
        48,
        0.0,
        false,
        false,
        false
    )
end


---@class Self.Vehicle
-- LocalPlayer's Vehicle
Self.Vehicle = {}
Self.Vehicle.Current = 0
Self.Vehicle.Previous = 0
Self.Vehicle.Speed = 0
Self.Vehicle.Gear = 0
Self.Vehicle.RPM = 0
Self.Vehicle.Throttle = 0
Self.Vehicle.MaxSpeed = 0
Self.Vehicle.EngineHealth = 0
Self.Vehicle.BodyHealth = 0
Self.Vehicle.Altitude = -1
Self.Vehicle.LandingGearState = -1
Self.Vehicle.DefaultHandling = nil
Self.Vehicle.DoorLockState = nil
Self.Vehicle.IsEngineOn = false
Self.Vehicle.IsCar = false
Self.Vehicle.IsBike = false
Self.Vehicle.IsQuad = false
Self.Vehicle.IsPlane = false
Self.Vehicle.IsHeli = false
Self.Vehicle.IsBoat = false
Self.Vehicle.IsFlatbed = false
Self.Vehicle.IsSportsCar = false
Self.Vehicle.IsDrifting = false
Self.Vehicle.IsValidLandVehicle = false
Self.Vehicle.ShouldFlashESC = false
Self.Vehicle.IsEngineBrakeDisabled = false
Self.Vehicle.IsTractionControlDisabled = false
Self.Vehicle.IsOffroaderEnabled = false
Self.Vehicle.IsLowSpeedWheelieEnabled = false
Self.Vehicle.HasRallyTires = false
Self.Vehicle.HasKersBoost = false
Self.Vehicle.HasLoudRadio = false
Self.Vehicle.HasUnbreakableWindows = false
Self.Vehicle.DeformMult = nil
Self.Vehicle.__index = Self.Vehicle
Self.Vehicle.__call = function()
    return Self.Vehicle.Current
end

---@param b_Previous? boolean
function Self.Vehicle:Exists(b_Previous)
    local i_Vehicle = b_Previous and self.Previous or self.Current
    return ENTITY.DOES_ENTITY_EXIST(i_Vehicle)
end

---@param b_Previous? boolean
function Self.Vehicle:GetModel(b_Previous)
    local i_Vehicle = b_Previous and self.Previous or self.Current
    return Game.GetEntityModel(i_Vehicle)
end

---@param b_Previous? boolean
function Self.Vehicle:GetPos(b_Previous)
    local i_Vehicle = b_Previous and self.Previous or self.Current
    return Game.GetEntityCoords(i_Vehicle, false)
end


function Self.Vehicle:ResetHandling()
    local _origin = self.DefaultHandling
    local CVehicle = Memory.GetVehicleInfo(self.Current)

    if CVehicle then
        CVehicle.m_acceleration:set_float(_origin.f_AccelerationMultiplier)
        CVehicle.m_initial_drag_coeff:set_float(_origin.f_InitialDragCoeff)
        CVehicle.m_initial_drive_force:set_float(_origin.f_InitialDriveForce)
        CVehicle.m_drive_max_flat_velocity:set_float(_origin.f_DriveMaxFlatVel)
        CVehicle.m_initial_drive_max_flat_vel:set_float(_origin.f_InitialDriveMaxFlatVel)
    end

    self.DefaultHandling = nil
end

function Self.Vehicle:HasChanged()
    return self.Current ~= self.Previous
end

---@param s script_util
function Self.Vehicle:OnTick(s)
    if PED.IS_PED_IN_ANY_VEHICLE(Self.GetPedID(), false) then
        self.Current = Self.GetVehicle()
        if not self:HasChanged() then
            self.Model = self:GetModel()
            self.IsCar = VEHICLE.IS_THIS_MODEL_A_CAR(self.Model)
            self.IsQuad = VEHICLE.IS_THIS_MODEL_A_QUADBIKE(self.Model)
            self.IsHeli = VEHICLE.IS_THIS_MODEL_A_HELI(self.Model)
            self.IsPlane = VEHICLE.IS_THIS_MODEL_A_PLANE(self.Model)
            self.IsFlatbed = ENTITY.GET_ENTITY_MODEL(self.Model) == 1353720154
            self.IsValidLandVehicle = (self.IsCar or self.IsQuad or self.IsBike)

            self.IsBoat = (
                VEHICLE.IS_THIS_MODEL_A_BOAT(self.Model) or
                VEHICLE.IS_THIS_MODEL_A_JETSKI(self.Model)
            )

            self.IsSportsCar = (
                self.IsCar and
                Game.Vehicle.IsSportsOrSuper(self.Current) or
                Game.Vehicle.IsSportsCar(self.Current)
            )

            Self.Vehicle.IsBike = (
                VEHICLE.IS_THIS_MODEL_A_BIKE(self.Model) and
                (VEHICLE.GET_VEHICLE_CLASS(self.Current) ~= 13) and
                (self.Model ~= 0x7B54A9D3)
            )
        else
            self:OnSwitch()
        end

        self.EngineHealth  = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(self.Model)
        self.BodyHealth    = VEHICLE.GET_VEHICLE_BODY_HEALTH(self.Model)
        self.IsEngineOn    = self.EngineHealth > 0 and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(self.Current) or false
        self.DoorLockState = (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(self.Current) <= 1) and 1 or 2

        if self.IsEngineOn then
            self.Speed = ENTITY.GET_ENTITY_SPEED(self.Current)
            self.Gear  = VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(self.Current)
            self.RPM   = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(self.Current)

            if not using_nos and not b_LaunchControlActive then
                self.MaxSpeed = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(self.Current)
            end
        end

        if (Self.IsDriving() and (self.IsCar or self.IsBike or self.IsQuad) and self.IsEngineOn) then
            self.IsEngineBrakeDisabled     = Memory.GetVehicleHandlingFlag(self.Current, HF._FREEWHEEL_NO_GAS)
            self.IsTractionControlDisabled = Memory.GetVehicleHandlingFlag(self.Current, HF._FORCE_NO_TC_OR_SC)
            self.HasKersBoost              = Memory.GetVehicleHandlingFlag(self.Current, HF._HAS_KERS)
            self.IsOffroaderEnabled        = Memory.GetVehicleHandlingFlag(self.Current, HF._OFFROAD_ABILITIES_X2)
            self.HasRallyTires             = Memory.GetVehicleHandlingFlag(self.Current, HF._HAS_RALLY_TYRES)
            self.IsLowSpeedWheelieEnabled  = Memory.GetVehicleHandlingFlag(self.Current, HF._LOW_SPEED_WHEELIES)

            if Self.IsDriving() and self.Speed > 1 then
                local speed_vector = ENTITY.GET_ENTITY_SPEED_VECTOR(self.Current, true)

                self.IsDrifting = (
                    VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(self.Current) and
                    (speed_vector.x ~= 0) and (speed_vector.x > 6 or speed_vector.x < -6)
                )
            else
                if self.IsDrifting then
                    self.IsDrifting = false
                end
            end
        end

        if (self.IsPlane or self.IsHeli) and Self.IsDriving() then
            self.LandingGearState = VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(self.Current) and VEHICLE.GET_LANDING_GEAR_STATE(self.Current) or -1
            self.Altitude = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(self.Current)
            self.Throttle = VEHICLE.GET_VEHICLE_THROTTLE_(self.Current)

            if self.Throttle <= 0 then
                self.Throttle = 0.05
            end
        end
    else
        self:OnExit()
    end
end

function Self.Vehicle:OnSwitch()
    if ((self.Previous > 0) and self:Exists(true) and ENTITY.IS_ENTITY_A_VEHICLE(self.Previous)) then
        if self.HasLoudRadio then
            AUDIO.SET_VEHICLE_RADIO_LOUD(self.Previous, false)
            self.HasLoudRadio = false
        end

        if not b_HasCustomTires then
            VEHICLE.TOGGLE_VEHICLE_MOD(self.Previous, 20, false)
        end

        if ((default_tire_smoke.r ~= driftSmoke_T.r) or
            (default_tire_smoke.g ~= driftSmoke_T.g) or
            (default_tire_smoke.b ~= driftSmoke_T.b)
        ) then
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(
                self.Previous,
                default_tire_smoke.r,
                default_tire_smoke.g,
                default_tire_smoke.b
            )
        end

        if (
            VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(self.Previous)) and
            (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(self.Previous) ~= 1)
        ) then
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(self.Previous, 1)
            VEHICLE.SET_VEHICLE_ALARM(self.Previous, false)
        end

        if self.HasUnbreakableWindows then
            VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(self.Previous, false)
            self.HasUnbreakableWindows = false
        end

        if b_EngineSoundChanged then
            AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(
                self.Previous,
                vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(self.Previous))
            )

            Game.Vehicle.SetAcceleration(self.Previous, 1.0)
            b_EngineSoundChanged = false
        end

        if self.DeformMult and (math.type(self.DeformMult) == "float") then
            Game.Vehicle.SetDeformation(self.Previous, self.DeformMult)
            self.DeformMult = nil
        end
    end

    self.Previous = self.Current
end

function Self.Vehicle:OnExit()
    if self.Speed ~= 0 then self.Speed = 0 end
    if self.Gear ~= 0 then self.Gear = 0 end
    if self.RPM ~= 0 then self.RPM = 0 end
    if self.MaxSpeed ~= 0 then self.MaxSpeed = 0 end
    if self.IsDrifting then self.IsDrifting = false end

    if self.DeformMult and (math.type(self.DeformMult) == "float") then
        Game.Vehicle.SetDeformation(self.Current, self.DeformMult)
        self.DeformMult = nil
    end

    if (self.Current ~= 0) and not self:Exists() then
        self.Current     = 0
        self.IsCar       = false
        self.IsBike      = false
        self.IsQuad      = false
        self.IsPlane     = false
        self.IsHeli      = false
        self.IsBoat      = false
        self.IsFlatbed   = false
        self.IsSportsCar = false
    end
end
