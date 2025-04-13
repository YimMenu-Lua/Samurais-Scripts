---@diagnostic disable

local t_SelectedEngine
local i_EngineSwapIndex    = 0
local i_VehSoundIndex      = 0
local t_EngineSoundsWindow = { should_draw = false }
local t_EngineSwapsWindow  = { should_draw = false }
local t_SpeedometerWindow  = { should_draw = false }
local VehCBGrid            = GridRenderer:New(2, 25, 10)
local PlaneGridCB          = GridRenderer:New(2, 25, 10)

local function FilterVehNames()
    t_FilteredNames = {}
    for _, veh in ipairs(t_GameVehicles) do
        if VEHICLE.IS_THIS_MODEL_A_CAR(joaat(veh)) or VEHICLE.IS_THIS_MODEL_A_BIKE(joaat(veh)) or VEHICLE.IS_THIS_MODEL_A_QUADBIKE(joaat(veh)) then
            valid_veh = veh
            if string.find(valid_veh:lower(), search_term:lower()) then
                table.insert(t_FilteredNames, valid_veh)
            end
        end
    end
end

local function DisplayVehNames()
    FilterVehNames()
    local t_VehNames = {}
    for _, veh in ipairs(t_FilteredNames) do
        local vehName = vehicles.get_vehicle_display_name(joaat(veh))
        if string.find(string.lower(veh), "drift") then
            vehName = string.format("%s  (Drift)", vehName)
        end
        table.insert(t_VehNames, vehName)
    end
    i_VehSoundIndex, used = ImGui.ListBox("##Vehicle Names", i_VehSoundIndex, t_VehNames, #t_FilteredNames)
end

VehCBGrid:AddCheckbox(
    _T("FAST_VEHS_CB_"),
    "fast_vehicles",
    function()
        if (
            not fast_vehicles and
            (Self.Vehicle.Current ~= 0) and
            (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad)
        ) then
            script.run_in_fiber(function()
                VEHICLE.MODIFY_VEHICLE_TOP_SPEED(Self.Vehicle.Current, 0)
            end)
        end
    end,
    nil,
    true,
    function()
        UI.Tooltip(_T("FAST_VEHS_TXT_"))
    end
)

VehCBGrid:AddCheckbox(
    "Launch Control",
    "launchCtrl",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("LAUNCH_CTRL_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "NOS",
    "speedBoost",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("NOS_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Big Subwoofer",
    "loud_radio",
    function()
        if not loud_radio then
            script.run_in_fiber(function()
                AUDIO.SET_VEHICLE_RADIO_LOUD(Self.Vehicle.Current, false)
                Self.Vehicle.HasLoudRadio = false
            end)
        end
    end,
    nil,
    true,
    function()
        UI.Tooltip(_T("LOUD_RADIO_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "NOS Purge",
    "nosPurge",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("NOS_PURGE_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Pops & Bangs",
    "popsNbangs",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("POPSNBANGS_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "High Beams on Horn",
    "hornLight",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("HIGH_BEAMS_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Auto Brake Lights",
    "autobrklight",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("BRAKE_LIGHT_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Keep Engine On",
    "holdF",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("IV_STYLE_EXIT_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Keep Wheels Turned",
    "keepWheelsTurned",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("KEEP_WHEELS_TURNED_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Can't Touch This!",
    "noJacking",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("CANT_TOUCH_THIS_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Instant 180°",
    "insta180",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("INSTA_180_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Strong Windows",
    "unbreakableWindows",
    function()
        if not unbreakableWindows and Self.Vehicle.HasUnbreakableWindows then
            script.run_in_fiber(function()
                VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(Self.Vehicle.Current, false)
                Self.Vehicle.HasUnbreakableWindows = false
            end)
        end
    end,
    nil,
    true,
    function()
        UI.Tooltip(_T("STRONG_WINDOWS_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Flappy Doors",
    "flappyDoors",
    nil,
    nil,
    true
)

VehCBGrid:AddCheckbox(
    "Vehicle Mines",
    "veh_mines",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("VEHICLE_MINES_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    "Better Car Crashes",
    "fender_bender",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("FENDER_BENDER_DESC_"))
    end
)

VehCBGrid:AddCheckbox(
    _T("RGB_LIGHTS_CB_"),
    "rgbLights",
    function()
        if rgbLights then
            script.run_in_fiber(function(rgbhl)
                if not VEHICLE.IS_TOGGLE_MOD_ON(Self.Vehicle.Current, 22) then
                    has_xenon = false
                else
                    has_xenon      = true
                    i_DefaultXenon = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(Self.Vehicle.Current)
                end
                rgbhl:sleep(200)
                start_rgb_loop = true
            end)
        else
            start_rgb_loop = false
        end
    end,
    nil,
    true
)

VehCBGrid:AddCheckbox(
    "ABS Brake Lights",
    "abs_lights",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("ABS_LIGHTS_DESC_"))
    end
)

PlaneGridCB:AddCheckbox(
    "Flares For All",
    "flares_forall",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("FLARES_FOR_ALL_DESC_"))
    end,
    not Game.IsOnline()
)

PlaneGridCB:AddCheckbox(
    "Higher Jet Speed",
    "real_plane_speed",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("PLANE_SPEED_DESC_"))
    end
)

PlaneGridCB:AddCheckbox(
    "No Engine Stalling",
    "no_stall",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("NO_ENGINE_STALL_DESC_"))
    end
)

PlaneGridCB:AddCheckbox(
    "Cannon Triggerbot",
    "cannon_triggerbot",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("CANNON_TRIGGERBOT_DESC_"))
    end
)

PlaneGridCB:AddCheckbox(
    "Cannon Manual Aim",
    "cannon_manual_aim",
    function()
        if not cannon_manual_aim then
            script.run_in_fiber(function()
                if (
                    Self.IsDriving() and
                    Self.Vehicle.IsHeli and
                    (ENTITY.GET_ENTITY_ALPHA(Self.Vehicle.Current) < 255)
                ) then
                    ENTITY.RESET_ENTITY_ALPHA(Self.Vehicle.Current)
                end
            end)
        end
    end,
    nil,
    true,
    function()
        UI.Tooltip(_T("CANNON_MANUAL_AIM_DESC_"))
    end
)

function VehicleUI()
    ImGui.BeginChild("Cars", 440, 440, true)
    ImGui.SetWindowFontScale(1.2)
    ImGui.SeparatorText("Cars & Bikes")
    ImGui.SetWindowFontScale(1)
    ImGui.Dummy(1, 10)
    VehCBGrid:Draw()
    ImGui.EndChild()

    ImGui.SameLine()
    ImGui.BeginChild("Aircraft", 410, 440, true)
    ImGui.SetWindowFontScale(1.2)
    ImGui.SeparatorText("Planes & Helis")
    ImGui.SetWindowFontScale(1)
    ImGui.Dummy(1, 10)
    PlaneGridCB:Draw()

    local aircraft_check = Self.IsDriving() and (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli)
    ImGui.Spacing(); ImGui.BeginDisabled(not aircraft_check)
    ImGui.SeparatorText("Auto-Pilot")
    if ImGui.Button(" Fly To Waypoint ") then
        UI.WidgetSound("Select")
        script.run_in_fiber(function(ap)
            local wp = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())
            if HUD.DOES_BLIP_EXIST(wp) then
                local waypoint_coords = HUD.GET_BLIP_COORDS(wp)
                if autopilot_objective or autopilot_random then
                    TASK.CLEAR_PED_TASKS(Self.GetPedID())
                    TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
                end
                autopilot_waypoint  = true
                autopilot_objective = false
                autopilot_random    = false
                YimToast:ShowSuccess("Samurai's Scripts", "Flying towards your waypoint")
                if Self.Vehicle.IsPlane then
                    local initialHoverModeState = VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(Self.Vehicle.Current)
                    TASK.TASK_PLANE_MISSION(
                        Self.GetPedID(), Self.Vehicle.Current, 0, 0, waypoint_coords.x, waypoint_coords.y,
                        waypoint_coords.z + 600,
                        4, 100.0, 0, 90, 0, 0, true
                    )
                    if VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(Self.Vehicle.Current) and VEHICLE.Self.Vehicle.IsPlane_LANDING_GEAR_INTACT(Self.Vehicle.Current) then
                        if VEHICLE.GET_LANDING_GEAR_STATE(Self.Vehicle.Current) ~= 4 then
                            if Self.GetElevation() >= 15 then
                                VEHICLE.CONTROL_LANDING_GEAR(Self.Vehicle.Current, 1)
                            else
                                repeat
                                    ap:sleep(10)
                                until Self.GetElevation() >= 15
                                VEHICLE.CONTROL_LANDING_GEAR(Self.Vehicle.Current, 1)
                            end
                        end
                    end
                    ap:sleep(500)
                    if VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(Self.Vehicle.Current) ~= initialHoverModeState then -- TASK_PLANE_MISSION always reverts to hover mode if available.
                        VEHICLE.SET_VEHICLE_FLIGHT_NOZZLE_POSITION_IMMEDIATE(Self.Vehicle.Current, initialHoverModeState)
                    end
                elseif Self.Vehicle.IsHeli then
                    TASK.TASK_HELI_MISSION(
                        Self.GetPedID(), Self.Vehicle.Current, 0, 0, waypoint_coords.x, waypoint_coords.y,
                        waypoint_coords.z,
                        4, 50.0, 4.0, -1, -1, 100, 100.0, 0
                    )
                end
            else
                YimToast:ShowWarning("Samurai's Scripts", "Please set a waypoint on the map first!")
            end
        end)
    end
    ImGui.SameLine()
    if ImGui.Button(" Fly To Objective ") then
        UI.WidgetSound("Select")
        script.run_in_fiber(function(ap)
            local objective_found, objective_coords = Game.FindObjectiveBlip()
            if objective_found and objective_coords ~= nil then
                if autopilot_waypoint or autopilot_random then
                    TASK.CLEAR_PED_TASKS(Self.GetPedID())
                    TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
                end
                autopilot_waypoint  = false
                autopilot_objective = true
                autopilot_random    = false
                YimToast:ShowSuccess("Samurai's Scripts", "Flying towards objective")
                if Self.Vehicle.IsPlane then
                    local initialHoverModeState = VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(Self.Vehicle.Current)
                    TASK.TASK_PLANE_MISSION(
                        Self.GetPedID(), Self.Vehicle.Current, 0, 0, objective_coords.x, objective_coords.y,
                        objective_coords.z + 600,
                        4, 100.0, 0, 90, 0, 0, true
                    )
                    if VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(Self.Vehicle.Current) and VEHICLE.Self.Vehicle.IsPlane_LANDING_GEAR_INTACT(Self.Vehicle.Current) then
                        if VEHICLE.GET_LANDING_GEAR_STATE(Self.Vehicle.Current) ~= 4 then
                            if Self.GetElevation() >= 15 then
                                VEHICLE.CONTROL_LANDING_GEAR(Self.Vehicle.Current, 1)
                            else
                                repeat
                                    ap:sleep(10)
                                until Self.GetElevation() >= 15
                                VEHICLE.CONTROL_LANDING_GEAR(Self.Vehicle.Current, 1)
                            end
                        end
                    end
                    ap:sleep(500)
                    if VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(Self.Vehicle.Current) ~= initialHoverModeState then -- TASK_PLANE_MISSION always reverts to hover mode if available.
                        VEHICLE.SET_VEHICLE_FLIGHT_NOZZLE_POSITION_IMMEDIATE(Self.Vehicle.Current, initialHoverModeState)
                    end
                elseif Self.Vehicle.IsHeli then
                    TASK.TASK_HELI_MISSION(
                        Self.GetPedID(), Self.Vehicle.Current, 0, 0, objective_coords.x, objective_coords.y,
                        objective_coords
                        .z,
                        4, 50.0, 4.0, -1, -1, 100, 100.0, 0
                    )
                end
            else
                YimToast:ShowWarning("Samurai's Scripts", "No objective found!")
            end
        end)
    end
    ImGui.SameLine()
    if ImGui.Button(" Random ") then
        UI.WidgetSound("Select")
        script.run_in_fiber(function(ap)
            if autopilot_waypoint or autopilot_objective then
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
            end
            autopilot_waypoint  = false
            autopilot_objective = false
            autopilot_random    = true
            YimToast:ShowSuccess("Samurai's Scripts", "Flying towards some random coordinates")
            if Self.Vehicle.IsPlane then
                local initialHoverModeState = VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(Self.Vehicle.Current)
                TASK.TASK_PLANE_MISSION(
                    Self.GetPedID(), Self.Vehicle.Current, 0, 0, math.random(-3000, 3000), math.random(-3000, 3000),
                    math.random(400, 900), 4, 100.0, 0, 90, 0, 0, true
                )
                if VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(Self.Vehicle.Current) and VEHICLE.Self.Vehicle.IsPlane_LANDING_GEAR_INTACT(Self.Vehicle.Current) then
                    if VEHICLE.GET_LANDING_GEAR_STATE(Self.Vehicle.Current) ~= 4 then
                        if Self.GetElevation() >= 15 then
                            VEHICLE.CONTROL_LANDING_GEAR(Self.Vehicle.Current, 1)
                        else
                            repeat
                                ap:sleep(10)
                            until Self.GetElevation() >= 15
                            VEHICLE.CONTROL_LANDING_GEAR(Self.Vehicle.Current, 1)
                        end
                    end
                end
                ap:sleep(500)
                if VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(Self.Vehicle.Current) ~= initialHoverModeState then -- TASK_PLANE_MISSION always reverts to hover mode if available.
                    VEHICLE.SET_VEHICLE_FLIGHT_NOZZLE_POSITION_IMMEDIATE(Self.Vehicle.Current, initialHoverModeState)
                end
            elseif Self.Vehicle.IsHeli then
                TASK.TASK_HELI_MISSION(
                    Self.GetPedID(), Self.Vehicle.Current, 0, 0, math.random(-3000, 3000), math.random(-3000, 3000),
                    math.random(10, 300),
                    4, 50.0, 4.0, -1, -1, 100, 100.0, 0
                )
            end
        end)
    end
    if autopilot_waypoint or autopilot_objective or autopilot_random then
        ImGui.SameLine()
        if ImGui.Button(_T("GENERIC_STOP_BTN_")) then
            UI.WidgetSound("Cancel")
            YimToast:ShowMessage("Samurai's Scripts", "Auto-Pilot canceled.")
            script.run_in_fiber(function()
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
                autopilot_waypoint  = false
                autopilot_objective = false
                autopilot_random    = false
            end)
        end
    end
    ImGui.EndDisabled()
    ImGui.EndChild()

    ImGui.BeginChild("MISC", 0, 280, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 10)
    ImGui.SetWindowFontScale(1.2)
    ImGui.SeparatorText("MISC")
    ImGui.SetWindowFontScale(1.0)

    ImGui.Dummy(1, 10)
    if Self.Vehicle.Current ~= nil and Self.Vehicle.Current ~= 0 then
        local manufacturer  = Game.Vehicle.Manufacturer(Self.Vehicle.Current)
        local vehicle_name  = Game.Vehicle.Name(Self.Vehicle.Current)
        local full_veh_name = string.format("%s %s", manufacturer, vehicle_name)
        local vehicle_class = Game.Vehicle.Class(Self.Vehicle.Current)
        ImGui.BulletText(string.format("%s  (%s)", full_veh_name, vehicle_class))
    else
        ImGui.BulletText("On Foot")
    end
    missiledefense, mdefUsed = ImGui.Checkbox("Missile Defence", missiledefense)
    UI.Tooltip(_T("MISSILE_DEF_DESC_"))
    if mdefUsed then
        CFG:SaveItem("missiledefense", missiledefense)
        if missiledefense then
            UI.WidgetSound("Radar")
            YimToast:ShowSuccess("Samurais Scripts", _T("MISSILE_DEF_ON_"))
        else
            UI.WidgetSound("Delete")
            YimToast:ShowMessage("Samurais Scripts", _T("MISSILE_DEF_OFF_"))
        end
    end

    ImGui.SameLine()
    speedometer.enabled, speedometerChecked = ImGui.Checkbox("Speedometer", speedometer.enabled)
    if speedometerChecked then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("speedometer", speedometer)
    end

    if speedometer.enabled then
        ImGui.SameLine()
        if ImGui.Button("Speedometer Options") then
            UI.WidgetSound("Select")
            t_SpeedometerWindow.should_draw = true
        end
    end

    ImGui.BeginDisabled(Self.Vehicle.Current == 0 or not Self.IsDriving())
    if ImGui.Button(string.format(" %s ", _T("ENGINE_SOUND_BTN_"))) then
        if Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad then
            UI.WidgetSound("Select")
            t_EngineSoundsWindow.should_draw = true
        else
            t_EngineSoundsWindow.should_draw = false
            UI.WidgetSound("Error")
            YimToast:ShowError("Samurais Scripts", _T("ENGINE_SOUND_ERROR_TXT_"))
        end
    end

    ImGui.SameLine()
    ImGui.BeginDisabled(
        Game.Vehicle.IsElectric(Self.Vehicle.Current) or not
        Self.IsDriving() or not
        Self.Vehicle.IsCar
    )
    if ImGui.Button(_T("ENGINE_SWAP_BTN_")) then
        UI.WidgetSound("Select")
        t_EngineSwapsWindow.should_draw = true
    end
    ImGui.EndDisabled()
    UI.Tooltip(_T("NON_ELECTRIC_CARS_TXT_"))

    ImGui.SameLine()
    if Self.Vehicle.EngineHealth <= 300 then
        engineButton_label = _T("FIX_ENGINE_")
        engine_hp          = 1000
        button_color_1     = "#008000"
        button_color_2     = "#005A00"
        button_color_3     = "#BFFFBF"
    else
        engineButton_label = _T("DESTROY_ENGINE_")
        engine_hp          = -4000
        button_color_1     = "#FF0000"
        button_color_2     = "#B30000"
        button_color_3     = "#FF8080"
    end
    if UI.ColoredButton(engineButton_label, button_color_1, button_color_2, button_color_3) then
        UI.WidgetSound("Select")
        script.run_in_fiber(function()
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(Self.Vehicle.Current, engine_hp)
        end)
    end

    if dummyCopCar == 0 then
        if VEHICLE.GET_VEHICLE_CLASS(Self.Vehicle.Current) ~= 18 then
            if ImGui.Button(" Equip Fake Siren ") then
                if Self.Vehicle.IsCar or Self.Vehicle.IsBike and not PED.IS_PED_IN_FLYING_VEHICLE(Self.GetPedID()) then
                    UI.WidgetSound("Select")
                    DummyCop()
                else
                    UI.WidgetSound("Error")
                    YimToast:ShowError("Samurais Scripts", "This feature is only available for cars and bikes.")
                end
            end
            if not Game.IsOnline() then
                UI.Tooltip("The siren audio only works Online.")
            end
        else
            ImGui.BeginDisabled()
            ImGui.Button("Equip Fake Siren")
            ImGui.EndDisabled()
            UI.Tooltip("Your vehicle has a real siren. You don't need a fake one.")
        end
    else
        if ImGui.Button("Remove Fake Siren") then
            UI.WidgetSound("Cancel")
            script.run_in_fiber(function(deletecop)
                VEHICLE.SET_VEHICLE_ACT_AS_IF_HAS_SIREN_ON(Self.Vehicle.Current, false)
                VEHICLE.SET_VEHICLE_CAUSES_SWERVING(Self.Vehicle.Current, false)
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(Self.Vehicle.Current, 0, false)
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(Self.Vehicle.Current, 1, false)
                if ENTITY.DOES_ENTITY_EXIST(dummyCopCar) then
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(dummyCopCar, true, true)
                    deletecop:sleep(200)
                    ENTITY.DELETE_ENTITY(dummyCopCar)
                end
                dummyCopCar = 0
            end)
        end
    end

    ImGui.SameLine()

    if ImGui.Button("Ejecto Seato Cuz") then
        UI.WidgetSound("Select")
        script.run_in_fiber(function(ejecto)
            local passengers = Game.Vehicle.GetOccupants(Self.Vehicle.Current)
            if (#passengers == 1) and (passengers[1] == Self.GetPedID()) then
                YimToast:ShowError("Samurai's Scripts", "You can not ejecto seato on yourself, cuz!")
                return
            end

            for _, ped in ipairs(passengers) do
                if ped ~= Self.GetPedID() then
                    if not PED.IS_PED_A_PLAYER(ped) then
                        TASK.CLEAR_PED_TASKS(ped)
                        TASK.TASK_LEAVE_VEHICLE(ped, Self.Vehicle.Current, 4160)
                    else
                        local player_index = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)
                        command.call("vehkick", { player_index })
                        ejecto:sleep(1000)
                        if PED.IS_PED_SITTING_IN_VEHICLE(ped, Self.Vehicle.Current) then
                            YimToast:ShowError("Samurai's Scripts", "Failed to eject the player from our vehicle!")
                        end
                    end
                end
            end
        end)
    end
    ImGui.EndDisabled()
    UI.Tooltip(_T("EJECTO_SEATO_DESC_"))

    ImGui.SameLine()
    ImGui.BeginDisabled(Self.IsDriving() or not Self.IsOutside() or Self.Vehicle.Previous == 0)
    if ImGui.Button("TP Into Last Vehicle") then
        UI.WidgetSound("Select")
        script.run_in_fiber(function()
            if (
                ENTITY.DOES_ENTITY_EXIST(Self.Vehicle.Previous) and
                ENTITY.IS_ENTITY_A_VEHICLE(Self.Vehicle.Previous) and
                VEHICLE.IS_VEHICLE_DRIVEABLE(Self.Vehicle.Previous, true)
            ) then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
                PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), Self.Vehicle.Previous, -1)
            else
                YimToast:ShowError(
                    "Samurai's Scripts",
                    "Your last vehicle was either destroyed or no longer exists in the game world."
                )
            end
        end)
    end

    ImGui.SameLine()
    if ImGui.Button("Bring Last Vehicle") then
        UI.WidgetSound("Select")
        script.run_in_fiber(function(blv)
            if (
                ENTITY.DOES_ENTITY_EXIST(Self.Vehicle.Previous) and
                ENTITY.IS_ENTITY_A_VEHICLE(Self.Vehicle.Previous) and
                VEHICLE.IS_VEHICLE_DRIVEABLE(Self.Vehicle.Previous, true)
            ) then
                local veh_coords  = ENTITY.GET_ENTITY_COORDS(Self.Vehicle.Previous, true)
                local self_coords = Self.GetPos()
                local distance    = MISC.GET_DISTANCE_BETWEEN_COORDS(
                    veh_coords.x,
                    veh_coords.y,
                    veh_coords.z,
                    self_coords.x,
                    self_coords.y,
                    self_coords.z,
                    false
                )
                if distance <= 15 then
                    YimToast:ShowWarning("Samurai's Scripts", "Your last vehicle is already too close")
                else
                    local self_fwd   = Self.GetForwardVector()
                    local veh_hash   = ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Previous)
                    local vmin, vmax = Game.GetModelDimensions(veh_hash)
                    local veh_length = vmax.y - vmin.y
                    local tp_offset  = vec2:new(
                        self_coords.x + (self_fwd.x * veh_length),
                        self_coords.y + (self_fwd.y * veh_length)
                    )
                    ENTITY.SET_ENTITY_COORDS(
                        Self.Vehicle.Previous,
                        tp_offset.x,
                        tp_offset.y,
                        self_coords.z,
                        false,
                        false,
                        false,
                        true
                    )
                end
            else
                YimToast:ShowError(
                    "Samurai's Scripts",
                    "Your last vehicle was either destroyed or no longer exists in the game world."
                )
            end
        end)
    end
    ImGui.EndDisabled()

    ImGui.BeginDisabled(
        Self.IsDriving() or not
        Self.IsOutside() or
        (Self.Vehicle.Current == 0) or not
        Self.Vehicle.IsCar
    )
    if ImGui.Button(("%s Doors"):format(_T
        ((Self.Vehicle.DoorLockState and
        Self.Vehicle.DoorLockState <= 1) and
        "LOCK_CAR_BTN_" or
        "UNLOCK_CAR_BTN_"
    )
        )) then
        script.run_in_fiber(function(dlocks)
            if Self.Vehicle.Current ~= 0 and Self.Vehicle.IsCar then
                if Self.Vehicle.Previous ~= 0 and Self.Vehicle.Previous ~= Self.Vehicle.Current and
                    VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Previous)) and
                    (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Previous) ~= 1) then
                    VEHICLE.SET_VEHICLE_DOORS_LOCKED(Self.Vehicle.Previous, 1)
                end
                Self.PlayKeyfobAnim()
                AUDIO.PLAY_SOUND_FRONTEND(-1, "REMOTE_CONTROL_FOB", "PI_MENU_SOUNDS", false)
                dlocks:sleep(250)
                local toggle = (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Current) == 1) and true or false
                Self.Vehicle.DoorLockState = toggle and 2 or 1
                Game.Vehicle.LockDoors(Self.Vehicle.Current, toggle, dlocks)
            end
        end)
    end
    ImGui.EndDisabled();
    if Self.Vehicle.Current ~= 0 and not Self.Vehicle.IsCar then
        UI.Tooltip(_T("LOCK_CARS_ONLY_TXT_"))
    end
    ImGui.SameLine()
    autovehlocks, avlUsed = ImGui.Checkbox("Auto-Lock", autovehlocks)
    UI.Tooltip(_T("AUTOVEHLOCKS_DESC_"))
    if avlUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("autovehlocks", autovehlocks)
    end

    ImGui.SameLine(); autoraiseroof, autoroofUsed = ImGui.Checkbox(_T("AUTO_RAISE_ROOF_CB_"), autoraiseroof)
    UI.Tooltip(_T("AUTO_RAISE_ROOF_DESC_"))
    if autoroofUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("autoraiseroof", autoraiseroof)
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()

    ImGui.BeginChild("Preferences", 0, 160, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 10)
    ImGui.SetWindowFontScale(1.2)
    ImGui.SeparatorText("Preferences")
    ImGui.SetWindowFontScale(1.0)

    limitVehOptions, lvoUsed = ImGui.Checkbox(_T("LIMIT_OPTIONS_CB_"), limitVehOptions)
    UI.Tooltip(_T("LIMIT_OPTIONS_DESC_"))
    if lvoUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("limitVehOptions", limitVehOptions)
    end

    ImGui.SameLine()
    louderPops, louderPopsUsed = ImGui.Checkbox("Louder Pops", louderPops)
    UI.Tooltip(_T("LOUDER_POPS_DESC_"))
    if louderPopsUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("louderPops", louderPops)
    end

    ImGui.SameLine()
    ImGui.PushItemWidth(200)
    lightSpeed, lightSpeedUsed = ImGui.SliderInt(_T("RGB_SPEED_TXT_"), lightSpeed, 1, 3)
    ImGui.PopItemWidth()
    if lightSpeedUsed then
        UI.WidgetSound("Nav")
        CFG:SaveItem("lightSpeed", lightSpeed)
    end

    if ImGui.Button("NOS Settings") then
        UI.WidgetSound("Select")
        ImGui.OpenPopup("Nos Settings")
    end
    ImGui.SetNextWindowPos(780, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowBgAlpha(0.9)
    ImGui.SetNextWindowSize(450, 260)
    if ImGui.BeginPopupModal("Nos Settings",
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoMove |
            ImGuiWindowFlags.NoTitleBar
        ) then
        is_typing = true
        ImGui.Spacing(); ImGui.Text("NOS Settings"); ImGui.SameLine()
        local avail_x, _ = ImGui.GetContentRegionAvail()
        ImGui.Dummy(avail_x - 55, 1)
        ImGui.SameLine()
        ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 80)
        if ImGui.Button("  X  ##nos_settings") then
            UI.WidgetSound("Cancel")
            ImGui.CloseCurrentPopup()
            is_typing = false
        end
        ImGui.PopStyleVar(); ImGui.Separator(); ImGui.Dummy(1, 10)
        nosAudio, nosaudioUsed = ImGui.Checkbox("NOS Sound", nosAudio)
        if nosaudioUsed then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("nosAudio", nosAudio)
        end

        ImGui.SameLine(); nosFlames, nosflamesUsed = ImGui.Checkbox("NOS Flames", nosFlames)
        if nosflamesUsed then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("nosFlames", nosFlames)
        end

        ImGui.SameLine(); nosvfx, nosvfxUsed = ImGui.Checkbox("Screen Effect", nosvfx)
        UI.Tooltip(_T("NOS_VFX_DESC_"))
        if nosvfxUsed then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("nosvfx", nosvfx)
        end

        ImGui.Dummy(1, 15); ImGui.Text(" Power:  "); ImGui.SameLine()
        nosPower, nspwrUsed = ImGui.SliderInt("##nospower", nosPower, 10, 100, "%d",
            ImGuiSliderFlags.NoInput | ImGuiSliderFlags.AlwaysClamp | ImGuiSliderFlags.Logarithmic)
        if nspwrUsed then
            UI.WidgetSound("Nav")
        end
        ImGui.Dummy(1, 20)
        if ImGui.Button(string.format(" %s ##nos_settings", _T("GENERIC_SAVE_BTN_"))) then
            UI.WidgetSound("Select")
            CFG:SaveItem("nosPower", nosPower)
            ImGui.CloseCurrentPopup()
            is_typing = false
        end
        ImGui.SameLine(); ImGui.Dummy(30, 1); ImGui.SameLine()
        if ImGui.Button(string.format(" %s ##nos_settings", _T("GENERIC_CANCEL_BTN_"))) then
            UI.WidgetSound("Cancel")
            ImGui.CloseCurrentPopup()
            is_typing = false
        end
        ImGui.End()
    end

    ImGui.SameLine()
    if ImGui.Button(_T("MINES_TYPE_BTN_")) then
        UI.WidgetSound("Select")
        ImGui.OpenPopup("Mine Types")
    end
    ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowBgAlpha(0.81)
    if ImGui.BeginPopupModal("Mine Types", true, ImGuiWindowFlags.AlwaysAutoResize) then
        is_typing = true
        ImGui.Dummy(1, 5); ImGui.Text(_T("MINES_TYPE_DESC_")); ImGui.Dummy(1, 5)
        vmine_type.spikes, spikeUsed = ImGui.Checkbox("Spike", vmine_type.spikes)
        if spikeUsed then
            UI.WidgetSound("Nav2")
            vmine_type.slick     = false
            vmine_type.explosive = false
            vmine_type.emp       = false
            vmine_type.kinetic   = false
            CFG:SaveItem("vmine_type", vmine_type)
        end

        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        vmine_type.slick, slickUsed = ImGui.Checkbox("Slick", vmine_type.slick)
        if slickUsed then
            UI.WidgetSound("Nav2")
            vmine_type.spikes    = false
            vmine_type.explosive = false
            vmine_type.emp       = false
            vmine_type.kinetic   = false
            CFG:SaveItem("vmine_type", vmine_type)
        end

        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        vmine_type.explosive, expUsed = ImGui.Checkbox("Explosive", vmine_type.explosive)
        if expUsed then
            UI.WidgetSound("Nav2")
            vmine_type.spikes  = false
            vmine_type.slick   = false
            vmine_type.emp     = false
            vmine_type.kinetic = false
            CFG:SaveItem("vmine_type", vmine_type)
        end

        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        vmine_type.emp, empUsed = ImGui.Checkbox("EMP", vmine_type.emp)
        if empUsed then
            UI.WidgetSound("Nav2")
            vmine_type.spikes    = false
            vmine_type.slick     = false
            vmine_type.explosive = false
            vmine_type.kinetic   = false
            CFG:SaveItem("vmine_type", vmine_type)
        end

        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        vmine_type.kinetic, kntcUsed = ImGui.Checkbox("Kinetic", vmine_type.kinetic)
        if kntcUsed then
            UI.WidgetSound("Nav2")
            vmine_type.spikes    = false
            vmine_type.slick     = false
            vmine_type.explosive = false
            vmine_type.emp       = false
            CFG:SaveItem("vmine_type", vmine_type)
        end

        ImGui.Dummy(1, 5)
        if missiledefense and (vmine_type.slick or vmine_type.explosive or vmine_type.emp or vmine_type.kinetic) then
            UI.ColoredText(_T("VEH_MINES_MDEF_WARN_"), "yellow", 0.69, 30)
        end
        ImGui.Dummy(1, 5)
        if vmine_type.spikes or vmine_type.slick or vmine_type.explosive or vmine_type.emp or vmine_type.kinetic then
            if ImGui.Button("Confirm") then
                UI.WidgetSound("Select")
                CFG:SaveItem("vmine_type", vmine_type)
                ImGui.CloseCurrentPopup()
                is_typing = false
            end
        end
        ImGui.End()
    end

    ImGui.SameLine()
    if cannon_triggerbot then
        if ImGui.Button("Cannon Triggerbot Options") then
            UI.WidgetSound("Select")
            ImGui.OpenPopup("Cannon Options")
        end
        ImGui.SetNextWindowPos(820, 400, ImGuiCond.Appearing)
        ImGui.SetNextWindowBgAlpha(0.9)
        ImGui.SetNextWindowSize(420, 220)
        if ImGui.BeginPopupModal("Cannon Options", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
            is_typing = true
            ImGui.Spacing(); ImGui.Text(_T("CANNON_TRIGGERBOT_OPTIONS_TXT_")); ImGui.SameLine()
            local avail_x, _ = ImGui.GetContentRegionAvail()
            ImGui.Dummy(avail_x - 55, 1)
            ImGui.SameLine()
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 80)
            if ImGui.Button("  X  ##Cannon Options") then
                UI.WidgetSound("Cancel")
                ImGui.CloseCurrentPopup()
                is_typing = false
            end
            ImGui.PopStyleVar(); ImGui.Separator(); ImGui.Dummy(1, 10)
            ImGui.Text(_T("CANNON_TRIGGERBOT_RANGE_")); ImGui.SameLine()
            ImGui.SetNextItemWidth(200)
            cannon_triggerbot_range, ctrUsed = ImGui.SliderInt("##cannon_triggerbot_range", cannon_triggerbot_range, 1000,
                5000)
            UI.Tooltip(_T("CANNON_TRIGGERBOT_RANGE_DESC_"))
            if ctrUsed then
                UI.WidgetSound("Nav")
                CFG:SaveItem("cannon_triggerbot_range", cannon_triggerbot_range)
            end
            ImGui.Dummy(1, 10)
            cannon_enemies_only, ceonlyUSed = ImGui.Checkbox(_T("ENEMY_ONLY_CB_"), cannon_enemies_only)
            if ceonlyUSed then
                UI.WidgetSound("Nav2")
                CFG:SaveItem("cannon_enemies_only", cannon_enemies_only)
            end
            ImGui.End()
        end
    end

    if cannon_manual_aim then
        ImGui.SameLine()
        if ImGui.Button("Cannon Aim Marker") then
            UI.WidgetSound("Select")
            ImGui.OpenPopup("Cannon Aim Marker")
        end
        ImGui.SetNextWindowPos(820, 400, ImGuiCond.Appearing)
        ImGui.SetNextWindowBgAlpha(0.9)
        ImGui.SetNextWindowSize(420, 220)
        if ImGui.BeginPopupModal("Cannon Aim Marker", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
            is_typing = true
            ImGui.Spacing()
            ImGui.Text("Cannon Aim Marker")
            ImGui.SameLine()
            local avail_x, _ = ImGui.GetContentRegionAvail()
            ImGui.Dummy(avail_x - 55, 1)
            ImGui.SameLine()
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 80)
            if ImGui.Button("  X  ##CannonAimMarker") then
                UI.WidgetSound("Cancel")
                ImGui.CloseCurrentPopup()
                is_typing = false
            end
            ImGui.PopStyleVar(); ImGui.Separator(); ImGui.Dummy(1, 10)
            ImGui.Text(_T("AIM_MARKER_SIZE_TXT_")); ImGui.SameLine()
            ImGui.SetNextItemWidth(220)
            cannon_marker_size, cmsUsed = ImGui.SliderFloat("##cannon_marker_size", cannon_marker_size, 0.1, 10.0)
            if cmsUsed then
                UI.WidgetSound("Nav")
                CFG:SaveItem("cannon_marker_size", cannon_marker_size)
            end
            ImGui.Dummy(1, 10)
            ImGui.Text(_T("AIM_MARKER_COL_TXT_"))
            cannon_marker_color, cmcUsed = ImGui.ColorEdit3("##markerCol", cannon_marker_color)
            if cmcUsed then
                UI.WidgetSound("Nav2")
                CFG:SaveItem("cannon_marker_color", cannon_marker_color)
            end
            ImGui.End()
        end
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()

    -- option windows
    if t_EngineSoundsWindow.should_draw then
        ImGui.SetNextWindowPos(820, 300, ImGuiCond.Appearing)
        ImGui.SetNextWindowSizeConstraints(100, 100, 600, 800)
        ImGui.Begin("Vehicle Sounds",
            ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoCollapse)
        if ImGui.Button(_T("GENERIC_CLOSE_BTN_")) then
            UI.WidgetSound("Cancel")
            t_EngineSoundsWindow.should_draw = false
        end
        ImGui.Spacing(); ImGui.Spacing()
        ImGui.SetNextItemWidth(250)
        search_term, used = ImGui.InputTextWithHint("", _T("SEARCH_VEH_HINT_"), search_term, 32)
        is_typing = ImGui.IsItemActive()
        ImGui.SetNextItemWidth(270)
        DisplayVehNames()
        local selected_name = t_FilteredNames[i_VehSoundIndex + 1]
        ImGui.Spacing()
        if ImGui.Button(_T("SELECT_SOUND_TXT_")) then
            UI.WidgetSound("Select")
            script.run_in_fiber(function()
                AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(Self.Vehicle.Current, selected_name)
                engine_sound_changed = true
            end)
        end
        ImGui.SameLine()
        if ImGui.Button(_T("RESTORE_DEFAULT_")) then
            UI.WidgetSound("Delete")
            script.run_in_fiber(function()
                AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(
                    Self.Vehicle.Current,
                    vehicles.get_vehicle_display_name(
                        ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current)
                    )
                )
                engine_sound_changed = false
            end)
        end
        ImGui.End()
    end

    if t_EngineSwapsWindow.should_draw then
        ImGui.SetNextWindowPos(820, 300, ImGuiCond.Appearing)
        ImGui.SetNextWindowBgAlpha(1.0)
        ImGui.SetNextWindowSizeConstraints(100, 100, 600, 800)
        ImGui.Begin(
            "Engine Swap",
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.NoCollapse
        )
        if ImGui.Button(_T("GENERIC_CLOSE_BTN_")) then
            UI.WidgetSound("Cancel")
            t_EngineSwapsWindow.should_draw = false
        end
        ImGui.Dummy(1, 10)
        is_typing = ImGui.IsItemActive()
        ImGui.SetNextItemWidth(300)
        if ImGui.BeginListBox("##engines", -1, 240) then
            for i = 1, #t_EngineSwaps do
                local is_selected = (i_EngineSwapIndex == i - 1)
                if ImGui.Selectable(t_EngineSwaps[i].name, is_selected) then
                    i_EngineSwapIndex = i - 1
                end
                UI.Tooltip(t_EngineSwaps[i].tt)

                if is_selected then
                    t_SelectedEngine = t_EngineSwaps[i_EngineSwapIndex + 1]
                    ImGui.SetItemDefaultFocus()
                end
            end
            ImGui.EndListBox()
        end
        ImGui.Spacing()
        ImGui.BeginDisabled(Game.Vehicle.IsElectric(Self.Vehicle.Current) or not Self.Vehicle.IsCar)
        if ImGui.Button(_T("SELECT_ENGINE_BTN_")) then
            UI.WidgetSound("Select")
            script.run_in_fiber(function(engineswap)
                AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(Self.Vehicle.Current, t_SelectedEngine.audioname)
                Game.Vehicle.SetAcceleration(Self.Vehicle.Current, t_SelectedEngine.acc_mult)
                engineswap:sleep(150)
                if AUDIO.IS_VEHICLE_RADIO_ON(Self.Vehicle.Current) then
                    AUDIO.SET_VEH_RADIO_STATION(Self.Vehicle.Current, "OFF")
                end
                engine_sound_changed = true
            end)
        end
        ImGui.SameLine()
        if ImGui.Button(_T("RESTORE_DEFAULT_")) then
            UI.WidgetSound("Delete")
            script.run_in_fiber(function(enginerestore)
                AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(
                    Self.Vehicle.Current,
                    vehicles.get_vehicle_display_name(
                        ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current)
                    )
                )
                Game.Vehicle.SetAcceleration(Self.Vehicle.Current, 1.0)
                enginerestore:sleep(150)
                if AUDIO.IS_VEHICLE_RADIO_ON(Self.Vehicle.Current) then
                    AUDIO.SET_VEH_RADIO_STATION(Self.Vehicle.Current, "OFF")
                end
                engine_sound_changed = false
            end)
        end
        ImGui.EndDisabled()
        ImGui.End()
    end

    if t_SpeedometerWindow.should_draw then
        ImGui.SetNextWindowPos(820, 300)
        ImGui.SetNextWindowBgAlpha(1.0)
        ImGui.SetNextWindowSizeConstraints(100, 100, 600, 800)
        ImGui.Begin(
            "Speedometer Options",
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.NoCollapse
        )

        if ImGui.Button(_T("GENERIC_CLOSE_BTN_")) then
            UI.WidgetSound("Cancel")
            t_SpeedometerWindow.should_draw = false
        end

        ImGui.Dummy(1, 10)
        ImGui.SeparatorText("Speed Unit")
        speedometer.speed_unit, mps = ImGui.RadioButton("M/s", speedometer.speed_unit, 0)
        ImGui.SameLine()
        speedometer.speed_unit, kmph = ImGui.RadioButton("Km/h", speedometer.speed_unit, 1)
        ImGui.SameLine()
        speedometer.speed_unit, mph = ImGui.RadioButton("Mi/h", speedometer.speed_unit, 2)
        if (mps or kmph or mph) then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("speedometer", speedometer)
        end

        ImGui.SeparatorText("Position")
        ImGui.PushItemWidth(300)
        speedometer.pos.x, _ = ImGui.SliderFloat(
            "Left/Right",
            speedometer.pos.x,
            0.0,
            Game.ScreenResolution.x - (speedometer.radius * 2.5)
        )
        speedometer.pos.y, _ = ImGui.SliderFloat("Up/Down", speedometer.pos.y, 0.0,
            Game.ScreenResolution.y - (speedometer.radius * 3.0))
        ImGui.PopItemWidth()

        ImGui.SeparatorText("Colors")
        speedometercircle_color = {Col(speedometer.circle_color):AsFloat()}
        speedometercircle_color, circlecolused = ImGui.ColorEdit4("Circle", speedometercircle_color)
        if circlecolused then
            speedometer.circle_color = ImU32(speedometercircle_color)
            CFG:SaveItem("speedometer", speedometer)
        end

        speedometertext_color = {Col(speedometer.text_color):AsFloat()}
        speedometertext_color, textcolused = ImGui.ColorEdit4("Text", speedometertext_color)
        if textcolused then
            speedometer.text_color = ImU32(speedometertext_color)
            CFG:SaveItem("speedometer", speedometer)
        end

        speedometermarkings_color = {Col(speedometer.markings_color):AsFloat()}
        speedometermarkings_color, markingsused = ImGui.ColorEdit4("Speed Markings", speedometermarkings_color)
        if markingsused then
            speedometer.markings_color = ImU32(speedometermarkings_color)
            CFG:SaveItem("speedometer", speedometer)
        end

        speedometerneedle_color = {Col(speedometer.needle_color):AsFloat()}
        speedometerneedle_color, needlecolused = ImGui.ColorEdit4("Needle", speedometerneedle_color)
        if needlecolused then
            speedometer.needle_color = ImU32(speedometerneedle_color)
            CFG:SaveItem("speedometer", speedometer)
        end

        speedometerneedle_base_color = {Col(speedometer.needle_base_color):AsFloat()}
        if #speedometerneedle_base_color == 4 then
            speedometerneedle_base_color[4] = nil
        end
        speedometerneedle_base_color, needlebaseused = ImGui.ColorEdit3("Needle Base", speedometerneedle_base_color)
        if needlebaseused then
            speedometer.needle_base_color = ImU32(speedometerneedle_base_color)
            CFG:SaveItem("speedometer", speedometer)
        end

        ImGui.Dummy(1, 10)
        ImGui.Separator()
        if ImGui.Button(_T("GENERIC_SAVE_BTN_")) then
            UI.WidgetSound("Select")
            CFG:SaveItem("speedometer", speedometer)
            t_SpeedometerWindow.should_draw = false
        end

        ImGui.SameLine()
        if ImGui.Button(_T("GENERIC_RESET_BTN_")) then
            UI.WidgetSound("Cancel")
            speedometer = DEFAULT_CONFIG.speedometer
            speedometer.enabled = true
            CFG:SaveItem("speedometer", speedometer)
        end
        ImGui.End()
    end
end

---@param current_speed number
---@param max_speed number
---@param gear string
---@param offset? float
function DrawSpeedometer(
    current_speed,
    max_speed,
    gear,
    current_altitude,
    max_altitude,
    landing_gear,
    offset
)
    if should_draw_speedometer then
        local radius = 160
        ImGui.SetNextWindowBgAlpha(0.0)
        ImGui.SetNextWindowSize(radius * 2.5, radius * 2.5)
        if ImGui.Begin(
            "Speedometer",
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.NoResize |
            ImGuiWindowFlags.NoScrollbar |
            ImGuiWindowFlags.NoScrollWithMouse |
            ImGuiWindowFlags.NoCollapse |
            ImGuiWindowFlags.NoMove
        ) then
            if speedometer.pos.x == 0 and speedometer.pos.y == 0 then
                speedometer.pos.x = Game.ScreenResolution.x - (radius * 2.5)
                speedometer.pos.y = Game.ScreenResolution.y - (radius * 3.5)
            end

            ImGui.SetWindowPos("Speedometer", speedometer.pos.x, speedometer.pos.y)
            pos_offset = offset or 0.0

            local ImDrawList = ImGui.GetWindowDrawList()
            local window_pos = vec2:new(ImGui.GetWindowPos())
            local window_size = vec2:new(ImGui.GetWindowSize())
            local line_thickness = 3.0
            local start_angle = -math.pi * 1.25
            local end_angle = math.pi * 0.25
            local center = vec2:new(
                window_pos.x + window_size.x * 0.5 + pos_offset,
                window_pos.y + window_size.y * 0.5 + pos_offset
            )

            -- background
            ImGui.ImDrawListAddCircleFilled(
                ImDrawList,
                center.x,
                center.y,
                radius,
                speedometer.circle_bgcolor
            )

            -- analog circle
            ImGui.ImDrawListAddCircle(
                ImDrawList,
                center.x,
                center.y,
                radius,
                speedometer.circle_color,
                100,
                line_thickness
            )

            if Self.Vehicle.IsPlane or Self.Vehicle.IsHeli then
                local altitude_text_offset = vec2:new(-43, -80)
                ImGui.SetWindowFontScale(0.77)
                ImGui.ImDrawListAddText(
                    ImDrawList,
                    center.x + altitude_text_offset.x,
                    center.y + altitude_text_offset.y,
                    speedometer.text_color,
                    string.format("Altitude [%.0fm]", current_altitude)
                )
                ImGui.SetWindowFontScale(1.0)
            end

            local max_fractions = (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and max_altitude or max_speed
            local step_0 = (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and 10 or 1
            local step_1 = (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and 100 or 10
            local step_2 = (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and 200 or 20

            -- fractions
            for i = 0, max_fractions, step_0 do
                local angle = start_angle + (end_angle - start_angle) * (i / max_fractions)
                local mark_start = center + vec2:new(math.cos(angle) * (radius - 10), math.sin(angle) * (radius - 10))
                local mark_end = center + vec2:new(math.cos(angle) * radius, math.sin(angle) * radius)
                ImGui.ImDrawListAddLine(
                    ImDrawList,
                    mark_start.x,
                    mark_start.y,
                    mark_end.x,
                    mark_end.y,
                    speedometer.markings_color,
                    line_thickness * 0.2
                )
            end

            -- halfway fractions
            for i = 0, max_fractions, step_1 do
                local angle = start_angle + (end_angle - start_angle) * (i / max_fractions)
                local mark_start = center + vec2:new(math.cos(angle) * (radius - 15), math.sin(angle) * (radius - 15))
                local mark_end = center + vec2:new(math.cos(angle) * radius, math.sin(angle) * radius)
                ImGui.ImDrawListAddLine(
                    ImDrawList,
                    mark_start.x,
                    mark_start.y,
                    mark_end.x,
                    mark_end.y,
                    speedometer.markings_color,
                    line_thickness * 0.5
                )
            end

            -- speed/altitude markings
            for i = 0, max_fractions, step_2 do
                local angle = start_angle + (end_angle - start_angle) * (i / max_fractions)
                local mark_start = center + vec2:new(math.cos(angle) * (radius - 20), math.sin(angle) * (radius - 20))
                local mark_end = center + vec2:new(math.cos(angle) * radius, math.sin(angle) * radius)
                ImGui.ImDrawListAddLine(
                    ImDrawList,
                    mark_start.x,
                    mark_start.y,
                    mark_end.x,
                    mark_end.y,
                    speedometer.markings_color,
                    line_thickness * 0.5
                )

                local mark_buff = string.format("%d", i)
                local txt_pos = center + vec2:new(math.cos(angle) * (radius - 35), math.sin(angle) * (radius - 35))
                local txt_size = vec2:new(ImGui.CalcTextSize(mark_buff))
                local txt_draw_pos = vec2:new(txt_pos.x - txt_size.x * 0.5, txt_pos.y - txt_size.y * 0.5)
                ImGui.SetWindowFontScale(0.9)
                ImGui.ImDrawListAddText(
                    ImDrawList,
                    txt_draw_pos.x,
                    txt_draw_pos.y,
                    speedometer.text_color,
                    mark_buff
                )
                ImGui.SetWindowFontScale(1.0)

                -- analog needle
                local speed_ratio = (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and
                math.min(current_altitude / max_altitude, 1) or math.min(current_speed / max_speed, 1)
                local speed_angle = start_angle + (end_angle - start_angle) * speed_ratio
                local needle_end = center + vec2:new(math.cos(speed_angle) * radius, math.sin(speed_angle) * radius)
                local start_thickness = line_thickness
                local end_thickness = line_thickness * 0.5

                for t = 0.0, 1.0, 0.05 do
                    local segment_point = center + (needle_end - center) * t
                    local thickness = start_thickness + (end_thickness - start_thickness) * t
                    ImGui.ImDrawListAddLine(
                        ImDrawList,
                        center.x,
                        center.y,
                        segment_point.x,
                        segment_point.y,
                        speedometer.needle_color,
                        thickness
                    )
                end

                -- needle base
                ImGui.ImDrawListAddCircleFilled(
                    ImDrawList,
                    center.x,
                    center.y,
                    line_thickness * 17.0,
                    speedometer.needle_base_color
                )

                -- digital speed & speed unit
                local speed_buff = string.format("%.0f", current_speed)
                local speed_text_size = vec2:new(ImGui.CalcTextSize(speed_buff))
                local unit_buff = string.format(
                    "%s",
                    (speedometer.speed_unit == 0 and "M/s") or
                    (speedometer.speed_unit == 1 and "Km/h") or
                    "Mi/h"
                )
                local unit_text_size = vec2:new(ImGui.CalcTextSize(unit_buff))
                ImGui.SetWindowFontScale(1.5)
                ImGui.ImDrawListAddText(
                    ImDrawList,
                    center.x - (speed_text_size.x / 1.5),
                    center.y - (speed_text_size.y * 0.8),
                    speedometer.text_color,
                    speed_buff
                )
                ImGui.SetWindowFontScale(1.0)
                ImGui.ImDrawListAddText(
                    ImDrawList,
                    center.x - (unit_text_size.x / 2),
                    center.y + (unit_text_size.y * 0.8),
                    speedometer.text_color,
                    unit_buff
                )

                if not Self.Vehicle.IsPlane and not Self.Vehicle.IsHeli then
                    -- driving gear indicator
                    local gear_text_offset = vec2:new(0, 69)
                    local gear_text_size = vec2:new(-10, -10)
                    ImGui.SetWindowFontScale(1.2)
                    ImGui.ImDrawListAddText(
                        ImDrawList,
                        center.x + gear_text_size.x + gear_text_offset.x,
                        center.y + gear_text_size.y + gear_text_offset.y,
                        Self.Vehicle.IsSportsCar and
                        ImU32({ 1.0, 0.215, 0.215, 1.0 }) or
                        speedometer.text_color,
                        gear or ""
                    )
                    ImGui.SetWindowFontScale(1.0)
                end

                -- RPM/throttle indicator
                local rpm_angle_range = start_angle - end_angle
                local rpm_indicator = (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and Self.Vehicle.Throttle or Self.Vehicle.RPM
                local num_active_segments = math.floor(30 * (rpm_indicator))
                for offset = -1.5, 1.5, 1 do
                    local prev_x, prev_y
                    for i = 0, num_active_segments do
                        local rpm_angle = (start_angle + (rpm_angle_range * (i / 30)) - 0.07)
                        local rpm_x = center.x + math.cos(rpm_angle) * (50 + offset)
                        local rpm_y = center.y + math.sin(rpm_angle) * (50 + offset)

                        if prev_x and prev_y then
                            ImGui.ImDrawListAddLine(
                                ImDrawList,
                                prev_x,
                                prev_y,
                                rpm_x,
                                rpm_y,
                                speedometer.needle_color
                            )
                        end
                        prev_x, prev_y = rpm_x, rpm_y
                    end
                end

                -- abs, esc, nos indicators
                if not Self.Vehicle.IsPlane and not Self.Vehicle.IsHeli then
                    if Game.Vehicle.HasABS(Self.Vehicle.Current) then
                        local abs_text_offset = vec2:new(-50, 100)
                        ImGui.SetWindowFontScale(0.77)
                        ImGui.ImDrawListAddText(
                            ImDrawList,
                            center.x + abs_text_offset.x,
                            center.y + abs_text_offset.y,
                            ImU32(
                                should_flash_bl and
                                { 1.0, 0.8, 0.0, 1.0 } or
                                { 0.1, 0.1, 0.1, 0.05 }
                            ),
                            "ABS"
                        )
                        ImGui.SetWindowFontScale(1.0)

                        local esc_text_offset = vec2:new(30, 100)
                        ImGui.SetWindowFontScale(0.77)
                        ImGui.ImDrawListAddText(
                            ImDrawList,
                            center.x + esc_text_offset.x,
                            center.y + esc_text_offset.y,
                            ImU32(
                                Self.Vehicle.ShouldFlashESC and
                                { 1.0, 0.215, 0.215, 1.0 } or
                                { 0.1, 0.1, 0.1, 0.05 }
                            ),
                            "ESC"
                        )
                        ImGui.SetWindowFontScale(1.0)
                    end

                    local nos_text_offset = vec2:new(-10, 100)
                    ImGui.SetWindowFontScale(0.77)
                    ImGui.ImDrawListAddText(
                        ImDrawList,
                        center.x + nos_text_offset.x,
                        center.y + nos_text_offset.y,
                        ImU32(
                            using_nos and
                            { 0.0, 0.215, 1.0, 1.0 } or
                            { 0.1, 0.1, 0.1, 0.05 }
                        ),
                        "NOS"
                    )
                    ImGui.SetWindowFontScale(1.0)
                else
                    local flares_text_offset = vec2:new(-50, 100)
                    ImGui.SetWindowFontScale(0.77)
                    ImGui.ImDrawListAddText(
                        ImDrawList,
                        center.x + flares_text_offset.x,
                        center.y + flares_text_offset.y,
                        ImU32(
                            is_shooting_flares and
                            { 0.1, 0.91, 0.0, 1.0 } or
                            { 0.1, 0.1, 0.1, 0.05 }
                        ),
                        "FLRS"
                    )
                    ImGui.SetWindowFontScale(1.0)

                    local gear_text_offset = vec2:new(30, 100)
                    ImGui.SetWindowFontScale(0.77)
                    ImGui.ImDrawListAddText(
                        ImDrawList,
                        center.x + gear_text_offset.x,
                        center.y + gear_text_offset.y,
                        ImU32(
                            (Self.Vehicle.LandingGearState > -1 and Self.Vehicle.LandingGearState < 4) and
                            { 0.91, 0.1, 0.0, 1.0 } or
                            { 0.1, 0.1, 0.1, 0.05 }
                        ),
                        "GEAR"
                    )
                    ImGui.SetWindowFontScale(1.0)
                end
            end
            ImGui.End()
        end
    end
end
