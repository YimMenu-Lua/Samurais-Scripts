---@diagnostic disable

--#region Global functions

-- #### Wrapper for `Translator:Translate`
--________________________________________
-- Translates text to the user's language.
--
-- If the label to translate is missing or the language
--
-- is invalid, it defaults to English (US).
---@param label string
function _T(label)
    return Translator:Translate(label)
end

---@param t table
---@return table
function ConstEnum(t)
    return setmetatable({}, {
        __index = t,
        __newindex = function(_, key)
            log.warning(
                string.format(
                    "Attempt to modify read-only enum: '%s'", key
                )
            )
            return key
        end,
        __metatable = false
    })
end

-- Must be called in a coroutine. Input time is in seconds.
---@param s integer
function Sleep(s)
    local ntime = os.clock() + s
    while os.clock() < ntime do
        coroutine.yield()
    end
end

---@param ... number
---@return number
function Sum(...)
    local args, result = { ... }, 0
    for i = 1, #args do
        if type(args[i]) ~= 'number' then
            error(string.format(
                "Invalid argument '%s' at position (%d) in function sum(). The function only takes numbers as parameters.",
                args[i], i
            ))
        end
        result = result + args[i]
    end
    return result
end

---@param toggle boolean
---@param station? string
---@param entity? integer
function PlayMusic(toggle, station, entity)
    script.run_in_fiber(function(mp)
        if toggle then
            if not entity then
                entity = Self.GetPedID()
            end
            if not station then
                station = t_RadioStations[math.random(1, #t_RadioStations)].station
            end
            local coords      = ENTITY.GET_ENTITY_COORDS(entity, true)
            local bone_idx    = PED.GET_PED_BONE_INDEX(entity, 24818)
            local pbus_model  = 345756458
            local dummy_model = 0xE75B4B1C
            if Game.RequestModel(pbus_model) then
                pBus = VEHICLE.CREATE_VEHICLE(pbus_model, coords.x, coords.y, (coords.z - 30), 0, true, false, false)
                ENTITY.FREEZE_ENTITY_POSITION(pBus, true)
                ENTITY.SET_ENTITY_COLLISION(pBus, false, false)
                ENTITY.SET_ENTITY_INVINCIBLE(pBus, true)
                ENTITY.SET_ENTITY_ALPHA(pBus, 0.0, false)
                VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(pBus, false, false)
            end
            mp:sleep(500)
            if ENTITY.DOES_ENTITY_EXIST(pBus) then
                entities.take_control_of(pBus, 300)
                if Game.RequestModel(dummy_model) then
                    dummyDriver = PED.CREATE_PED(4, dummy_model, coords.x, coords.y, (coords.z + 40), 0, true, false)
                    if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
                        entities.take_control_of(dummyDriver, 300)
                        ENTITY.SET_ENTITY_ALPHA(dummyDriver, 0.0, false)
                        PED.SET_PED_INTO_VEHICLE(dummyDriver, pBus, -1)
                        PED.SET_PED_CONFIG_FLAG(dummyDriver, 402, true)
                        PED.SET_PED_CONFIG_FLAG(dummyDriver, 398, true)
                        PED.SET_PED_CONFIG_FLAG(dummyDriver, 167, true)
                        PED.SET_PED_CONFIG_FLAG(dummyDriver, 251, true)
                        PED.SET_PED_CONFIG_FLAG(dummyDriver, 255, true)
                        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(dummyDriver, true)
                        AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(pBus, vehicles.get_vehicle_display_name(2765724541))
                        VEHICLE.SET_VEHICLE_ENGINE_ON(pBus, true, false, false)
                        AUDIO.SET_VEHICLE_RADIO_LOUD(pBus, true)
                        VEHICLE.SET_VEHICLE_LIGHTS(pBus, 1)
                        mp:sleep(500)
                        if station ~= nil then
                            AUDIO.SET_VEH_RADIO_STATION(pBus, station)
                        end
                        mp:sleep(500)
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            pBus, entity, bone_idx, -4.0, -1.3, -1.0, 0.0, 90.0, -90.0,
                            false, true, false, true, 1, true, 1
                        )
                        ENTITY.SET_ENTITY_VISIBLE(pBus, false, false)
                    else
                        YimToast:ShowError("Samurais Scripts", "Failed to start music!")
                        return
                    end
                end
            else
                YimToast:ShowError("Samurais Scripts", "Failed to start music!")
                return
            end
        else
            if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(dummyDriver, true, true)
                mp:sleep(200)
                ENTITY.DELETE_ENTITY(dummyDriver)
                dummyDriver = 0
            end
            if ENTITY.DOES_ENTITY_EXIST(pBus) then
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(pBus, true, true)
                mp:sleep(200)
                ENTITY.DELETE_ENTITY(pBus)
                pBus = 0
            end
        end
        anim_music = toggle
    end)
end

function DummyCop()
    script.run_in_fiber(function(dcop)
        if Self.Vehicle.Current ~= nil and Self.Vehicle.Current ~= 0 then
            local polhash, veh_bone1, veh_bone2, attach_mode
            if Self.Vehicle.IsCar then
                if VEHICLE.DOES_VEHICLE_HAVE_ROOF(Self.Vehicle.Current) and not VEHICLE.IS_VEHICLE_A_CONVERTIBLE(Self.Vehicle.Current, false) then
                    polhash, veh_bone1, veh_bone2, attach_mode = 0xD1E0B7D7, "interiorlight", "interiorlight", 1
                else
                    polhash, veh_bone1, veh_bone2, attach_mode = 0xD1E0B7D7, "interiorlight", "dashglow", 2
                end
            elseif Self.Vehicle.IsBike or Self.Vehicle.IsQuad then
                polhash, veh_bone1, veh_bone2, attach_mode = 0xFDEFAEC3, "chassis_dummy", "chassis_dummy", 1
            else
                YimToast:ShowError("Samurais Scripts", "Can not equip a fake siren on this vehicle.")
            end
            if Game.RequestModel(polhash) then
                dummyCopCar = VEHICLE.CREATE_VEHICLE(polhash, 0.0, 0.0, 0.0, 0, true, false, false)
            end
            if ENTITY.DOES_ENTITY_EXIST(dummyCopCar) then
                if entities.take_control_of(dummyCopCar, 300) then
                    ENTITY.SET_ENTITY_COLLISION(dummyCopCar, false, false)
                    VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(dummyCopCar, false, false)
                    VEHICLE.SET_VEHICLE_UNDRIVEABLE(dummyCopCar, true)
                    ENTITY.SET_ENTITY_ALPHA(dummyCopCar, 5.0, false)
                    ENTITY.SET_ENTITY_INVINCIBLE(dummyCopCar, true)
                    local boneidx1 = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(dummyCopCar, veh_bone1)
                    local boneidx2 = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current, veh_bone2)
                    VEHICLE.SET_VEHICLE_LIGHTS(dummyCopCar, 1)
                    ENTITY.SET_ENTITY_HEADING(dummyCopCar, ENTITY.GET_ENTITY_HEADING(Self.Vehicle.Current))
                    if attach_mode == 1 then
                        ENTITY.ATTACH_ENTITY_BONE_TO_ENTITY_BONE(dummyCopCar, Self.Vehicle.Current, boneidx1, boneidx2, false,
                            true)
                    else
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(dummyCopCar, Self.Vehicle.Current, boneidx2, 0.46, 0.4, -0.9, 0.0, 0.0,
                            0.0, false,
                            true,
                            false, true, 1, true, 1)
                    end
                    dcop:sleep(500)
                    VEHICLE.SET_VEHICLE_SIREN(dummyCopCar, true)
                    VEHICLE.SET_VEHICLE_HAS_MUTED_SIRENS(dummyCopCar, false)
                    AUDIO.TRIGGER_SIREN_AUDIO(dummyCopCar)
                    VEHICLE.SET_VEHICLE_ACT_AS_IF_HAS_SIREN_ON(Self.Vehicle.Current, true)
                    VEHICLE.SET_VEHICLE_CAUSES_SWERVING(Self.Vehicle.Current, true)
                    VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(Self.Vehicle.Current, 0, true)
                    VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(Self.Vehicle.Current, 1, true)
                    -- ENTITY.SET_ENTITY_VISIBLE(dummyCopCar, false, false) -- you can't see the lights anymore but the dummy police vehicle no longer appears to other players.
                end
            end
        end
    end)
end

function CheckVehicleCollision()
    if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(Self.Vehicle.Current) then
        local entity = ENTITY.GET_LAST_ENTITY_HIT_BY_ENTITY_(Self.Vehicle.Current)
        if entity ~= nil and entity ~= 0 and ENTITY.DOES_ENTITY_EXIST(entity) then
            local entity_type = Memory.GetEntityType(entity)
            if entity_type == 6 then
                return false, "Hit and run"
            elseif entity_type == 5 or entity_type == 157 then
                return true, "Samir, you're breaking the car!"
            elseif entity_type == 1 or entity_type == 33 or entity_type == 7 then
                if ENTITY.DOES_ENTITY_HAVE_PHYSICS(entity) then
                    local model = ENTITY.GET_ENTITY_MODEL(entity)
                    for _, m in ipairs(t_CollisionInvalidModels) do
                        if model == m then
                            return true, "Samir, you're breaking the car!"
                        end
                    end
                    return false, "Wrecking ball"
                else
                    return true, "Samir, you're breaking the car!"
                end
            end
        else
            return true, "Samir, you're breaking the car!"
        end
    end
    return false, ""
end

function BankDriftPoints_SP(points)
    local chars_T <const> = {
        { hash = 225514697,  int = 0 },
        { hash = 2602752943, int = 1 },
        { hash = 2608926626, int = 2 },
    }
    script.run_in_fiber(function()
        for _, v in ipairs(chars_T) do
            if ENTITY.GET_ENTITY_MODEL(Self.GetPedID()) == v.hash then
                stats.set_int("SP" .. tostring(v.int) .. "_TOTAL_CASH",
                    stats.get_int("SP" .. tostring(v.int) .. "_TOTAL_CASH") + points)
                AUDIO.PLAY_SOUND_FRONTEND(-1, "LOCAL_PLYR_CASH_COUNTER_INCREASE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS",
                    true)
            end
        end
    end)
end

function StandUp()
    if is_sitting then
        ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
        TASK.CLEAR_PED_TASKS(Self.GetPedID())
        if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
            ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
            thisSeat = 0
        end
        is_sitting = false
    end
end

---@param level integer
---@return string
function WantedLevelToStars(level)
    local stars = ""
    if level == 0 then
        return "Clear"
    end

    for _ = 1, level do
        stars = stars .. " *"
    end

    return stars
end

---@param playerPed integer
---@param playerName string
function SpawnPervert(playerPed, playerName)
    if not Game.RequestModel(0x55446010) then
        return
    end

    local sequenceID = 0
    local spawn_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        playerPed, math.random(3, 10), math.random(3, 10), 0.0
    )

    perv = PED.CREATE_PED(PED_TYPE._CIVMALE, 0x55446010, spawn_pos.x, spawn_pos.y, spawn_pos.z, math.random(1, 180), true,
        false)
    if not ENTITY.DOES_ENTITY_EXIST(perv) then
        UI.WidgetSound("Error")
        YimToast:ShowError(
            "Samurai's Scripts",
            string.format("Failed to spawn a stalker pervert for %s.", playerName)
        )
        return
    end

    UI.WidgetSound("Select")
    YimToast:ShowSuccess(
        "Samurai's Scripts",
        string.format("Spawned a stalker pervert for %s.", playerName)
    )

    TASK.OPEN_SEQUENCE_TASK(sequenceID)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(perv, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(perv, true)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
        perv,
        playerPed,
        3.0,
        3.0,
        3.0,
        20.0,
        -1,
        10.0,
        true
    )

    if Game.RequestAnimDict("switch@trevor@jerking_off") then
        TASK.TASK_PLAY_ANIM(
            perv,
            "switch@trevor@jerking_off",
            "trev_jerking_off_loop",
            4.0,
            -4.0,
            -1,
            196665,
            1.0,
            false,
            false,
            false
        )
    end

    TASK.SET_SEQUENCE_TO_REPEAT(sequenceID, true)
    TASK.TASK_PERFORM_SEQUENCE(perv, sequenceID)
    TASK.CLEAR_SEQUENCE_TASK(sequenceID)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(0x55446010)
    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(perv)
end

Disable_E = function()
    PAD.DISABLE_CONTROL_ACTION(0, 38, true)
    PAD.DISABLE_CONTROL_ACTION(0, 46, true)
    PAD.DISABLE_CONTROL_ACTION(0, 51, true)
    PAD.DISABLE_CONTROL_ACTION(0, 206, true)
end

---@return number
function SetAnimFlags()
    local flag_loop      = Lua_fn.CondReturn(looped, AF._LOOPING, 0)
    local flag_freeze    = Lua_fn.CondReturn(freeze, AF._HOLD_LAST_FRAME, 0)
    local flag_upperbody = Lua_fn.CondReturn(upperbody, AF._UPPERBODY, 0)
    local flag_control   = Lua_fn.CondReturn(controllable, AF._SECONDARY, 0)
    local flag_collision = Lua_fn.CondReturn(noCollision, AF._TURN_OFF_COLLISION, 0)
    local flag_killOnEnd = Lua_fn.CondReturn(killOnEnd, AF._ENDS_IN_DEAD_POSE, 0)
    return Sum(flag_loop, flag_freeze, flag_upperbody, flag_control, flag_collision, flag_killOnEnd)
end

function OnAnimInterrupt()
    if is_playing_anim and Self.IsAlive() and not SS.IsKeyJustPressed(keybinds.stop_anim.code)
        and not ENTITY.IS_ENTITY_PLAYING_ANIM(Self.GetPedID(), curr_playing_anim.dict, curr_playing_anim.anim, 3) then
        if Game.RequestAnimDict(curr_playing_anim.dict) then
            local curr_flag = manualFlags and i_AnimFlag or curr_playing_anim.flag
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            TASK.TASK_PLAY_ANIM(Self.GetPedID(), curr_playing_anim.dict, curr_playing_anim.anim, 4.0, -4.0, -1,
                curr_flag, 1.0, false, false, false)
        end
    end
end

---@param s script_util
function ShootFlares(s)
    if Game.RequestWeaponAsset(0x47757124) then
        for _, bone in pairs(t_PlaneBones) do
            local bone_idx  = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(self.get_veh(), bone)
            local jet_fwd_X = ENTITY.GET_ENTITY_FORWARD_X(self.get_veh())
            local jet_fwd_Y = ENTITY.GET_ENTITY_FORWARD_Y(self.get_veh())
            if bone_idx ~= -1 then
                is_shooting_flares = true
                local bone_pos = ENTITY.GET_ENTITY_BONE_POSTION(self.get_veh(), bone_idx)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
                    ((bone_pos.x + 0.01) + (jet_fwd_X / 1.13)), ((bone_pos.y + 0.01) + jet_fwd_Y / 1.13), bone_pos.z,
                    ((bone_pos.x - 0.01) - (jet_fwd_X / 1.13)), ((bone_pos.y - 0.01) - jet_fwd_Y / 1.13),
                    bone_pos.z + 0.06,
                    1.0, false, 0x47757124, Self.GetPedID(), true, false, 100.0
                )
                AUDIO.PLAY_SOUND_FRONTEND(-1, "HIT_OUT", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
                s:sleep(250)
            end
        end
        is_shooting_flares = false
    end
end

---@param bool boolean
---@param startPos vec3
---@param endPos_1 vec3
---@param endPos_2 vec3
---@param color table
function DrawLaser(bool, startPos, endPos_1, endPos_2, color)
    if bool then
        GRAPHICS.DRAW_LINE(
            startPos.x, startPos.y, startPos.z,
            endPos_1.x, endPos_1.y, endPos_1.z,
            color.r, color.g, color.b, 255
        )
        GRAPHICS.DRAW_MARKER(
            28, endPos_1.x, endPos_1.y, endPos_1.z,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01, 0.01, 0.01,
            color.r, color.g, color.b, 255,
            ---@diagnostic disable-next-line
            false, false, 2, false, 0, 0, false
        )
    else
        GRAPHICS.DRAW_LINE(
            startPos.x, startPos.y, startPos.z,
            endPos_2.x, endPos_2.y, endPos_2.z,
            color.r, color.g, color.b, 255
        )
    end
end

---@param enemiesOnly boolean
---@param entity integer
---@param coords vec3
function ShootCannon(enemiesOnly, entity, coords)
    if ENTITY.DOES_ENTITY_EXIST(entity) and (ENTITY.IS_ENTITY_A_VEHICLE(entity) or ENTITY.IS_ENTITY_A_PED(entity)) and not
        ENTITY.IS_ENTITY_DEAD(entity, false) then
        if not enemiesOnly then
            VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(Self.GetPedID(), entity, coords.x, coords.y, coords.z)
        else
            if ENTITY.IS_ENTITY_A_PED(entity) then
                if Self.IsPedMyEnemy(entity) and not ENTITY.IS_ENTITY_DEAD(entity, false) then
                    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(Self.GetPedID(), entity, coords.x, coords.y, coords.z)
                end
            elseif ENTITY.IS_ENTITY_A_VEHICLE(entity) then
                if Game.Vehicle.IsEnemyVehicle(entity) then
                    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(Self.GetPedID(), entity, coords.x, coords.y, coords.z)
                end
            end
        end
    end
end

---@param src vec3
---@param dest vec3
---@param dmg number
---@param owner integer
---@param speed integer
function ShootExplosiveMG(src, dest, dmg, owner, speed)
    if Game.RequestWeaponAsset(3800181289) then
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
            src.x,
            src.y,
            src.z,
            dest.x,
            dest.y,
            dest.z,
            dmg,
            false,
            3800181289,
            owner,
            true,
            false,
            speed
        )
    end
end

---@param player_id integer
---@param players_current_table integer
---@param card_one integer
---@param card_two integer
---@param card_three integer
SetPokerCards = function(player_id, players_current_table, card_one, card_two, card_three)
    locals.set_int("three_card_poker",
        (three_card_poker_cards) + (three_card_poker_current_deck) +
        (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (1) + (player_id * 3), card_one)

    locals.set_int("three_card_poker",
        (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) +
        (1 + (players_current_table * three_card_poker_deck_size)) + (1) + (player_id * 3), card_one)

    locals.set_int("three_card_poker",
        (three_card_poker_cards) + (three_card_poker_current_deck) +
        (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (2) + (player_id * 3), card_two)

    locals.set_int("three_card_poker",
        (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) +
        (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (player_id * 3), card_two)

    locals.set_int("three_card_poker",
        (three_card_poker_cards) + (three_card_poker_current_deck) +
        (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (3) + (player_id * 3), card_three)

    locals.set_int("three_card_poker",
        (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) +
        (1 + (players_current_table * three_card_poker_deck_size)) + (3) + (player_id * 3), card_three)
end

---@param card_index integer
GetCardNameFromIndex = function(card_index)
    if card_index == 0 then
        return "Rolling"
    end

    local card_number = math.fmod(card_index, 13)
    local cardName = ""
    local cardSuit = ""

    if card_number == 1 then
        cardName = "Ace"
    elseif card_number == 11 then
        cardName = "Jack"
    elseif card_number == 12 then
        cardName = "Queen"
    elseif card_number == 0 then
        cardName = "King"
    else
        cardName = tostring(card_number)
    end

    if card_index >= 1 and card_index <= 13 then
        cardSuit = "Clubs"
    elseif card_index >= 14 and card_index <= 26 then
        cardSuit = "Diamonds"
    elseif card_index >= 27 and card_index <= 39 then
        cardSuit = "Hearts"
    elseif card_index >= 40 and card_index <= 52 then
        cardSuit = "Spades"
    end

    return string.format("%s of %s", cardName, cardSuit)
end

function PlayHandsUp()
    script.run_in_fiber(function()
        if Game.RequestAnimDict("mp_missheist_countrybank@lift_hands") then
            TASK.TASK_PLAY_ANIM(Self.GetPedID(), "mp_missheist_countrybank@lift_hands", "lift_hands_in_air_outro", 4.0,
                -4.0, -1,
                50, 1.0, false, false, false)
        end
    end)
end

---@param ped integer
function AttachPed(ped)
    local myBone = PED.GET_PED_BONE_INDEX(Self.GetPedID(), 6286)
    script.run_in_fiber(function(ap)
        if not ped_grabbed and not PED.IS_PED_A_PLAYER(ped) then
            if entities.take_control_of(ped, 300) then
                if is_handsUp then
                    TASK.CLEAR_PED_TASKS(Self.GetPedID())
                    is_handsUp = false
                end
                if is_playing_anim then
                    if anim_music then
                        PlayMusic(false)
                        anim_music = false
                    end
                    cleanup(ap)
                    is_playing_anim = false
                end
                if is_playing_scenario then
                    stopScenario(Self.GetPedID(), ap)
                    is_playing_scenario = false
                end
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, Self.GetPedID(), myBone, 0.35, 0.3, -0.04, 100.0, 90.0, -10.0, false,
                    true,
                    false, true, 1, true, 1)
                ped_grabbed = true
                i_AttachedPed = ped
            else
                YimToast:ShowError("Samurai's Scripts", _T("NPC_CTRL_FAIL_"))
            end
        end
    end)
    return ped_grabbed, i_AttachedPed
end

---@param veh integer
function AttachVeh(veh)
    local attach_X
    local veh_class = Game.Vehicle.Class(veh)
    local myBone = PED.GET_PED_BONE_INDEX(Self.GetPedID(), 6286)
    script.run_in_fiber(function(av)
        if not vehicle_grabbed and not VEHICLE.IS_THIS_MODEL_A_TRAIN(veh_model) then
            if not entities.take_control_of(veh, 300) then
                YimToast:ShowError("Samurai's Scripts", _T("NPC_CTRL_FAIL_"))
                return false, 0
            end

            if is_handsUp then
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                is_handsUp = false
            end

            if is_playing_anim then
                if anim_music then
                    PlayMusic(false)
                    anim_music = false
                end
                cleanup(av)
                is_playing_anim = false
            end

            if is_playing_scenario then
                stopScenario(Self.GetPedID(), ap)
                is_playing_scenario = false
            end

            if isCrouched then
                PED.RESET_PED_MOVEMENT_CLIPSET(Self.GetPedID(), 0.3)
                isCrouched = false
            end

            if veh_class == "Commercial" or veh_class == "Industrial" or veh_class == "Utility" then
                if VEHICLE.IS_BIG_VEHICLE(veh) then
                    attach_X  = 2.1
                    attach_RY = 0.0
                else
                    attach_X  = 1.9
                    attach_RY = 0.0
                end
            elseif veh_class == "Cycles" or veh_class == "Motorcycles" then
                attach_X  = 0.4
                attach_RY = 0.0
            elseif veh_class == "Planes" or veh_class == "Helicopters" then
                attach_X  = 1.45
                attach_RY = 90
            else
                attach_X  = 1.17
                attach_RY = 0.0
            end

            ENTITY.ATTACH_ENTITY_TO_ENTITY(
                veh,
                Self.GetPedID(),
                myBone,
                attach_X,
                0.0,
                0.0,
                0.0,
                attach_RY,
                -16.0,
                false,
                true,
                false,
                true,
                1,
                true,
                1
            )
            vehicle_grabbed = true
            i_GrabbedVeh     = veh
        end
    end)
    return vehicle_grabbed, i_GrabbedVeh
end

---@param vehToTow integer
function Flatbed_GetTowOffset(vehToTow)
    local vehicleClass = VEHICLE.GET_VEHICLE_CLASS(vehToTow)
    if vehicleClass == 1 then
        return 0.9, -2.3
    elseif vehicleClass == 2 then
        return 0.993, -2.17046
    elseif vehicleClass == 6 then
        return 1.00069420, -2.17046
    elseif vehicleClass == 7 then
        return 1.009, -2.17036
    elseif vehicleClass == 15 then
        return 1.3, -2.21069
    elseif vehicleClass == 16 then
        return 1.5, -2.21069
    end

    return 1.1, -2.0
end

function Flatbed_Detach()
    if Self.Vehicle.IsFlatbed then
        if towed_vehicle ~= 0 and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(towed_vehicle, Self.Vehicle.Current) then
            local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(towed_vehicle, false)
            local flatbed_fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(Self.Vehicle.Current)
            local flatbed_Pos = ENTITY.GET_ENTITY_COORDS(Self.Vehicle.Current, false)
            if entities.take_control_of(towed_vehicle, 350) then
                ENTITY.DETACH_ENTITY(towed_vehicle, true, true)
                ENTITY.SET_ENTITY_COORDS(towed_vehicle, attachedVehcoords.x - (flatbed_fwdVec.x * 10),
                    attachedVehcoords.y - (flatbed_fwdVec.y * 10), flatbed_Pos.z, false, false, false, false)
                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(towed_vehicle, 5.0)
                towed_vehicle = 0
            end
        else
            for _, v in ipairs(entities.get_all_vehicles_as_handles()) do
                local modelHash       = ENTITY.GET_ENTITY_MODEL(v)
                local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(Self.Vehicle.Current, modelHash)
                if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                    local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attachedVehicle, false)
                    local flatbed_fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(Self.Vehicle.Current)
                    if entities.take_control_of(attachedVehicle, 350) then
                        ENTITY.DETACH_ENTITY(attachedVehicle, true, true)
                        ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (flatbed_fwdVec * 10),
                            attachedVehcoords.y - (flatbed_fwdVec * 10), attachedVehcoords.z, false, false, false, false)
                        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attachedVehicle, 5.0)
                        towed_vehicle = 0
                    end
                end
            end
        end
    end
end
--#endregion


--#region Helpers

-- Lua helpers.
---@class Lua_fn
Lua_fn = {}
Lua_fn.__index = Lua_fn

---@param cond boolean
---@param ifTrue any
---@param ifFalse any
Lua_fn.CondReturn = function(cond, ifTrue, ifFalse)
    return cond and ifTrue or ifFalse
end

-- Checks whether a string starts with the provided prefix and returns true or false.
---@param str string
---@param prefix string
Lua_fn.str_startswith = function(str, prefix)
    return str:sub(1, #prefix) == prefix
end

-- Checks whether a string contains the provided substring and returns true or false.
---@param str string
---@param sub string
Lua_fn.str_contains = function(str, sub)
    return str:find(sub, 1, true) ~= nil
end

-- Checks whether a string ends with the provided suffix and returns true or false.
---@param str string
---@param suffix string
Lua_fn.str_endswith = function(str, suffix)
    return str:sub(- #suffix) == suffix
end

-- Inserts a string into another string at the given position. (index starts from 0).
--[[ -- Example:

    Lua_fn.str_insert("Hello", 5, " World")
      -> "Hello World"
]]
---@param str string
---@param pos integer
---@param text string
Lua_fn.str_insert = function(str, pos, text)
    return str:sub(1, pos) .. text .. str:sub(pos)
end

-- Replaces a string with a new string.
---@param str string
---@param old string
---@param new string
Lua_fn.str_replace = function(str, old, new)
    local search_index = 1
    local result
    while true do
        local start_index, end_index = str:find(old, search_index, true)
        if not start_index then
            break
        end
        local changed = str:sub(end_index + 1)
        result = str:sub(1, (start_index - 1)) .. new .. changed
        search_index = -1 * changed:len()
    end
    return result
end

-- Rounds n float to x number of decimals.
--[[ -- Example:

    Lua_fn.round(420.69458797, 2)
      -> 420.69
]]
---@param n number
---@param x integer
Lua_fn.Round = function(n, x)
    return tonumber(string.format("%." .. (x or 0) .. "f", n))
end

-- Helper function for printing
-- floats with a maximum of 4 decimal fractions.
---@param num number
Lua_fn.floatPrecision = function(num)
    if #tostring(math.fmod(num, 1)) > 6 then
        return string.format("%.4f", num)
    end
    return tostring(num)
end

-- Returns a string containing the input value separated by the thousands.
--[[ -- Example:

    Lua_fn.separateInt(42069)
      -> "42,069"
]]
---@param value number | string
Lua_fn.SeparateInt = function(value)
    return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Returns a string containing the input value separated by the thousands and prefixed by a dollar sign.
--[[ -- Example:

    Lua_fn.formatMoney(42069)
      -> "$42,069"
]]
---@param value number | string
Lua_fn.FormatMoney = function(value)
    return "$" .. tostring(Lua_fn.SeparateInt(value))
end

--[[ Decodes hex to string.

HEX must be provided in a string format.

- Example:

      Lua_fn.hexToString("63756E74")
        -> "cunt"
]]
---@param hex string
---@return string
Lua_fn.HexToString = function(hex)
    return (hex:gsub("%x%x", function(digits)
        return string.char(tonumber(digits, 16))
    end))
end

-- Encodes a string into hex
---@param str string
---@return string
Lua_fn.StringToHex = function(str)
    return (str:gsub(".", function(char)
        return string.format("%02x", char:byte())
    end))
end

---@param n integer
---@param base integer
Lua_fn.IntToHex = function(n, base)
    local hex_rep, str, i, d = "0123456789ABCDEF", "", 0, 0
    while n > 0 do
        i = i + 1
        n, d = math.floor(n / base), (n % base) + 1
        str = string.sub(hex_rep, d, d) .. str
    end
    return '0x' .. str
end

---@param tbl table
---@param value any
Lua_fn.TableContains = function(tbl, value)
    if #tbl == 0 then
        return false
    end

    for i = 1, #tbl do
        if type(tbl[i]) == "table" then
            return Lua_fn.TableContains(tbl[i], value)
        else
            if type(tbl[i]) == type(value) then
                if tbl[i] == value then
                    return true
                end
            end
        end
    end

    return false
end

-- Pretty prints tables and accounts for circular references.
---@param t table
---@param indent? integer
---@param seen? table
---@return string
Lua_fn.PrintTable = function(t, indent, seen)
    if not indent then
        indent = 2
    end

    if not seen then
        seen = {}
    end

    if seen[t] then
        return string.rep(" ", indent) .. "{<circular reference>}"
    end

    seen[t] = true

    local ret_str = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2

    for k, v in pairs(t) do
        ret_str = ret_str .. string.rep(" ", indent)

        if type(k) == "number" then
            ret_str = ret_str .. "[" .. k .. "] = "
        elseif type(k) == "string" then
            ret_str = ret_str .. k .. " = "
        else
            ret_str = ret_str .. tostring(k) .. " = "
        end

        if type(v) == "number" then
            ret_str = ret_str .. v .. ",\r\n"
        elseif type(v) == "string" then
            ret_str = ret_str .. "\"" .. v .. "\",\r\n"
        elseif type(v) == "table" then
            ret_str = ret_str .. Lua_fn.PrintTable(v, indent + 2, seen) .. ",\r\n"
        else
            ret_str = ret_str .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end

    ret_str = ret_str .. string.rep(" ", indent - 2) .. "}"
    return ret_str
end


-- Returns the number of values in a table. Doesn't count nil fields.
---@param t table
---@return number
Lua_fn.GetTableLength = function(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Returns the number of duplicate items in a table.
---@param t table
---@param value string | number | integer | table
Lua_fn.GetTableDupes = function(t, value)
    local count = 0
    for _, v in ipairs(t) do
        if value == v then
            count = count + 1
        end
    end
    return count
end

-- Removes duplicate items from a table and returns a new one with the results.
--
-- If `debug` is set to `true`, it adds a table with duplicate items to the return as well.
---@param t table
---@param debug? boolean
Lua_fn.RemoveTableDupes = function(t, debug)
    local t_exists, t_clean, t_dupes, t_result = {}, {}, {}, {}

    for _, v in ipairs(t) do
        if not t_exists[v] then
            t_clean[#t_clean + 1] = v
            t_exists[v] = true
        else
            if debug then
                t_dupes[#t_dupes + 1] = v
            end
        end
    end

    if debug then
        t_result.clean = t_clean
        t_result.dupes = t_dupes
    end

    return debug and t_result or t_clean
end

--
-- Bitwise Operations
--

---@param num number
---@param bit number
Lua_fn.get_bit = function(num, bit)
    return (num & (1 << bit)) >> bit
end

---@param num number
---@param bit number
Lua_fn.has_bit = function(num, bit)
    return (num & (1 << bit)) ~= 0
end

---@param num number
---@param bit number
Lua_fn.set_bit = function(num, bit)
    return num | (1 << bit)
end

---@param num number
---@param bit number
Lua_fn.clear_bit = function(num, bit)
    return num & ~(1 << bit)
end


-- Lua version of Bob Jenskins' "Jenkins One At A Time" hash function
--
-- https://en.wikipedia.org/wiki/Jenkins_hash_function
---@param key string
---@return integer
Lua_fn.Joaat = function(key)
    local hash = 0
    key = key:lower()

    for i = 1, #key do
        hash = hash + string.byte(key, i)
        hash = hash + (hash << 10)
        hash = hash & 0xFFFFFFFF
        hash = hash ~ (hash >> 6)
    end

    hash = hash + (hash << 3)
    hash = hash & 0xFFFFFFFF
    hash = hash ~ (hash >> 11)
    hash = hash + (hash << 15)
    hash = hash & 0xFFFFFFFF
    return hash
end

-- Converts a rotation vector to a direction vector.
---@param rotation vec3
Lua_fn.RotToDir = function(rotation)
    local radians = vec3:new(
        rotation.x * (math.pi / 180),
        rotation.y * (math.pi / 180),
        rotation.z * (math.pi / 180)
    )

    local direction = vec3:new(
        -math.sin(radians.z) * math.abs(math.cos(radians.x)),
        math.cos(radians.z) * math.abs(math.cos(radians.x)),
        math.sin(radians.x)
    )

    return direction
end


-- ImGui helpers.
---@class UI
UI = {}
UI.__index = UI

-- Creates a text wrapped around the provided size. (We can use coloredText() and set the color to white but this is simpler.)
---@param text string
---@param wrap_size integer
UI.WrappedText = function(text, wrap_size)
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
    ImGui.TextWrapped(text)
    ImGui.PopTextWrapPos()
end

-- Creates a colored ImGui text.
---@param text string
---@param color any
---@param alpha? number
---@param wrap_size? number
UI.ColoredText = function(text, color, alpha, wrap_size)
    local r, g, b, a = Col(color):AsFloat()
    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, alpha or a)

    if wrap_size then
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
    end

    ImGui.TextWrapped(text)

    if wrap_size then
        ImGui.PopTextWrapPos()
    end
    ImGui.PopStyleColor(1)
end

-- Creates a colored ImGui button.
---@param text string
---@param color any
---@param hovercolor any
---@param activecolor any
---@param alpha? number
---@return boolean
UI.ColoredButton = function(text, color, hovercolor, activecolor, alpha)
    local buttonR, buttonG, buttonB, buttonA = Col(color):AsFloat()
    local hoveredR, hoveredG, hoveredB, hoveredA = Col(hovercolor):AsFloat()
    local activeR, activeG, activeB, activeA = Col(activecolor):AsFloat()

    ImGui.PushStyleColor(ImGuiCol.Button, buttonR, buttonG, buttonB, buttonA)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hoveredR, hoveredG, hoveredB, hoveredA)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, activeR, activeG, activeB, activeA)
    local retVal = ImGui.Button(text)
    ImGui.PopStyleColor(3)
    return retVal
end

-- Creates a help marker (?) symbol in front of the widget this function is called after.
--
-- When the symbol is hovered, it displays a tooltip.
---@param text string
---@param color? any
---@param alpha? number
UI.HelpMarker = function(text, color, alpha)
    if not disableTooltips then
        ImGui.SameLine()
        ImGui.TextDisabled("(?)")
        if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            ImGui.SetNextWindowBgAlpha(0.75)
            ImGui.BeginTooltip()
            if color then
                UI.ColoredText(text, color, alpha, 20)
            else
                ImGui.PushTextWrapPos(ImGui.GetFontSize() * 20)
                ImGui.TextWrapped(text)
                ImGui.PopTextWrapPos()
            end
            ImGui.EndTooltip()
        end
    end
end

-- Displays a tooltip whenever the widget this function is called after is hovered.
---@param text string
---@param color? any
---@param alpha? number
UI.Tooltip = function(text, color)
    if not disableTooltips then
        if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            ImGui.SetNextWindowBgAlpha(0.75)
            ImGui.BeginTooltip()
            if color then
                UI.ColoredText(text, color, alpha, 20)
            else
                ImGui.PushTextWrapPos(ImGui.GetFontSize() * 20)
                ImGui.TextWrapped(text)
                ImGui.PopTextWrapPos()
            end
            ImGui.EndTooltip()
        end
    end
end

-- Checks if an ImGui widget was clicked.
---@param button string A string representing a mouse button: `lmb` for Left Mouse Button or `rmb` for Right Mouse Button.
---@return boolean
UI.IsItemClicked = function(button)
    if button == "lmb" then
        return (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(0))
    elseif button == "rmb" then
        return (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(1))
    end

    return false
end

-- Sets the clipboard text.
---@param text string
---@param cond boolean
UI.SetClipBoard = function(text, cond)
    if cond then
        UI.WidgetSound("Click")
        ImGui.SetClipboardText(text)
        YimToast:ShowMessage("Samurai's Scripts", "Link copied to clipboard.")
    end
end

-- Plays a sound when an ImGui widget is clicked.
---@param sound string
UI.WidgetSound = function(sound)
    if disableUiSounds or not t_UISounds[sound] then
        return
    end

    script.run_in_fiber(function()
        AUDIO.PLAY_SOUND_FRONTEND(-1, t_UISounds[sound].soundName, t_UISounds[sound].soundRef, false)
    end)
end


-- Script-specific helpers.
--
-- SS as in Samurai's Scripts, not Schutzstaffel... 🙄
SS = {}
SS.__index = SS

---@param data string
SS.debug = function(data)
    if SS_debug then
        log.debug(data)
    end
end

SS.IsAnyKeyPressed = function()
    return KeyManager:IsAnyKeyPressed()
end

---@param key integer | string
SS.IsKeyPressed = function(key)
    return KeyManager:IsKeyPressed(key)
end

---@param key integer | string
SS.IsKeyJustPressed = function(key)
    return KeyManager:IsKeyJustPressed(key)
end

SS.ResetMovement = function()
    PED.RESET_PED_MOVEMENT_CLIPSET(Self.GetPedID(), 0.3)
    PED.RESET_PED_STRAFE_CLIPSET(Self.GetPedID())
    PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(Self.GetPedID())
    WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(Self.GetPedID(), 3839837909) -- default
    PED.CLEAR_PED_ALTERNATE_MOVEMENT_ANIM(Self.GetPedID(), 0, -8.0)
    TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(Self.GetPedID(), false, false)
    currentMvmt  = ""
    currentStrf  = ""
    currentWmvmt = ""
end

---@param data table
---@param isJson boolean
SS.SetMovement = function(data, isJson)
    local mvmtclipset = isJson and data.Name or data.mvmt
    script.run_in_fiber(function(s)
        SS.ResetMovement()
        s:sleep(100)
        if mvmtclipset then
            while not STREAMING.HAS_CLIP_SET_LOADED(mvmtclipset) do
                STREAMING.REQUEST_CLIP_SET(mvmtclipset)
                coroutine.yield()
            end
            PED.SET_PED_MOVEMENT_CLIPSET(Self.GetPedID(), mvmtclipset, 1.0)
            PED.SET_PED_ALTERNATE_MOVEMENT_ANIM(Self.GetPedID(), 0, "move_clown@generic", "idle", 1090519040, true)
            TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(Self.GetPedID(), true, true)
            currentMvmt = mvmtclipset
        end
        if data.wmvmt then
            PED.SET_PED_WEAPON_MOVEMENT_CLIPSET(Self.GetPedID(), data.wmvmt)
            currentWmvmt = data.wmvmt
        end
        if data.strf then
            while not STREAMING.HAS_CLIP_SET_LOADED(data.strf) do
                STREAMING.REQUEST_CLIP_SET(data.strf)
                coroutine.yield()
            end
            PED.SET_PED_STRAFE_CLIPSET(Self.GetPedID(), data.strf)
            currentStrf = data.strf
        end
        if data.wanim then
            WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(Self.GetPedID(), joaat(data.wanim))
        end
    end)
end

---@param warehouse table
SS.GetCEOwarehouseInfo = function(warehouse)
    script.run_in_fiber(function()
        local property_index = (stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(warehouse.id)) - 1)
        warehouse.name       = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(("MP_WHOUSE_%d"):format(property_index))
        if t_CEOwarehouses[warehouse.name] then
            warehouse.size.small  = t_CEOwarehouses[warehouse.name].size == 0
            warehouse.size.medium = t_CEOwarehouses[warehouse.name].size == 1
            warehouse.size.large  = t_CEOwarehouses[warehouse.name].size == 2
            warehouse.max         = t_CEOwarehouses[warehouse.name].max
            warehouse.pos         = t_CEOwarehouses[warehouse.name].coords
        end
    end)
end

---@param index number
---@param entry table
SS.GetMCbusinessInfo = function(index, entry)
    for _, v in ipairs(t_MCbusinessIDs) do
        if Lua_fn.TableContains(v.possible_ids, index) then
            entry.name       = v.name
            entry.id         = v.id
            entry.unit_max   = v.unit_max
            entry.val_offset = v.val_offset
            entry.blip       = v.blip
        end
    end
end

---@param scr_name string
SS.FinishSale = function(scr_name)
    script.execute_as_script(scr_name, function()
        if t_SellScripts[scr_name] then
            if not t_SellScripts[scr_name].b then -- gb_*
                for _, data in pairs(t_SellScripts[scr_name]) do
                    locals.set_int(scr_name, data.l + data.o, data.v)
                end
            else -- fm_content_*
                if not NETWORK.NETWORK_GET_HOST_OF_THIS_SCRIPT() == self.get_id() then
                    YimToast:ShowWarning("Samurai's Scripts",
                        "Unable to finish sale mission because you are not host of this script.")
                else
                    local val = locals.get_int(scr_name, t_SellScripts[scr_name].b + 1 + 0)
                    if not Lua_fn.has_bit(val, 11) then
                        val = Lua_fn.set_bit(val, 11)
                        locals.set_int(scr_name, t_SellScripts[scr_name].b + 1 + 0, val)
                    end
                    locals.set_int(scr_name, t_SellScripts[scr_name].l + t_SellScripts[scr_name].o, 3) -- End reason. Thanks ShinyWasabi! Now I know what 3 is 😅
                end
            end
        end
    end)
end

SS.FinishCargoSourceMission = function()
    if script.is_active("gb_contraband_buy") then
        script.execute_as_script("gb_contraband_buy", function()
            if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
                YimToast:ShowError("Samurai's Scripts", "You are not host of this script.")
                return
            end
            locals.set_int("gb_contraband_buy", 621 + 5, 1)   -- 1.70 -- case -1: return "INVALID - UNSET";
            locals.set_int("gb_contraband_buy", 621 + 191, 6) -- 1.70 -- func_40 Local_621.f_191 = iParam0;
            locals.set_int("gb_contraband_buy", 621 + 192, 4) -- 1.70 -- func_15 Local_621.f_192 = iParam0;
        end)
    elseif script.is_active("fm_content_cargo") then
        script.execute_as_script("fm_content_cargo", function()
            if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
                YimToast:ShowError("Samurai's Scripts", "You are not host of this script.")
                return
            end
            local val = locals.get_int("fm_content_cargo", 5883 + 1 + 0) -- GENERIC_BITSET_I_WON -- 1.70 -- var uLocal_5883 = 4;
            if not Lua_fn.has_bit(val, 11) then
                val = Lua_fn.set_bit(val, 11)
                locals.set_int("fm_content_cargo", 5883 + 1 + 0, val)
            end
            locals.set_int("fm_content_cargo", 5979 + 1157, 3) -- EndReason -- 1.70 -- func_8 Local_5979.f_1157 = iParam0;
        end)
    end
end

---@param s script_util
SS.FillAll = function(s)
    if not Game.IsOnline() then
        YimToast:ShowError("Samurai's Scripts", _T("GENERIC_UNAVAILABLE_SP_"))
        return
    end
    if stats.get_int("MPX_HANGAR_OWNED") ~= 0 then
        if not hangarLoop then
            hangarLoop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT0") > 0 then
        if not wh1_loop then
            wh1_loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT1") > 0 then
        if not wh2_loop then
            wh2_loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT2") > 0 then
        if not wh3_loop then
            wh3_loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT3") > 0 then
        if not wh4_loop then
            wh4_loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT4") > 0 then
        if not wh5_loop then
            wh5_loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_FAC_SLOT0") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY0") < 100 then
        globals.set_int(gb_global + 0 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT1") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY1") < 100 then
        globals.set_int(gb_global + 1 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT2") and stats.get_int("MPX_MATTOTALFORFACTORY2") < 100 then
        globals.set_int(gb_global + 2 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT3") and stats.get_int("MPX_MATTOTALFORFACTORY3") < 100 then
        globals.set_int(gb_global + 3 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT4") and stats.get_int("MPX_MATTOTALFORFACTORY4") < 100 then
        globals.set_int(gb_global + 4 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT5") and stats.get_int("MPX_MATTOTALFORFACTORY5") < 100 then
        globals.set_int(gb_global + 5 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_XM22_LAB_OWNED") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY6") < 100 then
        globals.set_int(gb_global + 6 + 1, 1)
        s:sleep(300)
    end
end

---@param keybind table
SS.SetKeyboardHotkey = function(keybind)
    ImGui.Dummy(1, 10)
    if key_name == nil then
        start_loading_anim = true
        UI.ColoredText(string.format("%s%s", _T("INPUT_WAIT_TXT_"), loading_label), "#FFFFFF", 0.75, 20)
        key_pressed, key_code, key_name = SS.IsAnyKeyPressed()
    else
        start_loading_anim = false
        for _, key in pairs(t_ReservedKeys.kb) do
            if key_code == key then
                _reserved = true
                break
            else
                _reserved = false
            end
        end

        if not _reserved then
            ImGui.Text("New Key: ")
            ImGui.SameLine()
            ImGui.Text(string.format("[%s]", key_name))
        else
            UI.ColoredText(_T("HOTKEY_RESERVED_"), "red", 0.86, 20)
        end

        ImGui.SameLine()
        ImGui.Dummy(5, 1)
        ImGui.SameLine()
        if UI.ColoredButton(string.format(" %s ##Shortcut", _T("GENERIC_CLEAR_BTN_")), "#FFDB58", "#FFFAA0", "#FFFFF0", 0.7) then
            UI.WidgetSound("Cancel")
            key_code, key_name = nil, nil
        end
    end

    ImGui.Dummy(1, 10)
    if not _reserved and key_code ~= nil then
        if ImGui.Button(string.format("%s##keybinds", _T("GENERIC_CONFIRM_BTN_"))) then
            UI.WidgetSound("Select")
            keybind.code, keybind.name = key_code, string.format("[%s]", key_name)
            CFG:SaveItem("keybinds", keybinds)
            key_code, key_name = nil, nil
            is_setting_hotkeys = false
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    end

    if ImGui.Button(string.format("%s##keybinds", _T("GENERIC_CANCEL_BTN_"))) then
        UI.WidgetSound("Cancel")
        key_code, key_name = nil, nil
        start_loading_anim = false
        is_setting_hotkeys = false
        ImGui.CloseCurrentPopup()
    end
end

SS.OpenKeyboardHotkeysWindow = function(window_name, keybind)
    ImGui.BulletText(window_name)
    local avail_x, _ = ImGui.GetContentRegionAvail()
    ImGui.SameLine(avail_x / 1.7)
    ImGui.SetNextItemWidth(120)
    keybind.name, _ = ImGui.InputText(
        string.format("##%s", window_name),
        keybind.name,
        32,
        ImGuiInputTextFlags.ReadOnly
    )

    if UI.IsItemClicked('lmb') then
        UI.WidgetSound("Select2")
        ImGui.OpenPopup(window_name)
        is_setting_hotkeys = true
    end

    ImGui.SameLine()
    ImGui.BeginDisabled(keybind.code == 0x0)
    if ImGui.Button(string.format("%s##%s", _T("GENERIC_UNBIND_LABEL_"), window_name)) then
        UI.WidgetSound("Delete")
        keybind.code, keybind.name = 0x0, "[Unbound]"
        CFG:SaveItem("keybinds", keybinds)
    end
    ImGui.EndDisabled()
    ImGui.SetNextWindowPos(780, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowSizeConstraints(240, 60, 600, 400)
    ImGui.SetNextWindowBgAlpha(0.8)
    if ImGui.BeginPopupModal(
            window_name,
            true,
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoTitleBar
        ) then
        is_setting_hotkeys = true
        SS.SetKeyboardHotkey(keybind)
        ImGui.End()
    end
end

---@param keybind table
SS.SetControllerHotkey = function(keybind)
    ImGui.Dummy(1, 10)
    if gpad_keyName == nil then
        start_loading_anim = true
        UI.ColoredText(string.format("%s%s", _T("INPUT_WAIT_TXT_"), loading_label), "#FFFFFF", 0.75, 20)
        gpad_keyCode, gpad_keyName = Game.GetKeyPressed()
    else
        start_loading_anim = false
        for _, key in pairs(t_ReservedKeys.gpad) do
            if gpad_keyCode == key then
                _reserved = true
                break
            else
                _reserved = false
            end
        end
        if not _reserved then
            ImGui.Text("New Key: "); ImGui.SameLine(); ImGui.Text(gpad_keyName)
        else
            UI.ColoredText(_T("HOTKEY_RESERVED_"), "red", 0.86, 20)
        end
        ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
        if UI.ColoredButton(
                string.format(
                    " %s ##gpadkeybinds",
                    _T("GENERIC_CLEAR_BTN_")
                ),
                "#FFDB58",
                "#FFFAA0",
                "#FFFFF0",
                0.7
            ) then
            UI.WidgetSound("Cancel")
            gpad_keyCode, gpad_keyName = nil, nil
        end
    end

    ImGui.Dummy(1, 10)
    if not _reserved and gpad_keyCode ~= nil then
        if ImGui.Button(string.format("%s##gpadkeybinds", _T("GENERIC_CONFIRM_BTN_"))) then
            UI.WidgetSound("Select")
            keybind.code, keybind.name = gpad_keyCode, gpad_keyName
            CFG:SaveItem("gpad_keybinds", gpad_keybinds)
            gpad_keyCode, gpad_keyName = nil, nil
            is_setting_hotkeys = false
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    end

    if ImGui.Button(string.format("%s##gpadkeybinds", _T("GENERIC_CANCEL_BTN_"))) then
        UI.WidgetSound("Cancel")
        gpad_keyCode, gpad_keyName = nil, nil
        start_loading_anim = false
        is_setting_hotkeys = false
        ImGui.CloseCurrentPopup()
    end
end

---@param window_name string
---@param keybind table
SS.OpenControllerHotkeysWindow = function(window_name, keybind)
    ImGui.BulletText(window_name)
    local avail_x, _ = ImGui.GetContentRegionAvail()
    ImGui.SameLine(avail_x / 1.7)
    ImGui.SetNextItemWidth(120)
    keybind.name, _ = ImGui.InputText(
        string.format(
            "##",
            window_name
        ),
        keybind.name,
        32,
        ImGuiInputTextFlags.ReadOnly
    )

    if UI.IsItemClicked('lmb') then
        UI.WidgetSound("Select2")
        ImGui.OpenPopup(window_name)
        is_setting_hotkeys = true
    end

    ImGui.SameLine()
    ImGui.BeginDisabled(keybind.code == 0)
    if ImGui.Button(string.format("%s##%s", _T("GENERIC_UNBIND_LABEL_"), window_name)) then
        UI.WidgetSound("Delete")
        keybind.code, keybind.name = 0, "[Unbound]"
        CFG:SaveItem("gpad_keybinds", gpad_keybinds)
    end

    ImGui.EndDisabled()
    ImGui.SetNextWindowPos(780, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowSizeConstraints(240, 60, 600, 400)
    ImGui.SetNextWindowBgAlpha(0.8)
    if ImGui.BeginPopupModal(
            window_name,
            true,
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoTitleBar
        ) then
        SS.SetControllerHotkey(keybind)
        ImGui.End()
    end
end

-- Handles config key addition/removal.
---@param saved table
---@param default table
SS.SyncConfing = function(saved, default)
    for k, v in pairs(default) do
        if saved[k] == nil then
            saved[k] = v
            _G[k] = v
            SS.debug(string.format("Added missing config key: '%s'", k))
        end
    end

    for k in pairs(saved) do
        if default[k] == nil then
            saved[k] = nil
            SS.debug(string.format("Removed redundant config key: '%s'", k))
        end
    end

    CFG:Save(saved)
end

SS.CanUseKeybinds = function()
    return (
        not is_typing and not
        is_setting_hotkeys and not
        Self.IsBrowsingApps() and not
        HUD.IS_MP_TEXT_CHAT_TYPING() and not
        HUD.IS_PAUSE_MENU_ACTIVE()
    )
end

-- Reverts changes done by the script.
SS.HandleEvents = function()
    if i_AttachedPed ~= nil and i_AttachedPed ~= 0 then
        ENTITY.DETACH_ENTITY(i_AttachedPed, true, true)
        ENTITY.FREEZE_ENTITY_POSITION(i_AttachedPed, false)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_AttachedPed, false)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_AttachedPed, false)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
        i_AttachedPed = 0; ped_grabbed = false
    end

    if i_GrabbedVeh ~= nil and i_GrabbedVeh ~= 0 then
        ENTITY.DETACH_ENTITY(i_GrabbedVeh, true, true)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
        i_GrabbedVeh = 0; vehicle_grabbed = false
    end

    if attached_vehicle ~= nil and attached_vehicle ~= 0 then
        local modelHash         = ENTITY.GET_ENTITY_MODEL(attached_vehicle)
        local attachedVehicle   = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(
            PED.GET_VEHICLE_PED_IS_USING(Self.GetPedID()),
            modelHash)
        local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attached_vehicle, false)
        local playerForwardX    = ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
        local playerForwardY    = ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
        controlled              = entities.take_control_of(attachedVehicle, 300)
        if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
            if controlled then
                ENTITY.DETACH_ENTITY(attachedVehicle, true, true)
                ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (playerForwardX * 10),
                    attachedVehcoords.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
            end
        end
        attached_vehicle = 0
    end


    if currentMvmt ~= "" then
        SS.ResetMovement()
    end

    if is_playing_anim then
        if anim_music then
            if ENTITY.DOES_ENTITY_EXIST(pBus) then
                ENTITY.DELETE_ENTITY(pBus)
            end
            if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
                ENTITY.DELETE_ENTITY(dummyDriver)
            end
        end
        TASK.CLEAR_PED_TASKS(Self.GetPedID())
        if selfPTFX[1] ~= nil then
            for _, v in ipairs(selfPTFX) do
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(v, false)
            end
        end
        local current_coords = self.get_pos()
        if PED.IS_PED_IN_ANY_VEHICLE(Self.GetPedID(), false) then
            local veh    = PED.GET_VEHICLE_PED_IS_USING(Self.GetPedID())
            local mySeat = Game.GetPedVehicleSeat(Self.GetPedID())
            PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), veh, mySeat)
        else
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Self.GetPedID(), current_coords.x, current_coords.y, current_coords.z, true,
                false, false)
        end
        if plyrProps[1] ~= nil then
            for _, v in ipairs(plyrProps) do
                if ENTITY.DOES_ENTITY_EXIST(v) then
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v, false, false)
                    ENTITY.DELETE_ENTITY(v)
                end
            end
        end
        is_playing_anim = false
    end

    if spawned_npcs[1] ~= nil then
        for i, v in ipairs(spawned_npcs) do
            if ENTITY.DOES_ENTITY_EXIST(v) then
                ENTITY.DELETE_ENTITY(v)
                table.remove(spawned_npcs, i)
            end
        end
    end

    if is_playing_scenario then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
        if ENTITY.DOES_ENTITY_EXIST(bbq) then
            ENTITY.DELETE_ENTITY(bbq)
        end
        is_playing_scenario = false
    end

    if is_playing_radio then
        if ENTITY.DOES_ENTITY_EXIST(pBus) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(pBus, false, false)
            ENTITY.DELETE_ENTITY(pBus)
        end
        if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
            ENTITY.DELETE_ENTITY(dummyDriver)
        end
        is_playing_radio = false
    end

    if is_handsUp then
        TASK.CLEAR_PED_TASKS(Self.GetPedID())
        is_handsUp = false
    end

    if isCrouched then
        PED.RESET_PED_MOVEMENT_CLIPSET(Self.GetPedID(), 0)
        isCrouched = false
    end

    if disable_waves then
        Game.World.DisableOceanWaves(false)
        disable_waves = false
    end

    if autopilot_waypoint or autopilot_objective or autopilot_random then
        if Self.IsDriving() then
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
            autopilot_waypoint, autopilot_objective, autopilot_random = false, false, false
        end
    end

    if is_sitting or ENTITY.IS_ENTITY_PLAYING_ANIM(Self.GetPedID(), "timetable@ron@ig_3_couch", "base", 3) then
        ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
        if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
            ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
        end
        is_sitting, thisSeat = false, 0
    end

    Self.Vehicle.IsEngineBrakeDisabled = false
    Self.Vehicle.HasKersBoost = false
    Self.Vehicle.IsOffroaderEnabled = false
    Self.Vehicle.HasRallyTires = false
    Self.Vehicle.IsTractionControlDisabled = false
    Self.Vehicle.IsLowSpeedWheelieEnabled = false

    if is_hiding then
        if hiding_in_boot or hiding_in_dumpster then
            ENTITY.DETACH_ENTITY(Self.GetPedID(), false, false)
            hiding_in_boot, hiding_in_dumpster = false, false
        end
        TASK.CLEAR_PED_TASKS(Self.GetPedID())
        is_hiding = false
    end
    TASK.CLEAR_PED_TASKS(Self.GetPedID())

    if cmd_ui_is_open then
        gui.override_mouse(false)
    end

    if VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Current) ~= 1 then
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(Self.Vehicle.Current, 1)
        VEHICLE.SET_VEHICLE_ALARM(Self.Vehicle.Current, false)
    end

    if engine_sound_changed then
        AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(
            Self.Vehicle.Current,
            vehicles.get_vehicle_display_name(
                ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current)
            )
        )
        Game.Vehicle.SetAcceleration(Self.Vehicle.Current, 1.0)
    end

    EntityForge:ForceCleanup()
    PreviewService:Clear()
end

SS.UpdateNPCdriveTask = function()
    TASK.CLEAR_PED_TASKS(i_NpcDriver)
    TASK.CLEAR_PED_SECONDARY_TASK(i_NpcDriver)
    TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_ThisVeh)
    TASK.TASK_VEHICLE_TEMP_ACTION(i_NpcDriver, i_ThisVeh, 1, 500)
    if npcDriveTask == "wp" or npcDriveTask == "obj" then
        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(i_NpcDriver, i_ThisVeh, npcDriveDest.x, npcDriveDest.y, npcDriveDest.z,
            npcDrivingSpeed, npcDrivingFlags, 100)
    else
        TASK.TASK_VEHICLE_DRIVE_WANDER(i_NpcDriver, i_ThisVeh, npcDrivingSpeed, npcDrivingFlags)
    end
    YimToast:ShowMessage(
        "Samurai's Scripts",
        string.format("NPC driving style changed to %s.", npcDriveSwitch == 0 and "Normal" or "Aggressive")
    )
end

---@param crates number
SS.GetCEOCratesOffset = function(crates)
    if not crates or crates <= 0 then
        return 0
    end

    if crates == 1 then
        return 15732 -- EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1
    end

    if crates == 2 then
        return 15733
    end

    if crates == 3 then
        return 15734
    end

    if crates == 4 or crates == 5 then
        return 15735
    end

    if crates >= 6 and crates <= 9 then
        return 15735 + math.floor((crates - 4) / 2)
    end

    if crates >= 10 and crates <= 110 then
        return 15738 + math.floor((crates - 10) / 5)
    end

    if crates == 111 then
        return 15752
    end

    return 0
end

-- Reset saved config without affecting
--
-- custom outfits, custom vehicles, and favorite actions.
SS.ResetSettings = function()
    for key, _ in pairs(DEFAULT_CONFIG) do
        if (
            key ~= "forged_entities" and
            key ~= "favorite_entities" and
            key ~= "favorite_actions"
        ) then
            _G[key] = DEFAULT_CONFIG[key]
            CFG:SaveItem(key, DEFAULT_CONFIG[key])
        end
    end
end

SS.IsUsingAirctaftMG = function()
    if Self.IsDriving() and (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and Game.Vehicle.IsWeaponized(self.get_veh()) then
        local armed, weapon = WEAPON.GET_CURRENT_PED_VEHICLE_WEAPON(Self.GetPedID(), weapon)
        if armed then
            for _, v in ipairs(t_AircraftMGs) do
                if weapon == joaat(v) then
                    return true, weapon
                end
            end
        end
    end
    return false, 0
end
--#endregion
