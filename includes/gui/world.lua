---@diagnostic disable

local i_GroupAnimIndex = 0

local function DisplayHijackAnims()
    local t_GroupAnimNames = {}
    for _, anim in ipairs(t_HijackOptions) do
        table.insert(t_GroupAnimNames, anim.name)
    end
    i_GroupAnimIndex, _ = ImGui.Combo("##groupAnims", i_GroupAnimIndex, t_GroupAnimNames, #t_HijackOptions)
end

local ShowNPCvehicleControls = function()
    if show_npc_veh_ui then
        ImGui.SameLine()
        ImGui.BeginChild("NPCvehControls", 600, f_PosY or 400, true)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
        ImGui.SetWindowFontScale(1.2)
        ImGui.SeparatorText("NPC Vehicle Options")
        ImGui.SetWindowFontScale(1.0)
        if show_npc_veh_seat_ctrl and i_ThisVeh ~= 0 then
            ImGui.SeparatorText("Seats:")
            if ImGui.Button(string.format("< %s", _T("PREVIOUS_SEAT_BTN_"))) then
                script.run_in_fiber(function()
                    if PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), i_ThisVeh) then
                        local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(i_ThisVeh)
                        local mySeat   = Game.GetPedVehicleSeat(Self.GetPedID())
                        if mySeat <= 0 then
                            mySeat = numSeats
                        end
                        mySeat = mySeat - 1
                        if VEHICLE.IS_VEHICLE_SEAT_FREE(i_ThisVeh, mySeat, true) then
                            UI.widgetSound("Nav")
                            PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), i_ThisVeh, mySeat)
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
                    if PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), i_ThisVeh) then
                        local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(i_ThisVeh)
                        local mySeat   = Game.GetPedVehicleSeat(Self.GetPedID())
                        if mySeat > numSeats then
                            mySeat = 0
                        end
                        mySeat = mySeat + 1
                        if VEHICLE.IS_VEHICLE_SEAT_FREE(i_ThisVeh, mySeat, true) then
                            UI.widgetSound("Nav")
                            PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), i_ThisVeh, mySeat)
                        else
                            mySeat = mySeat + 1
                            return
                        end
                    end
                end)
            end
        end
        if i_NpcDriver ~= 0 and ENTITY.DOES_ENTITY_EXIST(i_NpcDriver) and not ENTITY.IS_ENTITY_DEAD(i_NpcDriver, true)
            and PED.IS_PED_SITTING_IN_VEHICLE(i_NpcDriver, i_ThisVeh) then
            ImGui.Spacing()
            ImGui.SeparatorText("Radio:")
            local mainRadioButtonLabel = npc_veh_radio_on and "Turn Off" or "Turn On"
            local mainRadioButtonParam = npc_veh_radio_on and "OFF" or
                t_RadioStations[math.random(1, (#t_RadioStations - 1))].station
            if ImGui.Button(mainRadioButtonLabel) then
                UI.widgetSound("Select2")
                script.run_in_fiber(function()
                    AUDIO.SET_VEH_RADIO_STATION(i_ThisVeh, mainRadioButtonParam)
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
                ImGui.Spacing()
                ImGui.SeparatorText("Convertible Roof:")
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
                            VEHICLE.LOWER_CONVERTIBLE_ROOF(i_ThisVeh, false)
                        elseif npc_veh_roof_state == 2 then
                            VEHICLE.RAISE_CONVERTIBLE_ROOF(i_ThisVeh, false)
                        end
                    end)
                end
                ImGui.EndDisabled()
            end
            ImGui.Spacing()
            ImGui.SeparatorText("Driving Commands:")
            ImGui.BulletText("Driving Style:"); ImGui.SameLine(); npcDriveSwitch, isChanged = ImGui.RadioButton("Chill",
                npcDriveSwitch, 0)
            if isChanged then
                UI.widgetSound("Nav")
                npcDrivingFlags = 803243
                npcDrivingSpeed = 19
                script.run_in_fiber(function()
                    TASK.SET_DRIVE_TASK_DRIVING_STYLE(i_NpcDriver, 803243)
                    TASK.SET_DRIVE_TASK_CRUISE_SPEED(i_NpcDriver, 19.0)
                    SS.UpdateNPCdriveTask()
                end)
            end
            ImGui.SameLine()
            npcDriveSwitch, isChanged = ImGui.RadioButton("Aggressive", npcDriveSwitch, 1)
            if isChanged then
                UI.widgetSound("Nav")
                npcDrivingFlags = 787324
                npcDrivingSpeed = 70.0
                script.run_in_fiber(function()
                    TASK.SET_DRIVE_TASK_DRIVING_STYLE(i_NpcDriver, 787324)
                    TASK.SET_DRIVE_TASK_CRUISE_SPEED(i_NpcDriver, 70.0)
                    SS.UpdateNPCdriveTask()
                end)
            end
            if ImGui.Button("Stop The Vehicle") then
                script.run_in_fiber(function(stp)
                    TASK.CLEAR_PED_TASKS(i_NpcDriver)
                    TASK.CLEAR_PED_SECONDARY_TASK(i_NpcDriver)
                    TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_ThisVeh)
                    if not VEHICLE.IS_VEHICLE_STOPPED(i_ThisVeh) then
                        TASK.TASK_VEHICLE_TEMP_ACTION(i_NpcDriver, i_ThisVeh, 1, 5000)
                        repeat
                            stp:sleep(10)
                        until VEHICLE.IS_VEHICLE_STOPPED(i_ThisVeh)
                        ENTITY.FREEZE_ENTITY_POSITION(i_ThisVeh, true)
                    end
                    npcDriveTask = ""
                    repeat
                        stp:sleep(10)
                    until npcDriveTask ~= "" or not PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), i_ThisVeh) or ENTITY.IS_ENTITY_DEAD(i_NpcDriver, true)
                    ENTITY.FREEZE_ENTITY_POSITION(i_ThisVeh, false)
                end)
            end
            if ImGui.Button("Drive Around") then
                script.run_in_fiber(function()
                    if npcDriveTask ~= "" then
                        TASK.CLEAR_PED_TASKS(i_NpcDriver)
                        TASK.CLEAR_PED_SECONDARY_TASK(i_NpcDriver)
                        TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_ThisVeh)
                    end
                    TASK.TASK_VEHICLE_DRIVE_WANDER(i_NpcDriver, i_ThisVeh, npcDrivingSpeed, npcDrivingFlags)
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
                            TASK.CLEAR_PED_TASKS(i_NpcDriver)
                            TASK.CLEAR_PED_SECONDARY_TASK(i_NpcDriver)
                            TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_ThisVeh)
                        end
                        npcDriveDest = HUD.GET_BLIP_COORDS(waypoint)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(i_NpcDriver, i_ThisVeh, npcDriveDest.x, npcDriveDest.y,
                            npcDriveDest.z, npcDrivingSpeed, npcDrivingFlags, 100)
                        npcDriveTask = "wp"
                        YimToast:ShowMessage("Samurai's Scripts", "Driving to waypoint...")
                    end
                end)
            end
            ImGui.SameLine()
            if ImGui.Button("Drive To Objective") then
                local objective_found, objective_coords = Game.FindObjectiveBlip()
                if not objective_found then
                    UI.widgetSound("Error")
                    YimToast:ShowError("Samurai's Scripts", "No objective found!")
                else
                    npcDriveDest = objective_coords
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(i_NpcDriver, i_ThisVeh, npcDriveDest.x, npcDriveDest.y,
                        npcDriveDest.z, npcDrivingSpeed, npcDrivingFlags, 100)
                    npcDriveTask = "obj"
                    YimToast:ShowMessage("Samurai's Scripts", "Driving to objective...")
                end
            end
        end
        ImGui.PopStyleVar()
        ImGui.EndChild()
    end
end

function worldUI()
    f_PosY = 560
    if pedGrabber or vehicleGrabber then
        f_PosY = f_PosY + 60
    end
    if animateNPCs then
        f_PosY = f_PosY + 60
    end

    ImGui.BeginChild("WoldChild", 460, f_PosY, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
    ImGui.BeginDisabled(ped_grabbed or vehicle_grabbed)
    pedGrabber, pgUsed = ImGui.Checkbox(_T("PED_GRABBER_CB_"), pedGrabber)
    UI.HelpMarker(_T("PED_GRABBER_DESC_"))
    if pgUsed then
        UI.widgetSound("Nav2")
        vehicleGrabber = false
    end
    vehicleGrabber, vgUsed = ImGui.Checkbox("Vehicle Grabber", vehicleGrabber)
    UI.HelpMarker(_T("VEH_GRABBER_DESC_"))
    if vgUsed then
        UI.widgetSound("Nav2")
        pedGrabber = false
    end
    ImGui.EndDisabled()

    if pedGrabber or vehicleGrabber then
        ImGui.Text(_T("THROW_FORCE_TXT_"))
        ImGui.SameLine()
        ImGui.PushItemWidth(220)
        pedthrowF, ptfUsed = ImGui.SliderInt("##throw_force", pedthrowF, 10, 100, "%d", 0)
        ImGui.PopItemWidth()
        if ptfUsed then
            UI.widgetSound("Nav")
        end
    end

    carpool, carpoolUsed = ImGui.Checkbox(_T("CARPOOL_CB_"), carpool)
    UI.HelpMarker(_T("CARPOOL_DESC_"))
    if carpoolUsed then
        UI.widgetSound("Nav2")
    end

    animateNPCs, used = ImGui.Checkbox(_T("ANIMATE_NPCS_CB_"), animateNPCs)
    if used then
        UI.widgetSound("Nav")
    end
    UI.HelpMarker(_T("ANIMATE_NPCS_DESC_"))
    if animateNPCs then
        ImGui.PushItemWidth(220)
        DisplayHijackAnims()
        ImGui.PopItemWidth()
        local hijackData = t_HijackOptions[i_GroupAnimIndex + 1]
        ImGui.SameLine()
        if not hijack_started then
            if ImGui.Button(string.format("  %s  ##hjStart", _T("GENERIC_PLAY_BTN_"))) then
                UI.widgetSound("Select")
                script.run_in_fiber(function(hjk)
                    local gta_peds = entities.get_all_peds_as_handles()
                    while not STREAMING.HAS_ANIM_DICT_LOADED(hijackData.dict) do
                        STREAMING.REQUEST_ANIM_DICT(hijackData.dict)
                        coroutine.yield()
                    end
                    for _, npc in pairs(gta_peds) do
                        if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
                            TASK.CLEAR_PED_SECONDARY_TASK(npc)
                            hjk:sleep(50)
                            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
                            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
                            TASK.TASK_PLAY_ANIM(npc, hijackData.dict, hijackData.anim, 4.0, -4.0, -1, 1, 1.0, false,
                                false, false)
                            hijack_started = true
                        end
                    end
                end)
            end
        else
            if ImGui.Button(string.format("  %s  ##hjStop", _T("GENERIC_STOP_BTN_"))) then
                UI.widgetSound("Cancel")
                script.run_in_fiber(function()
                    local gta_peds = entities.get_all_peds_as_handles()
                    for _, npc in ipairs(gta_peds) do
                        if not PED.IS_PED_A_PLAYER(npc) then
                            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, false)
                            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, false)
                            TASK.CLEAR_PED_TASKS(npc)
                            hijack_started = false
                        end
                    end
                end)
            end
        end
    end

    kamikazeDrivers, kdUsed = ImGui.Checkbox(_T("KAMIKAZE_DRIVERS_CB_"), kamikazeDrivers)
    UI.HelpMarker(_T("KAMIKAZE_DRIVERS_DESC_"))
    if kdUsed then
        UI.widgetSound("Nav2")
        if kamikazeDrivers then
            publicEnemy = false
        end
    end

    publicEnemy, peUsed = ImGui.Checkbox(_T("PUBLIC_ENEMY_CB_"), publicEnemy)
    UI.HelpMarker(_T("PUBLIC_ENEMY_DESC_"))
    if peUsed then
        UI.widgetSound("Nav2")
        if publicEnemy then
            kamikazeDrivers = false
            runaway         = false
            script.run_in_fiber(function()
                default_wanted_lvl = PLAYER.GET_MAX_WANTED_LEVEL()
            end)
        else
            script.run_in_fiber(function()
                local myGroup = PED.GET_PED_GROUP_INDEX(Self.GetPedID())
                if default_wanted_lvl ~= nil then
                    PLAYER.SET_MAX_WANTED_LEVEL(default_wanted_lvl)
                    PLAYER.SET_POLICE_IGNORE_PLAYER(self.get_id(), false)
                end
                for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                    if not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_GROUP_MEMBER(ped, myGroup) then
                        if PED.IS_PED_IN_COMBAT(ped, Self.GetPedID()) then
                            for _, attr in ipairs(t_PEcombatAttributes) do
                                PED.SET_PED_COMBAT_ATTRIBUTES(ped, attr.id, (not attr.bool))
                            end
                            for _, cflg in ipairs(t_PEconfigFlags) do
                                if PED.GET_PED_CONFIG_FLAG(ped, cflg.id, cflg.bool) then
                                    PED.SET_PED_CONFIG_FLAG(ped, cflg.id, (not cflg.bool))
                                end
                            end
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, false)
                            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, false)
                        end
                    end
                end
            end)
        end
    end

    public_seats, pseatsUsed = ImGui.Checkbox("Public Seating", public_seats)
    UI.HelpMarker(_T("PUBLIC_SEATS_DESC_"))
    if pseatsUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("public_seats", public_seats)
    end

    ambient_scenarios, ascnUsed = ImGui.Checkbox("Ambient Scenarios", ambient_scenarios)
    UI.HelpMarker(_T("AMB_SCN_DESC_"))
    if ascnUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("ambient_scenarios", ambient_scenarios)
    end

    if ambient_scenarios then
        ImGui.SameLine()
        ambient_scenario_prompt, ascnpUsed = ImGui.Checkbox("Show Prompt", ambient_scenario_prompt)
        UI.HelpMarker("Enable or disable button prompts when near an ambient scenario location.")
        if ascnpUsed then
            UI.widgetSound("Nav2")
            CFG:SaveItem("ambient_scenario_prompt", ambient_scenario_prompt)
        end
    end

    extend_world, ewbUsed = ImGui.Checkbox(_T("EXTEND_WORLD_CB_"), extend_world)
    UI.HelpMarker(_T("EXTEND_WORLD_DESC_"))
    if ewbUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("extend_world", extend_world)
        if not extend_world then
            script.run_in_fiber(function()
                Game.World.ExtendBounds(false)
                world_extended = false
            end)
        end
    end

    disable_waves, dowUsed = ImGui.Checkbox(_T("SMOOTH_WATERS_CB_"), disable_waves)
    UI.HelpMarker(_T("SMOOTH_WATERS_DESC_"))
    if dowUsed then
        UI.widgetSound("Nav2")
        Game.World.DisableOceanWaves(disable_waves)
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
    if carpool and show_npc_veh_ui then
        ShowNPCvehicleControls()
    end
end
