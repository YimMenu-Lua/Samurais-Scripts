---@class PublicSeating
---@field isSitting boolean
---@field seatHandle integer
---@field lastScanTime number
PublicSeating = {}
PublicSeating.__index = PublicSeating
PublicSeating.enabled = public_seats
PublicSeating.isSitting = false
PublicSeating.seatHandle = 0
PublicSeating.animDict = "timetable@ron@ig_3_couch"
PublicSeating.animName = "base"


---@param s script_util
function PublicSeating:Update(s)
    if self.isSitting then
        self:UpdateWhileSitting()
    else
        if Self.IsMoving() or not Self.IsOutside() or not Self.IsOnFoot() or not Self.IsAlive() then
            return
        end

        local found, handle, offset = self:ScanForNearbySeat()

        if not found then
            s:sleep(250)
            return
        end

        Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to sit down")

        if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
            self:Sit(handle, offset)
        end
    end
end

function PublicSeating:ScanForNearbySeat()
    local myCoords = Self.GetPos()

    for _, modelName in ipairs(self.SeatModels) do
        local modelHash = joaat(modelName)
        local obj = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(
            myCoords.x,
            myCoords.y,
            myCoords.z,
            1.5,
            modelHash,
            false,
            false,
            false
        )

        if ENTITY.DOES_ENTITY_EXIST(obj) then
            local pos = Game.GetEntityCoords(obj, false)

            if myCoords:distance(pos) <= 2 then
                if ambient_scenarios and Game.DoesHumanScenarioExistInArea(pos, 1, true) then
                    return false
                end

                local offset = vec3:new(0.0, -0.6, 1.0)

                if string.find(modelName, "bench") and modelName ~= "prop_bench_07" then
                    offset.x = -0.5
                elseif modelName == "prop_hobo_seat_01" then
                    offset.z = 0.8
                elseif string.find(modelName, "skid_chair") then
                    offset.z = 0.6
                end

                return true, obj, offset
            end
        end
        yield()
    end

    return false
end

function PublicSeating:Sit(seat, offset)
    Await(Game.RequestAnimDict, self.animDict)

    ENTITY.FREEZE_ENTITY_POSITION(seat, true)
    TASK.TASK_TURN_PED_TO_FACE_ENTITY(Self.GetPedID(), seat, 100)
    Sleep(150)

    TASK.TASK_PLAY_ANIM(
        Self.GetPedID(),
        self.animDict,
        self.animName,
        1.69,
        4.0,
        -1,
        33,
        1.0,
        false,
        false,
        false
    )

    local boneIndex = PED.GET_PED_BONE_INDEX(Self.GetPedID(), 0)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(
        Self.GetPedID(),
        seat,
        boneIndex,
        offset.x,
        offset.y,
        offset.z,
        0.0,
        0.0,
        180.0,
        false,
        false,
        false,
        false,
        20,
        true,
        1
    )

    self.isSitting = true
    self.seatHandle = seat
end

function PublicSeating:UpdateWhileSitting()
    if not ENTITY.IS_ENTITY_PLAYING_ANIM(Self.GetPedID(), self.animDict, self.animName, 3)
    or Self.IsRagdolling()
    or Self.IsInCombat()
    or PLAYER.IS_PLAYER_FREE_AIMING(Self.GetPlayerID())
    or not Self.IsAlive() then
        self:Cleanup()
        return
    end

    Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to get up")

    if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
        self:StandUp()
    end
end

function PublicSeating:StandUp()
    ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
    TASK.STOP_ANIM_TASK(Self.GetPedID(), self.animDict, self.animName, -2.69)

    if ENTITY.DOES_ENTITY_EXIST(self.seatHandle) then
        ENTITY.FREEZE_ENTITY_POSITION(self.seatHandle, false)
    end

    self.isSitting = false
    self.seatHandle = 0
end

function PublicSeating:Cleanup()
    if not self.isSitting then
        return
    end

    if ENTITY.IS_ENTITY_ATTACHED(Self.GetPedID()) then
        ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
    end

    TASK.CLEAR_PED_TASKS(Self.GetPedID())

    if ENTITY.DOES_ENTITY_EXIST(self.seatHandle) then
        ENTITY.FREEZE_ENTITY_POSITION(self.seatHandle, false)
    end

    self.isSitting = false
    self.seatHandle = 0
end


PublicSeating.SeatModels = {
    "prop_bench_01a",
    "prop_table_01_chr_b",
    "prop_bench_05",
    "prop_rub_couch02",
    "prop_hobo_seat_01",
    "prop_skid_chair_02",
    "prop_bench_02",
    "prop_bench_09",
    "prop_waiting_seat_01",
    "prop_table_06_chr",
    "prop_bench_10",
    "prop_chair_04b",
    "prop_rub_couch03",
    "prop_table_03_chr",
    "prop_bench_03",
    "prop_table_01_chr_a",
    "prop_table_02_chr",
    "prop_chair_01b",
    "prop_bench_11",
    "prop_rub_couch01",
    "prop_chair_01a",
    "prop_chair_06",
    "prop_table_03b_chr",
    "prop_old_deck_chair",
    "prop_rub_couch04",
    "prop_skid_chair_01",
    "prop_table_05_chr",
    "prop_chair_03",
    "prop_bench_08",
    "v_club_officechair",
    "v_corp_cd_chair",
    "prop_off_chair_03",
    "prop_skid_chair_03",
    "prop_chair_02",
    "prop_chair_05",
    "prop_chateau_chair_01",
    "prop_bench_06",
    "prop_bench_07",
    "prop_wait_bench_01",
    "prop_off_chair_04",
    "v_serv_ct_chair02",
    "prop_table_04_chr",
    "v_corp_offchair",
    "prop_off_chair_05",
    "prop_roller_car_01",
    "prop_roller_car_02",
    "prop_yacht_seat_01",
    "prop_yacht_seat_02",
    "prop_yacht_seat_03",
    "prop_chair_08",
    "prop_chair_10",
    "prop_ld_bench01",
    "prop_chair_04a",
    "prop_off_chair_01",
    "prop_bench_04",
    "prop_chair_09",
    "prop_rock_chair_01",
    "hei_prop_yah_seat_02",
    "hei_prop_yah_seat_03",
    "hei_prop_yah_seat_01",
    "h4_prop_h4_chair_01a",
    "h4_prop_h4_couch_01a",
    "h4_prop_h4_weed_chair_01a",
    "prop_fib_3b_bench",
    "v_ilev_ph_bench",
    "v_ilev_leath_chr",
    "v_corp_bk_chair3",
    "prop_gc_chair02",
    "v_ilev_fh_dineeamesa",
    "v_ilev_hd_chair",
    "v_ilev_m_sofa",
    "v_ilev_chair02_ped",
    "v_ilev_p_easychair",
    "v_ilev_fh_kitchenstool",
    "prop_off_chair_04_s",
    "prop_ld_farm_couch01",
    "prop_ld_farm_couch02",
    "prop_ld_farm_chair01",
    "v_ret_gc_chair03",
    "prop_old_wood_chair",
    "prop_off_chair_04b",
    "ch_prop_casino_chair_01a",
    "ch_chint01_gamingr1_sofa",
    "ch_prop_casino_track_chair_01",
    "ch_chint03_sofas",
    "ch_chint07_foyer_sofa_01",
    "ch_chint07_foyer_sofa_03",
    "ch_chint07_foyer_sofa_004",
    "h4_mp_h_yacht_armchair_01",
    "h4_mp_h_yacht_armchair_03",
    "h4_mp_h_yacht_armchair_04",
    "h4_mp_h_yacht_sofa_02",
    "h4_mp_h_yacht_sofa_01",
    "h4_mp_h_yacht_strip_chair_01",
    "h4_int_05_wooden_chairs_2",
    "h4_int_05_wood_chair_2",
    "h4_int_05_wooden_chairs_3",
    "h4_int_05_wood_chair_003",
    "h4_int_05_wood_chair_1",
    "h4_int_04_armchair_fireplace",
    "h4_int_04_arm_chair",
    "h4_int_04_chair_chesterfield_01a",
    "h4_int_04_desk_chair"
}
