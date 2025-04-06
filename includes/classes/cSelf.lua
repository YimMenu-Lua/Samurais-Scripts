---@class Self
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

---@return number
Self.GetVehicle = function()
    return self.get_veh()
end

---@return vec3
Self.GetPos = function()
   return vec3:new(
        self.get_pos().x,
        self.get_pos().y,
        self.get_pos().z
    )
end

---@return vec3
Self.GetForwardVector = function()
    local fwdvec = ENTITY.GET_ENTITY_FORWARD_VECTOR(Self.GetPedID())
    return vec3:new(fwdvec.x, fwdvec.y, fwdvec.z)
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

---@return boolean
Self.IsRagdoll = function()
    return PED.IS_PED_RAGDOLL(Self.GetPedID())
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

Self.IsDriving = function()
    if self.get_veh() == 0 then
        return false
    end

    return (VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.get_veh(), -1, false) == Self.GetPedID())
end

-- Returns the hash of localPlayer's selected weapon.
---@return integer
Self.Weapon = function()
    local weaponHash = 0

    _, weaponHash = WEAPON.GET_CURRENT_PED_WEAPON(Self.GetPedID(), weaponHash, false)
    return weaponHash
end

-- Teleports localPlayer to the provided coordinates.
---@param keepVehicle boolean
---@param coords vec3
Self.Teleport = function(keepVehicle, coords)
    script.run_in_fiber(function(selftp)
        STREAMING.REQUEST_COLLISION_AT_COORD(coords.x, coords.y, coords.z)
        selftp:sleep(200)
        if keepVehicle then
            PED.SET_PED_COORDS_KEEP_VEHICLE(Self.GetPedID(), coords.x, coords.y, coords.z)
        else
            if not Self.IsOnFoot() then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
            end
            ENTITY.SET_ENTITY_COORDS(Self.GetPedID(), coords.x, coords.y, coords.z, false, false, true, false)
        end
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
        if Game.RequestAnimDict(call_anim_dict) then
            TASK.TASK_PLAY_PHONE_GESTURE_ANIMATION(
                Self.GetPedID(), call_anim_dict, call_anim,
                call_anim_boneMask, 0.25, 0.25, true, false
            )
            repeat
                s:sleep(10)
            until not AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() or not Self.CanUsePhoneAnims()
            TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(Self.GetPedID(), 0.25)
        end
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

Self.CantTouchThis = function(toggle)
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

-- Returns whether the player is currently using any mobile or computer app.
Self.IsBrowsingApps = function()
    for _, v in ipairs(t_AppScriptNames) do
        if script.is_active(v) then
            return true
        end
    end
    return false
end

-- Returns whether the player is inside a modshop.
Self.IsInCarModShop = function()
    if not Self.IsOutside() then
        for _, v in ipairs(t_ModshopScriptNames) do
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
    local pedCoords = Game.GetCoords(ped, true)
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
    if (
        Self.IsOnFoot() and not
        is_playing_anim and not
        is_playing_scenario and not
        is_playing_amb_scenario
    ) then
        local selfPos = self.get_pos()
        local selfFwd = Game.GetForwardVector(Self.GetPedID())
        local fwdPos  = vec3:new(selfPos.x + (selfFwd.x * 1.3), selfPos.y + (selfFwd.y * 1.3), selfPos.z)
        local veh     = Game.GetClosestVehicle(fwdPos, 20)

        if veh ~= nil and veh > 0 then
            if VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(veh)) then
                local bootBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "boot")
                if bootBone ~= -1 then
                    local vehCoords     = ENTITY.GET_ENTITY_COORDS(veh, false)
                    local vehFwdVec     = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)

                    -- create a search area based on the vehicle's length and engine placement
                    local engineBone    = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "engine")
                    local lfwheelBone   = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "wheel_lf")
                    local engBoneCoords = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(veh, engineBone)
                    local lfwBoneCoords = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(veh, lfwheelBone)
                    local bonedistance  = vec3:distance(lfwBoneCoords, engBoneCoords)
                    local isRearEngined = bonedistance > 2 -- Can also read vehicle model flag FRONT_BOOT
                    local vmin, vmax    = Game.GetModelDimensions(ENTITY.GET_ENTITY_MODEL(veh))
                    local veh_length    = vmax.y - vmin.y
                    local tempPos       = isRearEngined and vec2:new(
                            vehCoords.x + (vehFwdVec.x * (veh_length / 1.6)),
                            vehCoords.y + (vehFwdVec.y * (veh_length / 1.6))
                        ) or
                        vec2:new(
                            vehCoords.x - (vehFwdVec.x * (veh_length / 1.6)),
                            vehCoords.y - (vehFwdVec.y * (veh_length / 1.6))
                        )

                    local search_area   = vec3:new(tempPos.x, tempPos.y, vehCoords.z)

                    if vec3:distance(Self.GetPos(), search_area) <= 1 then
                        return true, veh, isRearEngined
                    end
                end
            end
        end
    end

    return false, 0, false
end

-- Checks if localPlayer is standing near a public seat
--
-- and returns its position and rotation vectors.
Self.IsNearPublicSeat = function()
    local retBool  = false
    local prop     = 0
    local x_offset = 0.0
    local z_offset = 1.0
    local seatPos  = vec3:new(0, 0, 0)
    local myCoords = Self.GetPos()

    for _, seat in ipairs(t_WorldSeats) do
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
            seatPos = Game.GetCoords(prop, false)
            if ambient_scenarios and Game.DoesHumanScenarioExistInArea(seatPos, 1, true) then
                return false, 0, 0, 0
            end

            if vec3:distance(myCoords, seatPos) <= 2 then
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
    end

    return retBool, prop, x_offset, z_offset
end

-- Checks if localPlayer is near a trash bin
--
-- and returns the entity handle of the bin if true.
Self.IsNearTrashBin = function()
    local binPos = vec3:new(0, 0, 0)
    local myCoords = Self.GetPos()
    local myFwdVec = Self.GetForwardVector()
    local searchPos = vec3:new(
        myCoords.x + myFwdVec.x * 1.2,
        myCoords.y + myFwdVec.y * 1.2,
        myCoords.z + myFwdVec.z * 1.2
    )

    for _, trash in ipairs(t_TrashBins) do
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
            binPos = Game.GetCoords(bin, false)
            if vec3:distance(searchPos, binPos) <= 1.3 then
                return true, bin
            end
        end
    end

    return false, 0
end

Self.CanUsePhoneAnims = function()
    return (
        not ENTITY.IS_ENTITY_DEAD(Self.GetPedID(), false) and not
        is_playing_anim and not
        is_playing_scenario and not
        ped_grabbed and not
        vehicle_grabbed and not
        is_handsUp and not
        is_sitting and not
        is_hiding and not
        is_playing_amb_scenario
        and (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET(Self.GetPedID()) == 0)
    )
end

Self.CanCrouch = function()
    return (
        Self.IsOnFoot() and not
        Self.IsInWater() and not
        Self.IsRagdoll() and not
        gui.is_open() and not
        ped_grabbed and not
        vehicle_grabbed and not
        is_playing_anim and not
        is_playing_scenario and not
        is_playing_amb_scenario and not
        is_typing and not
        is_sitting and not
        is_setting_hotkeys and not
        is_hiding and not
        isCrouched and not
        HUD.IS_MP_TEXT_CHAT_TYPING() and not
        Self.IsBrowsingApps()
    )
end

Self.CanUseHandsUp = function()
    return (
        (Self.IsOnFoot() or Self.Vehicle.IsCar) and not
        gui.is_open() and not
        HUD.IS_MP_TEXT_CHAT_TYPING() and not
        ped_grabbed and not
        vehicle_grabbed and not
        is_playing_anim and not
        is_playing_scenario and not
        is_playing_amb_scenario and not
        is_typing and not
        is_setting_hotkeys and not
        is_hiding and not
        Self.IsBrowsingApps()
    )
end

Self.PlayKeyfobAnim = function()
    if (
        is_playing_anim or
        is_playing_scenario or
        is_playing_amb_scenario or
        isCrouched or
        is_handsUp or
        ped_grabbed or
        vehicle_grabbed or
        is_hiding or
        Self.IsRagdoll() or
        Self.IsSwimming() or not
        Self.IsAlive()
    ) then
        return
    end

    local dict <const> = "anim@mp_player_intmenu@key_fob@"
    if Game.RequestAnimDict(dict) then
        TASK.TASK_PLAY_ANIM(
            Self.GetPedID(),
            dict,
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
end

---@class Self.Vehicle
Self.Vehicle = {}
Self.Vehicle.__index = Self.Vehicle
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
Self.Vehicle.ShouldFlashESC = false
Self.Vehicle.IsEngineBrakeDisabled = false
Self.Vehicle.IsTractionControlDisabled = false
Self.Vehicle.IsOffroaderEnabled = false
Self.Vehicle.IsLowSpeedWheelieEnabled = false
Self.Vehicle.HasRallyTires = false
Self.Vehicle.HasKersBoost = false
Self.Vehicle.HasLoudRadio = false
Self.Vehicle.HasUnbreakableWindows = false

---@param vehicle integer
Self.Vehicle.ResetHandling = function(vehicle)
    if vehicle == 0 or not Self.Vehicle.DefaultHandling then
        return
    end

    local _origin = Self.Vehicle.DefaultHandling
    local CVehicle = Memory.GetVehicleInfo(vehicle)
    if CVehicle then
        CVehicle.m_acceleration:set_float(_origin.f_AccelerationMultiplier)
        CVehicle.m_initial_drag_coeff:set_float(_origin.f_InitialDragCoeff)
        CVehicle.m_initial_drive_force:set_float(_origin.f_InitialDriveForce)
        CVehicle.m_drive_max_flat_velocity:set_float(_origin.f_DriveMaxFlatVel)
        CVehicle.m_initial_drive_max_flat_vel:set_float(_origin.f_InitialDriveMaxFlatVel)
    end
    Self.Vehicle.DefaultHandling = nil
end
