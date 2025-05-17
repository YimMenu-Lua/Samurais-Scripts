---@diagnostic disable

local i_GroupAnimIndex = 0
local i_CarpoolDrivingStyleSwitch = 1
local b_dsChill = false
local b_dsFast = false
local b_NPCAnimStarted = false
local t_AnimatedNPCs = {}

local function DisplayHijackAnims()
    local t_GroupAnimNames = {}
    for _, anim in ipairs(t_HijackOptions) do
        table.insert(t_GroupAnimNames, anim.name)
    end

    i_GroupAnimIndex, _ = ImGui.Combo("##groupAnims", i_GroupAnimIndex, t_GroupAnimNames, #t_HijackOptions)
end

local ShowNPCvehicleControls = function()
    if Carpool.isCarpooling then
        ImGui.SameLine()
        ImGui.BeginChild("NPCvehControls", 600, f_PosY or 400, true)
            ImGui.SetWindowFontScale(1.2)
            ImGui.SeparatorText("NPC Vehicle Options")
            ImGui.SetWindowFontScale(1.0)

            ImGui.Spacing()
            ImGui.SeparatorText("Driving Commands:")
            ImGui.Spacing()

            ImGui.BulletText("Driving Style:")
            ImGui.SameLine()
            i_CarpoolDrivingStyleSwitch, b_dsChill = ImGui.RadioButton("Chill", i_CarpoolDrivingStyleSwitch, 1)

            ImGui.SameLine()

            i_CarpoolDrivingStyleSwitch, b_dsFast = ImGui.RadioButton("Aggressive", i_CarpoolDrivingStyleSwitch, 2)

            if b_dsChill or b_dsFast then
                UI.WidgetSound("Nav")
                Carpool:SetDrivingStyle(i_CarpoolDrivingStyleSwitch)
            end

            if ImGui.Button(Carpool.task ~= 99 and "Stop The Vehicle" or "Keep Driving") then
                script.run_in_fiber(function(s)
                    if Carpool.task ~= 99 then
                        Carpool:Stop()
                    else
                        Carpool:Resume(s)
                    end
                end)
            end

            ImGui.SameLine()

            if ImGui.Button("Cruise Around") then
                script.run_in_fiber(function(s)
                    Carpool:Wander(s)
                end)
            end

            if ImGui.Button("Drive To Waypoint") then
                script.run_in_fiber(function(s)
                    local waypoint = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())

                    if not HUD.DOES_BLIP_EXIST(waypoint) then
                        UI.WidgetSound("Error")
                        YimToast:ShowError(
                            "Samurai's Scripts",
                            "Please set a waypoint on the map first!"
                        )
                        return
                    end

                    UI.WidgetSound("Select")
                    local v_Pos = HUD.GET_BLIP_COORDS(waypoint)

                    Carpool:GoTo(v_Pos, s)
                    YimToast:ShowMessage(
                        "Samurai's Scripts",
                        "Driving to waypoint..."
                    )
                end)
            end

            ImGui.SameLine()

            if ImGui.Button("Drive To Objective") then
                script.run_in_fiber(function(s)
                local objective_found, objective_coords = Game.GetObjectiveBlipCoords()
                if not objective_found then
                    UI.WidgetSound("Error")
                    YimToast:ShowError(
                        "Samurai's Scripts",
                        "No objective found!"
                    )
                    return
                end

                UI.WidgetSound("Select")
                Carpool:GoTo(objective_coords, s)
                YimToast:ShowMessage("Samurai's Scripts", "Driving to objective...")
                end)
            end

            if Carpool.vehicleData.maxSeats > 1 then
                ImGui.Spacing()
                ImGui.SeparatorText("Seats:")
                ImGui.Spacing()

                if ImGui.Button(string.format("< %s", _T("PREVIOUS_SEAT_BTN_"))) then
                    Carpool:ShuffleSeats(-1)
                end

                ImGui.SameLine()
                if ImGui.Button(string.format("%s >", _T("NEXT_SEAT_BTN_"))) then
                    Carpool:ShuffleSeats(1)
                end
            end

            if (Carpool.driver ~= 0) then
                ImGui.Spacing()
                ImGui.SeparatorText("Radio:")

                if ImGui.Button(Carpool.vehicleData.radio.isOn and "Turn Off" or "Turn On") then
                    UI.WidgetSound("Select2")
                    script.run_in_fiber(function()
                        AUDIO.SET_VEH_RADIO_STATION(
                            i_CarpoolVehicle,
                            Carpool.vehicleData.radio.isOn
                            and "OFF"
                            or t_RadioStations[math.random(1, (#t_RadioStations - 1))].station
                        )
                    end)
                end

                ImGui.SameLine()

                UI.VehicleRadioCombo(
                    Carpool.vehicle,
                    "##carpoolradio",
                    tostring(Carpool.vehicleData.radio.station)
                )

                if Carpool.vehicleData.isConvertible then
                    ImGui.Spacing()
                    ImGui.SeparatorText("Convertible Roof:")
                    ImGui.Spacing()

                    local roofButtonLabel

                    if Carpool.vehicleData.roofState == 0 then
                        roofButtonLabel = "Lower"
                    elseif Carpool.vehicleData.roofState == 1 then
                        roofButtonLabel = "Lowering..."
                    elseif Carpool.vehicleData.roofState == 2 then
                        roofButtonLabel = "Raise"
                    elseif Carpool.vehicleData.roofState == 3 then
                        roofButtonLabel = "Raising..."
                    else
                        roofButtonLabel = ""
                    end

                    ImGui.BeginDisabled((Carpool.vehicleData.roofState == 1) or (Carpool.vehicleData.roofState == 3))

                    if ImGui.Button(roofButtonLabel) then
                        if Carpool.vehicleData.speed > 6.66 then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Samurai's Scripts",
                                "You can not operate the convertible roof at this speed."
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            if Carpool.vehicleData.roofState == 0 then
                                VEHICLE.LOWER_CONVERTIBLE_ROOF(Carpool.vehicle, false)
                            elseif Carpool.vehicleData.roofState == 2 then
                                VEHICLE.RAISE_CONVERTIBLE_ROOF(Carpool.vehicle, false)
                            end
                        end)
                    end
                    ImGui.EndDisabled()
                end
            end
        ImGui.EndChild()
    end
end

function WorldUI()
    f_PosY = 560
    if b_PedGrabber or b_VehicleGrabber then
        f_PosY = f_PosY + 60
    end
    if animateNPCs then
        f_PosY = f_PosY + 60
    end

    ImGui.BeginChild("WoldChild", 460, f_PosY, true)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
        ImGui.BeginDisabled(b_PedGrabbed or b_VehicleGrabbed)
            b_PedGrabber, pgUsed = ImGui.Checkbox(_T("PED_GRABBER_CB_"), b_PedGrabber)
            UI.HelpMarker(_T("PED_GRABBER_DESC_"))

            if pgUsed then
                UI.WidgetSound("Nav2")
                b_VehicleGrabber = false
            end

            b_VehicleGrabber, vgUsed = ImGui.Checkbox("Vehicle Grabber", b_VehicleGrabber)
            UI.HelpMarker(_T("VEH_GRABBER_DESC_"))

            if vgUsed then
                UI.WidgetSound("Nav2")
                b_PedGrabber = false
            end

        ImGui.EndDisabled()

        if b_PedGrabber or b_VehicleGrabber then
            ImGui.Text(_T("THROW_FORCE_TXT_"))
            ImGui.SameLine()
            ImGui.PushItemWidth(220)
            i_PedThrowForce, ptfUsed = ImGui.SliderInt("##throw_force", i_PedThrowForce, 10, 100, "%d", 0)
            ImGui.PopItemWidth()

            if ptfUsed then
                UI.WidgetSound("Nav")
            end
        end

        b_Carpool, carpoolUsed = ImGui.Checkbox(_T("CARPOOL_CB_"), b_Carpool)
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

                        Await(Game.RequestAnimDict, hijackData.dict)

                        for _, npc in pairs(gta_peds) do
                            if not PED.IS_PED_A_PLAYER(npc)
                            and not PED.IS_PED_IN_ANY_VEHICLE(npc, true)
                            and not PED.IS_PED_GROUP_MEMBER(ped, Self.GetGroupIndex())
                            and not SS.IsScriptEntity(ped) then
                                TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
                                TASK.CLEAR_PED_SECONDARY_TASK(npc)
                                hjk:sleep(50)
                                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
                                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
                                TASK.TASK_PLAY_ANIM(
                                    npc,
                                    hijackData.dict,
                                    hijackData.anim,
                                    4.0,
                                    -4.0,
                                    -1,
                                    1,
                                    1.0,
                                    false,
                                    false,
                                    false
                                )

                                b_NPCAnimStarted = true
                                table.insert(t_AnimatedNPCs, ped)
                            end
                        end
                    end)
                end
            else
                if ImGui.Button(string.format("  %s  ##hjStop", _T("GENERIC_STOP_BTN_"))) then
                    UI.WidgetSound("Cancel")
                    script.run_in_fiber(function()
                        local t_Peds = (#t_AnimatedNPCs ~= 0) and t_AnimatedNPCs or entities.get_all_peds_as_handles()

                        for _, npc in ipairs(t_Peds) do
                            if not PED.IS_PED_A_PLAYER(npc)
                            and not PED.IS_PED_IN_ANY_VEHICLE(npc, true)
                            and not PED.IS_PED_GROUP_MEMBER(ped, Self.GetGroupIndex())
                            and not SS.IsScriptEntity(ped) then
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
                runaway = false

                script.run_in_fiber(function()
                    i_DefaultWantedLevel = PLAYER.GET_MAX_WANTED_LEVEL()
                end)
            else
                script.run_in_fiber(function()
                    if i_DefaultWantedLevel then
                        PLAYER.SET_MAX_WANTED_LEVEL(i_DefaultWantedLevel)
                        PLAYER.SET_POLICE_IGNORE_PLAYER(self.get_id(), false)
                    end

                    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                        if not PED.IS_PED_A_PLAYER(npc)
                        and not PED.IS_PED_GROUP_MEMBER(ped, Self.GetGroupIndex())
                        and not SS.IsScriptEntity(ped)
                        and PED.IS_PED_IN_COMBAT(ped, Self.GetPedID()) then
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

    if b_Carpool and Carpool.isCarpooling then
        ShowNPCvehicleControls()
    end
end
