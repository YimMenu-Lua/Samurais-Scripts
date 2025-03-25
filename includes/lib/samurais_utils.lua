---@diagnostic disable: undefined-global, lowercase-global, undefined-doc-name, undefined-field, param-type-mismatch

--#region Global functions

GetGameVersion = function()
    local pVers = memory.scan_pattern("8B C3 33 D2 C6 44 24 20")
    local pBnum = pVers:add(0x24):rip()
    local pOver = pBnum:add(0x20)
    local ret = {
        _build  = pBnum:get_string(),
        _online = pOver:get_string()
    }
    return ret
end

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

-- Must be called from a coroutine. Input time is in seconds.
---@param s integer
sleep = function(s)
    local ntime = os.clock() + s
    while os.clock() < ntime do
        coroutine.yield()
    end
end

---@param ... number
---@return number
sum = function(...)
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

---@param ptr pointer
---@param size integer
function memory_hex_dump(ptr, size)
    local result = {}
    for i = 0, size - 1 do
        local byte = ptr:add(i):get_byte()
        table.insert(result, string.format("%02X", byte))
    end
    log.debug("Memory Dump: " .. table.concat(result, " "))
end

---@param ptr pointer
function memory_get_vec3(ptr)
    local x = ptr:get_float()
    local y = ptr:add(0x4):get_float()
    local z = ptr:add(0x8):get_float()
    return vec3:new(x, y, z)
end

---@param toggle boolean
---@param station? string
---@param entity? integer
play_music = function(toggle, station, entity)
    script.run_in_fiber(function(mp)
        if toggle then
            if not entity then
                entity = self.get_ped()
            end
            if not station then
                station = radio_stations[math.random(1, #radio_stations)].station
            end
            local coords      = ENTITY.GET_ENTITY_COORDS(entity, true)
            local bone_idx    = PED.GET_PED_BONE_INDEX(entity, 24818)
            local pbus_model  = 345756458
            local dummy_model = 0xE75B4B1C
            if Game.requestModel(pbus_model) then
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
                if Game.requestModel(dummy_model) then
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

dummyCop = function()
    script.run_in_fiber(function(dcop)
        if current_vehicle ~= nil and current_vehicle ~= 0 then
            local polhash, veh_bone1, veh_bone2, attach_mode
            if is_car then
                if VEHICLE.DOES_VEHICLE_HAVE_ROOF(current_vehicle) and not VEHICLE.IS_VEHICLE_A_CONVERTIBLE(current_vehicle, false) then
                    polhash, veh_bone1, veh_bone2, attach_mode = 0xD1E0B7D7, "interiorlight", "interiorlight", 1
                else
                    polhash, veh_bone1, veh_bone2, attach_mode = 0xD1E0B7D7, "interiorlight", "dashglow", 2
                end
            elseif is_bike or is_quad then
                polhash, veh_bone1, veh_bone2, attach_mode = 0xFDEFAEC3, "chassis_dummy", "chassis_dummy", 1
            else
                YimToast:ShowError("Samurais Scripts", "Can not equip a fake siren on this vehicle.")
            end
            if Game.requestModel(polhash) then
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
                    local boneidx2 = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, veh_bone2)
                    VEHICLE.SET_VEHICLE_LIGHTS(dummyCopCar, 1)
                    ENTITY.SET_ENTITY_HEADING(dummyCopCar, ENTITY.GET_ENTITY_HEADING(current_vehicle))
                    if attach_mode == 1 then
                        ENTITY.ATTACH_ENTITY_BONE_TO_ENTITY_BONE(dummyCopCar, current_vehicle, boneidx1, boneidx2, false,
                            true)
                    else
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(dummyCopCar, current_vehicle, boneidx2, 0.46, 0.4, -0.9, 0.0, 0.0,
                            0.0, false,
                            true,
                            false, true, 1, true, 1)
                    end
                    dcop:sleep(500)
                    VEHICLE.SET_VEHICLE_SIREN(dummyCopCar, true)
                    VEHICLE.SET_VEHICLE_HAS_MUTED_SIRENS(dummyCopCar, false)
                    AUDIO.TRIGGER_SIREN_AUDIO(dummyCopCar)
                    VEHICLE.SET_VEHICLE_ACT_AS_IF_HAS_SIREN_ON(current_vehicle, true)
                    VEHICLE.SET_VEHICLE_CAUSES_SWERVING(current_vehicle, true)
                    VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(current_vehicle, 0, true)
                    VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(current_vehicle, 1, true)
                    -- ENTITY.SET_ENTITY_VISIBLE(dummyCopCar, false, false) -- you can't see the lights anymore but the dummy police vehicle no longer appears to other players.
                end
            end
        end
    end)
end

checkVehicleCollision = function()
    if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) then
        local entity = ENTITY.GET_LAST_ENTITY_HIT_BY_ENTITY_(current_vehicle)
        if entity ~= nil and entity ~= 0 and ENTITY.DOES_ENTITY_EXIST(entity) then
            local entity_type = SS.getEntityType(entity)
            if entity_type == 6 then
                return false, "Hit and run"
            elseif entity_type == 5 or entity_type == 157 then
                return true, "Samir, you're breaking the car!"
            elseif entity_type == 1 or entity_type == 33 or entity_type == 7 then
                if ENTITY.DOES_ENTITY_HAVE_PHYSICS(entity) then
                    local model = ENTITY.GET_ENTITY_MODEL(entity)
                    for _, m in ipairs(collision_invalid_models) do
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

bankDriftPoints_SP = function(points)
    local chars_T <const> = {
        { hash = 225514697,  int = 0 },
        { hash = 2602752943, int = 1 },
        { hash = 2608926626, int = 2 },
    }
    script.run_in_fiber(function()
        for _, v in ipairs(chars_T) do
            if ENTITY.GET_ENTITY_MODEL(self.get_ped()) == v.hash then
                stats.set_int("SP" .. tostring(v.int) .. "_TOTAL_CASH",
                    stats.get_int("SP" .. tostring(v.int) .. "_TOTAL_CASH") + points)
                AUDIO.PLAY_SOUND_FRONTEND(-1, "LOCAL_PLYR_CASH_COUNTER_INCREASE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS",
                    true)
            end
        end
    end)
end

standUp = function()
    if is_sitting then
        ENTITY.DETACH_ENTITY(self.get_ped(), true, false)
        TASK.CLEAR_PED_TASKS(self.get_ped())
        if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
            ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
            thisSeat = 0
        end
        is_sitting = false
    end
end

---@param level integer
doWantedStars = function(level)
    local stars = ""
    if level == 0 then
        return "Clear"
    end
    for _ = 1, level do
        stars = stars .. " *"
    end
    return stars
end

spawnPervert = function(playerPed, playerName)
    if not Game.requestModel(0x55446010) then
        return
    end
    local sequenceID = 0
    local spawn_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        playerPed, math.random(3, 10), math.random(3, 10), 0.0
    )

    perv = PED.CREATE_PED(PED_TYPE._CIVMALE, 0x55446010, spawn_pos.x, spawn_pos.y, spawn_pos.z, math.random(1, 180), true,
        false)
    if ENTITY.DOES_ENTITY_EXIST(perv) then
        UI.widgetSound("Select")
        gui.show_success("Samurai's Scripts", string.format("Spawned a stalker pervert for %s.", playerName))
        TASK.OPEN_SEQUENCE_TASK(sequenceID)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(perv, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(perv, true)
        TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
            perv, playerPed, 3.0, 3.0, 3.0,
            20.0, -1, 10.0, true
        )
        if Game.requestAnimDict("switch@trevor@jerking_off") then
            TASK.TASK_PLAY_ANIM(
                perv, "switch@trevor@jerking_off", "trev_jerking_off_loop",
                4.0, -4.0, -1, 196665, 1.0, false, false, false
            )
        end
        TASK.SET_SEQUENCE_TO_REPEAT(sequenceID, true)
        TASK.TASK_PERFORM_SEQUENCE(perv, sequenceID)
        TASK.CLEAR_SEQUENCE_TASK(sequenceID)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(0x55446010)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(perv)
    else
        UI.widgetSound("Error")
        YimToast:ShowError("Samurai's Scripts", string.format("Failed to spawn a stalker pervert for %s.", playerName))
    end
end

Disable_E = function()
    PAD.DISABLE_CONTROL_ACTION(0, 38, true)
    PAD.DISABLE_CONTROL_ACTION(0, 46, true)
    PAD.DISABLE_CONTROL_ACTION(0, 51, true)
    PAD.DISABLE_CONTROL_ACTION(0, 206, true)
end

updatefilteredAnims = function()
    filteredAnims = {}
    for _, anim in ipairs(animlist) do
        if anim_sortby_idx == 0 then
            if string.find(string.lower(anim.name), string.lower(actions_search)) then
                table.insert(filteredAnims, anim)
            end
        else
            if anim.cat == animSortbyList[anim_sortby_idx + 1] then
                if string.find(string.lower(anim.name), string.lower(actions_search)) then
                    table.insert(filteredAnims, anim)
                end
            end
        end
    end
    table.sort(animlist, function(a, b)
        return a.name < b.name
    end)
end

displayFilteredAnims = function()
    updatefilteredAnims()
    local animNames = {}
    for _, anim in ipairs(filteredAnims) do
        table.insert(animNames, anim.name)
    end
    anim_index, used = ImGui.ListBox("##animlistbox", anim_index, animNames, #filteredAnims)
end

updatefilteredScenarios = function()
    filteredScenarios = {}
    for _, scene in ipairs(ped_scenarios) do
        if string.find(string.lower(scene.name), string.lower(actions_search)) then
            table.insert(filteredScenarios, scene)
        end
    end
end

displayFilteredScenarios = function()
    updatefilteredScenarios()
    local scenarioNames = {}
    for _, scene in ipairs(filteredScenarios) do
        table.insert(scenarioNames, scene.name)
    end
    scenario_index, used = ImGui.ListBox("##scenarioList", scenario_index, scenarioNames, #filteredScenarios)
end

updateRecentlyPlayed = function()
    filteredRecents = {}
    for _, v in ipairs(recently_played_a) do
        if string.find(string.lower(v.name), string.lower(actions_search)) then
            table.insert(filteredRecents, v)
        end
    end
end

displayRecentlyPlayed = function()
    updateRecentlyPlayed()
    local recentNames = {}
    for _, v in ipairs(filteredRecents) do
        local recentName = v.name
        if v.dict ~= nil then
            recentName = string.format("[Animation]  %s", recentName)
        elseif v.scenario ~= nil then
            recentName = string.format("[Scenario]    %s", recentName)
        end
        table.insert(recentNames, recentName)
    end
    recents_index, used = ImGui.ListBox("##recentsList", recents_index, recentNames, #filteredRecents)
end

updateFavoriteActions = function()
    filteredFavs = {}
    for _, v in ipairs(favorite_actions) do
        if string.find(string.lower(v.name), string.lower(actions_search)) then
            table.insert(filteredFavs, v)
        end
    end
end

displayFavoriteActions = function()
    updateFavoriteActions()
    local favNames = {}
    for _, v in ipairs(filteredFavs) do
        local favName = v.name
        if v.dict ~= nil then
            favName = string.format("[Animation]  %s", favName)
        elseif v.scenario ~= nil then
            favName = string.format("[Scenario]    %s", favName)
        end
        table.insert(favNames, favName)
    end
    fav_actions_index, used = ImGui.ListBox("##favsList", fav_actions_index, favNames, #filteredFavs)
end

decodeJsonMvmts = function()
    if io.exists("movementClipsetsCompact.json") then
        local jsonFile = io.open("movementClipsetsCompact.json", "r")
        if jsonFile then
            local content = jsonFile:read("*all")
            if not content or #content == 0 then
                YimToast:ShowError("Samurai's Scripts",
                    "Failed to read Json data. The file is either empty or corrupted!")
                jsonMvmt = false
                return
            end
            jsonFile:flush()
            jsonFile:close()
            return CFG:Decode(content)
        end
    end
end

displayMvmts = function()
    mvmtNames = {}
    if jsonMvmt then
        if not jsonMvmts_t or #jsonMvmts_t == 0 then
            jsonMvmts_t = decodeJsonMvmts()
        else
            ---@diagnostic disable-next-line
            for _, v in ipairs(jsonMvmts_t) do
                if string.find((v.Name):lower(), jsonMvmtSearch:lower()) then
                    table.insert(mvmtNames, v)
                end
            end
            ImGui.SetNextItemWidth(380)
            jsonMvmtSearch, typed = ImGui.InputTextWithHint("##mvmtsearch", "Search", jsonMvmtSearch, 128)
            is_typing = ImGui.IsItemActive()
            if ImGui.BeginListBox("##jsonmvmtNames", 400, 100) then
                for i = 1, #mvmtNames do
                    local is_selected = (mvmt_index == i)
                    if ImGui.Selectable(mvmtNames[i].Name, is_selected) then
                        mvmt_index = i
                    end
                    if UI.isItemClicked("lmb") then
                        SS.setMovement(mvmtNames[i], true)
                    end
                end
                ImGui.EndListBox()
            end
        end
    else
        for _, v in ipairs(movement_options_t) do
            table.insert(mvmtNames, v.name)
        end
        ImGui.SetNextItemWidth(220)
        mvmt_index, mvmtSelected = ImGui.Combo("##mvmt", mvmt_index, mvmtNames, #movement_options_t)
        if mvmtSelected then
            SS.setMovement(movement_options_t[mvmt_index + 1], false)
        end
    end
end

updateNpcs = function()
    filteredNpcs = {}
    for _, npc in ipairs(npcList) do
        table.insert(filteredNpcs, npc)
    end
    table.sort(filteredNpcs, function(a, b)
        return a.name < b.name
    end)
end

displayNpcs = function()
    updateNpcs()
    local npcNames = {}
    for _, npc in ipairs(filteredNpcs) do
        table.insert(npcNames, npc.name)
    end
    npc_index, used = ImGui.Combo("##npcList", npc_index, npcNames, #filteredNpcs)
end

---@return number
setAnimFlags = function()
    local flag_loop      = Lua_fn.condReturn(looped, AF._LOOPING, 0)
    local flag_freeze    = Lua_fn.condReturn(freeze, AF._HOLD_LAST_FRAME, 0)
    local flag_upperbody = Lua_fn.condReturn(upperbody, AF._UPPERBODY, 0)
    local flag_control   = Lua_fn.condReturn(controllable, AF._SECONDARY, 0)
    local flag_collision = Lua_fn.condReturn(noCollision, AF._TURN_OFF_COLLISION, 0)
    local flag_killOnEnd = Lua_fn.condReturn(killOnEnd, AF._ENDS_IN_DEAD_POSE, 0)
    return sum(flag_loop, flag_freeze, flag_upperbody, flag_control, flag_collision, flag_killOnEnd)
end

onAnimInterrupt = function()
    if is_playing_anim and Game.Self.isAlive() and not SS.isKeyJustPressed(keybinds.stop_anim.code)
        and not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), curr_playing_anim.dict, curr_playing_anim.anim, 3) then
        if Game.requestAnimDict(curr_playing_anim.dict) then
            local curr_flag = manualFlags and anim_flag or curr_playing_anim.flag
            TASK.CLEAR_PED_TASKS(self.get_ped())
            TASK.TASK_PLAY_ANIM(self.get_ped(), curr_playing_anim.dict, curr_playing_anim.anim, 4.0, -4.0, -1,
                curr_flag, 1.0, false, false, false)
        end
    end
end

displayMaleSounds = function()
    filteredMaleSounds = {}
    for _, v in ipairs(male_sounds_T) do
        table.insert(filteredMaleSounds, v.name)
    end
    sound_index1, used = ImGui.Combo("##maleSounds", sound_index1, filteredMaleSounds, #male_sounds_T)
end

displayFemaleSounds = function()
    filteredFemaleSounds = {}
    for _, v in ipairs(female_sounds_T) do
        table.insert(filteredFemaleSounds, v.name)
    end
    sound_index2, used = ImGui.Combo("##femaleSounds", sound_index2, filteredFemaleSounds, #female_sounds_T)
end

displayRadioStations = function()
    filteredRadios = {}
    for _, v in ipairs(radio_stations) do
        table.insert(filteredRadios, v.name)
    end
    radio_index, used = ImGui.Combo("##radioStations", radio_index, filteredRadios, #radio_stations)
end

filterVehNames = function()
    filteredNames = {}
    for _, veh in ipairs(gta_vehicles_T) do
        if VEHICLE.IS_THIS_MODEL_A_CAR(joaat(veh)) or VEHICLE.IS_THIS_MODEL_A_BIKE(joaat(veh)) or VEHICLE.IS_THIS_MODEL_A_QUADBIKE(joaat(veh)) then
            valid_veh = veh
            if string.find(valid_veh:lower(), search_term:lower()) then
                table.insert(filteredNames, valid_veh)
            end
        end
    end
end

displayVehNames = function()
    filterVehNames()
    local vehNames = {}
    for _, veh in ipairs(filteredNames) do
        local vehName = vehicles.get_vehicle_display_name(joaat(veh))
        if string.find(string.lower(veh), "drift") then
            vehName = string.format("%s  (Drift)", vehName)
        end
        table.insert(vehNames, vehName)
    end
    vehSound_index, used = ImGui.ListBox("##Vehicle Names", vehSound_index, vehNames, #filteredNames)
end

resetLastVehState = function()
    if (
        (last_vehicle > 0) and
        ENTITY.DOES_ENTITY_EXIST(last_vehicle) and
        ENTITY.IS_ENTITY_A_VEHICLE(last_vehicle)
    ) then
        if loud_radio_enabled then
            AUDIO.SET_VEHICLE_RADIO_LOUD(last_vehicle, false)
            loud_radio_enabled = false
        end

        if not has_custom_tires then
            VEHICLE.TOGGLE_VEHICLE_MOD(last_vehicle, 20, false)
        end

        if (
            (default_tire_smoke.r ~= driftSmoke_T.r) or
            (default_tire_smoke.g ~= driftSmoke_T.g) or
            (default_tire_smoke.b ~= driftSmoke_T.b)
        ) then
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(
                last_vehicle,
                default_tire_smoke.r,
                default_tire_smoke.g,
                default_tire_smoke.b
            )
        end

        if (
            VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(last_vehicle)) and
            (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(last_vehicle) ~= 1)
        ) then
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(last_vehicle, 1)
            VEHICLE.SET_VEHICLE_ALARM(last_vehicle, false)
        end

        if ubwindowsToggled then
            VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(last_vehicle, false)
            ubwindowsToggled = false
        end
    end
    last_vehicle = current_vehicle
end

onVehEnter = function()
    current_vehicle = self.get_veh()
    if (
        Game.Self.isDriving() and
        (is_car or is_bike or is_quad) and
        VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle)
    ) then
        engine_brake_disabled  = SS.getVehicleHandlingFlag(HF._FREEWHEEL_NO_GAS)
        traction_ctrl_disabled = SS.getVehicleHandlingFlag(HF._FORCE_NO_TC_OR_SC)
        kers_boost_enabled     = SS.getVehicleHandlingFlag(HF._HAS_KERS)
        offroader_enabled      = SS.getVehicleHandlingFlag(HF._OFFROAD_ABILITIES_X2)
        rally_tires_enabled    = SS.getVehicleHandlingFlag(HF._HAS_RALLY_TYRES)
        easy_wheelie_enabled   = SS.getVehicleHandlingFlag(HF._LOW_SPEED_WHEELIES)
    end

    if Game.Self.isDriving() and (current_vehicle ~= last_vehicle) then
        resetLastVehState()
    end

    return current_vehicle
end

---@param s script_util
shoot_flares = function(s)
    if Game.requestWeaponAsset(0x47757124) then
        for _, bone in pairs(plane_bones_T) do
            local bone_idx  = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(self.get_veh(), bone)
            local jet_fwd_X = ENTITY.GET_ENTITY_FORWARD_X(self.get_veh())
            local jet_fwd_Y = ENTITY.GET_ENTITY_FORWARD_Y(self.get_veh())
            if bone_idx ~= -1 then
                local bone_pos = ENTITY.GET_ENTITY_BONE_POSTION(self.get_veh(), bone_idx)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
                    ((bone_pos.x + 0.01) + (jet_fwd_X / 1.13)), ((bone_pos.y + 0.01) + jet_fwd_Y / 1.13), bone_pos.z,
                    ((bone_pos.x - 0.01) - (jet_fwd_X / 1.13)), ((bone_pos.y - 0.01) - jet_fwd_Y / 1.13),
                    bone_pos.z + 0.06,
                    1.0, false, 0x47757124, self.get_ped(), true, false, 100.0
                )
                AUDIO.PLAY_SOUND_FRONTEND(-1, "HIT_OUT", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
                s:sleep(250)
            end
        end
    end
end

---@param bool boolean
---@param startPos vec3
---@param endPos_1 vec3
---@param endPos_2 vec3
---@param color table
draw_laser = function(bool, startPos, endPos_1, endPos_2, color)
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
shoot_cannon = function(enemiesOnly, entity, coords)
    if ENTITY.DOES_ENTITY_EXIST(entity) and (ENTITY.IS_ENTITY_A_VEHICLE(entity) or ENTITY.IS_ENTITY_A_PED(entity)) and not
        ENTITY.IS_ENTITY_DEAD(entity, false) then
        if not enemiesOnly then
            VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(self.get_ped(), entity, coords.x, coords.y, coords.z)
        else
            if ENTITY.IS_ENTITY_A_PED(entity) then
                if Game.Self.isPedEnemy(entity) and not ENTITY.IS_ENTITY_DEAD(entity, false) then
                    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(self.get_ped(), entity, coords.x, coords.y, coords.z)
                end
            elseif ENTITY.IS_ENTITY_A_VEHICLE(entity) then
                if Game.Vehicle.isEnemyVehicle(entity) then
                    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(self.get_ped(), entity, coords.x, coords.y, coords.z)
                end
            end
        end
    end
end

---@param src vec3
---@param dest vec3
---@param dmg number
---@param owner integer
---@param speed number
shoot_explosive_mg = function(src, dest, dmg, owner, speed)
    if Game.requestWeaponAsset(3800181289) then
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
            src.x, src.y, src.z,
            dest.x, dest.y, dest.z,
            dmg, false, 3800181289, owner, true, false, speed
        )
    end
end

sortCustomPaints = function()
    filteredPaints = {}
    for _, v in ipairs(custom_paints_T) do
        if paints_sortby_switch == 0 then
            if paints_col_sort_idx == 0 then
                if string.find((v.name):lower(), custom_paints_sq:lower()) then
                    table.insert(filteredPaints, v)
                end
            else
                if v.shade == paints_sortByColors[paints_col_sort_idx + 1] then
                    if string.find((v.name):lower(), custom_paints_sq:lower()) then
                        table.insert(filteredPaints, v)
                    end
                end
            end
        elseif paints_sortby_switch == 1 then
            if paints_mfr_sort_idx == 0 then
                if string.find((v.name):lower(), custom_paints_sq:lower()) then
                    table.insert(filteredPaints, v)
                end
            else
                if v.manufacturer == paints_sortByMfrs[paints_mfr_sort_idx + 1] then
                    if string.find((v.name):lower(), custom_paints_sq:lower()) then
                        table.insert(filteredPaints, v)
                    end
                end
            end
        end
    end
    table.sort(filteredPaints, function(a, b)
        return a.name < b.name
    end)
end

displayCustomPaints = function()
    sortCustomPaints()
    local customPaintNames = {}
    for _, v in ipairs(filteredPaints) do
        table.insert(customPaintNames, v.name)
    end
    custom_paint_index, isChanged = ImGui.ListBox("##customPaintsList", custom_paint_index, customPaintNames,
        #filteredPaints)
end

showPaintsCount = function()
    if filteredPaints ~= nil then
        ImGui.Text(string.format("[ %d ]", #filteredPaints))
    else
        ImGui.Text("[ 0 ]")
    end
end

listVehicles = function()
    vehicle_list   = {}
    local this_veh = {}
    for _, veh in ipairs(gta_vehicles_T) do
        local vehicle_hash = joaat(veh)
        local displayName  = vehicles.get_vehicle_display_name(veh)
        this_veh           = { hash = vehicle_hash, name = displayName }
        table.insert(vehicle_list, this_veh)
    end
end

updatefilteredVehicles = function()
    listVehicles()
    filtered_vehicles = {}
    for _, veh in ipairs(vehicle_list) do
        if string.find(string.lower(veh.name), vCreator_searchQ:lower()) then
            table.insert(filtered_vehicles, veh)
        end
    end
    table.sort(filtered_vehicles, function(a, b)
        return a.name < b.name
    end)
end

displayFilteredList = function()
    updatefilteredVehicles()
    vehicle_names = {}
    for _, veh in ipairs(filtered_vehicles) do
        local displayName = veh.name
        if string.find(string.lower(displayName), "drift") then
            displayName = string.format("%s  (Drift)", displayName)
        end
        table.insert(vehicle_names, displayName)
    end
    vehicle_index, _ = ImGui.ListBox("##vehList", vehicle_index, vehicle_names, #filtered_vehicles)
end

showAttachedVehicles = function()
    attachment_names = {}
    for _, veh in pairs(veh_attachments) do
        table.insert(attachment_names, veh.name)
    end
    attachment_index, _ = ImGui.Combo("##attached_vehs", attachment_index, attachment_names, #veh_attachments)
end

filterSavedVehicles = function()
    filteredCreations = {}
    if saved_vehicles[1] ~= nil then
        for _, t in pairs(saved_vehicles) do
            table.insert(filteredCreations, t)
        end
    end
end

showSavedVehicles = function()
    filterSavedVehicles()
    for _, veh in pairs(filteredCreations) do
        table.insert(persist_names, veh.name)
    end
    persist_index, _ = ImGui.ListBox("##persist_vehs", persist_index, persist_names, #filteredCreations)
end

appendVehicleMods = function(v, t)
    script.run_in_fiber(function()
        for i = 0, 49 do
            table.insert(t, VEHICLE.GET_VEHICLE_MOD(v, i))
        end
    end)
end

setVehicleMods = function(v, t)
    script.run_in_fiber(function()
        VEHICLE.SET_VEHICLE_MOD_KIT(v, 0)
        for slot, mod in pairs(t) do
            VEHICLE.SET_VEHICLE_MOD(v, (slot - 1), mod, true)
        end
    end)
end

---@param main integer
---@param mods table
---@param col_1 table
---@param col_2 table
---@param attachments table
spawnPersistVeh = function(main, mods, col_1, col_2, tint, attachments)
    script.run_in_fiber(function()
        local Pos      = self.get_pos()
        local forwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
        local forwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
        local heading  = ENTITY.GET_ENTITY_HEADING(self.get_ped())
        if Game.requestModel(main) then
            spawned_persist = VEHICLE.CREATE_VEHICLE(main, Pos.x + (forwardX * 7), Pos.y + (forwardY * 7), Pos.z, heading,
                true,
                false, false)
            VEHICLE.SET_VEHICLE_IS_STOLEN(spawned_persist, false)
            DECORATOR.DECOR_SET_INT(spawned_persist, "MPBitset", 0)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(spawned_persist, col_1.r, col_1.g, col_1.b)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(spawned_persist, col_2.r, col_2.g, col_2.b)
            setVehicleMods(spawned_persist, mods)
            VEHICLE.SET_VEHICLE_WINDOW_TINT(spawned_persist, tint)
        end
        for _, att in ipairs(attachments) do
            if Game.requestModel(att.hash) then
                local attach = VEHICLE.CREATE_VEHICLE(att.hash, Pos.x + (forwardX * 7), Pos.y + (forwardY * 7), Pos.z,
                    heading,
                    true, false, false)
                VEHICLE.SET_VEHICLE_IS_STOLEN(attach, false)
                DECORATOR.DECOR_SET_INT(attach, "MPBitset", 0)
                VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(attach, att.color_1.r, att.color_1.g, att.color_1.b)
                VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(attach, att.color_2.r, att.color_2.g, att.color_2.b)
                setVehicleMods(attach, att.mods)
                VEHICLE.SET_VEHICLE_WINDOW_TINT(attach, att.tint)
                if ENTITY.DOES_ENTITY_EXIST(spawned_persist) and ENTITY.DOES_ENTITY_EXIST(attach) then
                    local Bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(spawned_persist, "chassis_dummy")
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(attach, spawned_persist, Bone, att.posx, att.posy, att.posz, att.rotx,
                        att.roty,
                        att.rotz, false, false, false, false, 2, true, 1)
                end
            end
        end
    end)
end

createWideBodyCivic = function()
    vehicle_creation = {
        name = "Widebody Civic",
        main_veh = 1074745671,
        mods = {},
        color_1 = { r = 0, g = 0, b = 0 },
        color_2 = { r = 0, g = 0, b = 0 },
        tint = 1,
        attachments = {
            {
                entity = 0,
                hash = 987469656,
                posx = 0.0,
                posy = -0.075,
                posz = 0.076,
                rotx = 0.0,
                roty = 0.0,
                rotz = 0.0,
                mods = { 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 3, 2, 2, -1, 4, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
                color_1 = { r = 0, g = 0, b = 0 },
                color_2 = { r = 0, g = 0, b = 0 },
                tint = 1,
            }
        }
    }
    table.insert(saved_vehicles, vehicle_creation)
    CFG:SaveItem("saved_vehicles", saved_vehicles)
    vehicle_creation = {}
end

resetOnSave = function()
    vehicleName       = ""
    creation_name     = ""
    main_vehicle_name = ""
    veh_axisMult      = 1
    vehicle_index     = 0
    persist_index     = 0
    spawned_veh_index = 0
    vehicleHash       = 0
    spawned_vehicle   = 0
    main_vehicle      = 0
    attachment_index  = 0
    selected_attchmnt = 0
    veh_attach_X      = 0.0
    veh_attach_Y      = 0.0
    veh_attach_Z      = 0.0
    veh_attach_RX     = 0.0
    veh_attach_RY     = 0.0
    veh_attach_RZ     = 0.0
    spawned_vehicles  = {}
    spawned_vehNames  = {}
    filteredVehNames  = {}
    persist_names     = {}
    veh_attachments   = {}
    attachment_names  = {}
    attached_vehicles = {}
    vehicle_creation  = { name = "", main_veh = 0, mods = {}, color_1 = { r = 0, g = 0, b = 0 }, color_2 = { r = 0, g = 0, b = 0 }, tint = 0, attachments = {} }
end

set_poker_cards = function(player_id, players_current_table, card_one, card_two, card_three)
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

get_cardname_from_index = function(card_index)
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

function playHandsUp()
    script.run_in_fiber(function()
        if Game.requestAnimDict("mp_missheist_countrybank@lift_hands") then
            TASK.TASK_PLAY_ANIM(self.get_ped(), "mp_missheist_countrybank@lift_hands", "lift_hands_in_air_outro", 4.0,
                -4.0, -1,
                50, 1.0, false, false, false)
        end
    end)
end

attachPed = function(ped)
    local myBone = PED.GET_PED_BONE_INDEX(self.get_ped(), 6286)
    script.run_in_fiber(function(ap)
        if not ped_grabbed and not PED.IS_PED_A_PLAYER(ped) then
            if entities.take_control_of(ped, 300) then
                if is_handsUp then
                    TASK.CLEAR_PED_TASKS(self.get_ped())
                    is_handsUp = false
                end
                if is_playing_anim then
                    if anim_music then
                        play_music(false)
                        anim_music = false
                    end
                    cleanup(ap)
                    is_playing_anim = false
                end
                if is_playing_scenario then
                    stopScenario(self.get_ped(), ap)
                    is_playing_scenario = false
                end
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, self.get_ped(), myBone, 0.35, 0.3, -0.04, 100.0, 90.0, -10.0, false,
                    true,
                    false, true, 1, true, 1)
                ped_grabbed = true
                attached_ped = ped
            else
                YimToast:ShowError("Samurai's Scripts", _T("NPC_CTRL_FAIL_"))
            end
        end
    end)
    return ped_grabbed, attached_ped
end

attachVeh = function(veh)
    local attach_X
    local veh_class = Game.Vehicle.class(veh)
    local myBone = PED.GET_PED_BONE_INDEX(self.get_ped(), 6286)
    script.run_in_fiber(function(av)
        if not vehicle_grabbed and not VEHICLE.IS_THIS_MODEL_A_TRAIN(veh_model) then
            if entities.take_control_of(veh, 300) then
                if is_handsUp then
                    TASK.CLEAR_PED_TASKS(self.get_ped())
                    is_handsUp = false
                end
                if is_playing_anim then
                    if anim_music then
                        play_music(false)
                        anim_music = false
                    end
                    cleanup(av)
                    is_playing_anim = false
                end
                if is_playing_scenario then
                    stopScenario(self.get_ped(), ap)
                    is_playing_scenario = false
                end
                if isCrouched then
                    PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.3)
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
                ENTITY.ATTACH_ENTITY_TO_ENTITY(veh, self.get_ped(), myBone, attach_X, 0.0, 0.0, 0.0, attach_RY, -16.0,
                    false,
                    true,
                    false, true, 1, true, 1)
                vehicle_grabbed = true
                grabbed_veh     = veh
            else
                YimToast:ShowError("Samurai's Scripts", _T("NPC_CTRL_FAIL_"))
            end
        end
    end)
    return vehicle_grabbed, grabbed_veh
end

displayHijackAnims = function()
    local groupAnimNames = {}
    for _, anim in ipairs(hijackOptions) do
        table.insert(groupAnimNames, anim.name)
    end
    grp_anim_index, used = ImGui.Combo("##groupAnims", grp_anim_index, groupAnimNames, #hijackOptions)
end

resetSliders = function()
    spawnDistance = vec3:new(0, 0, 0)
    spawnRot      = vec3:new(0, 0, 0)
end

updateFilteredProps = function()
    filteredProps = {}
    for _, p in ipairs(custom_props) do
        if string.find(string.lower(p.name), objects_search:lower()) then
            table.insert(filteredProps, p)
        end
        table.sort(custom_props, function(a, b)
            return a.name < b.name
        end)
    end
end

displayFilteredProps = function()
    updateFilteredProps()
    local propNames = {}
    for _, p in ipairs(filteredProps) do
        table.insert(propNames, p.name)
    end
    prop_index, used = ImGui.ListBox("##propList", prop_index, propNames, #filteredProps)
    prop = filteredProps[prop_index + 1]
    if prop ~= nil then
        propHash = prop.hash
        propName = prop.name
    end
end

getAllObjects = function()
    filteredObjects = {}
    for _, object in ipairs(gta_objets) do
        if objects_search ~= "" then
            if string.find(string.lower(object), objects_search:lower()) then
                table.insert(filteredObjects, object)
            end
        else
            table.insert(filteredObjects, object)
        end
    end
    objects_index, used = ImGui.ListBox("##gtaObjectsList", objects_index, filteredObjects, #filteredObjects)
    prop                = filteredObjects[objects_index + 1]
    propHash            = joaat(prop)
    propName            = prop
    if gui.is_open() and os_switch ~= 0 then
        for _, b in ipairs(mp_blacklist) do
            if propName == b then
                showInvalidObjText = true
                blacklisted_obj    = true
                invalidType        = _T("COCKSTAR_BLACKLIST_WARN_")
                break
            else
                showInvalidObjText = false
                blacklisted_obj    = false
            end
            for _, c in ipairs(crash_objects) do
                if propName == c then
                    showInvalidObjText = true
                    invalidType = _T("CRASH_OBJECT_WARN_")
                    break
                else
                    showInvalidObjText = false
                end
            end
        end
    end
end

updateSelfBones = function()
    filteredSelfBones = {}
    for _, bone in ipairs(pedBones) do
        table.insert(filteredSelfBones, bone)
    end
end

displaySelfBones = function()
    updateSelfBones()
    local boneNames = {}
    for _, bone in ipairs(filteredSelfBones) do
        table.insert(boneNames, bone.name)
    end
    selected_bone, used = ImGui.Combo("##pedBones", selected_bone, boneNames, #filteredSelfBones)
end

updateVehBones = function()
    filteredVehBones = {}
    for _, bone in ipairs(vehBones) do
        local bone_idx = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, bone)
        if bone_idx ~= nil and bone_idx ~= -1 then
            table.insert(filteredVehBones, bone)
        end
    end
end

displayVehBones = function()
    updateVehBones()
    local boneNames = {}
    for _, bone in ipairs(filteredVehBones) do
        table.insert(boneNames, bone)
    end
    selected_bone, used = ImGui.Combo("##vehBones", selected_bone, boneNames, #filteredVehBones)
end

stopPreview = function()
    if previewStarted then
        previewStarted = false
    end
    pedPreviewModel     = 0
    vehiclePreviewModel = 0
    objectPreviewModel  = 0
    previewEntity       = 0
end

displaySpawnedObjects = function()
    spawnedNames = {}
    if spawned_props[1] ~= nil then
        for _, v in ipairs(spawned_props) do
            table.insert(spawnedNames, v.name)
        end
    end
    spawned_index, spiUsed = ImGui.Combo("##spawnedProps", spawned_index, spawnedNames, #spawned_props)
end

displayAttachedObjects = function()
    selfAttachNames = {}
    if attached_props[1] ~= nil then
        for _, v in ipairs(attached_props) do
            table.insert(selfAttachNames, v.name)
        end
    end
    attached_index, used = ImGui.Combo("##Attached Objects", attached_index, selfAttachNames, #attached_props)
end

displayVehAttachments = function()
    vehAttachNames = {}
    if vehicle_attachments[1] ~= nil then
        for _, v in ipairs(vehicle_attachments) do
            table.insert(vehAttachNames, v.name)
        end
    end
    vattached_index, used = ImGui.Combo("##vehAttachedObjects", vattached_index, vehAttachNames, #vehicle_attachments)
end

filterPersistProps = function()
    filteredPersistProps = {}
    if persist_attachments[1] ~= nil then
        for _, t in ipairs(persist_attachments) do
            table.insert(filteredPersistProps, t)
        end
    end
end

showPersistProps = function()
    filterPersistProps()
    persist_prop_names = {}
    for _, p in ipairs(filteredPersistProps) do
        table.insert(persist_prop_names, p.name)
    end
    persist_prop_index, _ = ImGui.ListBox("##persist_props", persist_prop_index, persist_prop_names,
        #filteredPersistProps)
end

displayLangs = function()
    filteredLangs = {}
    for _, lang in ipairs(lang_T) do
        table.insert(filteredLangs, lang.name)
    end
    lang_idx, lang_idxUsed = ImGui.Combo("##langs", lang_idx, filteredLangs, #lang_T)
    if UI.isItemClicked("lmb") then
        UI.widgetSound("Nav")
    end
end

flatbed_getTowOffset = function(vehToTow)
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

flatbed_detach = function()
    if is_using_flatbed then
        if towed_vehicle ~= 0 and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(towed_vehicle, current_vehicle) then
            local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(towed_vehicle, false)
            local flatbed_fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(current_vehicle)
            local flatbed_Pos = ENTITY.GET_ENTITY_COORDS(current_vehicle, false)
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
                local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(current_vehicle, modelHash)
                if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                    local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attachedVehicle, false)
                    local flatbed_fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(current_vehicle)
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
Lua_fn.condReturn = function(cond, ifTrue, ifFalse)
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
Lua_fn.round = function(n, x)
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
Lua_fn.separateInt = function(value)
    return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Returns a string containing the input value separated by the thousands and prefixed by a dollar sign.
--[[ -- Example:

    Lua_fn.formatMoney(42069)
      -> "$42,069"
]]
---@param value number | string
Lua_fn.formatMoney = function(value)
    return "$" .. tostring(Lua_fn.separateInt(value))
end

--[[ Converts a HEX string to RGB integers and returns 3 numbers representing Red, Green and Blue respectively.

- Example:

      red, green, blue = Lua_fn.hexToRGB("#E0D0B6")
        -> 224, 208, 182
- Another example:

      r, g, b = Lua_fn.hexToRGB("0B4")
        -> 0, 187, 68
]]
---@param hex string
Lua_fn.hexToRGB = function(hex)
    local r, g, b
    hex = hex:gsub("#", "")
    if hex:len() == 3 then -- short HEX
        r, g, b = (tonumber("0x" .. hex:sub(1, 1)) * 17), (tonumber("0x" .. hex:sub(2, 2)) * 17),
            (tonumber("0x" .. hex:sub(3, 3)) * 17)
    else
        r, g, b = tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)),
            tonumber("0x" .. hex:sub(5, 6))
    end
    return r, g, b
end

---@param r number
---@param g number
---@param b number
Lua_fn.RGBtoHex = function(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

--[[ Decodes hex to string.

HEX must be provided in a string format.

- Example:

      Lua_fn.hexToString("63756E74")
        -> "cunt"
]]
---@param hex string
---@return string
Lua_fn.hexToString = function(hex)
    return (hex:gsub("%x%x", function(digits)
        return string.char(tonumber(digits, 16))
    end))
end

-- Encodes a string into hex
---@param str string
---@return string
Lua_fn.stringToHex = function(str)
    return (str:gsub(".", function(char)
        return string.format("%02x", char:byte())
    end))
end

---@param n integer
---@param base integer
Lua_fn.intToHex = function(n, base)
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
Lua_fn.tableContains = function(tbl, value)
    if #tbl == 0 then
        return false
    end
    for i = 1, #tbl do
        if type(tbl[i]) == 'table' then
            for _, entry in pairs(tbl[i]) do
                if type(entry) == type(value) then
                    if entry == value then
                        return true
                    end
                end
            end
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

-- Returns key, value pairs of a table.
---@param t table
---@param indent? integer
---@return string
Lua_fn.listIter = function(t, indent)
    if not indent then
        indent = 0
    end
    local ret_str = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(t) do
        ret_str = ret_str .. string.rep(" ", indent)
        if type(k) == "number" then
            ret_str = ret_str .. "[" .. k .. "] = "
        elseif type(k) == "string" then
            ret_str = ret_str .. k .. " = "
        end
        if type(v) == "number" then
            ret_str = ret_str .. v .. ",\r\n"
        elseif type(v) == "string" then
            ret_str = ret_str .. "\"" .. v .. "\",\r\n"
        elseif type(v) == "table" then
            ret_str = ret_str .. Lua_fn.listIter(v, indent + 2) .. ",\r\n"
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
Lua_fn.getTableLength = function(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Returns the number of duplicate items in a table.
---@param t table
---@param value string | number | integer | table
Lua_fn.getTableDupes = function(t, value)
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
-- If `is_dev` is set to `true`, it adds a table with duplicate items to the return as well.
--
-- If you use the dev flag then you will need to specify which table you want to use (clean items or duplicates)
--
--[[
  **Example:**

  case1:

    local clean_items = Lua_fn.removeTableDupes(yourTable, false) -- when set to false it only returns a table with clean items (no duplicates)
    log.info(tostring(Lua_fn.listIter(clean_items, 0)))

  case2:

    local results = Lua_fn.removeTableDupes(yourTable, true) -- when set to true it returns a table containing both clean items and duplicates.
    local clean_items = results.clean_T
    local duplicate_items = results.dupes_T
    log.info("\10Clean Items:\10" .. tostring(Lua_fn.listIter(clean_items, 0)))
    log.info("\10Duplicate Items:\10" .. tostring(Lua_fn.listIter(duplicate_items, 0)))
]]
---@param t table
---@param debug boolean
Lua_fn.removeTableDupes = function(t, debug)
    local exists_T, clean_T, dupes_T, result_T = {}, {}, {}, {}
    for _, v in ipairs(t) do
        if not exists_T[v] then
            clean_T[#clean_T + 1] = v
            exists_T[v] = true
        else
            if debug then
                dupes_T[#dupes_T + 1] = v
            end
        end
    end
    if debug then
        result_T.clean_T = clean_T
        result_T.dupes_T = dupes_T
    end
    return debug and result_T or clean_T
end

-- Converts 0 and 1 values to Lua booleans. Useful when working with memory.
---@param value integer
Lua_fn.Lua_bool = function(value)
    if type(value) == "number" then
        if value == 0 then
            return false
        elseif value == 1 then
            return true
        else
            return error("Incorrect value", 2)
        end
    else
        return error("Incorrect value", 2)
    end
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
Lua_fn.joaat = function(key)
    local hash = 0
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

---@param col string | table
UI.getColor = function(col)
    local r, g, b
    local errorMsg = ""
    if type(col) == "string" then
        if col:find("^#") then
            r, g, b = Lua_fn.hexToRGB(col)
            r, g, b = Lua_fn.round((r / 255), 1), Lua_fn.round((g / 255), 1), Lua_fn.round((b / 255), 1)
        elseif col == "black" then
            r, g, b = 0, 0, 0
        elseif col == "white" then
            r, g, b = 1, 1, 1
        elseif col == "red" then
            r, g, b = 1, 0, 0
        elseif col == "green" then
            r, g, b = 0, 1, 0
        elseif col == "blue" then
            r, g, b = 0, 0, 1
        elseif col == "yellow" then
            r, g, b = 1, 1, 0
        elseif col == "orange" then
            r, g, b = 1, 0.5, 0
        elseif col == "pink" then
            r, g, b = 1, 0, 0.5
        elseif col == "purple" then
            r, g, b = 1, 0, 1
        else
            r, g, b = 1, 1, 1
            errorMsg = ("'" .. tostring(col) .. "' is not a valid color for this function.\nOnly these strings can be used as color inputs:\n - 'black'\n - 'white'\n - 'red'\n - 'green'\n - 'blue'\n - 'yellow'\n - 'orange'\n - 'pink'\n - 'purple'")
        end
    elseif type(col) == "table" then
        -- check color input values and convert them to floats between 0 and 1 which is what ImGui accepts for color values.
        if col[1] > 1 then
            col[1] = Lua_fn.round((col[1] / 255), 2)
        end
        if col[2] > 1 then
            col[2] = Lua_fn.round((col[2] / 255), 2)
        end
        if col[3] > 1 then
            col[3] = Lua_fn.round((col[3] / 255), 2)
        end
        r, g, b = col[1], col[2], col[3]
    end
    return r, g, b, errorMsg
end

-- Creates a text wrapped around the provided size. (We can use coloredText() and set the color to white but this is simpler.)
---@param text string
---@param wrap_size integer
UI.wrappedText = function(text, wrap_size)
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
    ImGui.TextWrapped(text)
    ImGui.PopTextWrapPos()
end

-- Creates a colored ImGui text.
---@param text string
---@param color string | table
---@param alpha? integer
---@param wrap_size number
--[[ -- Usage:
  - text: The text to display.
  - color: Can be either a HEX string (both short and long hex formats are accepted) or a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red").
  - alpha: A value between 0 and 1 representing visibility.
  - wrap_size: A number representing the size your text will wrap around.
]]
UI.coloredText = function(text, color, alpha, wrap_size)
    r, g, b, errorMsg = UI.getColor(color)
    if type(alpha) ~= "number" or alpha == nil then
        alpha = 1
    end
    if alpha > 1 then
        alpha = 1
    end
    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, alpha)
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
    ImGui.TextWrapped(text)
    ImGui.PopTextWrapPos()
    ImGui.PopStyleColor(1)
    if errorMsg ~= "" then
        if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            ImGui.SetNextWindowBgAlpha(0.8)
            ImGui.BeginTooltip()
            ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
            ImGui.TextWrapped(errorMsg)
            ImGui.PopTextWrapPos()
            ImGui.EndTooltip()
        end
    end
end

-- Creates a colored ImGui button.
---@param text string
---@param color string | table
---@param hovercolor string | table
---@param activecolor string | table
---@param alpha? integer
---@return boolean
--[[ -- Usage:
  - text: The button label.
  - color: The default button color. Can be either a HEX string (both short and long hex formats are accepted), a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red").
  - hovercolor: The color the button will change to when it's hovered. Same format as the 'color' parameter.
  - activecolor: The color the button will change to when it's clicked. Same format as the 'color' parameter.
  - alpha: A value between 0 and 1 representing visibility.
]]
UI.coloredButton = function(text, color, hovercolor, activecolor, alpha)
    local r, g, b                   = UI.getColor(color)
    local hoverR, hoverG, hoverB    = UI.getColor(hovercolor)
    local activeR, activeG, activeB = UI.getColor(activecolor)
    if type(alpha) ~= "number" or alpha == nil then
        alpha = 1
    end
    if alpha > 1 then
        alpha = 1
    end
    ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, alpha)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hoverR, hoverG, hoverB, alpha)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, activeR, activeG, activeB, alpha)
    local retVal = ImGui.Button(text)
    ImGui.PopStyleColor(3)
    return retVal
end

-- Creates a help marker (?) symbol in front of the widget this function is called after. When the symbol is hovered, it displays a tooltip.
---@param colorFlag boolean
---@param text string
---@param color? string | table | any
---@param alpha? integer | any
--[[ -- Usage:
  - colorFlag: true/false. If set to true, the color parameter will be required and the provided text will be colored, otherwise the color parameter will be ignored and can be left empty.
  - text: The text that will be displayed inside the tooltip.
  - color: Can be either a HEX string (both short and long hex formats are accepted), a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red"). If colorFlag is set to true, this parameter will be required.
  - alpha: A value between 0 and 1 representing visibility. If left empty it defaults to 1.
]]
UI.helpMarker = function(colorFlag, text, color, alpha)
    if not disableTooltips then
        ImGui.SameLine()
        ImGui.TextDisabled("(?)")
        if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            ImGui.SetNextWindowBgAlpha(0.75)
            ImGui.BeginTooltip()
            if colorFlag == true then
                UI.coloredText(text, color, alpha, 20)
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
---@param colorFlag boolean
---@param text string
---@param color? any
---@param alpha? any
--[[ -- Usage:
  - colorFlag: true/false. If set to true, the color parameter will be required and the provided text will be colored otherwise the color parameter will be ignored and can be left empty.
  - text: The text that will be displayed inside the tooltip.
  - color: Can be either a HEX string (both short and long hex formats are accepted), a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red"). If colorFlag is set to true, this parameter will be required.
  - alpha: A value between 0 and 1 representing visibility. If left empty it defaults to 1.
]]
UI.toolTip = function(colorFlag, text, color, alpha)
    if not disableTooltips then
        if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            ImGui.SetNextWindowBgAlpha(0.75)
            ImGui.BeginTooltip()
            if colorFlag == true then
                UI.coloredText(text, color, alpha, 20)
            else
                ImGui.PushTextWrapPos(ImGui.GetFontSize() * 20)
                ImGui.TextWrapped(text)
                ImGui.PopTextWrapPos()
            end
            ImGui.EndTooltip()
        end
    end
end

---Checks if an ImGui widget was clicked with either the left or the right mouse button.
---@param mb string
---@return boolean
--[[

**Usage:**
- mb: A string representing a mouse button. Can be either "lmb" for Left Mouse Button or "rmb" for Right Mouse Button.
]]
UI.isItemClicked = function(mb)
    local retBool = false
    if mb == "lmb" then
        retBool = ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(0)
    elseif mb == "rmb" then
        retBool = ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(1)
    else
        error(
            string.format(
                "Error in function isItemClicked(): Invalid param %s. Correct inputs: 'lmb' for Left Mouse Button or 'rmb' for Right Mouse Button.",
                mb),
            2)
    end
    return retBool
end

-- Sets the clipboard text.
---@param text string
---@param cond boolean
UI.setClipBoard = function(text, cond)
    if cond then
        UI.widgetSound("Click")
        ImGui.SetClipboardText(text)
        YimToast:ShowMessage("Samurai's Scripts", "Link copied to clipboard.")
    end
end

-- Plays a sound when an ImGui widget is clicked.
---@param sound string
UI.widgetSound = function(sound)
    if not disableUiSounds then
        script.run_in_fiber(function()
            AUDIO.PLAY_SOUND_FRONTEND(-1, ui_sounds_T[sound].soundName, ui_sounds_T[sound].soundRef, false)
        end)
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

SS.isAnyKeyPressed = function()
    return KeyManager:IsAnyKeyPressed()
end

---@param key integer
SS.isKeyPressed = function(key)
    return KeyManager:IsKeyPressed(key)
end

---@param key integer
SS.isKeyJustPressed = function(key)
    return KeyManager:IsKeyJustPressed(key)
end

SS.resetMovement = function()
    PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.3)
    PED.RESET_PED_STRAFE_CLIPSET(self.get_ped())
    PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
    WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 3839837909) -- default
    PED.CLEAR_PED_ALTERNATE_MOVEMENT_ANIM(self.get_ped(), 0, -8.0)
    TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(self.get_ped(), false, false)
    currentMvmt  = ""
    currentStrf  = ""
    currentWmvmt = ""
end

---@param data table
---@param isJson boolean
SS.setMovement = function(data, isJson)
    local mvmtclipset = isJson and data.Name or data.mvmt
    script.run_in_fiber(function(s)
        SS.resetMovement()
        s:sleep(100)
        if mvmtclipset then
            while not STREAMING.HAS_CLIP_SET_LOADED(mvmtclipset) do
                STREAMING.REQUEST_CLIP_SET(mvmtclipset)
                coroutine.yield()
            end
            PED.SET_PED_MOVEMENT_CLIPSET(self.get_ped(), mvmtclipset, 1.0)
            PED.SET_PED_ALTERNATE_MOVEMENT_ANIM(self.get_ped(), 0, "move_clown@generic", "idle", 1090519040, true)
            TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(self.get_ped(), true, true)
            currentMvmt = mvmtclipset
        end
        if data.wmvmt then
            PED.SET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped(), data.wmvmt)
            currentWmvmt = data.wmvmt
        end
        if data.strf then
            while not STREAMING.HAS_CLIP_SET_LOADED(data.strf) do
                STREAMING.REQUEST_CLIP_SET(data.strf)
                coroutine.yield()
            end
            PED.SET_PED_STRAFE_CLIPSET(self.get_ped(), data.strf)
            currentStrf = data.strf
        end
        if data.wanim then
            WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), joaat(data.wanim))
        end
    end)
end

---@param warehouse table
SS.getCEOwhouseInfo = function(warehouse)
    script.run_in_fiber(function()
        local property_index = (stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(warehouse.id)) - 1)
        warehouse.name       = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(("MP_WHOUSE_%d"):format(property_index))
        if ceo_warehouses_t[warehouse.name] then
            warehouse.size.small  = ceo_warehouses_t[warehouse.name].size == 0
            warehouse.size.medium = ceo_warehouses_t[warehouse.name].size == 1
            warehouse.size.large  = ceo_warehouses_t[warehouse.name].size == 2
            warehouse.max         = ceo_warehouses_t[warehouse.name].max
            warehouse.pos         = ceo_warehouses_t[warehouse.name].coords
        end
    end)
end

---@param index number
---@param entry table
SS.getMCbusinessInfo = function(index, entry)
    for _, v in ipairs(mc_business_ids_t) do
        if Lua_fn.tableContains(v.possible_ids, index) then
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
        if supported_sale_scripts[scr_name] then
            if not supported_sale_scripts[scr_name].b then -- gb_*
                for _, data in pairs(supported_sale_scripts[scr_name]) do
                    locals.set_int(scr_name, data.l + data.o, data.v)
                end
            else -- fm_content_*
                if not NETWORK.NETWORK_GET_HOST_OF_THIS_SCRIPT() == self.get_id() then
                    YimToast:ShowWarning("Samurai's Scripts",
                        "Unable to finish sale mission because you are not host of this script.")
                else
                    local val = locals.get_int(scr_name, supported_sale_scripts[scr_name].b + 1 + 0)
                    if not Lua_fn.has_bit(val, 11) then
                        val = Lua_fn.set_bit(val, 11)
                        locals.set_int(scr_name, supported_sale_scripts[scr_name].b + 1 + 0, val)
                    end
                    locals.set_int(scr_name, supported_sale_scripts[scr_name].l + supported_sale_scripts[scr_name].o, 3) -- End reason. Thanks ShinyWasabi! Now I know what 3 is 😅
                end
            end
        end
    end)
end

SS.finishCargoSourceMission = function()
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
SS.fillAll = function(s)
    if not Game.isOnline() then
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
SS.set_hotkey = function(keybind)
    ImGui.Dummy(1, 10)
    if key_name == nil then
        start_loading_anim = true
        UI.coloredText(string.format("%s%s", _T("INPUT_WAIT_TXT_"), loading_label), "#FFFFFF", 0.75, 20)
        key_pressed, key_code, key_name = SS.isAnyKeyPressed()
    else
        start_loading_anim = false
        for _, key in pairs(reserved_keys_T.kb) do
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
            UI.coloredText(_T("HOTKEY_RESERVED_"), "red", 0.86, 20)
        end

        ImGui.SameLine()
        ImGui.Dummy(5, 1)
        ImGui.SameLine()
        if UI.coloredButton(string.format(" %s ##Shortcut", _T("GENERIC_CLEAR_BTN_")), "#FFDB58", "#FFFAA0", "#FFFFF0", 0.7) then
            UI.widgetSound("Cancel")
            key_code, key_name = nil, nil
        end
    end

    ImGui.Dummy(1, 10)
    if not _reserved and key_code ~= nil then
        if ImGui.Button(string.format("%s##keybinds", _T("GENERIC_CONFIRM_BTN_"))) then
            UI.widgetSound("Select")
            keybind.code, keybind.name = key_code, string.format("[%s]", key_name)
            CFG:SaveItem("keybinds", keybinds)
            key_code, key_name = nil, nil
            is_setting_hotkeys = false
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    end

    if ImGui.Button(string.format("%s##keybinds", _T("GENERIC_CANCEL_BTN_"))) then
        UI.widgetSound("Cancel")
        key_code, key_name = nil, nil
        start_loading_anim = false
        is_setting_hotkeys = false
        ImGui.CloseCurrentPopup()
    end
end

SS.openHotkeyWindow = function(window_name, keybind)
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

    if UI.isItemClicked('lmb') then
        UI.widgetSound("Select2")
        ImGui.OpenPopup(window_name)
        is_setting_hotkeys = true
    end

    ImGui.SameLine()
    ImGui.BeginDisabled(keybind.code == 0x0)
    if ImGui.Button(string.format("%s##%s", _T("GENERIC_UNBIND_LABEL_"), window_name)) then
        UI.widgetSound("Delete")
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
        SS.set_hotkey(keybind)
        ImGui.End()
    end
end

---@param keybind table
SS.set_gpad_hotkey = function(keybind)
    ImGui.Dummy(1, 10)
    if gpad_keyName == nil then
        start_loading_anim = true
        UI.coloredText(string.format("%s%s", _T("INPUT_WAIT_TXT_"), loading_label), "#FFFFFF", 0.75, 20)
        gpad_keyCode, gpad_keyName = Game.getKeyPressed()
    else
        start_loading_anim = false
        for _, key in pairs(reserved_keys_T.gpad) do
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
            UI.coloredText(_T("HOTKEY_RESERVED_"), "red", 0.86, 20)
        end
        ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
        if UI.coloredButton(
                string.format(
                    " %s ##gpadkeybinds",
                    _T("GENERIC_CLEAR_BTN_")
                ),
                "#FFDB58",
                "#FFFAA0",
                "#FFFFF0", 0.7
            ) then
            UI.widgetSound("Cancel")
            gpad_keyCode, gpad_keyName = nil, nil
        end
    end

    ImGui.Dummy(1, 10)
    if not _reserved and gpad_keyCode ~= nil then
        if ImGui.Button(string.format("%s##gpadkeybinds", _T("GENERIC_CONFIRM_BTN_"))) then
            UI.widgetSound("Select")
            keybind.code, keybind.name = gpad_keyCode, gpad_keyName
            CFG:SaveItem("gpad_keybinds", gpad_keybinds)
            gpad_keyCode, gpad_keyName = nil, nil
            is_setting_hotkeys = false
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    end

    if ImGui.Button(string.format("%s##gpadkeybinds", _T("GENERIC_CANCEL_BTN_"))) then
        UI.widgetSound("Cancel")
        gpad_keyCode, gpad_keyName = nil, nil
        start_loading_anim = false
        is_setting_hotkeys = false
        ImGui.CloseCurrentPopup()
    end
end

---@param window_name string
---@param keybind table
SS.gpadHotkeyWindow = function(window_name, keybind)
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

    if UI.isItemClicked('lmb') then
        UI.widgetSound("Select2")
        ImGui.OpenPopup(window_name)
        is_setting_hotkeys = true
    end

    ImGui.SameLine()
    ImGui.BeginDisabled(keybind.code == 0)
    if ImGui.Button(string.format("%s##%s", _T("GENERIC_UNBIND_LABEL_"), window_name)) then
        UI.widgetSound("Delete")
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
        SS.set_gpad_hotkey(keybind)
        ImGui.End()
    end
end

-- Seamlessly add/remove keyboard keybinds on script update without requiring a config reset.
SS.check_kb_keybinds = function()
    local kb_keybinds_list = DEFAULT_CONFIG.keybinds
    local t_len            = Lua_fn.getTableLength
    if t_len(keybinds) == t_len(kb_keybinds_list) then
        SS.debug('No new keyboard keybinds.')
        return false -- early exit
    elseif t_len(keybinds) > t_len(kb_keybinds_list) then
        for k, _ in pairs(keybinds) do
            local kk = kb_keybinds_list[k]
            if kk == nil then -- removed keybind
                SS.debug('Removed keyboard keybind: ' .. tostring(keybinds[k]))
                keybinds[k] = nil
                CFG:SaveItem("keybinds", keybinds)  -- save
                keybinds = CFG:ReadItem("keybinds") -- refresh
            end
        end
    else
        for k, _ in pairs(kb_keybinds_list) do
            local kk = keybinds[k]
            if kk == nil then -- new keybind
                SS.debug('Added keyboard keybind: ' .. tostring(k))
                keybinds[k] = kb_keybinds_list[k]
                CFG:SaveItem("keybinds", keybinds)  -- save
                keybinds = CFG:ReadItem("keybinds") -- refresh
            end
        end
    end
end

-- Seamlessly add/remove controller keybinds on script update without requiring a config reset.
SS.check_gpad_keybinds = function()
    local gpad_keybinds_list = DEFAULT_CONFIG.gpad_keybinds
    local t_len              = Lua_fn.getTableLength
    if t_len(gpad_keybinds) == t_len(gpad_keybinds_list) then
        SS.debug('No new gamepad keybinds.')
        return false -- early exit
    elseif t_len(gpad_keybinds) > t_len(gpad_keybinds_list) then
        for k, _ in pairs(gpad_keybinds) do
            local kk = gpad_keybinds_list[k]
            if kk == nil then -- removed keybind
                SS.debug('Removed gamepad keybind: ' .. tostring(gpad_keybinds[k]))
                gpad_keybinds[k] = nil
                CFG:SaveItem("gpad_keybinds", gpad_keybinds)  -- save
                gpad_keybinds = CFG:ReadItem("gpad_keybinds") -- refresh
            end
        end
    else
        for k, _ in pairs(gpad_keybinds_list) do
            local kk = gpad_keybinds[k]
            if kk == nil then -- new keybind
                SS.debug('Added gamepad keybind: ' .. tostring(k))
                gpad_keybinds[k] = gpad_keybinds_list[k]
                CFG:SaveItem("gpad_keybinds", gpad_keybinds)  -- save
                gpad_keybinds = CFG:ReadItem("gpad_keybinds") -- refresh
            end
        end
    end
end

SS.canUseKeybinds = function()
    return (
        not is_typing and not
        is_setting_hotkeys and not
        Game.Self.isBrowsingApps() and not
        HUD.IS_MP_TEXT_CHAT_TYPING() and not
        HUD.IS_PAUSE_MENU_ACTIVE()
    )
end

SS.canUsePhoneAnims = function()
    return (
        not ENTITY.IS_ENTITY_DEAD(self.get_ped(), false) and not
        is_playing_anim and not
        is_playing_scenario and not
        ped_grabbed and not
        vehicle_grabbed and not 
        is_handsUp and not
        is_sitting and not
        is_hiding and not
        is_playing_amb_scenario
        and (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET(self.get_ped()) == 0)
    )
end

SS.canCrouch = function()
    return (
        Game.Self.isOnFoot() and not
        Game.Self.isInWater() and not
        Game.Self.is_ragdoll() and not
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
        Game.Self.isBrowsingApps()
    )
end

SS.canUseHandsUp = function()
    return (
        (Game.Self.isOnFoot() or is_car) and not
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
        Game.Self.isBrowsingApps()
    )
end

SS.playKeyfobAnim = function()
    if is_playing_anim or is_playing_scenario or is_playing_amb_scenario or isCrouched or is_handsUp or ped_grabbed or
        vehicle_grabbed or is_hiding or Game.Self.is_ragdoll() or Game.Self.isSwimming() or not Game.Self.isAlive() then
        return -- early exit
    end
    local dict <const> = "anim@mp_player_intmenu@key_fob@"
    if Game.requestAnimDict(dict) then
        TASK.TASK_PLAY_ANIM(self.get_ped(), dict, "fob_click", 4.0, -4.0, -1,
            48, 0.0, false, false, false)
    end
end

-- Reverts changes done by the script.
SS.handle_events = function()
    if attached_ped ~= nil and attached_ped ~= 0 then
        ENTITY.DETACH_ENTITY(attached_ped, true, true)
        ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
        attached_ped = 0; ped_grabbed = false
    end

    if grabbed_veh ~= nil and grabbed_veh ~= 0 then
        ENTITY.DETACH_ENTITY(grabbed_veh, true, true)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
        grabbed_veh = 0; vehicle_grabbed = false
    end

    if attached_vehicle ~= nil and attached_vehicle ~= 0 then
        local modelHash         = ENTITY.GET_ENTITY_MODEL(attached_vehicle)
        local attachedVehicle   = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(
            PED.GET_VEHICLE_PED_IS_USING(self.get_ped()),
            modelHash)
        local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attached_vehicle, false)
        local playerForwardX    = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
        local playerForwardY    = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
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

    if spawned_props[1] ~= nil then
        for i, v in ipairs(spawned_props) do
            if ENTITY.DOES_ENTITY_EXIST(v.entity) then
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v.entity, false, false)
                ENTITY.DELETE_ENTITY(v.entity)
                table.remove(spawned_props, i)
            end
        end
    end

    if selfAttachments[1] ~= nil then
        for i, v in ipairs(selfAttachments) do
            ENTITY.DETACH_ENTITY(v.entity, true, true)
            table.remove(selfAttachments, i)
        end
    end

    if vehAttachments[1] ~= nil then
        for i, v in ipairs(vehAttachments) do
            ENTITY.DETACH_ENTITY(v.entity, true, true)
            table.remove(vehAttachments, i)
        end
    end

    if currentMvmt ~= "" then
        SS.resetMovement()
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
        TASK.CLEAR_PED_TASKS(self.get_ped())
        if selfPTFX[1] ~= nil then
            for _, v in ipairs(selfPTFX) do
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(v, false)
            end
        end
        local current_coords = self.get_pos()
        if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), false) then
            local veh    = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
            local mySeat = Game.getPedVehicleSeat(self.get_ped())
            PED.SET_PED_INTO_VEHICLE(self.get_ped(), veh, mySeat)
        else
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.get_ped(), current_coords.x, current_coords.y, current_coords.z, true,
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
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
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
        TASK.CLEAR_PED_TASKS(self.get_ped())
        is_handsUp = false
    end

    if isCrouched then
        PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
        isCrouched = false
    end

    if disable_waves then
        Game.World.disableOceanWaves(false)
        disable_waves = false
    end

    if autopilot_waypoint or autopilot_objective or autopilot_random then
        if Game.Self.isDriving() then
            TASK.CLEAR_PED_TASKS(self.get_ped())
            TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
            autopilot_waypoint, autopilot_objective, autopilot_random = false, false, false
        end
    end

    if spawned_persist_T[1] ~= nil then
        for i, v in ipairs(spawned_persist_T) do
            if ENTITY.DOES_ENTITY_EXIST(v) then
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v, true, true)
                ENTITY.DELETE_ENTITY(v)
                table.remove(spawned_persist_T, i)
            end
        end
    end

    if is_sitting or ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "timetable@ron@ig_3_couch", "base", 3) then
        ENTITY.DETACH_ENTITY(self.get_ped(), true, false)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
        if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
            ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
        end
        is_sitting, thisSeat = false, 0
    end

    engine_brake_disabled, kers_boost_enabled, offroader_enabled,
    rally_tires_enabled, traction_ctrl_disabled, easy_wheelie_enabled = false, false, false, false, false, false

    if is_hiding then
        if hiding_in_boot or hiding_in_dumpster then
            ENTITY.DETACH_ENTITY(self.get_ped(), false, false)
            hiding_in_boot, hiding_in_dumpster = false, false
        end
        TASK.CLEAR_PED_TASKS(self.get_ped())
        is_hiding = false
    end
    TASK.CLEAR_PED_TASKS(self.get_ped())

    if cmd_ui_is_open then
        gui.override_mouse(false)
    end

    if VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(current_vehicle) ~= 1 then
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(current_vehicle, 1)
        VEHICLE.SET_VEHICLE_ALARM(current_vehicle, false)
    end
end

-- Checks if localPlayer is standing near a public seat
--
-- and returns its position and rotation vectors.
SS.isNearPublicSeat = function()
    local retBool, prop, seatPos, x_offset, z_offset, myCoords = false, 0, vec3:new(0.0, 0.0, 0.0), 0.0, 1.0,
        self.get_pos()
    for _, seat in ipairs(world_seats_T) do
        prop = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(myCoords.x, myCoords.y, myCoords.z, 1.5, joaat(seat), false, false,
            false)
        if ENTITY.DOES_ENTITY_EXIST(prop) then
            seatPos = Game.getCoords(prop, false)
            if ambient_scenarios and Game.DoesHumanScenarioExistInArea(seatPos, 1, true) then
                return false, 0, 0, 0
            end
            local distance = vec3:distance(myCoords, seatPos)
            if distance <= 2 then
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
SS.isNearTrashBin = function()
    local binPos, myCoords, myFwdVec = vec3:new(0.0, 0.0, 0.0), self.get_pos(), Game.getForwardVec(self.get_ped())
    local searchPos = vec3:new(
        myCoords.x + myFwdVec.x * 1.2,
        myCoords.y + myFwdVec.y * 1.2,
        myCoords.z + myFwdVec.z * 1.2
    )
    for _, trash in ipairs(trash_bins_T) do
        bin = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(searchPos.x, searchPos.y, searchPos.z, 1.5, joaat(trash), false, false,
            false)
        if ENTITY.DOES_ENTITY_EXIST(bin) then
            binPos = Game.getCoords(bin, false)
            local distance = vec3:distance(searchPos, binPos)
            if distance <= 1.3 then
                return true, bin
            end
        end
    end

    return fasle, 0
end

-- Checks if localPlayer is near any vehicle's trunk
--
-- and returns the vehicle handle if true.
SS.isNearCarTrunk = function()
    if Game.Self.isOnFoot() and not is_playing_anim and not is_playing_scenario and not is_playing_amb_scenario then
        local selfPos = self.get_pos()
        local selfFwd = Game.getForwardVec(self.get_ped())
        local fwdPos  = vec3:new(selfPos.x + (selfFwd.x * 1.3), selfPos.y + (selfFwd.y * 1.3), selfPos.z)
        local veh     = Game.getClosestVehicle(fwdPos, 20)
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
                    local vmin, vmax    = Game.getModelDimensions(ENTITY.GET_ENTITY_MODEL(veh))
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

                    if vec3:distance(self.get_pos(), search_area) <= 1 then
                        return true, veh, isRearEngined
                    end
                end
            end
        end
    end

    return false, 0, false
end

SS.updateNPCdriveTask = function()
    TASK.CLEAR_PED_TASKS(npcDriver)
    TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
    TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
    TASK.TASK_VEHICLE_TEMP_ACTION(npcDriver, thisVeh, 1, 500)
    if npcDriveTask == "wp" or npcDriveTask == "obj" then
        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(npcDriver, thisVeh, npcDriveDest.x, npcDriveDest.y, npcDriveDest.z,
            npcDrivingSpeed, npcDrivingFlags, 100)
    else
        TASK.TASK_VEHICLE_DRIVE_WANDER(npcDriver, thisVeh, npcDrivingSpeed, npcDrivingFlags)
    end
    YimToast:ShowMessage("Samurai's Scripts",
        string.format("NPC driving style changed to %s.", npcDriveSwitch == 0 and "Normal" or "Aggressive"))
end

SS.showNPCvehicleControls = function()
    ImGui.SeparatorText("NPC Vehicle Options")
    if show_npc_veh_seat_ctrl and thisVeh ~= 0 then
        ImGui.Text("Seats:")
        if ImGui.Button(string.format("< %s", _T("PREVIOUS_SEAT_BTN_"))) then
            script.run_in_fiber(function()
                if PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) then
                    local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(thisVeh)
                    local mySeat   = Game.getPedVehicleSeat(self.get_ped())
                    if mySeat <= 0 then
                        mySeat = numSeats
                    end
                    mySeat = mySeat - 1
                    if VEHICLE.IS_VEHICLE_SEAT_FREE(thisVeh, mySeat, true) then
                        UI.widgetSound("Nav")
                        PED.SET_PED_INTO_VEHICLE(self.get_ped(), thisVeh, mySeat)
                    else
                        mySeat = mySeat - 1
                        return
                    end
                end
            end)
        end
        ImGui.SameLine()
        if ImGui.Button(string.format("%s >", _T("NEXT_SEAT_BTN_"))) then
            script.run_in_fiber(function()
                if PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) then
                    local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(thisVeh)
                    local mySeat   = Game.getPedVehicleSeat(self.get_ped())
                    if mySeat > numSeats then
                        mySeat = 0
                    end
                    mySeat = mySeat + 1
                    if VEHICLE.IS_VEHICLE_SEAT_FREE(thisVeh, mySeat, true) then
                        UI.widgetSound("Nav")
                        PED.SET_PED_INTO_VEHICLE(self.get_ped(), thisVeh, mySeat)
                    else
                        mySeat = mySeat + 1
                        return
                    end
                end
            end)
        end
    end
    if npcDriver ~= 0 and ENTITY.DOES_ENTITY_EXIST(npcDriver) and not ENTITY.IS_ENTITY_DEAD(npcDriver, true)
        and PED.IS_PED_SITTING_IN_VEHICLE(npcDriver, thisVeh) then
        ImGui.Spacing(); ImGui.Text("Radio:")
        local mainRadioButtonLabel = npc_veh_radio_on and "Turn Off" or "Turn On"
        local mainRadioButtonParam = npc_veh_radio_on and "OFF" or
            radio_stations[math.random(1, (#radio_stations - 1))].station
        if ImGui.Button(mainRadioButtonLabel) then
            UI.widgetSound("Select2")
            script.run_in_fiber(function()
                AUDIO.SET_VEH_RADIO_STATION(thisVeh, mainRadioButtonParam)
            end)
        end
        if npc_veh_radio_on then
            ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
            if ImGui.Button("< Previous Station") then
                UI.widgetSound("Nav")
                script.run_in_fiber(function()
                    AUDIO.SET_RADIO_RETUNE_DOWN()
                end)
            end
            ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
            if ImGui.Button("Next Station >") then
                UI.widgetSound("Nav")
                script.run_in_fiber(function()
                    AUDIO.SET_RADIO_RETUNE_UP()
                end)
            end
        end
        if npc_veh_has_conv_roof then
            ImGui.Spacing(); ImGui.Text("Convertible Roof:")
            local roofButtonLabel
            if npc_veh_roof_state == 0 then
                roofButtonLabel = "Lower"
            elseif npc_veh_roof_state == 1 then
                roofButtonLabel = "Lowering..."
            elseif npc_veh_roof_state == 2 then
                roofButtonLabel = "Raise"
            elseif npc_veh_roof_state == 3 then
                roofButtonLabel = "Raising..."
            else
                roofButtonLabel = ""
            end
            ImGui.BeginDisabled(npc_veh_roof_state == 1 or npc_veh_roof_state == 3)
            if ImGui.Button(roofButtonLabel) then
                if npc_veh_speed > 6.66 then
                    UI.widgetSound("Error")
                    YimToast:ShowError("Samurai's Scripts", "You can not operate the convertible roof at this speed.")
                end
                UI.widgetSound("Select")
                script.run_in_fiber(function()
                    if npc_veh_roof_state == 0 then
                        VEHICLE.LOWER_CONVERTIBLE_ROOF(thisVeh, false)
                    elseif npc_veh_roof_state == 2 then
                        VEHICLE.RAISE_CONVERTIBLE_ROOF(thisVeh, false)
                    end
                end)
            end
            ImGui.EndDisabled()
        end
        ImGui.Spacing(); ImGui.Text("Driving Commands:")
        ImGui.BulletText("Driving Style:"); ImGui.SameLine(); npcDriveSwitch, isChanged = ImGui.RadioButton("Chill",
            npcDriveSwitch, 0)
        if isChanged then
            UI.widgetSound("Nav")
            npcDrivingFlags = 803243
            npcDrivingSpeed = 19
            script.run_in_fiber(function()
                TASK.SET_DRIVE_TASK_DRIVING_STYLE(npcDriver, 803243)
                TASK.SET_DRIVE_TASK_CRUISE_SPEED(npcDriver, 19.0)
                SS.updateNPCdriveTask()
            end)
        end
        ImGui.SameLine(); npcDriveSwitch, isChanged = ImGui.RadioButton("Aggressive", npcDriveSwitch, 1)
        if isChanged then
            UI.widgetSound("Nav")
            npcDrivingFlags = 787324
            npcDrivingSpeed = 70.0
            script.run_in_fiber(function()
                TASK.SET_DRIVE_TASK_DRIVING_STYLE(npcDriver, 787324)
                TASK.SET_DRIVE_TASK_CRUISE_SPEED(npcDriver, 70.0)
                SS.updateNPCdriveTask()
            end)
        end
        if ImGui.Button("Stop The Vehicle") then
            script.run_in_fiber(function(stp)
                TASK.CLEAR_PED_TASKS(npcDriver)
                TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
                TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
                if not VEHICLE.IS_VEHICLE_STOPPED(thisVeh) then
                    TASK.TASK_VEHICLE_TEMP_ACTION(npcDriver, thisVeh, 1, 5000)
                    repeat
                        stp:sleep(10)
                    until VEHICLE.IS_VEHICLE_STOPPED(thisVeh)
                    ENTITY.FREEZE_ENTITY_POSITION(thisVeh, true)
                end
                npcDriveTask = ""
                repeat
                    stp:sleep(10)
                until npcDriveTask ~= "" or not PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) or ENTITY.IS_ENTITY_DEAD(npcDriver, true)
                ENTITY.FREEZE_ENTITY_POSITION(thisVeh, false)
            end)
        end
        if ImGui.Button("Drive Around") then
            script.run_in_fiber(function()
                if npcDriveTask ~= "" then
                    TASK.CLEAR_PED_TASKS(npcDriver)
                    TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
                    TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
                end
                TASK.TASK_VEHICLE_DRIVE_WANDER(npcDriver, thisVeh, npcDrivingSpeed, npcDrivingFlags)
                npcDriveTask = "random"
                YimToast:ShowMessage("Samurai's Scripts", "Cruising around...")
            end)
        end
        ImGui.SameLine()
        if ImGui.Button("Drive To Waypoint") then
            script.run_in_fiber(function()
                local waypoint = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())
                if not HUD.DOES_BLIP_EXIST(waypoint) then
                    UI.widgetSound("Error")
                    YimToast:ShowError("Samurai's Scripts", "Please set a waypoint on the map first!")
                    return
                else
                    UI.widgetSound("Select")
                    if npcDriveTask ~= "" then
                        TASK.CLEAR_PED_TASKS(npcDriver)
                        TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
                        TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
                    end
                    npcDriveDest = HUD.GET_BLIP_COORDS(waypoint)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(npcDriver, thisVeh, npcDriveDest.x, npcDriveDest.y,
                        npcDriveDest.z, npcDrivingSpeed, npcDrivingFlags, 100)
                    npcDriveTask = "wp"
                    YimToast:ShowMessage("Samurai's Scripts", "Driving to waypoint...")
                end
            end)
        end
        ImGui.SameLine()
        if ImGui.Button("Drive To Objective") then
            local objective_found, objective_coords = Game.findObjectiveBlip()
            if not objective_found then
                UI.widgetSound("Error")
                YimToast:ShowError("Samurai's Scripts", "No objective found!")
            else
                npcDriveDest = objective_coords
                TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(npcDriver, thisVeh, npcDriveDest.x, npcDriveDest.y,
                    npcDriveDest.z, npcDrivingSpeed, npcDrivingFlags, 100)
                npcDriveTask = "obj"
                YimToast:ShowMessage("Samurai's Scripts", "Driving to objective...")
            end
        end
    end
    ImGui.Separator()
end

-- Reads localPlayer's vehicle information from memory.
SS.getVehicleInfo = function()
    local vehPtr = memory.handle_to_ptr(self.get_veh())
    ---@class CVehicle
    local CVehicle = setmetatable({}, {})
    CVehicle.__index = CVehicle
    if vehPtr:is_valid() then
        local CHandlingData          = vehPtr:add(0x0960):deref()
        local CVehicleModelInfo      = vehPtr:add(0x20):deref()
        local CVehicleDamage         = vehPtr:add(0x0420)
        local CDeformation           = CVehicleDamage:add(0x0010)
        CVehicle.m_model_info_flags  = CVehicleModelInfo:add(0x057C)
        CVehicle.m_model_flags       = CHandlingData:add(0x0124)
        CVehicle.m_handling_flags    = CHandlingData:add(0x0128)
        CVehicle.m_deformation_mult  = CHandlingData:add(0x00F8)
        CVehicle.m_sub_handling_data = CHandlingData:add(0x158):deref()
        CVehicle.m_deformation       = CDeformation:add(0x0000)
        CVehicle.m_deform_god        = vehPtr:add(0x096C)
    end
    return CVehicle
end

-- Checks if a handling flag is set
--
-- in localPlayer's current vehicle.
---@param flag number
SS.getVehicleHandlingFlag = function(flag)
    local m_handling_flags = SS.getVehicleInfo().m_handling_flags
    local handling_flags   = m_handling_flags:get_dword()
    return Lua_fn.has_bit(handling_flags, flag)
end

-- Enables or disables a handling flag for localPlayer's vehicle.
---@param flag number
---@param toggle boolean
SS.setHandlingFlag = function(flag, toggle)
    if not is_car and not is_bike and not is_quad then
        return
    end
    local m_handling_flags = SS.getVehicleInfo().m_handling_flags
    local handling_flags   = m_handling_flags:get_dword()
    local bitwiseOp        = toggle and Lua_fn.set_bit or Lua_fn.clear_bit
    local new_flag         = bitwiseOp(handling_flags, flag)
    m_handling_flags:set_dword(new_flag)
end

---@param flag integer
SS.getVehicleModelFlag = function(flag)
    local base_ptr = SS.getVehicleInfo()
        .m_model_info_flags -- array of 7 uint32_t (7 * 32 = 224 flags total. Outdated ref: https://gtamods.com/wiki/Vehicles.meta)
    local index    = math.floor(flag / 32)
    local bitPos   = flag % 32
    local flag_ptr = base_ptr:add(index * 4)
    local dword    = flag_ptr:get_dword()
    return Lua_fn.has_bit(dword, bitPos)
end

---@param flag integer
---@param toggle boolean
SS.setVehicleModelFlag = function(flag, toggle)
    local base_ptr  = SS.getVehicleInfo().m_model_info_flags
    local index     = math.floor(flag / 32)
    local bitPos    = flag % 32
    local flag_ptr  = base_ptr:add(index * 4)
    local dword     = flag_ptr:get_dword()
    local bitwiseOp = toggle and Lua_fn.set_bit or Lua_fn.clear_bit
    local new_flag  = bitwiseOp(dword, bitPos)
    flag_ptr:set_dword(new_flag)
end

---@unused
---@param dword integer
SS.setWeaponEffectGroup = function(dword)
    local pedPtr = memory.handle_to_ptr(self.get_ped())
    if pedPtr:is_valid() then
        local CPedWeaponManager = pedPtr:add(0x10B8):deref()
        local CWeaponInfo       = CPedWeaponManager:add(0x0020):deref()
        local sWeaponFx         = CWeaponInfo:add(0x0170)
        local eEffectGroup      = sWeaponFx:add(0x00) -- int32_t
        eEffectGroup:set_dword(dword)
    end
end

-- Returns the model type of an entity (ped, object, vehicle, MLO, time, etc...)
---@param entity integer
SS.getEntityType = function(entity)
    if ENTITY.DOES_ENTITY_EXIST(entity) then
        local entPtr = memory.handle_to_ptr(entity)
        if entPtr:is_valid() then
            local m_model_info = entPtr:add(0x0020):deref()
            local m_model_type = m_model_info:add(0x009D)
            return m_model_type:get_word()
        end
    end
    return 0
end

-- Reads information about the player from memory.
--
-- **Note:** param `ped` is a Ped ID, not a Player ID.
---@param ped integer
SS.getPlayerInfo = function(ped)
    local pedPtr = memory.handle_to_ptr(ped)
    if pedPtr:is_valid() then
        ---@class CPed
        local CPed            = setmetatable({}, {})
        CPed.__index          = CPed
        local CPlayerInfo     = pedPtr:add(0x10A8):deref()
        local m_ped_type      = pedPtr:add(0x1098)            -- uint32_t
        local m_ped_task_flag = pedPtr:add(0x144B)            -- uint8_t
        local m_seatbelt      = pedPtr:add(0x143C):get_word() -- uint8_t

        CPed.ped_type         = m_ped_type:get_dword()
        CPed.task_flag        = m_ped_task_flag:get_word()
        CPed.swim_speed_ptr   = CPlayerInfo:add(0x01C8)
        CPed.run_speed_ptr    = CPlayerInfo:add(0x0D50)
        CPed.velocity_ptr     = CPlayerInfo:add(0x0300) -- rage::fvector3

        CPed.canPedRagdoll    = function()
            return (CPed.ped_type & 0x20) ~= 0
        end;

        CPed.hasSeatbelt      = function()
            return (m_seatbelt & 0x3) ~= 0
        end;

        CPed.getGameState     = function()
            local m_game_state = CPlayerInfo:add(0x0230):get_dword()
            return eGameState[m_game_state + 2]
        end;

        return CPed
    end
end

---@param crates number
SS.get_ceo_crates_offset = function(crates)
    if crates ~= nil and crates > 0 then
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
        if crates == 6 or crates == 7 then
            return 15736
        end
        if crates == 8 or crates == 9 then
            return 15737
        end
        if crates >= 10 and crates <= 14 then
            return 15738
        end
        if crates >= 15 and crates <= 19 then
            return 15739
        end
        if crates >= 20 and crates <= 24 then
            return 15740
        end
        if crates >= 25 and crates <= 29 then
            return 15741
        end
        if crates >= 30 and crates <= 34 then
            return 15742
        end
        if crates >= 35 and crates <= 39 then
            return 15743
        end
        if crates >= 40 and crates <= 44 then
            return 15744
        end
        if crates >= 45 and crates <= 49 then
            return 15745
        end
        if crates >= 50 and crates <= 59 then
            return 15746
        end
        if crates >= 60 and crates <= 69 then
            return 15747
        end
        if crates >= 70 and crates <= 79 then
            return 15748
        end
        if crates >= 80 and crates <= 89 then
            return 15749
        end
        if crates >= 90 and crates <= 99 then
            return 15750
        end
        if crates >= 100 and crates <= 110 then
            return 15751
        end
        if crates == 111 then
            return 15752
        end
    end
    return 0
end

-- Reset saved config without affecting
--
-- custom outfits, custom vehicles, and favorite actions.
SS.reset_settings = function()
    for key, _ in pairs(DEFAULT_CONFIG) do
        if key ~= "saved_vehicles" and
            key ~= "persist_attachments" and
            key ~= "favorite_actions" then
            _G[key] = DEFAULT_CONFIG[key]
            CFG:SaveItem(key, DEFAULT_CONFIG[key])
        end
    end
    initStrings()
end

SS.isUsingAirctaftMG = function()
    if Game.Self.isDriving() and (is_plane or is_heli) and Game.Vehicle.hasWeapons(self.get_veh()) then
        local armed, weapon = WEAPON.GET_CURRENT_PED_VEHICLE_WEAPON(self.get_ped(), weapon)
        if armed then
            for _, v in ipairs(aircraft_mgs_t) do
                if weapon == joaat(v) then
                    return true, weapon
                end
            end
        end
    end
    return false, 0
end

-- GTA helpers.
---@class Game
Game = {}
Game.__index = Game
Game.Version = GetGameVersion()

Game.Language = function()
    local language_codes_T <const> = {
        { name = "English",             id = 0,  iso = "en-US" },
        { name = "French",              id = 1,  iso = "fr-FR" },
        { name = "German",              id = 2,  iso = "de-DE" },
        { name = "Italian",             id = 3,  iso = "it-IT" },
        { name = "Spanish, Spain",      id = 4,  iso = "es-ES" },
        { name = "Portugese",           id = 5,  iso = "pt-BR" },
        { name = "Polish",              id = 6,  iso = "pl-PL" },
        { name = "Russian",             id = 7,  iso = "ru-RU" },
        { name = "Korean",              id = 8,  iso = "ko-KR" },
        { name = "Chinese Traditional", id = 9,  iso = "zh-TW" },
        { name = "Japanese",            id = 10, iso = "ja-JP" },
        { name = "Spanish, Mexico",     id = 11, iso = "es-MX" },
        { name = "Chinese Simplified",  id = 12, iso = "zh-CN" },
    }
    local lang_iso, lang_name
    local lang = LOCALIZATION.GET_CURRENT_LANGUAGE()
    for _, l in ipairs(language_codes_T) do
        if lang == l.id then
            lang_iso  = l.iso
            lang_name = l.name
            break
        else
            lang_iso  = "en-US"
            lang_name = "English"
        end
    end
    if lang_iso == "es-MX" then
        lang_iso = "es-ES"
    end
    return lang_iso, lang_name
end

Game.getKeyPressed = function()
    local btn, gpad
    local controls_T <const> = {
        { ctrl = 7,   gpad = "[R3]" },
        { ctrl = 10,  gpad = "[LT]" },
        { ctrl = 11,  gpad = "[RT]" },
        { ctrl = 14,  gpad = "[DPAD RIGHT]" },
        { ctrl = 15,  gpad = "[DPAD LEFT]" },
        { ctrl = 19,  gpad = "[DPAD DOWN]" },
        { ctrl = 20,  gpad = "[DPAD DOWN]" },
        { ctrl = 21,  gpad = "[A]" },
        { ctrl = 22,  gpad = "[X]" },
        { ctrl = 23,  gpad = "[Y]" },
        { ctrl = 27,  gpad = "[DPAD UP]" },
        { ctrl = 29,  gpad = "[R3]" },
        { ctrl = 30,  gpad = "[LEFT STICK]" },
        { ctrl = 34,  gpad = "[LEFT STICK]" },
        { ctrl = 36,  gpad = "[L3]" },
        { ctrl = 37,  gpad = "[LB]" },
        { ctrl = 38,  gpad = "[LB]" },
        { ctrl = 42,  gpad = "[DPAD UP]" },
        { ctrl = 43,  gpad = "[DPAD DOWN]" },
        { ctrl = 44,  gpad = "[RB]" },
        { ctrl = 45,  gpad = "[B]" },
        { ctrl = 46,  gpad = "[DPAD RIGHT]" },
        { ctrl = 47,  gpad = "[DPAD LEFT]" },
        { ctrl = 56,  gpad = "[Y]" },
        { ctrl = 57,  gpad = "[B]" },
        { ctrl = 70,  gpad = "[A]" },
        { ctrl = 71,  gpad = "[RT]" },
        { ctrl = 72,  gpad = "[LT]" },
        { ctrl = 73,  gpad = "[A]" },
        { ctrl = 74,  gpad = "[DPAD RIGHT]" },
        { ctrl = 75,  gpad = "[Y]" },
        { ctrl = 76,  gpad = "[RB]" },
        { ctrl = 79,  gpad = "[R3]" },
        { ctrl = 81,  gpad = "(NONE)" },
        { ctrl = 82,  gpad = "(NONE)" },
        { ctrl = 83,  gpad = "(NONE)" },
        { ctrl = 84,  gpad = "(NONE)" },
        { ctrl = 84,  gpad = "[DPAD LEFT]" },
        { ctrl = 96,  gpad = "(NONE)" },
        { ctrl = 97,  gpad = "(NONE)" },
        { ctrl = 124, gpad = "[LEFT STICK]" },
        { ctrl = 125, gpad = "[LEFT STICK]" },
        { ctrl = 112, gpad = "[LEFT STICK]" },
        { ctrl = 127, gpad = "[LEFT STICK]" },
        { ctrl = 117, gpad = "[LB]" },
        { ctrl = 118, gpad = "[RB]" },
        { ctrl = 167, gpad = "(NONE)" },
        { ctrl = 168, gpad = "(NONE)" },
        { ctrl = 169, gpad = "(NONE)" },
        { ctrl = 170, gpad = "[B]" },
        { ctrl = 172, gpad = "[DPAD UP]" },
        { ctrl = 173, gpad = "[DPAD DOWN]" },
        { ctrl = 174, gpad = "[DPAD LEFT]" },
        { ctrl = 175, gpad = "[DPAD RIGHT]" },
        { ctrl = 178, gpad = "[Y]" },
        { ctrl = 194, gpad = "[B]" },
        { ctrl = 243, gpad = "(NONE)" },
        { ctrl = 244, gpad = "[BACK]" },
        { ctrl = 249, gpad = "(NONE)" },
        { ctrl = 288, gpad = "[A]" },
        { ctrl = 289, gpad = "[X]" },
        { ctrl = 303, gpad = "[DPAD UP]" },
        { ctrl = 307, gpad = "[DPAD RIGHT]" },
        { ctrl = 308, gpad = "[DPAD LEFT]" },
        { ctrl = 311, gpad = "[DPAD DOWN]" },
        { ctrl = 318, gpad = "[START]" },
        { ctrl = 322, gpad = "(NONE)" },
        { ctrl = 344, gpad = "[DPAD RIGHT]" },
    }
    for _, v in ipairs(controls_T) do
        if PAD.IS_CONTROL_JUST_PRESSED(0, v.ctrl) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, v.ctrl) then
            btn, gpad = v.ctrl, v.gpad
        end
    end
    if not PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
        return btn, gpad
    else
        return nil, nil
    end
end

Game.isOnline = function()
    return network.is_session_started() and not script.is_active("maintransition")
end

---@param text string
---@param type integer
Game.busySpinnerOn = function(text, type)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(type)
end

Game.busySpinnerOff = function()
    HUD.BUSYSPINNER_OFF()
end

---@param text string
Game.showButtonPrompt = function(text)
    if not HUD.IS_HELP_MESSAGE_ON_SCREEN() then
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_HELP("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
        HUD.END_TEXT_COMMAND_DISPLAY_HELP(0, false, true, -1)
    end
end

---@param posX float
---@param posY float
---@param width float
---@param height float
---@param fgCol table
---@param bgCol table
---@param value number
Game.drawBar = function(posX, posY, width, height, fgCol, bgCol, value)
    local bgPaddingX = 0.005
    local bgPaddingY = 0.01
    -- background
    GRAPHICS.DRAW_RECT(posX, posY, width + bgPaddingX, height + bgPaddingY, bgCol.r, bgCol.g, bgCol.b, bgCol.a, false)

    -- foreground
    GRAPHICS.DRAW_RECT(posX - width * 0.5 + value * width * 0.5, posY, width * value, height, fgCol.r, fgCol.g, fgCol.b,
        fgCol.a, false)
end

---@param posX float
---@param PosY float
---@param text string
---@param col table
---@param scale vec2 | table
---@param font number
Game.drawText = function(posX, PosY, text, col, scale, font)
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("TWOSTRINGS")
    HUD.SET_TEXT_COLOUR(col.r, col.g, col.b, col.a)
    HUD.SET_TEXT_SCALE(scale.x, scale.y)
    HUD.SET_TEXT_OUTLINE()
    HUD.SET_TEXT_FONT(font)
    HUD.SET_TEXT_CENTRE(true)
    HUD.SET_TEXT_DROP_SHADOW()
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(posX, PosY, 0)
end

---@param entity integer
Game.addBlipForEntity = function(entity)
    HUD.ADD_BLIP_FOR_ENTITY(entity)
end

-- Full list of blip icon IDs: https://wiki.rage.mp/index.php?title=Blips
---@param blip integer
---@param icon integer
Game.setBlipIcon = function(blip, icon)
    HUD.SET_BLIP_SPRITE(blip, icon)
end

-- Sets a custom name for a blip. Custom names appear on the pause menu and the world map.
---@param blip integer
---@param name string
Game.setBlipName = function(blip, name)
    HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
    HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
end

---@param model integer
Game.requestModel = function(model)
    if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_IN_CDIMAGE(model) then
        while not STREAMING.HAS_MODEL_LOADED(model) do
            STREAMING.REQUEST_MODEL(model)
            coroutine.yield()
        end
        return STREAMING.HAS_MODEL_LOADED(model)
    end

    return false
end

---@param model integer
Game.getModelDimensions = function(model)
    if STREAMING.IS_MODEL_VALID(model) then
        local vmin = memory.allocate(0xC)
        local vmax = memory.allocate(0xC)
        ---@diagnostic disable-next-line
        local retVecMin, retVecMax = MISC.GET_MODEL_DIMENSIONS(model, vmin, vmax) -- keeps yapping about assigning 'pointer' to param 'vec3'
        memory.free(vmin); memory.free(vmax)
        return retVecMin, retVecMax
    end

    return vec3:new(0, 0, 0), vec3:new(0, 0, 0)
end

---@param dict string
Game.requestNamedPtfxAsset = function(dict)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict) do
        STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)
        coroutine.yield()
    end

    return STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict)
end

---@param dict string
Game.requestAnimDict = function(dict)
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        coroutine.yield()
    end
    return STREAMING.HAS_ANIM_DICT_LOADED(dict)
end

---@param dict string
Game.requestTextureDict = function(dict)
    while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict) do
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(dict, false)
        coroutine.yield()
    end
    return GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict)
end

---@param weapon integer
Game.requestWeaponAsset = function(weapon)
    while not WEAPON.HAS_WEAPON_ASSET_LOADED(weapon) do
        WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0)
        coroutine.yield()
    end
    return WEAPON.HAS_WEAPON_ASSET_LOADED(weapon)
end

---@param scr string
Game.requestScript = function(scr)
    while not SCRIPT.HAS_SCRIPT_LOADED(scr) do
        SCRIPT.REQUEST_SCRIPT(scr)
        coroutine.yield()
    end
    return SCRIPT.HAS_SCRIPT_LOADED(scr)
end

---@param entity integer
---@param isAlive boolean
Game.getCoords = function(entity, isAlive)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, isAlive)
    return vec3:new(coords.x, coords.y, coords.z)
end

---@param entity integer
Game.getHeading = function(entity)
    return ENTITY.GET_ENTITY_HEADING(entity)
end

---@param entity integer
Game.getForwardX = function(entity)
    return ENTITY.GET_ENTITY_FORWARD_X(entity)
end

---@param entity integer
Game.getForwardY = function(entity)
    return ENTITY.GET_ENTITY_FORWARD_Y(entity)
end

---@param entity integer
Game.getForwardVec = function(entity)
    local fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)
    return vec3:new(fwdVec.x, fwdVec.y, fwdVec.z)
end

---@param ped integer
---@param boneID integer
Game.getPedBoneIndex = function(ped, boneID)
    return PED.GET_PED_BONE_INDEX(ped, boneID)
end

---@param ped integer
---@param boneID integer
Game.getPedBoneCoords = function(ped, boneID)
    return PED.GET_PED_BONE_COORDS(ped, boneID, 0, 0, 0)
end

---@param entity integer
---@param boneName string
Game.getEntityBoneIndexByName = function(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, boneName)
end

---@param entity integer
---@param boneName string
Game.getWorldPosFromEntityBone = function(entity, boneName)
    local boneIndex = Game.getEntityBoneIndexByName(entity, boneName)
    return ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(entity, boneIndex)
end

---@param entity integer
---@param boneName string
Game.getEntityBonePos = function(entity, boneName)
    local boneIndex = Game.getEntityBoneIndexByName(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_POSTION(entity, boneIndex)
end

---@param entity integer
---@param boneName string
Game.getEntityBoneRot = function(entity, boneName)
    local boneIndex = Game.getEntityBoneIndexByName(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_ROTATION(entity, boneIndex)
end

---@param entity integer
Game.getEntityBoneCount = function(entity)
    return ENTITY.GET_ENTITY_BONE_COUNT(entity)
end

---Returns the entity localPlayer is aiming at.
Game.getAimedEntity = function()
    local Entity = 0
    if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
        _, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), Entity)
    end
    return Entity
end

---Gets the hash from an entity handle.
---@param entity integer
Game.getEntityModel = function(entity)
    return ENTITY.GET_ENTITY_MODEL(entity)
end

---Returns a number for the vehicle seat the provided ped is sitting in (-1 driver, 0 front passenger, etc...).
---@param ped integer
Game.getPedVehicleSeat = function(ped)
    if PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) then
        ---@type integer
        local pedSeat
        local vehicle  = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        local maxSeats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
        for i = -1, maxSeats do
            if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
                local sittingPed = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, true)
                if sittingPed == ped then
                    pedSeat = i
                    break
                end
            end
        end
        return pedSeat
    end
end

-- Returns a handle for the closest vehicle to a provided entity or coordinates.
--
-- Param `excludeEntity` is not necessary but can be used to ignore a specific vehicle
--
-- using its entity handle .
---@param closeTo integer | vec3
---@param range integer
---@param excludeEntity? integer
Game.getClosestVehicle = function(closeTo, range, excludeEntity)
    local thisPos = type(closeTo) == 'number' and ENTITY.GET_ENTITY_COORDS(closeTo, false) or closeTo
    if VEHICLE.IS_ANY_VEHICLE_NEAR_POINT(thisPos.x, thisPos.y, thisPos.z, range) then
        local veh_handles = entities.get_all_vehicles_as_handles()
        for i = 0, #veh_handles do
            if excludeEntity and veh_handles[i] == excludeEntity then
                i = i + 1
            end
            local vehPos = ENTITY.GET_ENTITY_COORDS(veh_handles[i], true)
            local vDist2 = SYSTEM.VDIST2(thisPos.x, thisPos.y, thisPos.z, vehPos.x, vehPos.y, vehPos.z)
            if vDist2 <= range and math.floor(VEHICLE.GET_VEHICLE_BODY_HEALTH(veh_handles[i])) > 0 then
                return veh_handles[i]
            end
        end
    end

    return 0
end

-- Returns a handle for the closest human ped to a provided entity or coordinates.
--
-- Does not return your own ped.
---@param closeTo integer | vec3
---@param range integer
---@param aliveOnly boolean
Game.getClosestPed = function(closeTo, range, aliveOnly)
    local thisPos = type(closeTo) == 'number' and ENTITY.GET_ENTITY_COORDS(closeTo, false) or closeTo
    if PED.IS_ANY_PED_NEAR_POINT(thisPos.x, thisPos.y, thisPos.z, range) then
        for _, ped in ipairs(entities.get_all_peds_as_handles()) do
            if PED.IS_PED_HUMAN(ped) and ped ~= self.get_ped() then
                local pedPos = ENTITY.GET_ENTITY_COORDS(ped, true)
                local vDist2 = SYSTEM.VDIST2(thisPos.x, thisPos.y, thisPos.z, pedPos.x, pedPos.y, pedPos.z)
                if vDist2 <= range then
                    if aliveOnly then
                        if not ENTITY.IS_ENTITY_DEAD(ped, false) then
                            return ped
                        end
                    else
                        return ped
                    end
                end
            end
        end
    end

    return 0
end

-- Temporary workaround to fix auto-pilot's "fly to objective" option.
Game.findObjectiveBlip = function()
    for _, v in ipairs(objectives_T) do
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(v)
        if HUD.DOES_BLIP_EXIST(blip) then
            return true, HUD.GET_BLIP_INFO_ID_COORD(blip)
        else
            local stdBlip    = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_STANDARD_BLIP_ENUM_ID())
            local blipCoords = HUD.GET_BLIP_INFO_ID_COORD(stdBlip)
            if blipCoords ~= vec3:new(0, 0, 0) then
                return true, blipCoords
            end
        end
    end

    return false
end

---@param area vec3
---@param radius number
---@param isFree boolean
Game.DoesHumanScenarioExistInArea = function(area, radius, isFree)
    for _, v in ipairs(ped_scenarios) do
        if TASK.DOES_SCENARIO_OF_TYPE_EXIST_IN_AREA(area.x, area.y, area.z, v.scenario, radius, isFree) then
            return true, v.name
        end
    end

    return false
end

-- Starts a Line Of Sight world probe shape test.
---@param src vec3
---@param dest vec3
---@param traceFlags integer
Game.rayCast = function(src, dest, traceFlags, entityToExclude)
    local rayHandle                          = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
        src.x, src.y, src.z,
        dest.x, dest.y, dest.z,
        traceFlags, entityToExclude, 7
    )
    local endCoords                          = memory.allocate(0xC)
    local surfaceNormal                      = memory.allocate(0xC)
    local entityHit                          = 0
    local _, hit, retEntityHit, retEndCoords = 0, false, 0, vec3:new(0, 0, 0)
    _, hit, retEndCoords, _, retEntityHit    = SHAPETEST.GET_SHAPE_TEST_RESULT(
    ---@diagnostic disable-next-line
        rayHandle, hit, endCoords, surfaceNormal, entityHit
    )
    memory.free(endCoords); memory.free(surfaceNormal)

    return hit, retEndCoords, retEntityHit
end

---@class Self
Game.Self = {}
Game.Self.__index = Game.Self

---@return number
Game.Self.get_elevation = function()
    return ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(self.get_ped())
end

---@return boolean
Game.Self.is_ragdoll = function()
    return PED.IS_PED_RAGDOLL(self.get_ped())
end

-- Returns localPlayer's maximum health.
---@return integer
Game.Self.maxHealth = function()
    return ENTITY.GET_ENTITY_MAX_HEALTH(self.get_ped())
end

-- Returns localPlayer's current health.
---@return integer
Game.Self.health = function()
    return ENTITY.GET_ENTITY_HEALTH(self.get_ped())
end

-- Returns localPlayer's maximum armour.
---@return integer
Game.Self.maxArmour = function()
    return PLAYER.GET_PLAYER_MAX_ARMOUR(self.get_id())
end

-- Returns localPlayer's current armour
---@return integer
Game.Self.armour = function()
    return PED.GET_PED_ARMOUR(self.get_ped())
end

-- Checks if localPlayer is alive.
Game.Self.isAlive = function()
    return not ENTITY.IS_ENTITY_DEAD(self.get_ped(), false)
end

-- Checks if localPlayer is on foot.
---@return boolean
Game.Self.isOnFoot = function()
    return PED.IS_PED_ON_FOOT(self.get_ped())
end

-- Checks if localPlayer is in water.
---@return boolean
Game.Self.isInWater = function()
    return ENTITY.IS_ENTITY_IN_WATER(self.get_ped())
end

Game.Self.isSwimming = function()
    return PED.IS_PED_SWIMMING(self.get_ped()) or PED.IS_PED_SWIMMING_UNDER_WATER(self.get_ped())
end

-- Checks if localPlayer is outside.
Game.Self.isOutside = function()
    return INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0
end

Game.Self.isMoving = function()
    return not PED.IS_PED_STOPPED(self.get_ped())
end

Game.Self.isDriving = function()
    if self.get_veh() == 0 then
        return false
    end
    return VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.get_veh(), -1, false) == self.get_ped()
end

-- Returns the hash of localPlayer's selected weapon.
---@return integer
Game.Self.weapon = function()
    local armed, weaponHash = WEAPON.GET_CURRENT_PED_WEAPON(self.get_ped(), weaponHash, false)
    if armed then
        return weaponHash
    end
    return 0
end

-- Teleports localPlayer to the provided coordinates.
---@param keepVehicle boolean
---@param coords vec3
Game.Self.teleport = function(keepVehicle, coords)
    script.run_in_fiber(function(selftp)
        STREAMING.REQUEST_COLLISION_AT_COORD(coords.x, coords.y, coords.z)
        selftp:sleep(200)
        if keepVehicle then
            PED.SET_PED_COORDS_KEEP_VEHICLE(self.get_ped(), coords.x, coords.y, coords.z)
        else
            if not Game.Self.isOnFoot() then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
            end
            ENTITY.SET_ENTITY_COORDS(self.get_ped(), coords.x, coords.y, coords.z, false, false, true, false)
        end
    end)
end

---Enables or disables physical phone intercations in GTA Online
---@param toggle boolean
Game.Self.PhoneAnims = function(toggle)
    for i = 242, 244 do -- PCF_PhoneDisableTextingAnimations, PCF_PhoneDisableTalkingAnimations, PCF_PhoneDisableCameraAnimations
        if PED.GET_PED_CONFIG_FLAG(self.get_ped(), i, true) == toggle then
            PED.SET_PED_CONFIG_FLAG(self.get_ped(), i, not toggle)
        end
    end
end

---Enables phone gestures in GTA Online.
---@param s script_util
Game.Self.PlayPhoneGestures = function(s)
    local is_phone_in_hand   = script.is_active("CELLPHONE_FLASHHAND")
    local is_browsing_email  = script.is_active("APPMPEMAIL")
    local call_anim_dict     = "anim@scripted@freemode@ig19_mobile_phone@male@"
    local call_anim          = "base"
    local call_anim_boneMask = "BONEMASK_HEAD_NECK_AND_R_ARM"
    if AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
        if Game.requestAnimDict(call_anim_dict) then
            TASK.TASK_PLAY_PHONE_GESTURE_ANIMATION(
                self.get_ped(), call_anim_dict, call_anim,
                call_anim_boneMask, 0.25, 0.25, true, false
            )
            repeat
                s:sleep(10)
            until not AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() or not SS.canUsePhoneAnims()
            TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(self.get_ped(), 0.25)
        end
    end
    if is_phone_in_hand then
        MOBILE.CELL_HORIZONTAL_MODE_TOGGLE(is_browsing_email)
        for _, v in ipairs(cell_inputs_T) do
            if PAD.IS_CONTROL_JUST_PRESSED(0, v.control) then
                MOBILE.CELL_SET_INPUT(v.input)
            end
        end
    end
end

Game.Self.NoJacking = function(toggle)
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 26, false) ~= toggle then
        PED.SET_PED_CONFIG_FLAG(self.get_ped(), 26, toggle)
    end
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 177, false) ~= toggle then
        PED.SET_PED_CONFIG_FLAG(self.get_ped(), 177, toggle)
    end
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 398, false) ~= toggle then
        PED.SET_PED_CONFIG_FLAG(self.get_ped(), 398, toggle)
    end
end

Game.Self.DisableActionMode = function()
    if not PED.GET_PED_RESET_FLAG(self.get_ped(), 200) then -- PRF_DisableActionMode
        PED.SET_PED_RESET_FLAG(self.get_ped(), 200, true)
    end
end

Game.Self.AllowHatsInVehicles = function()
    if not PED.GET_PED_RESET_FLAG(self.get_ped(), 337) then -- PRF_AllowHeadPropInVehicle
        PED.SET_PED_RESET_FLAG(self.get_ped(), 337, true)
    end
end

Game.Self.NoRagdollOnVehRoof = function()
    if not PED.GET_PED_RESET_FLAG(self.get_ped(), 274) then -- PRF_BlockRagdollFromVehicleFallOff
        PED.SET_PED_RESET_FLAG(self.get_ped(), 274, true)
    end
end

-- Returns whether the player is currently using any mobile or computer app.
Game.Self.isBrowsingApps = function()
    for _, v in ipairs(app_script_names_T) do
        if script.is_active(v) then
            return true
        end
    end
    return false
end

-- Returns whether the player is currently modifying their vehicle in a modshop. <- Also returns true when just near a mod shop and not actually inside (tested with LS Customs).
Game.Self.isInCarModShop = function()
    for _, v in ipairs(modshop_script_names) do
        if script.is_active(v) then
            return true
        end
    end
    return false
end

---@param ped integer
Game.Self.isPedEnemy = function(ped)
    local relationship = PED.GET_RELATIONSHIP_BETWEEN_PEDS(ped, self.get_ped())
    local pedCoords = Game.getCoords(ped, true)
    return PED.IS_PED_IN_COMBAT(ped, self.get_ped()) or
        (relationship > 2 and relationship <= 5) or
        PED.IS_ANY_HOSTILE_PED_NEAR_POINT(
            self.get_ped(), pedCoords.x, pedCoords.y, pedCoords.z, 1
        )
end

---@class Vehicle
-- Conflicts with YimLLS `Vehicle` alias.
Game.Vehicle = {}
Game.Vehicle.__index = Game.Vehicle

-- Returns the name of the specified vehicle.
---@param vehicle number
Game.Vehicle.name = function(vehicle)
    if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        return vehicles.get_vehicle_display_name(Game.getEntityModel(vehicle))
    end
    return ""
end

-- Returns the manufacturer's name of the specified vehicle.
---@param vehicle number
Game.Vehicle.manufacturer = function(vehicle)
    if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        local mfr = VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(Game.getEntityModel(vehicle))
        return (mfr:lower():gsub("^%l", string.upper))
    end

    return ""
end

-- Returns the class of the specified vehicle.
Game.Vehicle.class = function(vehicle)
    local vehClass = VEHICLE.GET_VEHICLE_CLASS(vehicle)
    if vehicle_classes_t[vehClass] then
        return vehicle_classes_t[vehClass]
    end

    return "Unknown" -- in case R* adds a new class.
end

-- Returns a table containing all occupants of a vehicle.
---@param vehicle integer
Game.Vehicle.getOccupants = function(vehicle)
    local passengers = {}
    if ENTITY.DOES_ENTITY_EXIST(vehicle) and ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        local maxPassengers = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
        for i = -1, maxPassengers do
            if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
                local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, false)
                if ped ~= 0 then
                    table.insert(passengers, ped)
                end
            end
        end
        return passengers
    end
end

---@param vehicle integer
Game.Vehicle.isEnemyVehicle = function(vehicle)
    if ENTITY.DOES_ENTITY_EXIST(vehicle) and ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        local occupants = Game.Vehicle.getOccupants(vehicle)
        if #occupants > 0 then
            for _, p in ipairs(occupants) do
                if not ENTITY.IS_ENTITY_DEAD(p, false) and Game.Self.isPedEnemy(p) then
                    return true
                end
            end
        end
    end
    return false
end

-- Returns whether a vehicle is weaponized.
---@param vehicle integer
Game.Vehicle.hasWeapons = function(vehicle)
    return VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(vehicle)
end

-- Returns whether local player's vehicle has ABS as standard.
Game.Vehicle.hasABS = function()
    if Game.Self.isDriving() and is_car then
        local m_model_flags = SS.getVehicleInfo().m_model_flags
        if m_model_flags ~= nil then
            local iModelFlags = m_model_flags:get_dword()
            return Lua_fn.has_bit(iModelFlags, MF._ABS_STD)
        end
    end
    return false
end

-- Returns whether local player's vehicle is a sports car.
--
-- *(different from the Sports class)*.
Game.Vehicle.isSportsCar = function()
    return SS.getVehicleModelFlag(VMF._SPORTS)
end

-- Returns whether local player's vehicle is a pussy shaver.
Game.Vehicle.isElectric = function()
    return SS.getVehicleModelFlag(VMF._IS_ELECTRIC)
end

-- Returns whether local player's vehicle is an F1 race car.
Game.Vehicle.isFormulaOne = function()
    return SS.getVehicleModelFlag(VMF._IS_FORMULA_VEHICLE) or
        Game.Vehicle.class(self.get_veh()) == "Open Wheel"
end

-- Returns whether local player's vehicle is a lowrider
--
-- equipped with hydraulic suspension.
Game.Vehicle.isLowrider = function()
    return SS.getVehicleModelFlag(VMF._HAS_LOWRIDER_HYDRAULICS) or
        SS.getVehicleModelFlag(VMF._HAS_LOWRIDER_DONK_HYDRAULICS)
end

-- Applies a custom paint job to the vehicle
---@param veh integer
---@param hex string
---@param p integer
---@param m boolean
---@param is_primary boolean
---@param is_secondary boolean
Game.Vehicle.setCustomPaint = function(veh, hex, p, m, is_primary, is_secondary)
    if ENTITY.DOES_ENTITY_EXIST(veh) then
        local pt = m and 3 or 1
        local r, g, b = Lua_fn.hexToRGB(hex)
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        if is_primary then
            VEHICLE.SET_VEHICLE_MOD_COLOR_1(veh, pt, 0, p)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh, r, g, b)
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, p, 0)
        end
        if is_secondary then
            VEHICLE.SET_VEHICLE_MOD_COLOR_2(veh, pt, 0)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh, r, g, b)
        end
    end
end

---@param vehicle integer
---@param toggle boolean
---@param s script_util
Game.Vehicle.lockDoors = function(vehicle, toggle, s)
    if VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(vehicle)) and
        entities.take_control_of(vehicle, 300) then
        if toggle then
            for i = 0, (VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(vehicle) + 1) do
                if VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(vehicle, i) > 0.0 then
                    VEHICLE.SET_VEHICLE_DOORS_SHUT(vehicle, false)
                    break
                end
            end
            if VEHICLE.IS_VEHICLE_A_CONVERTIBLE(vehicle, false) and autoraiseroof and
                VEHICLE.GET_CONVERTIBLE_ROOF_STATE(vehicle) ~= 0 then
                VEHICLE.RAISE_CONVERTIBLE_ROOF(vehicle, false)
            else
                for i = 0, 7 do
                    -- VEHICLE.FIX_VEHICLE_WINDOW(vehicle, i) -- Unnecessary. Locking your car doesn't magically fix its broken windows. *realism intensifies*
                    VEHICLE.ROLL_UP_WINDOW(vehicle, i)
                end
            end
        end
        -- these won't do anything if the engine is off --
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, true)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, true)
        --------------------------------------------------
        AUDIO.SET_HORN_PERMANENTLY_ON_TIME(vehicle, 1000)
        AUDIO.SET_HORN_PERMANENTLY_ON(vehicle)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, toggle and 2 or 1)
        VEHICLE.SET_VEHICLE_ALARM(vehicle, toggle)
        YimToast:ShowMessage("Samurai's Scripts", ("Vehicle %s"):format(toggle and "locked." or "unlocked."))
        s:sleep(696)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, false)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, false)
    end
end

---@class World
Game.World = {}
Game.World.__index = Game.World

---@param bool boolean
Game.World.extendBounds = function(bool)
    if bool then
        PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(-42069420.0, -42069420.0, -42069420.0)
        PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(42069420.0, 42069420.0, 42069420.0)
    else
        PLAYER.RESET_WORLD_BOUNDARY_FOR_PLAYER()
    end
end

---@param bool boolean
Game.World.disableOceanWaves = function(bool)
    if bool then
        MISC.WATER_OVERRIDE_SET_STRENGTH(1.0)
    else
        MISC.WATER_OVERRIDE_SET_STRENGTH(-1)
    end
end

-- Draws a green chevron down element on top of an entity in the game world.
---@param entity integer
Game.World.markSelectedEntity = function(entity)
    script.run_in_fiber(function()
        if not ENTITY.IS_ENTITY_ATTACHED(entity) then
            local entity_hash  = ENTITY.GET_ENTITY_MODEL(entity)
            local entity_pos   = ENTITY.GET_ENTITY_COORDS(entity, false)
            local min, max     = Game.getModelDimensions(entity_hash)
            local entityHeight = max.z - min.z
            GRAPHICS.DRAW_MARKER(2, entity_pos.x, entity_pos.y, entity_pos.z + (entityHeight + 0.4),
                -- Reference for textures: https://github.com/esc0rtd3w/illicit-sprx/blob/master/main/illicit/textures.h
                ---@diagnostic disable-next-line: param-type-mismatch
                0, 0, 0, 0, 180, 0, 0.3, 0.3, 0.3, 0, 255, 0, 100, true, true, 1, false, 0, 0, false)
        end
    end)
end
--#endregion
