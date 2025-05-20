---@class HNS
HNS = {}
HNS.__index = HNS

HNS.isHiding = false
HNS.hidingInTrash = false
HNS.hidingInVehicle = false
HNS.hidingInBoot = false
HNS.isWanted = false
HNS.wasSpotted = false
HNS.lastCheckTime = 0
HNS.trashBin = 0
HNS.bootVehicle = {
    handle = 0,
    isRearEngined = false,
    length = 0,
    height = 0
}
HNS.vehAnim = {
    dict = "missmic3leadinout_mcs1",
    anim = "cockpit_pilot"
}
HNS.trashAnim = {
    dict = "anim@amb@inspect@crouch@male_a@base",
    anim = "base"
}
HNS.bootAnim = {
    dict = "timetable@tracy@sleep@",
    anim = "base"
}


function HNS:Reset()
    TASK.CLEAR_PED_TASKS(Self.GetPedID())
    PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self.GetPlayerID())

    if ENTITY.IS_ENTITY_ATTACHED(Self.GetPedID()) then
        ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
    end

    HNS.isHiding = false
    HNS.hidingInTrash = false
    HNS.hidingInVehicle = false
    HNS.hidingInBoot = false
    HNS.isWanted = false
    HNS.wasSpotted = false
    HNS.lastCheckTime = 0
    HNS.trashBin = 0
    HNS.bootVehicle = {
        handle = 0,
        isRearEngined = false,
        length = 0,
        height = 0
    }
end

function HNS:HideInVehicle()
    if not PED.IS_PED_SITTING_IN_ANY_VEHICLE(Self.GetPedID()) or not self.isWanted then
        return
    end

    local cond

    if Self.IsDriving() then
        cond = VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current)
    else
        cond = true
    end

    if cond
    and not PAD.IS_CONTROL_PRESSED(0, 71)
    and not PAD.IS_CONTROL_PRESSED(0, 72)
    and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(Self.Vehicle.Current) then
        Game.ShowButtonPrompt("Press ~INPUT_FRONTEND_ACCEPT~ to hide inside the vehicle.")

        if PAD.IS_CONTROL_JUST_PRESSED(0, 201) and not HUD.IS_MP_TEXT_CHAT_TYPING() then
            YimActions:ResetPlayer()
            Await(Game.RequestAnimDict, self.vehAnim.dict)

            VEHICLE.SET_VEHICLE_IS_WANTED(Self.Vehicle.Current, false)
            TASK.TASK_PLAY_ANIM(
                Self.GetPedID(),
                self.vehAnim.dict,
                self.vehAnim.anim,
                6.0,
                3.0,
                -1,
                18,
                1.0,
                false,
                false,
                false
            )

            if Self.IsDriving() then
                VEHICLE.SET_VEHICLE_ENGINE_ON(Self.GetVehicle(), false, false, true)
            end

            self.isHiding = true
            self.hidingInVehicle = true
            self.hidingInTrash = false
            self.hidingInBoot = false
            Sleep(1000)
        end
    end
end

function HNS:HideInTrash()
    if (self.trashBin == 0) or not ENTITY.DOES_ENTITY_EXIST(self.trashBin) then
        return
    end

    Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to hide in the dumpster.")

    if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
        if self.wasSpotted then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "The cops have spotted you! You can't hide until they lose sight of you.",
                false,
                1.5
            )
            return
        end

        YimActions:ResetPlayer()
        TASK.TASK_TURN_PED_TO_FACE_ENTITY(Self.GetPedID(), self.trashBin, 10)
        CAM.DO_SCREEN_FADE_OUT(500)
        Sleep(1000)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(
            Self.GetPedID(),
            self.trashBin,
            -1,
            0.0,
            0.12,
            1.13,
            0.0,
            0.0,
            90.0,
            false,
            false,
            false,
            false,
            20,
            true,
            1
        )

        Await(Game.RequestAnimDict, self.trashAnim.dict)
        TASK.TASK_PLAY_ANIM(
            Self.GetPedID(),
            self.trashAnim.dict,
            self.trashAnim.anim,
            4.0,
            -4.0,
            -1,
            1,
            1.0,
            false,
            false,
            false
        )

        Sleep(200)
        CAM.DO_SCREEN_FADE_IN(500)
        Sleep(200)
        AUDIO.PLAY_SOUND_FRONTEND(
            -1,
            "TRASH_BAG_LAND",
            "DLC_HEIST_SERIES_A_SOUNDS",
            true
        )
        Sleep(1000)

        self.isHiding = true
        self.hidingInTrash = true
        self.hidingInBoot = false
        self.hidingInVehicle = false
    end
end

function HNS:HideInTrunk()
    if (self.bootVehicle.handle == 0) or not ENTITY.DOES_ENTITY_EXIST(self.bootVehicle.handle) then
        return
    end

    Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to hide in the trunk.")

    if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
        local z_offset = 0.93
        local veh = self.bootVehicle.handle

        if self.wasSpotted then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "The cops have spotted you. You can't hide until they lose sight of you.",
                false,
                1.5
            )
            return
        end

        if Game.Vehicle.Class(veh) == "Vans" then
            z_offset = 1.1
        else
            if Game.Vehicle.Class(veh) == "SUVs" then
                z_offset = 1.2
            end
        end

        Await(Game.RequestAnimDict, "rcmnigel3_trunk")
        YimActions:ResetPlayer()

        if not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY_IN_FRONT(Self.GetPedID(), veh) then
            TASK.TASK_TURN_PED_TO_FACE_ENTITY(Self.GetPedID(), veh, 0)
            repeat
                yield()
            until not TASK.GET_IS_TASK_ACTIVE(Self.GetPedID(), 225) -- CTaskTurnToFaceEntityOrCoord
        end

        TASK.TASK_PLAY_ANIM(
            Self.GetPedID(),
            "rcmnigel3_trunk",
            "out_trunk_trevor",
            4.0,
            -4.0,
            1500,
            2,
            0.0,
            false,
            false,
            false
        )
        Sleep(800)

        if not VEHICLE.IS_VEHICLE_STOPPED(veh) then
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "Vehicle must be stopped.",
                false,
                1.5
            )
            return
        end

        ENTITY.FREEZE_ENTITY_POSITION(Self.GetPedID(), true)
        ENTITY.SET_ENTITY_COLLISION(Self.GetPedID(), false, true)
        Sleep(50)
        VEHICLE.SET_VEHICLE_DOOR_OPEN(veh, 5, false, false)
        Sleep(500)
        ENTITY.FREEZE_ENTITY_POSITION(Self.GetPedID(), false)

        local chassis_bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "chassis_dummy")

        if (chassis_bone == nil) or (chassis_bone == -1) then
            chassis_bone = 0
        end

        local veh_hash = ENTITY.GET_ENTITY_MODEL(veh)
        local vmin, vmax = Game.GetModelDimensions(veh_hash)

        self.bootVehicle.length = vmax.y - vmin.y
        self.bootVehicle.height = vmax.z - vmin.z
        local attachPosY = self.bootVehicle.isRearEngined
        and (self.bootVehicle.length / 3)
        or (-self.bootVehicle.length / 3)
        -- local attachPosZ = self.bootVehicle.height * 0.42

        Await(Game.RequestAnimDict, self.bootAnim.dict)

        TASK.TASK_PLAY_ANIM(
            Self.GetPedID(),
            self.bootAnim.dict,
            self.bootAnim.anim,
            4.0,
            -4.0,
            -1,
            2,
            1.0,
            false,
            false,
            false
        )

        ENTITY.ATTACH_ENTITY_TO_ENTITY(
            Self.GetPedID(),
            veh,
            chassis_bone,
            -0.3,
            attachPosY,
            z_offset,
            180.0,
            0.0,
            0.0,
            false,
            false,
            false,
            false,
            20,
            true,
            1
        )

        Sleep(500)
        VEHICLE.SET_VEHICLE_DOOR_SHUT(veh, 5, false)
        ENTITY.SET_ENTITY_COLLISION(Self.GetPedID(), true, true)

        self.isHiding = true
        self.hidingInBoot = true
        self.hidingInTrash = false
        self.hidingInVehicle = false
        Sleep(1000)
    end
end

function HNS:WhileOnFoot()
    if self.isHiding or not Self.IsOutside() or not Self.IsOnFoot() then
        return
    end

    local currentTime = MISC.GET_GAME_TIMER()
    if currentTime - self.lastCheckTime < 1000 then
        return
    end
    self.lastCheckTime = currentTime

    script.run_in_fiber(function(s)
        s:sleep(1)

        if (self.bootVehicle.handle == 0) then
            _, self.bootVehicle.handle, self.bootVehicle.isRearEngined = Self.IsNearCarTrunk()
        end

        s:sleep(1)

        if (self.trashBin == 0) then
            _, self.trashBin = Self.IsNearTrashBin()
        end
    end)

    if (self.bootVehicle.handle ~= 0) then
        if Self.GetPos():distance(Game.GetEntityCoords(self.bootVehicle.handle, false)) >= 3.5 then
            self.bootVehicle = {
                handle = 0,
                isRearEngined = false
            }
            return
        end
    end

    if (self.trashBin ~= 0) then
        if Self.GetPos():distance(Game.GetEntityCoords(self.trashBin, false)) > 2 then
            self.trashBin = 0
            return
        end
    end
end

function HNS:GetHidingContext()
    if Self.IsOnFoot() then
        self:WhileOnFoot()

        if self.trashBin ~= 0 then
            self:HideInTrash()
        elseif self.bootVehicle.handle ~= 0 then
            self:HideInTrunk()
        end
    elseif self.isWanted and not self.wasSpotted then
        self:HideInVehicle()
    end
end

function HNS:WhileIsHiding()
    local v_WantedCentrePos

    if self.isHiding then
        if not Self.IsAlive() then
            self:Reset()
        end

        if self.hidingInVehicle and not ENTITY.DOES_ENTITY_EXIST(Self.GetVehicle()) then
            self.isHiding, self.hidingInVehicle = false, false
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self.GetPlayerID())
        end

        if self.hidingInBoot and not ENTITY.DOES_ENTITY_EXIST(self.bootVehicle.handle) then
            self.isHiding, self.hidingInBoot, self.bootVehicle.handle = false, false, 0
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self.GetPlayerID())
        end

        if self.isHidingInDumpster and not ENTITY.DOES_ENTITY_EXIST(self.trashBin) then
            self.isHiding, self.isHidingInDumpster, self.trashBin = false, false, 0
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self.GetPlayerID())
        end

        if not v_WantedCentrePos then
            v_WantedCentrePos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                Self.GetPedID(),
                math.random(-35, 35),
                math.random(-35, 35),
                math.random(0, 5)
            )
        end

        if self.isWanted and not self.wasSpotted then
            PED.SET_COP_PERCEPTION_OVERRIDES(40.0, 40.0, 40.0, 100.0, 100.0, 100.0, 0.0)
            ---@diagnostic disable-next-line
            PLAYER.SET_PLAYER_WANTED_CENTRE_POSITION(Self.GetPlayerID(), v_WantedCentrePos, true)
        end

        if self.hidingInVehicle then
            if self.wasSpotted then
                YimToast:ShowWarning(
                    "Samurai's Scripts",
                    "You have been spotted by the cops! You can't hide until they lose sight of you.",
                    false,
                    1.5
                )

                self:Reset()
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                return
            end

            Game.ShowButtonPrompt(
                "Press ~INPUT_FRONTEND_ACCEPT~ or ~INPUT_VEH_ACCELERATE~ or ~INPUT_VEH_BRAKE~ to stop hiding."
            )

            if (PAD.IS_CONTROL_JUST_PRESSED(0, 201)
            or PAD.IS_CONTROL_PRESSED(0, 71)
            or PAD.IS_CONTROL_PRESSED(0, 72))
            and not HUD.IS_MP_TEXT_CHAT_TYPING() then
                TASK.CLEAR_PED_TASKS(Self.GetPedID())

                if Self.IsDriving() then
                    VEHICLE.SET_VEHICLE_ENGINE_ON(Self.GetVehicle(), true, false, false)
                end

                self:Reset()
                Sleep(1000)
            end
        end

        if self.hidingInBoot then
            Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to get out.")

            if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
                local my_pos = Self.GetPos()
                local groundZ = 0
                local outPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                    Self.GetPedID(),
                    0,
                    self.bootVehicle.isRearEngined and 2 or -2,
                    0
                )

                _, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
                    my_pos.x,
                    my_pos.y,
                    my_pos.z,
                    groundZ,
                    false,
                    false
                )

                local outHeading = self.bootVehicle.isRearEngined
                and Game.GetHeading(self.bootVehicle.handle)
                or (Game.GetHeading(self.bootVehicle.handle) - 180)

                VEHICLE.SET_VEHICLE_DOOR_OPEN(self.bootVehicle.handle, 5, false, false)
                Sleep(500)
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
                ENTITY.SET_ENTITY_COORDS(
                    Self.GetPedID(),
                    outPos.x,
                    outPos.y,
                    groundZ,
                    false,
                    false,
                    false,
                    false
                )

                ENTITY.SET_ENTITY_HEADING(Self.GetPedID(), outHeading)
                VEHICLE.SET_VEHICLE_DOOR_SHUT(self.bootVehicle.handle, 5, false)
                Sleep(200)

                if ENTITY.GET_ENTITY_SPEED(self.bootVehicle.handle) > 4.0 then
                    PED.SET_PED_TO_RAGDOLL(Self.GetPedID(), 1500, 0, 0, false, false, false)
                end

                self:Reset()
                Sleep(1000)
            end
        end

        if self.hidingInTrash then
            Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to get out.")
            if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
                CAM.DO_SCREEN_FADE_OUT(500)
                Sleep(1000)
                local my_pos = Self.GetPos()
                local groundZ = 0

                _, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
                    my_pos.x,
                    my_pos.y,
                    my_pos.z,
                    groundZ,
                    false,
                    false
                )

                ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
                ENTITY.SET_ENTITY_HEADING(Self.GetPedID(), (ENTITY.GET_ENTITY_HEADING(Self.GetPedID()) + 90))
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                local my_fwd = Game.GetForwardVector(Self.GetPedID())
                ENTITY.SET_ENTITY_COORDS(
                    Self.GetPedID(),
                    my_pos.x + (my_fwd.x * 1.3),
                    my_pos.y + (my_fwd.y * 1.3),
                    groundZ,
                    false,
                    false,
                    false,
                    false
                )
                CAM.DO_SCREEN_FADE_IN(500)
                AUDIO.PLAY_SOUND_FRONTEND(-1, "TRASH_BAG_LAND", "DLC_HEIST_SERIES_A_SOUNDS", true)

                Await(Game.RequestAnimDict, "move_m@_idles@shake_off")
                TASK.TASK_PLAY_ANIM(
                    Self.GetPedID(),
                    "move_m@_idles@shake_off",
                    "shakeoff_1",
                    4.0,
                    -4.0,
                    3000,
                    48,
                    0.0,
                    false,
                    false,
                    false
                )

                Sleep(1000)
                self:Reset()
            end
        end
    elseif v_WantedCentrePos then
        v_WantedCentrePos = nil
    end
end

function HNS:Main()
    self.isWanted = PLAYER.GET_PLAYER_WANTED_LEVEL(Self.GetPlayerID()) > 0
    self.wasSpotted = PLAYER.IS_WANTED_AND_HAS_BEEN_SEEN_BY_COPS(Self.GetPlayerID())

    if not self.isHiding then
        self:GetHidingContext()
    else
        self:WhileIsHiding()
    end
end
