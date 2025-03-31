---@ diagnostic disable

local i_MainVehicle        = 0
local i_SpawnedPersist     = 0
local i_VehicleIndex       = 0
local i_PersistIndex       = 0
local i_SpawnedVehIndex    = 0
local i_VehicleHash        = 0
local i_SpawnedVehicle     = 0
local i_PersistSwitch      = 0
local i_AttachmentIndex    = 0
local i_SelectedAttachment = 0
local f_VehAxisMult        = 1.0
local f_VehAttach_X        = 0.0
local f_VehAttach_Y        = 0.0
local f_VehAttach_Z        = 0.0
local f_VehAttach_RX       = 0.0
local f_VehAttach_RY       = 0.0
local f_VehAttach_RZ       = 0.0

local function VehicleCreator_ListVehicles()
    t_Vehiclelist   = {}
    local t_ThisVeh = {}
    for _, veh in ipairs(t_VehicleNames) do
        local i_VehicleHash = joaat(veh)
        local s_DisplayName = vehicles.get_vehicle_display_name(veh)
        t_ThisVeh           = { hash = i_VehicleHash, name = s_DisplayName }
        table.insert(t_Vehiclelist, t_ThisVeh)
    end
end

local function VehicleCreator_UpdatefilteredVehicles()
    VehicleCreator_ListVehicles()
    t_FilteredVehicles = {}
    for _, veh in ipairs(t_Vehiclelist) do
        if string.find(string.lower(veh.name), vCreator_searchQ:lower()) then
            table.insert(t_FilteredVehicles, veh)
        end
    end
    table.sort(t_FilteredVehicles, function(a, b)
        return a.name < b.name
    end)
end

VehicleCreator_DisplayFilteredList = function()
    VehicleCreator_UpdatefilteredVehicles()
    t_CreatorVehicleNames = {}
    for _, veh in ipairs(t_FilteredVehicles) do
        local s_DisplayName = veh.name
        if string.find(string.lower(s_DisplayName), "drift") then
            s_DisplayName = string.format("%s  (Drift)", s_DisplayName)
        end
        table.insert(t_CreatorVehicleNames, s_DisplayName)
    end
    i_VehicleIndex, _ = ImGui.ListBox("##vehList", i_VehicleIndex, t_CreatorVehicleNames, #t_FilteredVehicles)
end

VehicleCreator_ShowAttachedVehicles = function()
    attachment_names = {}
    for _, veh in pairs(veh_attachments) do
        table.insert(attachment_names, veh.name)
    end
    i_AttachmentIndex, _ = ImGui.Combo("##attached_vehs", i_AttachmentIndex, attachment_names, #veh_attachments)
end

VehicleCreator_FilterSavedVehicles = function()
    filteredCreations = {}
    if saved_vehicles[1] ~= nil then
        for _, t in pairs(saved_vehicles) do
            table.insert(filteredCreations, t)
        end
    end
end

VehicleCreator_ShowSavedVehicles = function()
    VehicleCreator_FilterSavedVehicles()
    for _, veh in pairs(filteredCreations) do
        table.insert(persist_names, veh.name)
    end
    i_PersistIndex, _ = ImGui.ListBox("##persist_vehs", i_PersistIndex, persist_names, #filteredCreations)
end

VehicleCreator_AppendVehicleMods = function(v, t)
    script.run_in_fiber(function()
        for i = 0, 49 do
            table.insert(t, VEHICLE.GET_VEHICLE_MOD(v, i))
        end
    end)
end

VehicleCreator_SetVehicleMods = function(v, t)
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
function VehicleCreator_SpawnPersistVeh(main, mods, col_1, col_2, tint, attachments)
    script.run_in_fiber(function()
        local Pos      = self.get_pos()
        local forwardX = ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
        local forwardY = ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
        local heading  = ENTITY.GET_ENTITY_HEADING(Self.GetPedID())
        if Game.RequestModel(main) then
            i_SpawnedPersist = VEHICLE.CREATE_VEHICLE(main, Pos.x + (forwardX * 7), Pos.y + (forwardY * 7), Pos.z, heading,
                true,
                false, false)
            VEHICLE.SET_VEHICLE_IS_STOLEN(i_SpawnedPersist, false)
            DECORATOR.DECOR_SET_INT(i_SpawnedPersist, "MPBitset", 0)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(i_SpawnedPersist, col_1.r, col_1.g, col_1.b)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(i_SpawnedPersist, col_2.r, col_2.g, col_2.b)
            VehicleCreator_SetVehicleMods(i_SpawnedPersist, mods)
            VEHICLE.SET_VEHICLE_WINDOW_TINT(i_SpawnedPersist, tint)
        end
        for _, att in ipairs(attachments) do
            if Game.RequestModel(att.hash) then
                local attach = VEHICLE.CREATE_VEHICLE(att.hash, Pos.x + (forwardX * 7), Pos.y + (forwardY * 7), Pos.z,
                    heading,
                    true, false, false)
                VEHICLE.SET_VEHICLE_IS_STOLEN(attach, false)
                DECORATOR.DECOR_SET_INT(attach, "MPBitset", 0)
                VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(attach, att.color_1.r, att.color_1.g, att.color_1.b)
                VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(attach, att.color_2.r, att.color_2.g, att.color_2.b)
                VehicleCreator_SetVehicleMods(attach, att.mods)
                VEHICLE.SET_VEHICLE_WINDOW_TINT(attach, att.tint)
                if ENTITY.DOES_ENTITY_EXIST(i_SpawnedPersist) and ENTITY.DOES_ENTITY_EXIST(attach) then
                    local Bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_SpawnedPersist, "chassis_dummy")
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(attach, i_SpawnedPersist, Bone, att.posx, att.posy, att.posz, att.rotx,
                        att.roty,
                        att.rotz, false, false, false, false, 2, true, 1)
                end
            end
        end
    end)
end

function VehicleCreator_CreateWideBodyCivic()
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

function VehicleCreator_ResetOnSave()
    vehicleName       = ""
    creation_name     = ""
    main_vehicle_name = ""
    f_VehAxisMult      = 1
    i_VehicleIndex     = 0
    i_PersistIndex     = 0
    i_SpawnedVehIndex = 0
    i_VehicleHash       = 0
    i_SpawnedVehicle   = 0
    i_MainVehicle      = 0
    i_AttachmentIndex  = 0
    i_SelectedAttachment = 0
    f_VehAttach_X      = 0.0
    f_VehAttach_Y      = 0.0
    f_VehAttach_Z      = 0.0
    f_VehAttach_RX     = 0.0
    f_VehAttach_RY     = 0.0
    f_VehAttach_RZ     = 0.0
    spawned_vehicles  = {}
    spawned_vehNames  = {}
    filteredVehNames  = {}
    persist_names     = {}
    veh_attachments   = {}
    attachment_names  = {}
    attached_vehicles = {}
    vehicle_creation  = { name = "", main_veh = 0, mods = {}, color_1 = { r = 0, g = 0, b = 0 }, color_2 = { r = 0, g = 0, b = 0 }, tint = 0, attachments = {} }
end

function vCreatorUI()
    ImGui.Dummy(1, 10)
    i_PersistSwitch, pswChanged = ImGui.RadioButton(_T("CREATE_TXT_"), i_PersistSwitch, 0)
    UI.HelpMarker(_T("CREATOR_DESC_"))
    if pswChanged then
        UI.widgetSound("Nav")
    end
    if saved_vehicles[1] ~= nil then
        ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine(); i_PersistSwitch, pswChanged = ImGui.RadioButton(
            _T("SAVED_VEHS_TXT_"), i_PersistSwitch, 1)
        if pswChanged then
            UI.widgetSound("Nav")
        end
    else
        ImGui.BeginDisabled()
        ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine(); i_PersistSwitch, pswChanged = ImGui.RadioButton(
            _T("SAVED_VEHS_TXT_"), i_PersistSwitch, 1)
        ImGui.EndDisabled()
        UI.Tooltip(_T("SAVED_VEHS_DESC_"))
    end
    if i_PersistSwitch == 0 then
        ImGui.Spacing()
        ImGui.PushItemWidth(350)
        vCreator_searchQ, used = ImGui.InputTextWithHint("##searchVehicles", _T("GENERIC_SEARCH_HINT_"),
            vCreator_searchQ,
            32)
        ImGui.PopItemWidth()
        is_typing = ImGui.IsItemActive()
        ImGui.PushItemWidth(350)
        VehicleCreator_DisplayFilteredList()
        ImGui.PopItemWidth()
        ImGui.Separator()
        if t_FilteredVehicles[1] ~= nil then
            i_VehicleHash = t_FilteredVehicles[i_VehicleIndex + 1].hash
            vehicleName = t_FilteredVehicles[i_VehicleIndex + 1].name
        end
        if ImGui.Button(string.format("   %s   ##vehcreator", _T("GENERIC_SPAWN_BTN_"))) then
            UI.widgetSound("Select")
            script.run_in_fiber(function()
                local plyrCoords   = self.get_pos()
                local plyrForwardX = Game.GetForwardX(Self.GetPedID())
                local plyrForwardY = Game.GetForwardY(Self.GetPedID())
                if Game.RequestModel(i_VehicleHash) then
                    i_SpawnedVehicle = VEHICLE.CREATE_VEHICLE(i_VehicleHash, plyrCoords.x + (plyrForwardX * 5),
                        plyrCoords.y + (plyrForwardY * 5), plyrCoords.z, (ENTITY.GET_ENTITY_HEADING(Self.GetPedID()) + 90),
                        true,
                        false, false)
                    VEHICLE.SET_VEHICLE_IS_STOLEN(i_SpawnedVehicle, false)
                    DECORATOR.DECOR_SET_INT(i_SpawnedVehicle, "MPBitset", 0)
                    if i_MainVehicle == 0 then
                        i_MainVehicle = i_SpawnedVehicle
                        main_vehicle_name = vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(i_MainVehicle))
                    else
                        table.insert(spawned_vehicles, i_SpawnedVehicle)
                        table.insert(spawned_vehNames, vehicleName)
                        local dupes = Lua_fn.GetTableDupes(spawned_vehNames, vehicleName)
                        if dupes > 1 then
                            newVehName = string.format("%s #%d", vehicleName, dupes)
                            table.insert(filteredVehNames, newVehName)
                        else
                            table.insert(filteredVehNames, vehicleName)
                        end
                    end
                end
            end)
        end
        if saved_vehicles[1] == nil then
            ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
            if ImGui.Button(_T("VC_DEMO_VEH_BTN_")) then
                UI.widgetSound("Select")
                VehicleCreator_CreateWideBodyCivic()
                VehicleCreator_SpawnPersistVeh(saved_vehicles[1].main_veh, saved_vehicles[1].mods, saved_vehicles[1].color_1,
                    saved_vehicles[1].color_2, saved_vehicles[1].tint, saved_vehicles[1].attachments)
            end
            UI.Tooltip(_T("VC_DEMO_VEH_DESC_"))
        end
        if i_MainVehicle ~= 0 then
            ImGui.Separator()
            UI.ColoredText(_T("VC_MAIN_VEH_TXT_"), "green", 0.9, 20)
            ImGui.SameLine()
            ImGui.Text(main_vehicle_name)
            ImGui.SameLine()
            if ImGui.Button(string.format(" %s ##mainVeh", _T("GENERIC_DELETE_BTN_"))) then
                UI.widgetSound("Delete")
                script.run_in_fiber(function(delmv)
                    if entities.take_control_of(i_MainVehicle, 300) then
                        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(i_MainVehicle, true, true)
                        delmv:sleep(100)
                        ENTITY.DELETE_ENTITY(i_MainVehicle)
                        i_MainVehicle = 0
                    end
                    if attached_vehicles[1] ~= nil then
                        table.remove(attached_vehicles, 1)
                    end
                    if spawned_vehicles[1] ~= nil then
                        for k, veh in ipairs(spawned_vehicles) do
                            if ENTITY.DOES_ENTITY_EXIST(veh) then
                                i_MainVehicle = veh
                                main_vehicle_name = vehicles.get_vehicle_display_name(
                                    ENTITY.GET_ENTITY_MODEL(i_MainVehicle)
                                )
                                table.remove(spawned_vehicles, k)
                                table.remove(spawned_vehNames, k)
                                table.remove(filteredVehNames, k)
                            end
                        end
                    end
                end)
            end
        end
        if spawned_vehicles[1] ~= nil then
            ImGui.SeparatorText(_T("VC_SPAWNED_VEHS_TXT_"))
            ImGui.PushItemWidth(230)
            i_SpawnedVehIndex, _ = ImGui.Combo("##Spawned Vehicles", i_SpawnedVehIndex, filteredVehNames,
                #spawned_vehicles)
            ImGui.PopItemWidth()
            selectedVeh = spawned_vehicles[i_SpawnedVehIndex + 1]
            ImGui.SameLine()
            if ImGui.Button(string.format("   %s   ##spawnedVeh", _T("GENERIC_DELETE_BTN_"))) then
                UI.widgetSound("Delete")
                script.run_in_fiber(function(del)
                    if entities.take_control_of(selectedVeh, 300) then
                        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(selectedVeh, true, true)
                        del:sleep(200)
                        VEHICLE.DELETE_VEHICLE(selectedVeh)
                        -- vehicle_creation = {}
                        creation_name    = ""
                        attached_vehicle = 0
                        if i_SpawnedVehIndex ~= 0 then
                            i_SpawnedVehIndex = 0
                        end
                        if i_AttachmentIndex ~= 0 then
                            i_AttachmentIndex = 0
                        end
                    else
                        YimToast:ShowError("Samurais Scripts", _T("GENERIC_VEH_DELETE_ERROR_"))
                    end
                end)
            end
            if ImGui.Button(string.format("%s%s", _T("VC_ATTACH_BTN_"), main_vehicle_name)) then
                if selectedVeh ~= i_MainVehicle then
                    script.run_in_fiber(function()
                        if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(selectedVeh, i_MainVehicle) then
                            UI.widgetSound("Select")
                            ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedVeh, i_MainVehicle,
                                ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), f_VehAttach_X,
                                f_VehAttach_Y,
                                f_VehAttach_Z, f_VehAttach_RX, f_VehAttach_RY, f_VehAttach_RZ, false, false, false,
                                false,
                                2, true, 1)
                            attached_vehicles.entity                                                              = selectedVeh
                            attached_vehicles.hash                                                                = ENTITY
                                .GET_ENTITY_MODEL(selectedVeh)
                            attached_vehicles.name                                                                = vehicles
                                .get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(selectedVeh))
                            attached_vehicles.posx                                                                = f_VehAttach_X
                            attached_vehicles.posy                                                                = f_VehAttach_Y
                            attached_vehicles.posz                                                                = f_VehAttach_Z
                            attached_vehicles.rotx                                                                = f_VehAttach_RX
                            attached_vehicles.roty                                                                = f_VehAttach_RY
                            attached_vehicles.rotz                                                                = f_VehAttach_RZ
                            attached_vehicles.tint                                                                = VEHICLE
                                .GET_VEHICLE_WINDOW_TINT(selectedVeh)
                            attached_vehicles.color_1.r, attached_vehicles.color_1.g, attached_vehicles.color_1.b =
                                VEHICLE
                                .GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(selectedVeh, attached_vehicles.color_1.r,
                                    attached_vehicles.color_1.g,
                                    attached_vehicles.color_1.b)
                            attached_vehicles.color_2.r, attached_vehicles.color_2.g, attached_vehicles.color_2.b =
                                VEHICLE
                                .GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(selectedVeh, attached_vehicles.color_2.r,
                                    attached_vehicles.color_2.g,
                                    attached_vehicles.color_2.b)
                            VehicleCreator_AppendVehicleMods(selectedVeh, attached_vehicles.mods)
                            table.insert(veh_attachments, attached_vehicles)
                            attached_vehicles = { entity = 0, hash = 0, mods = {}, color_1 = { r = 0, g = 0, b = 0 }, color_2 = { r = 0, g = 0, b = 0 }, tint = 0, posx = 0.0, posy = 0.0, posz = 0.0, rotx = 0.0, roty = 0.0, rotz = 0.0 }
                        else
                            UI.widgetSound("Error")
                            YimToast:ShowError("Samurais Scripts", _T("VC_ALREADY_ATTACHED_"))
                        end
                    end)
                else
                    UI.widgetSound("Error")
                    YimToast:ShowError("Samurais Scripts", _T("VC_SELF_ATTACH_ERR_"))
                end
            end
        end
        if veh_attachments[1] ~= nil then
            ImGui.Spacing(); ImGui.SeparatorText("Attached Vehicles")
            ImGui.PushItemWidth(230)
            VehicleCreator_ShowAttachedVehicles()
            ImGui.PopItemWidth()
            i_SelectedAttachment = veh_attachments[i_AttachmentIndex + 1]
            ImGui.Text(_T("GENERIC_MULTIPLIER_LABEL_"))
            ImGui.PushItemWidth(271)
            f_VehAxisMult, _ = ImGui.InputInt("##AttachMultiplier", f_VehAxisMult, 1, 2)
            ImGui.PopItemWidth()
            ImGui.Spacing()
            ImGui.Text("X Axis :"); ImGui.SameLine(); ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Y Axis :"); ImGui
                .SameLine()
            ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Z Axis :")
            ImGui.ArrowButton("##Xleft", 0)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.posx = i_SelectedAttachment.posx + 0.001 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##XRight", 1)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.posx = i_SelectedAttachment.posx - 0.001 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.Dummy(5, 1); ImGui.SameLine()
            ImGui.ArrowButton("##Yleft", 0)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.posy = i_SelectedAttachment.posy + 0.001 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##YRight", 1)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.posy = i_SelectedAttachment.posy - 0.001 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.Dummy(5, 1); ImGui.SameLine()
            ImGui.ArrowButton("##zUp", 2)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.posz = i_SelectedAttachment.posz + 0.001 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##zDown", 3)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.posz = i_SelectedAttachment.posz - 0.001 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.Text("X Rotation :"); ImGui.SameLine(); ImGui.Text("Y Rotation :"); ImGui.SameLine(); ImGui.Text(
                "Z Rotation :")
            ImGui.ArrowButton("##rotXleft", 0)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.rotx = i_SelectedAttachment.rotx + 0.01 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##rotXright", 1)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.rotx = i_SelectedAttachment.rotx - 0.01 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.Dummy(5, 1); ImGui.SameLine()
            ImGui.ArrowButton("##rotYleft", 0)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.roty = i_SelectedAttachment.roty + 0.01 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##rotYright", 1)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.roty = i_SelectedAttachment.roty - 0.01 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.Dummy(5, 1); ImGui.SameLine()
            ImGui.ArrowButton("##rotZup", 2)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.rotz = i_SelectedAttachment.rotz + 0.01 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##rotZdown", 3)
            if ImGui.IsItemActive() then
                UI.widgetSound("Nav")
                i_SelectedAttachment.rotz = i_SelectedAttachment.rotz - 0.01 * f_VehAxisMult
                ENTITY.ATTACH_ENTITY_TO_ENTITY(i_SelectedAttachment.entity, i_MainVehicle,
                    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(i_MainVehicle, "chassis_dummy"), i_SelectedAttachment.posx,
                    i_SelectedAttachment.posy,
                    i_SelectedAttachment.posz, i_SelectedAttachment.rotx, i_SelectedAttachment.roty, i_SelectedAttachment.rotz, false,
                    false,
                    false,
                    false,
                    2, true, 1)
            end
            ImGui.Spacing()
            if ImGui.Button(string.format("   %s   ##vehcreator1", _T("GENERIC_SAVE_BTN_"))) then
                UI.widgetSound("Select2")
                ImGui.OpenPopup("Save Merged Vehicles")
            end
            ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
            ImGui.SetNextWindowBgAlpha(0.81)
            if ImGui.BeginPopupModal("Save Merged Vehicles", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
                creation_name, _ = ImGui.InputTextWithHint(
                    "##save_merge", _T("VC_NAME_HINT_"), creation_name, 128
                )
                is_typing = ImGui.IsItemActive(); ImGui.Spacing()
                if not start_loading_anim then
                    if ImGui.Button(string.format("%s##vehcreator2", _T("GENERIC_SAVE_BTN_"))) then
                        script.run_in_fiber(function(save)
                            if creation_name ~= "" then
                                if saved_vehicles[1] ~= nil then
                                    for _, v in pairs(saved_vehicles) do
                                        if creation_name == v.name then
                                            UI.widgetSound("Error")
                                            YimToast:ShowError("Samurai's Scripts", _T("VC_NAME_ERROR_"))
                                            return
                                        end
                                    end
                                end
                                UI.widgetSound("Select")
                                vehicle_creation.name                                                              = creation_name
                                vehicle_creation.main_veh                                                          = ENTITY
                                    .GET_ENTITY_MODEL(i_MainVehicle)
                                vehicle_creation.attachments                                                       = veh_attachments
                                vehicle_creation.tint                                                              = VEHICLE
                                    .GET_VEHICLE_WINDOW_TINT(i_MainVehicle)
                                vehicle_creation.color_1.r, vehicle_creation.color_1.g, vehicle_creation.color_1.b =
                                    VEHICLE
                                    .GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(i_MainVehicle, vehicle_creation.color_1.r,
                                        vehicle_creation.color_1.g,
                                        vehicle_creation.color_1.b)
                                vehicle_creation.color_2.r, vehicle_creation.color_2.g, vehicle_creation.color_2.b =
                                    VEHICLE
                                    .GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(i_MainVehicle, vehicle_creation.color_2.r,
                                        vehicle_creation.color_2
                                        .g, vehicle_creation.color_2.b)
                                VehicleCreator_AppendVehicleMods(i_MainVehicle, vehicle_creation.mods)
                                start_loading_anim = true
                                save:sleep(500)
                                table.insert(saved_vehicles, vehicle_creation)
                                CFG:SaveItem("saved_vehicles", saved_vehicles)
                                ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(i_MainVehicle)
                                for _, veh in ipairs(spawned_vehicles) do
                                    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(veh)
                                end
                                YimToast:ShowSuccess("Samurais Scripts", _T("VC_SAVE_SUCCESS_"))
                                VehicleCreator_ResetOnSave()
                                start_loading_anim = false
                                ImGui.CloseCurrentPopup()
                            else
                                UI.widgetSound("Error")
                                YimToast:ShowWarning("Samurais Scripts", _T("VC_SAVE_ERROR_"))
                            end
                        end)
                    end
                else
                    ImGui.BeginDisabled()
                    ImGui.Button(string.format("  %s  ", loading_label))
                    ImGui.EndDisabled()
                end
                ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
                if ImGui.Button(string.format("%s##vehcreator", _T("GENERIC_CANCEL_BTN_"))) then
                    UI.widgetSound("Cancel")
                    creation_name = ""
                    ImGui.CloseCurrentPopup()
                end
                ImGui.End()
            end
        end
    elseif i_PersistSwitch == 1 then
        if saved_vehicles[1] ~= nil then
            ImGui.PushItemWidth(350)
            VehicleCreator_ShowSavedVehicles()
            ImGui.PopItemWidth()
            persist_info = filteredCreations[i_PersistIndex + 1]
            ImGui.Spacing()
            if ImGui.Button(string.format("%s##vehcreator", _T("VC_SPAWN_PERSISTENT_"))) then
                UI.widgetSound("Select")
                VehicleCreator_SpawnPersistVeh(persist_info.main_veh, persist_info.mods, persist_info.color_1, persist_info.color_2,
                    persist_info.tint, persist_info.attachments)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
            if UI.ColoredButton(_T("VC_DELETE_PERSISTENT_"), "#E40000", "#FF3F3F", "#FF8080", 0.87) then
                UI.widgetSound("Focus_In")
                ImGui.OpenPopup("Remove Persistent")
            end
            ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
            ImGui.SetNextWindowSizeConstraints(200, 100, 400, 400)
            ImGui.SetNextWindowBgAlpha(0.7)
            if ImGui.BeginPopupModal("Remove Persistent", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
                UI.ColoredText(_T("CONFIRM_PROMPT_"), "yellow", 0.91, 35)
                ImGui.Dummy(1, 20)
                if ImGui.Button(string.format("   %s   ##vehcreator", _T("GENERIC_YES_"))) then
                    for key, value in ipairs(saved_vehicles) do
                        if persist_info == value then
                            table.remove(saved_vehicles, key)
                            CFG:SaveItem("saved_vehicles", saved_vehicles)
                        end
                    end
                    if saved_vehicles[1] == nil then
                        i_PersistSwitch = 0
                    end
                    UI.widgetSound("Select")
                    ImGui.CloseCurrentPopup()
                    YimToast:ShowSuccess("Samurais Scripts", _T("VC_DELETE_NOTIF_"))
                end
                ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
                if ImGui.Button(string.format("   %s   ##vehcreator", _T("GENERIC_NO_"))) then
                    UI.widgetSound("Cancel")
                    ImGui.CloseCurrentPopup()
                end
                ImGui.End()
            end
        end
    end
end
