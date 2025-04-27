---@diagnostic disable

--#region Global functions

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

---@param runnable function
---@param _args any
---@param timeout? number | nil  -- Optional timeout in milliseconds.
function Await(runnable, _args, timeout)
    if type(runnable) ~= "function" then
        error(
            string.format(
                "Invalid argument! Function expected, got %s instead.",
                type(runnable)
            )
        )
        return false
    end

    if type(_args) ~= "table" then
        _args = { _args }
    end

    if not timeout then
        timeout = 3000
    end

    local startTime = Time.millis()
    while not runnable(table.unpack(_args)) do
        if timeout and (Time.millis() - startTime) > timeout then
            log.warning("[Await Error]: timeout reached!")
            return false
        end
        coroutine.yield()
    end

    return true
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

function DummyCop()
    script.run_in_fiber(function(dcop)
        if Self.Vehicle.Current ~= 0 then
            local i_ModelHash, s_Bone1, s_Bone2, i_AttachMode

            if Self.Vehicle.IsCar then
                if VEHICLE.DOES_VEHICLE_HAVE_ROOF(Self.Vehicle.Current) and not VEHICLE.IS_VEHICLE_A_CONVERTIBLE(Self.Vehicle.Current, false) then
                    i_ModelHash, s_Bone1, s_Bone2, i_AttachMode = 0xD1E0B7D7, "interiorlight", "interiorlight", 1
                else
                    i_ModelHash, s_Bone1, s_Bone2, i_AttachMode = 0xD1E0B7D7, "interiorlight", "dashglow", 2
                end
            elseif Self.Vehicle.IsBike or Self.Vehicle.IsQuad then
                i_ModelHash, s_Bone1, s_Bone2, i_AttachMode = 0xFDEFAEC3, "chassis_dummy", "chassis_dummy", 1
            else
                YimToast:ShowError("Samurais Scripts", "Can not equip a fake siren on this vehicle!")
            end

            i_DummyCopCar = Game.CreateVehicle(
                i_ModelHash,
                vec3:zero(),
                0,
                true,
                false
            )

            if ENTITY.DOES_ENTITY_EXIST(i_DummyCopCar) then
                if entities.take_control_of(i_DummyCopCar, 300) then
                    local i_BoneIndex1 = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_DummyCopCar, s_Bone1)
                    local i_BoneIndex2 = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current, s_Bone2)

                    ENTITY.SET_ENTITY_COLLISION(i_DummyCopCar, false, false)
                    VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(i_DummyCopCar, false, false)
                    VEHICLE.SET_VEHICLE_UNDRIVEABLE(i_DummyCopCar, true)
                    ENTITY.SET_ENTITY_ALPHA(i_DummyCopCar, 5.0, false)
                    ENTITY.SET_ENTITY_INVINCIBLE(i_DummyCopCar, true)
                    VEHICLE.SET_VEHICLE_LIGHTS(i_DummyCopCar, 1)
                    ENTITY.SET_ENTITY_HEADING(i_DummyCopCar, Game.GetHeading(Self.Vehicle.Current))

                    if i_AttachMode == 1 then
                        ENTITY.ATTACH_ENTITY_BONE_TO_ENTITY_BONE(
                            i_DummyCopCar,
                            Self.Vehicle.Current,
                            i_BoneIndex1,
                            i_BoneIndex2,
                            false,
                            true
                        )
                    else
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            i_DummyCopCar,
                            Self.Vehicle.Current,
                            i_BoneIndex2,
                            0.46,
                            0.4,
                            -0.9,
                            0.0,
                            0.0,
                            0.0,
                            false,
                            true,
                            false,
                            true,
                            1,
                            true,
                            1
                        )
                    end

                    dcop:sleep(500)
                    VEHICLE.SET_VEHICLE_SIREN(i_DummyCopCar, true)
                    VEHICLE.SET_VEHICLE_HAS_MUTED_SIRENS(i_DummyCopCar, false)
                    AUDIO.TRIGGER_SIREN_AUDIO(i_DummyCopCar)
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
    if b_IsSitting then
        ENTITY.DETACH_ENTITY(Self.GetPedID(), true, false)
        TASK.CLEAR_PED_TASKS(Self.GetPedID())
        if ENTITY.DOES_ENTITY_EXIST(i_PublicSeat) then
            ENTITY.FREEZE_ENTITY_POSITION(i_PublicSeat, false)
            i_PublicSeat = 0
        end
        b_IsSitting = false
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
    Await(Game.RequestModel, 0x55446010)

    local sequenceID = 0
    local spawn_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        playerPed,
        math.random(3, 10),
        math.random(3, 10),
        0.0
    )

    i_StalkingPervert = Game.CreatePed(
        0x55446010,
        spawn_pos,
        math.random(1, 180),
        Game.IsOnline(),
        false
    )

    if not ENTITY.DOES_ENTITY_EXIST(i_StalkingPervert) then
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
        string.format(
            "Spawned a stalker pervert for %s.", playerName
        )
    )

    TASK.OPEN_SEQUENCE_TASK(sequenceID)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_StalkingPervert, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_StalkingPervert, true)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
        i_StalkingPervert,
        playerPed,
        3.0,
        3.0,
        3.0,
        20.0,
        -1,
        10.0,
        true
    )

    Await(Game.RequestAnimDict, "switch@trevor@jerking_off")
    TASK.TASK_PLAY_ANIM(
        i_StalkingPervert,
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

    TASK.SET_SEQUENCE_TO_REPEAT(sequenceID, true)
    TASK.TASK_PERFORM_SEQUENCE(i_StalkingPervert, sequenceID)
    TASK.CLEAR_SEQUENCE_TASK(sequenceID)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(0x55446010)
    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(i_StalkingPervert)
end

Disable_E = function()
    PAD.DISABLE_CONTROL_ACTION(0, 38, true)
    PAD.DISABLE_CONTROL_ACTION(0, 46, true)
    PAD.DISABLE_CONTROL_ACTION(0, 51, true)
    PAD.DISABLE_CONTROL_ACTION(0, 206, true)
end

---@param s script_util
function CobraManeuver(s)
    if not Self.IsDriving() or not Self.Vehicle.IsPlane then
        return
    end

    if Self.Vehicle.Altitude < 500 then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Altitude too low to perform a Cobra Maneuver!"
        )
        return
    end

    if Self.Vehicle.Speed < 50 then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Your speed is too slow to perform a Cobra Maneuver!"
        )
        return
    end

    local veh = Self.Vehicle.Current
    local startRot = Game.GetEntityRotation(veh, 2)
    local currentPitch = startRot.x

    if (startRot.x <= -6) or (startRot.y <= -20) or (startRot.y >= 20) then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Please level your jet first."
        )
        return
    end

    FlareCountermeasures:Deploy()

    local pitchDelta = 89.0
    local targetPitch = currentPitch + pitchDelta

    if currentPitch < -10.0 then
        targetPitch = 85.0
    elseif currentPitch > 10.0 then
        targetPitch = math.min(currentPitch + 50.0, 85.0)
    else
        targetPitch = 85.0
    end

    local targetRot = vec3:new(targetPitch, startRot.y, startRot.z)
    local steps = 500

    for i = 1, steps do
        if SS.IsAnyKeyPressed() then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "Cobra Maneuver was interrupted! Giving control back to the player."
            )
            return
        end

        local alpha = i / steps * 5
        local lastRot = Game.GetEntityRotation(veh, 2)
        local newRot = startRot:lerp(targetRot, alpha)

        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 88, 1.0)
        ENTITY.SET_ENTITY_ROTATION(
            veh,
            newRot.x,
            newRot.y,
            newRot.z,
            2,
            true
        )

        local velocity = ENTITY.GET_ENTITY_VELOCITY(veh)
        if i == math.floor(steps / 50) then
            local backwardImpulse = vec3:new(
                -velocity.x * 1.5,
                -velocity.y * 1.5,
                0.0
            )

            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
                veh,
                1,
                backwardImpulse.x,
                backwardImpulse.y,
                backwardImpulse.z,
                true,
                true,
                true,
                true
            )

            ENTITY.SET_ENTITY_VELOCITY(
                veh,
                velocity.x * 0.2,
                velocity.y * 0.2,
                velocity.z * 0.2
            )
        end

        s:sleep(10)

        if newRot.x >= (targetPitch - 0.1) and velocity.y <= 10 then
            s:sleep(500)
            break
        end
    end

    for _ = 1, 100 do
        if SS.IsAnyKeyPressed() then
            YimToast:ShowWarning(
                "Samurai's Scripts",
                "Cobra Maneuver was interrupted! Giving control back to the player."
            )
            return
        end

        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 87, 1.0)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 110, -1.0)
        yield()
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
    Await(Game.RequestWeaponAsset, 3800181289)
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
        Await(Game.RequestAnimDict, "mp_missheist_countrybank@lift_hands")
        TASK.TASK_PLAY_ANIM(
            Self.GetPedID(),
            "mp_missheist_countrybank@lift_hands",
            "lift_hands_in_air_outro",
            4.0,
            -4.0,
            -1,
            50,
            1.0,
            false,
            false,
            false
        )
    end)
end

---@param ped integer
function AttachPed(ped)
    local myBone = PED.GET_PED_BONE_INDEX(Self.GetPedID(), 6286)
    script.run_in_fiber(function(ap)
        if not b_PedGrabbed and not PED.IS_PED_A_PLAYER(ped) then
            if not entities.take_control_of(ped, 300) then
                YimToast:ShowError("Samurai's Scripts", _T("NPC_CTRL_FAIL_"))
                return
            end

            YimActions:Cleanup()
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(
                ped,
                Self.GetPedID(),
                myBone,
                0.35,
                0.3,
                -0.04,
                100.0,
                90.0,
                -10.0,
                false,
                true,
                false,
                true,
                1,
                true,
                1
            )

            b_PedGrabbed = true
            i_GrabbedPed = ped
        end
    end)

    return b_PedGrabbed, i_GrabbedPed
end

---@param veh integer
function AttachVeh(veh)
    local attach_X
    local veh_class = Game.Vehicle.Class(veh)
    local myBone = PED.GET_PED_BONE_INDEX(Self.GetPedID(), 6286)
    script.run_in_fiber(function(av)
        if not b_VehicleGrabbed and not VEHICLE.IS_THIS_MODEL_A_TRAIN(veh_model) then
            if not entities.take_control_of(veh, 300) then
                YimToast:ShowError("Samurai's Scripts", _T("NPC_CTRL_FAIL_"))
                return false, 0
            end

            YimActions:Cleanup()

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

            b_VehicleGrabbed = true
            i_GrabbedVeh     = veh
        end
    end)

    return b_VehicleGrabbed, i_GrabbedVeh
end

---@param t_LookupTable table
---@param key string | number
---@param value any
table.MatchByKey = function(t_LookupTable, key, value)
    if not t_LookupTable or (#t_LookupTable == 0) then
        return false
    end

    for i = 1, #t_LookupTable do
        if t_LookupTable[i][key] == value then
            return true
        end
    end

    return false
end

---@param t table
---@param value any
table.Find = function(t, value)
    if #t == 0 then
        return false
    end

    for i = 1, table.GetLength(t) do
        if type(t[i]) == "table" then
            return table.Find(t[i], value)
        else
            if type(t[i]) == type(value) then
                if t[i] == value then
                    return true
                end
            end
        end
    end

    return false
end

-- Serializes tables in pretty format and accounts for circular reference.
---@param tbl table
---@param indent? number
---@param key_order? table
---@param seen? table
table.Serialize = function(tbl, indent, key_order, seen)
    indent = indent or 0
    seen = seen or {}

    if seen[tbl] then
        return '"<circular reference>"'
    end

    seen[tbl] = true

    local function get_indent(level)
        return string.rep(" ", level)
    end

    local is_array = #tbl > 0
    local pieces = {}

    local function find(t, val)
        for _, v in ipairs(t) do
            if v == val then
                return true
            end
        end
        return false
    end

    local function is_empty_table(t)
        return type(t) == "table" and next(t) == nil
    end

    local function serialize_value(v, depth)
        if type(v) == "string" then
            return string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" then
            return tostring(v)
        elseif type(v) == "table" then
            if is_empty_table(v) then
                return "{}"
            elseif seen[v] then
                return '"<circular reference>"'
            else
                return table.Serialize(v, depth, key_order, seen)
            end
        else
            return "\"<unsupported>\""
        end
    end

    table.insert(pieces, get_indent(indent) .. "{\n")

    local keys = {}

    if is_array then
        for i = 1, #tbl do
            table.insert(keys, i)
        end
    else
        if key_order then
            for _, k in ipairs(key_order) do
                if tbl[k] ~= nil then
                    table.insert(keys, k)
                end
            end

            for k in pairs(tbl) do
                if not find(keys, k) then
                    table.insert(keys, k)
                end
            end
        else
            for k in pairs(tbl) do
                table.insert(keys, k)
            end

            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)
        end
    end

    for _, k in ipairs(keys) do
        local v = tbl[k]
        local ind = get_indent(indent + 1)

        if is_array then
            table.insert(pieces, ind .. serialize_value(v, indent + 1) .. ",\n")
        else
            local key
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                key = k
            else
                key = "[" .. serialize_value(k, indent + 1) .. "]"
            end

            table.insert(pieces, ind .. key .. " = " .. serialize_value(v, indent + 1) .. ",\n")
        end
    end

    table.insert(pieces, get_indent(indent) .. "}")
    return table.concat(pieces)
end

-- Returns the number of values in a table. Doesn't count nil fields.
---@param t table
---@return number
table.GetLength = function(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Returns the number of duplicate items in a table.
---@param t table
---@param value string | number | integer | table
table.GetDuplicates = function(t, value)
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
table.RemoveDuplicates = function(t, debug)
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

---@param b64 string
---@param index number
Lua_fn.wrap_b64_string = function(b64, index)
    local out = {}

    for i = 1, #b64, index do
        table.insert(out, b64:sub(i, i + index - 1))
    end

    return table.concat(out, "\n")
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

--
-- Bitwise Operations
--

---@param num number
---@param pos number
Lua_fn.get_bit = function(num, pos)
    return (num & (1 << pos)) >> pos
end

---@param num number
---@param pos number
Lua_fn.has_bit = function(num, pos)
    return (num & (1 << pos)) ~= 0
end

---@param num number
---@param pos number
---@return number
Lua_fn.set_bit = function(num, pos)
    return num | (1 << pos)
end

---@param num number
---@param pos number
---@return number
Lua_fn.clear_bit = function(num, pos)
    return num & ~(1 << pos)
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

---@param name string
---@param callback function
---@param ... any
UI.ConfirmPopup = function(name, callback, ...)
    if ImGui.BeginPopupModal(
            name,
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.AlwaysAutoResize
        ) then
        UI.ColoredText(_T("CONFIRM_PROMPT_"), "yellow", 1, 30)
        ImGui.Spacing()

        if ImGui.Button(_T("GENERIC_YES_"), 80, 30) then
            UI.WidgetSound("Select")
            callback(...)
            ImGui.CloseCurrentPopup()
        end

        ImGui.SameLine()
        ImGui.Spacing()
        ImGui.SameLine()

        if ImGui.Button(_T("GENERIC_NO_"), 80, 30) then
            UI.WidgetSound("Cancel")
            ImGui.CloseCurrentPopup()
        end

        ImGui.EndPopup()
        return true
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
UI.SetClipBoardText = function(text, cond)
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

---@param window_name string
---@param keybind table
---@param isController? boolean
UI.HotkeyPrompt = function(window_name, keybind, isController)
    ImGui.BulletText(window_name)

    local avail_x, _ = ImGui.GetContentRegionAvail()
    local configVal  = isController and gpad_keybinds or keybinds
    local configName = isController and "gpad_keybinds" or "keybinds"

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
        b_IsSettingHotkeys = true
    end

    ImGui.SameLine()
    ImGui.BeginDisabled(keybind.code == 0)
    if ImGui.Button(string.format("%s##%s", _T("GENERIC_UNBIND_LABEL_"), window_name)) then
        UI.WidgetSound("Delete")
        keybind.code, keybind.name = 0, "[Unbound]"
        CFG:SaveItem(configName, configVal)
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
        SS.SetHotkey(keybind, isController)
        ImGui.EndPopup()
    end
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
    s_CurrentMovementClipset = ""
    s_CurrentStrafeClipset   = ""
    s_CurrentWeaponMovement  = ""
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
            s_CurrentMovementClipset = mvmtclipset
        end

        if data.wmvmt then
            PED.SET_PED_WEAPON_MOVEMENT_CLIPSET(Self.GetPedID(), data.wmvmt)
            s_CurrentWeaponMovement = data.wmvmt
        end

        if data.strf then
            while not STREAMING.HAS_CLIP_SET_LOADED(data.strf) do
                STREAMING.REQUEST_CLIP_SET(data.strf)
                coroutine.yield()
            end
            PED.SET_PED_STRAFE_CLIPSET(Self.GetPedID(), data.strf)
            s_CurrentStrafeClipset = data.strf
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
    for _, v in ipairs(t_BikerBusinessIDs) do
        if table.Find(v.possible_ids, index) then
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

            locals.set_int("gb_contraband_buy", 621 + 5, 1)   -- 1.70 b3442 -- case -1: return "INVALID - UNSET";
            locals.set_int("gb_contraband_buy", 621 + 191, 6) -- 1.70 b3442 -- func_40 Local_621.f_191 = iParam0;
            locals.set_int("gb_contraband_buy", 621 + 192, 4) -- 1.70 b3442 -- func_15 Local_621.f_192 = iParam0;
        end)
    elseif script.is_active("fm_content_cargo") then
        script.execute_as_script("fm_content_cargo", function()
            if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
                YimToast:ShowError("Samurai's Scripts", "You are not host of this script.")
                return
            end

            local val = locals.get_int("fm_content_cargo", 5883 + 1 + 0) -- GENERIC_BITSET_I_WON -- 1.70 b3442 -- var uLocal_5883 = 4;
            if not Lua_fn.has_bit(val, 11) then
                val = Lua_fn.set_bit(val, 11)
                locals.set_int("fm_content_cargo", 5883 + 1 + 0, val)
            end
            locals.set_int("fm_content_cargo", 5979 + 1157, 3) -- EndReason -- 1.70 b3442 -- func_8 Local_5979.f_1157 = iParam0;
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
        if not b_HangarLoop then
            b_HangarLoop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT0") > 0 then
        if not b_Warehouse1Loop then
            b_Warehouse1Loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT1") > 0 then
        if not b_Warehouse2Loop then
            b_Warehouse2Loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT2") > 0 then
        if not b_Warehouse3Loop then
            b_Warehouse3Loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT3") > 0 then
        if not b_Warehouse4Loop then
            b_Warehouse4Loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_WHOUSE_SLOT4") > 0 then
        if not b_Warehouse5Loop then
            b_Warehouse5Loop = true
            s:sleep(300)
        end
    end
    if stats.get_int("MPX_PROP_FAC_SLOT0") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY0") < 100 then
        globals.set_int(FreemodeGlobal2 + 0 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT1") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY1") < 100 then
        globals.set_int(FreemodeGlobal2 + 1 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT2") and stats.get_int("MPX_MATTOTALFORFACTORY2") < 100 then
        globals.set_int(FreemodeGlobal2 + 2 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT3") and stats.get_int("MPX_MATTOTALFORFACTORY3") < 100 then
        globals.set_int(FreemodeGlobal2 + 3 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT4") and stats.get_int("MPX_MATTOTALFORFACTORY4") < 100 then
        globals.set_int(FreemodeGlobal2 + 4 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_PROP_FAC_SLOT5") and stats.get_int("MPX_MATTOTALFORFACTORY5") < 100 then
        globals.set_int(FreemodeGlobal2 + 5 + 1, 1)
        s:sleep(300)
    end
    if stats.get_int("MPX_XM22_LAB_OWNED") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY6") < 100 then
        globals.set_int(FreemodeGlobal2 + 6 + 1, 1)
        s:sleep(300)
    end
end

---@param keybind table
---@param isController? boolean
SS.SetHotkey = function(keybind, isController)
    local configName = isController and "gpad_keybinds" or "keybinds"
    local configVal = isController and gpad_keybinds or keybinds
    local reserved_lookup = isController and t_ReservedKeys.gpad or t_ReservedKeys.kb

    ImGui.Dummy(1, 10)

    if not key_name then
        b_ShouldAnimateLoadingLabel = true
        UI.ColoredText(string.format("%s%s", _T("INPUT_WAIT_TXT_"), s_LoadingLabel), "#FFFFFF", 0.75, 20)

        if isController then
            key_code, key_name = Game.GetKeyPressed()
        else
            _, key_code, key_name = SS.IsAnyKeyPressed()
        end
    else
        b_ShouldAnimateLoadingLabel = false

        for _, key in pairs(reserved_lookup) do
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

        if ImGui.Button(string.format(" %s ##keybind", _T("GENERIC_CLEAR_BTN_"))) then
            UI.WidgetSound("Cancel")
            key_code, key_name = nil, nil
        end
    end

    ImGui.Dummy(1, 10)

    if key_code and not _reserved then
        if ImGui.Button(string.format("%s##keybinds", _T("GENERIC_CONFIRM_BTN_"))) then
            UI.WidgetSound("Select")
            local oldKey = keybind.code
            keybind.code, keybind.name = key_code, string.format("[%s]", key_name)

            if not isController then
                KeyManager:UpdateKeybind(oldKey, {code = key_code, name = key_name})
            end

            CFG:SaveItem(configName, configVal)
            key_code, key_name = nil, nil
            b_IsSettingHotkeys = false
            ImGui.CloseCurrentPopup()
        end

        ImGui.SameLine()
        ImGui.Spacing()
        ImGui.SameLine()
    end

    if ImGui.Button(string.format("%s##keybinds", _T("GENERIC_CANCEL_BTN_"))) then
        UI.WidgetSound("Cancel")
        key_code, key_name = nil, nil
        b_ShouldAnimateLoadingLabel = false
        b_IsSettingHotkeys = false
        ImGui.CloseCurrentPopup()
    end
end

-- Seamlessly add/remove keyboard keybinds on script update without requiring a config reset.
SS.check_kb_keybinds = function()
    local kb_keybinds_list = DEFAULT_CONFIG.keybinds
    local t_len            = table.GetLength
    if t_len(keybinds) == t_len(kb_keybinds_list) then
        SS.debug('No new keyboard keybinds.')
        return
    end

    if t_len(keybinds) > t_len(kb_keybinds_list) then
        for k, _ in pairs(keybinds) do
            local kk = kb_keybinds_list[k]
            if kk == nil then -- removed keybind
                SS.debug('Removed keyboard keybind: ' .. tostring(keybinds[k]))
                keybinds[k] = nil
                CFG:SaveItem("keybinds", keybinds) -- save
                keybinds = CFG:ReadItem("keybinds") -- refresh
            end
        end
    else
        for k, _ in pairs(kb_keybinds_list) do
            local kk = keybinds[k]
            if kk == nil then -- new keybind
                SS.debug('Added keyboard keybind: ' .. tostring(k))
                keybinds[k] = kb_keybinds_list[k]
                CFG:SaveItem("keybinds", keybinds) -- save
                keybinds = CFG:ReadItem("keybinds") -- refresh
            end
        end
    end
end

-- Seamlessly add/remove controller keybinds on script update without requiring a config reset.
SS.check_gpad_keybinds = function()
    local gpad_keybinds_list = DEFAULT_CONFIG.gpad_keybinds
    local t_len              = table.GetLength
    if t_len(gpad_keybinds) == t_len(gpad_keybinds_list) then
        SS.debug('No new gamepad keybinds.')
        return
    end

    if t_len(gpad_keybinds) > t_len(gpad_keybinds_list) then
        for k, _ in pairs(gpad_keybinds) do
            local kk = gpad_keybinds_list[k]
            if kk == nil then -- removed keybind
                SS.debug('Removed gamepad keybind: ' .. tostring(gpad_keybinds[k]))
                gpad_keybinds[k] = nil
                CFG:SaveItem("gpad_keybinds", gpad_keybinds) -- save
                gpad_keybinds = CFG:ReadItem("gpad_keybinds") -- refresh
            end
        end
    else
        for k, _ in pairs(gpad_keybinds_list) do
            local kk = gpad_keybinds[k]
            if kk == nil then -- new keybind
                SS.debug('Added gamepad keybind: ' .. tostring(k))
                gpad_keybinds[k] = gpad_keybinds_list[k]
                CFG:SaveItem("gpad_keybinds", gpad_keybinds) -- save
                gpad_keybinds = CFG:ReadItem("gpad_keybinds") -- refresh
            end
        end
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
        not b_IsTyping and not
        b_IsSettingHotkeys and not
        Self.IsBrowsingApps() and not
        HUD.IS_MP_TEXT_CHAT_TYPING() and not
        HUD.IS_PAUSE_MENU_ACTIVE()
    )
end

---@param lookup_table? table
SS.DetachPlayerAttachments = function(lookup_table)
    local b_HadAttachments = false

    local function DetachEntity(entity)
        if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity, Self.GetPedID()) then
            b_HadAttachments = true
            ENTITY.DETACH_ENTITY(entity, true, true)
            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(entity)
        end
    end

    if lookup_table and #lookup_table > 0 then
        for i = #lookup_table, 1, -1 do
            DetachEntity(lookup_table[i])
            table.remove(lookup_table, i)
        end
    else
        for _, v in ipairs(entities.get_all_objects_as_handles()) do
            DetachEntity(v)
        end

        for _, p in ipairs(entities.get_all_peds_as_handles()) do
            DetachEntity(p)
        end

        for _, p in ipairs(entities.get_all_vehicles_as_handles()) do
            DetachEntity(p)
        end


        EntityForge:DetachAllEntities()
    end

    if not b_HadAttachments then
        YimToast:ShowMessage(
            "Samurai's Scripts",
            "There doesn't seem to be anything attached to us."
        )
    else
        YimToast:ShowSuccess(
            "Samurai's Scripts",
            "Attachments dropped."
        )
    end

    YimActions:Cleanup()
    b_VehicleGrabbed = false
    b_PedGrabbed = false
    i_GrabbedPed = 0
    i_GrabbedVeh = 0
end

-- Reverts changes done by the script.
SS.Cleanup = function()
    if Self.Vehicle.DeformMult
        and (math.type(self.DeformMult) == "float")
        and ((Self.Vehicle.Previous == 0) or (Self.Vehicle.Previous == Self.Vehicle.Current)) then
        Game.Vehicle.SetDeformation(Self.Vehicle.Current, Self.Vehicle.DeformMult)
        Self.Vehicle.DeformMult = nil
    end

    Self.Vehicle.IsEngineBrakeDisabled = false
    Self.Vehicle.HasKersBoost = false
    Self.Vehicle.IsOffroaderEnabled = false
    Self.Vehicle.HasRallyTires = false
    Self.Vehicle.IsTractionControlDisabled = false
    Self.Vehicle.IsLowSpeedWheelieEnabled = false

    if disable_waves then
        Game.World.DisableOceanWaves(false)
        disable_waves = false
    end

    if (autopilot_waypoint or autopilot_objective or autopilot_random) then
        TASK.CLEAR_PED_TASKS(Self.GetPedID())
        TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
        autopilot_waypoint, autopilot_objective, autopilot_random = false, false, false
    end

    if b_IsCommandsUIOpen then
        b_ShouldDrawCommandsUI = false
        b_IsCommandsUIOpen = false
        gui.override_mouse(false)
    end

    if VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Current) ~= 1 then
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(Self.Vehicle.Current, 1)
        VEHICLE.SET_VEHICLE_ALARM(Self.Vehicle.Current, false)
    end

    if b_EngineSoundChanged then
        AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(
            Self.Vehicle.Current,
            vehicles.get_vehicle_display_name(
                ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current)
            )
        )
        Game.Vehicle.SetAcceleration(Self.Vehicle.Current, 1.0)
        b_EngineSoundChanged = false
    end

    PreviewService:Clear()
    EntityForge:ForceCleanup()
    Flatbed:ForceCleanup()
    YimActions:ForceCleanup()
    Game.Audio:StopAllEmitters()

    for _, category in ipairs({ g_SpawnedEntities.objects, g_SpawnedEntities.peds, g_SpawnedEntities.vehicles }) do
        if next(category) ~= nil then
            for handle in pairs(category) do
                if ENTITY.DOES_ENTITY_EXIST(category[handle]) then
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(category[handle], true, true)
                    ENTITY.DELETE_ENTITY(category[handle])
                    category[handle] = nil
                end
            end
        end
    end
end

---@param s script_util
SS.OnSessionSwitch = function(s)
    if script.is_active("maintransition") then
        SS.Cleanup()
        repeat
            s:sleep(100)
        until not script.is_active("maintransition")
        s:sleep(1000)
        return
    end
end

---@param s script_util
SS.OnPlayerSwitch = function(s)
    if Self.IsSwitchingPlayers() and not script.is_active("maintransition") then
        SS.Cleanup()
        repeat
            s:sleep(100)
        until not Self.IsSwitchingPlayers()
        s:sleep(1000)
        return
    end
end

SS.UpdateNPCdriveTask = function()
    TASK.CLEAR_PED_TASKS(i_CarpoolDriver)
    TASK.CLEAR_PED_SECONDARY_TASK(i_CarpoolDriver)
    TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_CarpoolVehicle)
    TASK.TASK_VEHICLE_TEMP_ACTION(i_CarpoolDriver, i_CarpoolVehicle, 1, 500)

    if s_NpcDriveTask == "wp" or s_NpcDriveTask == "obj" then
        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(i_CarpoolDriver, i_CarpoolVehicle, v_NpcDriveDestination.x,
            v_NpcDriveDestination.y, v_NpcDriveDestination.z,
            i_CarpoolDefaultDrivingSpeed, i_CarpoolDrivingFlags, 100)
    else
        TASK.TASK_VEHICLE_DRIVE_WANDER(i_CarpoolDriver, i_CarpoolVehicle, i_CarpoolDefaultDrivingSpeed,
            i_CarpoolDrivingFlags)
    end

    YimToast:ShowMessage(
        "Samurai's Scripts",
        string.format(
            "NPC driving style changed to %s.", i_CarpoolDrivingStyleSwitch == 0 and "Normal" or "Aggressive"
        )
    )
end

SS.CrashLevels = {
    minor = {
        threshold = 10,
        healthDamage = 10,
        screenEffect = nil,
        kill = false
    },
    major = {
        threshold = fast_vehicles and 45 or 35,
        healthDamage = 35,
        screenEffect = "ULP_PLAYERWAKEUP",
        kill = false
    },
    fatal = {
        threshold = fast_vehicles and 70 or 45,
        healthDamage = 100,
        screenEffect = nil,
        kill = true -- you gon' die
    }
}

-- Better Car Crashes
SS.HandleVehicleCrash = function(level, vehicle)
    local occupants = Game.Vehicle.GetOccupants(vehicle)
    local config = SS.CrashLevels[level]

    if not config then
        return
    end

    if config.screenEffect and not GRAPHICS.ANIMPOSTFX_IS_RUNNING(config.screenEffect) then
        GRAPHICS.ANIMPOSTFX_PLAY(config.screenEffect, 5000, false)
    end

    if next(occupants) ~= nil then
        for _, ped in ipairs(occupants) do
            if config.kill then
                ENTITY.SET_ENTITY_HEALTH(ped, 0, 0, 0)
            else
                ENTITY.SET_ENTITY_HEALTH(ped, ENTITY.GET_ENTITY_HEALTH(ped) - config.healthDamage, 0, 0)
            end
        end
    end

    if level == "minor" then
        VEHICLE.SMASH_VEHICLE_WINDOW(vehicle, math.random(0, 3))
    elseif level == "major" then
        if Game.IsOnline() then
            local v_PlayerPos = Self.GetPos()
            local s_SoundName = (
                (Self.GetPedModel() == 0x705E61F2) and
                "WAVELOAD_PAIN_MALE" or
                "WAVELOAD_PAIN_FEMALE"
            )

            AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
                "SCREAM_PANIC_SHORT",
                s_SoundName,
                v_PlayerPos.x,
                v_PlayerPos.y,
                v_PlayerPos.z,
                "SPEECH_PARAMS_FORCE_SHOUTED"
            )
        end

        VEHICLE.SET_VEHICLE_DOOR_BROKEN(vehicle, math.random(-1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle)),
            true)
        VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, -0.69)
        Sleep(500)
        VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, 0.69)
        Sleep(500)
        VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, 0)
    elseif level == "fatal" then
        for i = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) do
            VEHICLE.SET_VEHICLE_DOOR_BROKEN(vehicle, i, true)
        end
    end
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
-- `EntityForge` and `YimActions`.
SS.ResetSettings = function()
    local ignoreKeys = {
        forged_entities = "",
        favorite_entities = "",
        yav3_favorites = "",
    }
    CFG:Reset(ignoreKeys)
end


---@param entity integer
---@param v_Min vec3
---@param v_Max vec3
SS.GetBoxCorners = function(entity, v_Min, v_Max)
    local corners = {}

    for x = 0, 1 do
        for y = 0, 1 do
            for z = 0, 1 do
                local v_Offset = vec3:new(
                    x == 0 and v_Min.x or v_Max.x,
                    y == 0 and v_Min.y or v_Max.y,
                    z == 0 and v_Min.z or v_Max.z
                )

                local v_WorldPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                    entity,
                    v_Offset.x,
                    v_Offset.y,
                    v_Offset.z
                )
                table.insert(corners, v_WorldPos)
            end
        end
    end

    return corners
end
--#endregion
