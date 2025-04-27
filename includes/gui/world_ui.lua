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
    if b_ShowCarpoolUI then
        ImGui.SameLine()
        ImGui.BeginChild("NPCvehControls", 600, f_PosY or 400, true)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
        ImGui.SetWindowFontScale(1.2)
        ImGui.SeparatorText("NPC Vehicle Options")
        ImGui.SetWindowFontScale(1.0)
        if b_ShowCarpoolSeatControls and i_CarpoolVehicle ~= 0 then
            ImGui.SeparatorText("Seats:")
            if ImGui.Button(string.format("< %s", _T("PREVIOUS_SEAT_BTN_"))) then
                script.run_in_fiber(function()
                    if PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), i_CarpoolVehicle) then
                        local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(i_CarpoolVehicle)
                        local mySeat   = Game.GetPedVehicleSeat(Self.GetPedID())
                        if mySeat <= 0 then
                            mySeat = numSeats
                        end
                        mySeat = mySeat - 1
                        if VEHICLE.IS_VEHICLE_SEAT_FREE(i_CarpoolVehicle, mySeat, true) then
                            UI.WidgetSound("Nav")
                            PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), i_CarpoolVehicle, mySeat)
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
                    if PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), i_CarpoolVehicle) then
                        local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(i_CarpoolVehicle)
                        local mySeat   = Game.GetPedVehicleSeat(Self.GetPedID())
                        if mySeat > numSeats then
                            mySeat = 0
                        end
                        mySeat = mySeat + 1
                        if VEHICLE.IS_VEHICLE_SEAT_FREE(i_CarpoolVehicle, mySeat, true) then
                            UI.WidgetSound("Nav")
                            PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), i_CarpoolVehicle, mySeat)
                        else
                            mySeat = mySeat + 1
                            return
                        end
                    end
                end)
            end
        end
        if i_CarpoolDriver ~= 0 and ENTITY.DOES_ENTITY_EXIST(i_CarpoolDriver) and not ENTITY.IS_ENTITY_DEAD(i_CarpoolDriver, true)
            and PED.IS_PED_SITTING_IN_VEHICLE(i_CarpoolDriver, i_CarpoolVehicle) then
            ImGui.Spacing()
            ImGui.SeparatorText("Radio:")
            local mainRadioButtonLabel = b_CarpoolVehRadioEnabled and "Turn Off" or "Turn On"
            local mainRadioButtonParam = b_CarpoolVehRadioEnabled and "OFF" or
                t_RadioStations[math.random(1, (#t_RadioStations - 1))].station
            if ImGui.Button(mainRadioButtonLabel) then
                UI.WidgetSound("Select2")
                script.run_in_fiber(function()
                    AUDIO.SET_VEH_RADIO_STATION(i_CarpoolVehicle, mainRadioButtonParam)
                end)
            end
            if b_CarpoolVehRadioEnabled then
                ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
                if ImGui.Button("< Previous Station") then
                    UI.WidgetSound("Nav")
                    script.run_in_fiber(function()
                        AUDIO.SET_RADIO_RETUNE_DOWN()
                    end)
                end
                ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
                if ImGui.Button("Next Station >") then
                    UI.WidgetSound("Nav")
                    script.run_in_fiber(function()
                        AUDIO.SET_RADIO_RETUNE_UP()
                    end)
                end
            end
            if b_CarpoolVehIsConvertible then
                ImGui.Spacing()
                ImGui.SeparatorText("Convertible Roof:")
                local roofButtonLabel
                if i_CarpoolVehRoofState == 0 then
                    roofButtonLabel = "Lower"
                elseif i_CarpoolVehRoofState == 1 then
                    roofButtonLabel = "Lowering..."
                elseif i_CarpoolVehRoofState == 2 then
                    roofButtonLabel = "Raise"
                elseif i_CarpoolVehRoofState == 3 then
                    roofButtonLabel = "Raising..."
                else
                    roofButtonLabel = ""
                end
                ImGui.BeginDisabled(i_CarpoolVehRoofState == 1 or i_CarpoolVehRoofState == 3)
                if ImGui.Button(roofButtonLabel) then
                    if f_CarpoolVehicleCurrentSpeed > 6.66 then
                        UI.WidgetSound("Error")
                        YimToast:ShowError("Samurai's Scripts", "You can not operate the convertible roof at this speed.")
                    end
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function()
                        if i_CarpoolVehRoofState == 0 then
                            VEHICLE.LOWER_CONVERTIBLE_ROOF(i_CarpoolVehicle, false)
                        elseif i_CarpoolVehRoofState == 2 then
                            VEHICLE.RAISE_CONVERTIBLE_ROOF(i_CarpoolVehicle, false)
                        end
                    end)
                end
                ImGui.EndDisabled()
            end
            ImGui.Spacing()
            ImGui.SeparatorText("Driving Commands:")
            ImGui.BulletText("Driving Style:"); ImGui.SameLine(); i_CarpoolDrivingStyleSwitch, isChanged = ImGui.RadioButton("Chill",
                i_CarpoolDrivingStyleSwitch, 0)
            if isChanged then
                UI.WidgetSound("Nav")
                i_CarpoolDrivingFlags = 803243
                i_CarpoolDefaultDrivingSpeed = 19
                script.run_in_fiber(function()
                    TASK.SET_DRIVE_TASK_DRIVING_STYLE(i_CarpoolDriver, 803243)
                    TASK.SET_DRIVE_TASK_CRUISE_SPEED(i_CarpoolDriver, 19.0)
                    SS.UpdateNPCdriveTask()
                end)
            end
            ImGui.SameLine()
            i_CarpoolDrivingStyleSwitch, isChanged = ImGui.RadioButton("Aggressive", i_CarpoolDrivingStyleSwitch, 1)
            if isChanged then
                UI.WidgetSound("Nav")
                i_CarpoolDrivingFlags = 787324
                i_CarpoolDefaultDrivingSpeed = 70.0
                script.run_in_fiber(function()
                    TASK.SET_DRIVE_TASK_DRIVING_STYLE(i_CarpoolDriver, 787324)
                    TASK.SET_DRIVE_TASK_CRUISE_SPEED(i_CarpoolDriver, 70.0)
                    SS.UpdateNPCdriveTask()
                end)
            end
            if ImGui.Button("Stop The Vehicle") then
                script.run_in_fiber(function(stp)
                    TASK.CLEAR_PED_TASKS(i_CarpoolDriver)
                    TASK.CLEAR_PED_SECONDARY_TASK(i_CarpoolDriver)
                    TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_CarpoolVehicle)
                    if not VEHICLE.IS_VEHICLE_STOPPED(i_CarpoolVehicle) then
                        TASK.TASK_VEHICLE_TEMP_ACTION(i_CarpoolDriver, i_CarpoolVehicle, 1, 5000)
                        repeat
                            stp:sleep(10)
                        until VEHICLE.IS_VEHICLE_STOPPED(i_CarpoolVehicle)
                        ENTITY.FREEZE_ENTITY_POSITION(i_CarpoolVehicle, true)
                    end
                    s_NpcDriveTask = ""
                    repeat
                        stp:sleep(10)
                    until s_NpcDriveTask ~= "" or not PED.IS_PED_SITTING_IN_VEHICLE(Self.GetPedID(), i_CarpoolVehicle) or ENTITY.IS_ENTITY_DEAD(i_CarpoolDriver, true)
                    ENTITY.FREEZE_ENTITY_POSITION(i_CarpoolVehicle, false)
                end)
            end
            if ImGui.Button("Drive Around") then
                script.run_in_fiber(function()
                    if s_NpcDriveTask ~= "" then
                        TASK.CLEAR_PED_TASKS(i_CarpoolDriver)
                        TASK.CLEAR_PED_SECONDARY_TASK(i_CarpoolDriver)
                        TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_CarpoolVehicle)
                    end
                    TASK.TASK_VEHICLE_DRIVE_WANDER(i_CarpoolDriver, i_CarpoolVehicle, i_CarpoolDefaultDrivingSpeed, i_CarpoolDrivingFlags)
                    s_NpcDriveTask = "random"
                    YimToast:ShowMessage("Samurai's Scripts", "Cruising around...")
                end)
            end
            ImGui.SameLine()
            if ImGui.Button("Drive To Waypoint") then
                script.run_in_fiber(function()
                    local waypoint = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())
                    if not HUD.DOES_BLIP_EXIST(waypoint) then
                        UI.WidgetSound("Error")
                        YimToast:ShowError("Samurai's Scripts", "Please set a waypoint on the map first!")
                        return
                    else
                        UI.WidgetSound("Select")
                        if s_NpcDriveTask ~= "" then
                            TASK.CLEAR_PED_TASKS(i_CarpoolDriver)
                            TASK.CLEAR_PED_SECONDARY_TASK(i_CarpoolDriver)
                            TASK.CLEAR_PRIMARY_VEHICLE_TASK(i_CarpoolVehicle)
                        end
                        v_NpcDriveDestination = HUD.GET_BLIP_COORDS(waypoint)
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(i_CarpoolDriver, i_CarpoolVehicle, v_NpcDriveDestination.x, v_NpcDriveDestination.y,
                            v_NpcDriveDestination.z, i_CarpoolDefaultDrivingSpeed, i_CarpoolDrivingFlags, 100)
                        s_NpcDriveTask = "wp"
                        YimToast:ShowMessage("Samurai's Scripts", "Driving to waypoint...")
                    end
                end)
            end
            ImGui.SameLine()
            if ImGui.Button("Drive To Objective") then
                local objective_found, objective_coords = Game.FindObjectiveBlip()
                if not objective_found then
                    UI.WidgetSound("Error")
                    YimToast:ShowError("Samurai's Scripts", "No objective found!")
                else
                    v_NpcDriveDestination = objective_coords
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(i_CarpoolDriver, i_CarpoolVehicle, v_NpcDriveDestination.x, v_NpcDriveDestination.y,
                        v_NpcDriveDestination.z, i_CarpoolDefaultDrivingSpeed, i_CarpoolDrivingFlags, 100)
                    s_NpcDriveTask = "obj"
                    YimToast:ShowMessage("Samurai's Scripts", "Driving to objective...")
                end
            end
        end
        ImGui.PopStyleVar()
        ImGui.EndChild()
    end
end

function WorldUI()
    f_PosY = 560
    if pedGrabber or vehicleGrabber then
        f_PosY = f_PosY + 60
    end
    if animateNPCs then
        f_PosY = f_PosY + 60
    end

    ImGui.BeginChild("WoldChild", 460, f_PosY, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
    ImGui.BeginDisabled(b_PedGrabbed or b_VehicleGrabbed)
    pedGrabber, pgUsed = ImGui.Checkbox(_T("PED_GRABBER_CB_"), pedGrabber)
    UI.HelpMarker(_T("PED_GRABBER_DESC_"))
    if pgUsed then
        UI.WidgetSound("Nav2")
        vehicleGrabber = false
    end
    vehicleGrabber, vgUsed = ImGui.Checkbox("Vehicle Grabber", vehicleGrabber)
    UI.HelpMarker(_T("VEH_GRABBER_DESC_"))
    if vgUsed then
        UI.WidgetSound("Nav2")
        pedGrabber = false
    end
    ImGui.EndDisabled()

    if pedGrabber or vehicleGrabber then
        ImGui.Text(_T("THROW_FORCE_TXT_"))
        ImGui.SameLine()
        ImGui.PushItemWidth(220)
        i_PedThrowForce, ptfUsed = ImGui.SliderInt("##throw_force", i_PedThrowForce, 10, 100, "%d", 0)
        ImGui.PopItemWidth()
        if ptfUsed then
            UI.WidgetSound("Nav")
        end
    end

    carpool, carpoolUsed = ImGui.Checkbox(_T("CARPOOL_CB_"), carpool)
    UI.HelpMarker(_T("CARPOOL_DESC_"))
    if carpoolUsed then
        UI.WidgetSound("Nav2")
    end

    animateNPCs, used = ImGui.Checkbox(_T("ANIMATE_NPCS_CB_"), animateNPCs)
    if used then
        UI.WidgetSound("Nav")
    end
    UI.HelpMarker(_T("ANIMATE_NPCS_DESC_"))
    if animateNPCs then
        ImGui.PushItemWidth(220)
        DisplayHijackAnims()
        ImGui.PopItemWidth()
        local hijackData = t_HijackOptions[i_GroupAnimIndex + 1]
        ImGui.SameLine()
        if not b_NPCAnimStarted then
            if ImGui.Button(string.format("  %s  ##hjStart", _T("GENERIC_PLAY_BTN_"))) then
                UI.WidgetSound("Select")
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
                            b_NPCAnimStarted = true
                        end
                    end
                end)
            end
        else
            if ImGui.Button(string.format("  %s  ##hjStop", _T("GENERIC_STOP_BTN_"))) then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function()
                    local gta_peds = entities.get_all_peds_as_handles()
                    for _, npc in ipairs(gta_peds) do
                        if not PED.IS_PED_A_PLAYER(npc) then
                            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, false)
                            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, false)
                            TASK.CLEAR_PED_TASKS(npc)
                            b_NPCAnimStarted = false
                        end
                    end
                end)
            end
        end
    end

    kamikazeDrivers, kdUsed = ImGui.Checkbox(_T("KAMIKAZE_DRIVERS_CB_"), kamikazeDrivers)
    UI.HelpMarker(_T("KAMIKAZE_DRIVERS_DESC_"))
    if kdUsed then
        UI.WidgetSound("Nav2")
        if kamikazeDrivers then
            publicEnemy = false
        end
    end

    publicEnemy, peUsed = ImGui.Checkbox(_T("PUBLIC_ENEMY_CB_"), publicEnemy)
    UI.HelpMarker(_T("PUBLIC_ENEMY_DESC_"))
    if peUsed then
        UI.WidgetSound("Nav2")
        if publicEnemy then
            kamikazeDrivers = false
            runaway         = false
            script.run_in_fiber(function()
                i_DefaultWantedLevel = PLAYER.GET_MAX_WANTED_LEVEL()
            end)
        else
            script.run_in_fiber(function()
                local myGroup = PED.GET_PED_GROUP_INDEX(Self.GetPedID())
                if i_DefaultWantedLevel ~= nil then
                    PLAYER.SET_MAX_WANTED_LEVEL(i_DefaultWantedLevel)
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
        UI.WidgetSound("Nav2")
        CFG:SaveItem("public_seats", public_seats)
    end

    ambient_scenarios, ascnUsed = ImGui.Checkbox("Ambient Scenarios", ambient_scenarios)
    UI.HelpMarker(_T("AMB_SCN_DESC_"))
    if ascnUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("ambient_scenarios", ambient_scenarios)
    end

    if ambient_scenarios then
        ImGui.SameLine()
        ambient_scenario_prompt, ascnpUsed = ImGui.Checkbox("Show Prompt", ambient_scenario_prompt)
        UI.HelpMarker("Enable or disable button prompts when near an ambient scenario location.")
        if ascnpUsed then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("ambient_scenario_prompt", ambient_scenario_prompt)
        end
    end

    extend_world, ewbUsed = ImGui.Checkbox(_T("EXTEND_WORLD_CB_"), extend_world)
    UI.HelpMarker(_T("EXTEND_WORLD_DESC_"))
    if ewbUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("extend_world", extend_world)
        if not extend_world then
            script.run_in_fiber(function()
                Game.World.ExtendBounds(false)
                b_WorldBoundsExtended = false
            end)
        end
    end

    disable_waves, dowUsed = ImGui.Checkbox(_T("SMOOTH_WATERS_CB_"), disable_waves)
    UI.HelpMarker(_T("SMOOTH_WATERS_DESC_"))
    if dowUsed then
        UI.WidgetSound("Nav2")
        Game.World.DisableOceanWaves(disable_waves)
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
    if carpool and b_ShowCarpoolUI then
        ShowNPCvehicleControls()
    end
end
