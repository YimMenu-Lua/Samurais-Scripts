---@diagnostic disable

local coords   = self.get_pos()
local heading  = 0.0
local forwardX = 0.0
local forwardY = 0.0

local function ResetSliders()
    spawnDistance = vec3:new(0, 0, 0)
    spawnRot      = vec3:new(0, 0, 0)
end

function UpdateFilteredProps()
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

function DisplayFilteredProps()
    UpdateFilteredProps()
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

function GetAllObjects()
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

function UpdateSelfBones()
    filteredSelfBones = {}
    for _, bone in ipairs(t_PedBones) do
        table.insert(filteredSelfBones, bone)
    end
end

function DisplaySelfBones()
    UpdateSelfBones()
    local boneNames = {}
    for _, bone in ipairs(filteredSelfBones) do
        table.insert(boneNames, bone.name)
    end
    selected_bone, used = ImGui.Combo("##pedBones", selected_bone, boneNames, #filteredSelfBones)
end

function UpdateVehBones()
    filteredVehBones = {}
    for _, bone in ipairs(t_VehicleBones) do
        local bone_idx = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current, bone)
        if bone_idx ~= nil and bone_idx ~= -1 then
            table.insert(filteredVehBones, bone)
        end
    end
end

function DisplayVehBones()
    UpdateVehBones()
    local boneNames = {}
    for _, bone in ipairs(filteredVehBones) do
        table.insert(boneNames, bone)
    end
    selected_bone, used = ImGui.Combo("##vehBones", selected_bone, boneNames, #filteredVehBones)
end

function DisplaySpawnedObjects()
    spawnedNames = {}
    if spawned_props[1] ~= nil then
        for _, v in ipairs(spawned_props) do
            table.insert(spawnedNames, v.name)
        end
    end
    spawned_index, spiUsed = ImGui.Combo("##spawnedProps", spawned_index, spawnedNames, #spawned_props)
end

function DisplayAttachedObjects()
    selfAttachNames = {}
    if attached_props[1] ~= nil then
        for _, v in ipairs(attached_props) do
            table.insert(selfAttachNames, v.name)
        end
    end
    attached_index, used = ImGui.Combo("##Attached Objects", attached_index, selfAttachNames, #attached_props)
end

function DisplayVehAttachments()
    vehAttachNames = {}
    if vehicle_attachments[1] ~= nil then
        for _, v in ipairs(vehicle_attachments) do
            table.insert(vehAttachNames, v.name)
        end
    end
    vattached_index, used = ImGui.Combo("##vehAttachedObjects", vattached_index, vehAttachNames, #vehicle_attachments)
end

function FilterPersistProps()
    filteredPersistProps = {}
    if persist_attachments[1] ~= nil then
        for _, t in ipairs(persist_attachments) do
            table.insert(filteredPersistProps, t)
        end
    end
end

function ShowPersistProps()
    FilterPersistProps()
    persist_prop_names = {}
    for _, p in ipairs(filteredPersistProps) do
        table.insert(persist_prop_names, p.name)
    end
    persist_prop_index, _ = ImGui.ListBox(
        "##persist_props",
        persist_prop_index,
        persist_prop_names,
        #filteredPersistProps
    )
end

function objectSpawnerUI()
    ImGui.BeginTabBar("Object Spawner")
    if ImGui.BeginTabItem("Spawn & Create") then
        ImGui.Spacing(); os_switch, os_switchUsed = ImGui.RadioButton(_T("CUSTOM_OBJECTS_TXT_"), os_switch, 0)
        if os_switchUsed then
            UI.widgetSound("Nav")
        end
        ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine(); os_switch, os_switchUsed = ImGui.RadioButton(
            _T("ALL_OBJECTS_TXT_"), os_switch, 1)
        ImGui.PushItemWidth(360)
        objects_search, used = ImGui.InputTextWithHint("##searchObjects", _T("GENERIC_SEARCH_HINT_"),
            objects_search, 32)
        is_typing = ImGui.IsItemActive()
        if os_switchUsed then
            UI.widgetSound("Nav")
        end
        if os_switch == 0 then
            DisplayFilteredProps()
        else
            GetAllObjects()
        end
        ImGui.PopItemWidth()
        ImGui.Spacing()
        ImGui.BeginDisabled(blacklisted_obj)
        preview, _ = ImGui.Checkbox(_T("PREVIEW_OBJECTS_CB_"), preview)
        ImGui.EndDisabled()
        if previewUsed then
            UI.widgetSound("Nav2")
        end
        if preview then
            spawnCoords            = ENTITY.GET_ENTITY_COORDS(previewEntity, false)
            previewLoop            = true
            currentObjectPreview   = propHash
            local previewObjectPos = ENTITY.GET_ENTITY_COORDS(previewEntity, false)
            ImGui.Text(_T("MOVE_OBJECTS_FB_")); ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine(); ImGui
                .Text(_T("MOVE_OBJECTS_UD_"))
            ImGui.Dummy(10, 1); ImGui.SameLine()
            ImGui.ArrowButton("##f2", 2)
            if ImGui.IsItemActive() then
                forwardX = forwardX * 0.1
                forwardY = forwardY * 0.1
                ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x + forwardX, previewObjectPos.y + forwardY,
                    previewObjectPos.z, false, false, false, false)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##f3", 3)
            if ImGui.IsItemActive() then
                forwardX = forwardX * 0.1
                forwardY = forwardY * 0.1
                ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x - forwardX, previewObjectPos.y - forwardY,
                    previewObjectPos.z, false, false, false, false)
            end
            ImGui.SameLine()
            ImGui.Dummy(60, 1); ImGui.SameLine()
            ImGui.ArrowButton("##z2", 2)
            if ImGui.IsItemActive() then
                zOffset = zOffset + 0.01
                ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x, previewObjectPos.y, previewObjectPos.z + 0.01,
                    false,
                    false, false, false)
            end
            ImGui.SameLine()
            ImGui.ArrowButton("##z3", 3)
            if ImGui.IsItemActive() then
                zOffset = zOffset - 0.01
                ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x, previewObjectPos.y, previewObjectPos.z - 0.01,
                    false,
                    false, false, false)
            end
        else
            previewStarted = false
            previewLoop    = false
            zOffset        = 0.0
            forwardX       = ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
            forwardY       = ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
        end
        if NETWORK.NETWORK_IS_SESSION_ACTIVE() then
            if not preview then
                ImGui.SameLine()
            end
            ImGui.BeginDisabled(blacklisted_obj)
            spawnForPlayer, _ = ImGui.Checkbox(_T("SPAWN_FOR_PLAYER_CB_"), spawnForPlayer)
            if spawnForPlayerUsed then
                UI.widgetSound("Nav2")
            end
            ImGui.EndDisabled()
        end
        if spawnForPlayer then
            ImGui.PushItemWidth(270)
            Game.displayPlayerListCombo()
            ImGui.PopItemWidth()
            selectedPlayer = filteredPlayers[playerIndex + 1]
            coords         = ENTITY.GET_ENTITY_COORDS(selectedPlayer, false)
            heading        = ENTITY.GET_ENTITY_HEADING(selectedPlayer)
            forwardX       = ENTITY.GET_ENTITY_FORWARD_X(selectedPlayer)
            forwardY       = ENTITY.GET_ENTITY_FORWARD_Y(selectedPlayer)
            ImGui.SameLine()
        else
            coords   = ENTITY.GET_ENTITY_COORDS(Self.GetPedID(), false)
            heading  = ENTITY.GET_ENTITY_HEADING(Self.GetPedID())
            forwardX = ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
            forwardY = ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
        end
        ImGui.SameLine(); ImGui.BeginDisabled(blacklisted_obj)
        if ImGui.Button(string.format("%s##obj", _T("GENERIC_SPAWN_BTN_"))) then
            UI.widgetSound("Select")
            script.run_in_fiber(function()
                while not STREAMING.HAS_MODEL_LOADED(propHash) do
                    STREAMING.REQUEST_MODEL(propHash)
                    coroutine.yield()
                end
                if preview then
                    spawnedObject = OBJECT.CREATE_OBJECT(propHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, true,
                        true, false)
                else
                    spawnedObject = OBJECT.CREATE_OBJECT(propHash, coords.x + (forwardX * 3), coords.y + (forwardY * 3),
                        coords.z,
                        true, true, false)
                end
                if ENTITY.DOES_ENTITY_EXIST(spawnedObject) then
                    ENTITY.SET_ENTITY_HEADING(spawnedObject, heading)
                    OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(spawnedObject)
                    local thisProp  = {}
                    thisProp.name   = propName
                    thisProp.hash   = propHash
                    thisProp.entity = spawnedObject
                    table.insert(spawned_props, thisProp)
                end
            end)
        end
        ImGui.EndDisabled()
        if showInvalidObjText then
            UI.ColoredText(string.format("%s%s", _T("INVALID_OBJECT_TXT_"), invalidType), "#EED202", nil, 15)
        end
        if spawned_props[1] ~= nil then
            ImGui.Text(_T("SPAWNED_OBJECTS_TXT_"))
            ImGui.PushItemWidth(270)
            DisplaySpawnedObjects()
            ImGui.PopItemWidth()
            selectedObject = spawned_props[spawned_index + 1]
            if #spawned_props > 1 then
                Game.World.MarkSelectedEntity(selectedObject.entity)
            end
            ImGui.SameLine()
            if ImGui.Button(string.format(" %s ##obj", _T("GENERIC_DELETE_BTN_"))) then
                UI.widgetSound("Delete")
                script.run_in_fiber(function(script)
                    if ENTITY.DOES_ENTITY_EXIST(selectedObject.entity) then
                        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(selectedObject.entity, true, true)
                        script:sleep(100)
                        ENTITY.DELETE_ENTITY(selectedObject.entity)
                        spawned_index = 0
                        if spawned_index > 1 then
                            spawned_index = spawned_index - 1
                        end
                    end
                end)
            end
            ImGui.Separator()
            attachToSelf, attachToSelfUsed = ImGui.Checkbox(_T("ATTACH_TO_SELF_CB_"), attachToSelf)
            if attachToSelfUsed then
                UI.widgetSound("Nav2")
            end
            if Self.Vehicle.Current ~= nil and Self.Vehicle.Current ~= 0 then
                ImGui.SameLine(); attachToVeh, attachToVehUsed = ImGui.Checkbox(_T("ATTACH_TO_VEH_CB_"),
                    attachToVeh)
                if attachToVehUsed then
                    attachToSelf = false
                    UI.widgetSound("Nav2")
                end
            else
                ImGui.BeginDisabled()
                ImGui.SameLine(); attachToVeh, _ = ImGui.Checkbox(_T("ATTACH_TO_VEH_CB_"), attachToVeh)
                ImGui.EndDisabled()
                UI.Tooltip(_T("GET_IN_VEH_WARNING_"))
            end
            if attachToSelf then
                attachToVeh = false
                ImGui.PushItemWidth(230)
                DisplaySelfBones()
                ImGui.PopItemWidth()
                boneData = filteredSelfBones[selected_bone + 1]
                ImGui.SameLine()
                if ImGui.Button(string.format(" %s ##self", _T("GENERIC_ATTACH_BTN_"))) then
                    script.run_in_fiber(function()
                        if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(selectedObject.entity, Self.GetPedID()) then
                            UI.widgetSound("Select2")
                            ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject.entity, Self.GetPedID(),
                                PED.GET_PED_BONE_INDEX(Self.GetPedID(), boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false,
                                false, false,
                                false,
                                2, true, 1)
                            attached = true
                            if selfAttachments[1] ~= nil then
                                for _, v in ipairs(selfAttachments) do
                                    if selectedObject.entity ~= v.entity then
                                        selfAttachments.entity = selectedObject.entity
                                        selfAttachments.hash   = Game.GetEntityModel(selectedObject.entity)
                                        selfAttachments.name   = selectedObject.name
                                        selfAttachments.bone   = boneData.ID
                                        selfAttachments.posx   = 0.0
                                        selfAttachments.posy   = 0.0
                                        selfAttachments.posz   = 0.0
                                        selfAttachments.rotx   = 0.0
                                        selfAttachments.roty   = 0.0
                                        selfAttachments.rotz   = 0.0
                                    end
                                end
                            else
                                selfAttachments.entity = selectedObject.entity
                                selfAttachments.hash   = Game.GetEntityModel(selectedObject.entity)
                                selfAttachments.name   = selectedObject.name
                                selfAttachments.bone   = boneData.ID
                                selfAttachments.posx   = 0.0
                                selfAttachments.posy   = 0.0
                                selfAttachments.posz   = 0.0
                                selfAttachments.rotx   = 0.0
                                selfAttachments.roty   = 0.0
                                selfAttachments.rotz   = 0.0
                            end
                            table.insert(attached_props, selfAttachments)
                            selfAttachments = {}
                            attached        = true
                            attachedToSelf  = true
                        else
                            UI.widgetSound("Error")
                            YimToast:ShowError("Samurai's Scripts", "This object is already attached!")
                        end
                    end)
                end
                if attached_props[1] ~= nil then
                    ImGui.Text(_T("ATTACHED_OBJECTS_TXT_"))
                    ImGui.PushItemWidth(230)
                    DisplayAttachedObjects()
                    ImGui.PopItemWidth()
                    selectedAttachment = attached_props[attached_index + 1]
                    ImGui.SameLine()
                    if ImGui.Button(string.format("%s##self", _T("GENERIC_DETACH_BTN_"))) then
                        UI.widgetSound("Cancel")
                        script.run_in_fiber(function()
                            ENTITY.DETACH_ENTITY(selectedAttachment.entity, true, true)
                            for k, v in ipairs(attached_props) do
                                if selectedAttachment.entity == v.entity then
                                    table.remove(attached_props, k)
                                end
                            end
                        end)
                    end
                end
            end
            if attachToVeh then
                attachToSelf = false
                ImGui.PushItemWidth(230)
                DisplayVehBones()
                ImGui.PopItemWidth()
                boneData = filteredVehBones[selected_bone + 1]
                ImGui.SameLine()
                if ImGui.Button(string.format(" %s ##veh", _T("GENERIC_ATTACH_BTN_"))) then
                    UI.widgetSound("Select2")
                    script.run_in_fiber(function()
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject.entity, Self.Vehicle.Current,
                            ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current, boneData), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            false, false,
                            false,
                            false,
                            2, true, 1)
                        attached       = ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(selectedObject.entity, self.get_veh())
                        attachedObject = selectedObject
                        if vehAttachments[1] ~= nil then
                            for _, v in ipairs(vehAttachments) do
                                if selectedObject.entity ~= v.entity then
                                    vehAttachments.entity = selectedObject.entity
                                    vehAttachments.hash   = Game.GetEntityModel(selectedObject.entity)
                                    vehAttachments.name   = selectedObject.name
                                    vehAttachments.bone   = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current,
                                        boneData)
                                    vehAttachments.posx   = 0.0
                                    vehAttachments.posy   = 0.0
                                    vehAttachments.posz   = 0.0
                                    vehAttachments.rotx   = 0.0
                                    vehAttachments.roty   = 0.0
                                    vehAttachments.rotz   = 0.0
                                end
                            end
                        else
                            vehAttachments.entity = selectedObject.entity
                            vehAttachments.hash   = Game.GetEntityModel(selectedObject.entity)
                            vehAttachments.name   = selectedObject.name
                            vehAttachments.bone   = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current, boneData)
                            vehAttachments.posx   = 0.0
                            vehAttachments.posy   = 0.0
                            vehAttachments.posz   = 0.0
                            vehAttachments.rotx   = 0.0
                            vehAttachments.roty   = 0.0
                            vehAttachments.rotz   = 0.0
                        end
                        table.insert(vehicle_attachments, vehAttachments)
                        vehAttachments = {}
                        attached       = true
                        attachedToSelf = true
                    end)
                end
                if vehicle_attachments[1] ~= nil then
                    ImGui.Text(_T("ATTACHED_OBJECTS_TXT_"))
                    ImGui.PushItemWidth(230)
                    DisplayVehAttachments()
                    ImGui.PopItemWidth()
                    selectedAttachment = vehicle_attachments[attached_index + 1]
                    ImGui.SameLine()
                    if ImGui.Button(string.format("%s##veh", _T("GENERIC_DETACH_BTN_"))) then
                        UI.widgetSound("Cancel")
                        script.run_in_fiber(function()
                            ENTITY.DETACH_ENTITY(selectedAttachment.entity, true, true)
                            for k, v in ipairs(vehicle_attachments) do
                                if selectedAttachment.entity == v.entity then
                                    table.remove(vehicle_attachments, k)
                                end
                            end
                        end)
                    end
                end
            end
            edit_mode, edit_modeUsed = ImGui.Checkbox(_T("EDIT_MODE_CB_"), edit_mode)
            if edit_modeUsed then
                UI.widgetSound("Nav2")
            end
            UI.HelpMarker(_T("EDIT_MODE_DESC_"))
            ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
            if ImGui.Button(string.format("   %s   ", _T("GENERIC_RESET_BTN_"))) then
                UI.widgetSound("Select")
                script.run_in_fiber(function()
                    if ENTITY.IS_ENTITY_ATTACHED(selected_att) then
                        selectedAttachment.posx, selectedAttachment.posy, selectedAttachment.posz,
                        selectedAttachment.rotx, selectedAttachment.roty, selectedAttachment.rotz = 0.0,
                            0.0, 0.0, 0.0, 0.0, 0.0
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_att, target, attachBone, 0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
                    else
                        ResetSliders()
                        ENTITY.SET_ENTITY_COORDS(selectedObject.entity, coords.x + (forwardX * 3),
                            coords.y + (forwardY * 3),
                            coords.z, false,
                            false, false, false)
                        ENTITY.SET_ENTITY_HEADING(selectedObject.entity, heading)
                        OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(selectedObject.entity)
                    end
                end)
            end
            UI.HelpMarker(_T("RESET_OBJECT_DESC_"))
            if edit_mode and not ENTITY.IS_ENTITY_ATTACHED(selectedObject.entity) then
                ImGui.Text(_T("XYZ_MULTIPLIER_TXT_"))
                ImGui.PushItemWidth(280)
                axisMult, _ = ImGui.InputInt("##multiplier", axisMult, 1, 2)
                ImGui.Text("                        X Axis :")
                spawnDistance.x, _ = ImGui.SliderFloat(" ", spawnDistance.x, -0.1 * axisMult, 0.1 * axisMult)
                activeX = ImGui.IsItemActive()
                ImGui.Separator()
                ImGui.Text("                        Y Axis :")
                spawnDistance.y, _ = ImGui.SliderFloat("  ", spawnDistance.y, -0.1 * axisMult, 0.1 * axisMult)
                activeY = ImGui.IsItemActive()
                ImGui.Separator()
                ImGui.Text("                        Z Axis :")
                spawnDistance.z, _ = ImGui.SliderFloat("   ", spawnDistance.z, -0.05 * axisMult, 0.05 * axisMult)
                activeZ = ImGui.IsItemActive()
                ImGui.Separator(); ImGui.Text(_T("ROTATE_OBJECT_TXT_"))
                ImGui.Text("                        X Axis :")
                spawnRot.x, _ = ImGui.SliderFloat("##xRot", spawnRot.x, -0.1 * axisMult, 0.1 * axisMult)
                rotX = ImGui.IsItemActive()
                ImGui.Separator()
                ImGui.Text("                        Y Axis :")
                spawnRot.y, _ = ImGui.SliderFloat("##yRot", spawnRot.y, -0.1 * axisMult, 0.1 * axisMult)
                rotY = ImGui.IsItemActive()
                ImGui.Separator()
                ImGui.Text("                        Z Axis :")
                spawnRot.z, _ = ImGui.SliderFloat("##zRot", spawnRot.z, -0.5 * axisMult, 0.5 * axisMult)
                rotZ = ImGui.IsItemActive()
                ImGui.PopItemWidth()
            else
                if edit_mode and attached_props[1] ~= nil or edit_mode and vehicle_attachments[1] ~= nil then
                    if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(selectedObject.entity, Self.GetPedID()) then
                        target       = Self.GetPedID()
                        attachBone   = PED.GET_PED_BONE_INDEX(Self.GetPedID(), selectedAttachment.bone)
                        selected_att = selectedAttachment.entity
                    elseif ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(selectedObject.entity, self.get_veh()) then
                        target       = Self.Vehicle.Current
                        attachBone   = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current, boneData)
                        selected_att = selectedAttachment.entity
                    end
                    ImGui.Text(_T("XYZ_MULTIPLIER_TXT_"))
                    ImGui.PushItemWidth(271)
                    axisMult, _ = ImGui.InputInt("##AttachMultiplier", axisMult, 1, 2)
                    ImGui.PopItemWidth()
                    ImGui.Spacing()
                    ImGui.Text("X Axis :"); ImGui.SameLine(); ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text(
                    "Y Axis :"); ImGui
                        .SameLine()
                    ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Z Axis :")
                    ImGui.ArrowButton("##Xleft", 0)
                    if ImGui.IsItemActive() then
                        selectedAttachment.posx = selectedAttachment.posx + 0.001 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.ArrowButton("##XRight", 1)
                    if ImGui.IsItemActive() then
                        selectedAttachment.posx = selectedAttachment.posx - 0.001 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.Dummy(5, 1); ImGui.SameLine()
                    ImGui.ArrowButton("##Yleft", 0)
                    if ImGui.IsItemActive() then
                        selectedAttachment.posy = selectedAttachment.posy + 0.001 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.ArrowButton("##YRight", 1)
                    if ImGui.IsItemActive() then
                        selectedAttachment.posy = selectedAttachment.posy - 0.001 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.Dummy(5, 1); ImGui.SameLine()
                    ImGui.ArrowButton("##zUp", 2)
                    if ImGui.IsItemActive() then
                        selectedAttachment.posz = selectedAttachment.posz + 0.001 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.ArrowButton("##zDown", 3)
                    if ImGui.IsItemActive() then
                        selectedAttachment.posz = selectedAttachment.posz - 0.001 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.Text("X Rotation :"); ImGui.SameLine(); ImGui.Text("Y Rotation :"); ImGui.SameLine(); ImGui
                        .Text(
                            "Z Rotation :")
                    ImGui.ArrowButton("##rotXleft", 0)
                    if ImGui.IsItemActive() then
                        selectedAttachment.rotx = selectedAttachment.rotx + 0.5 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.ArrowButton("##rotXright", 1)
                    if ImGui.IsItemActive() then
                        selectedAttachment.rotx = selectedAttachment.rotx - 0.5 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.Dummy(5, 1); ImGui.SameLine()
                    ImGui.ArrowButton("##rotYleft", 0)
                    if ImGui.IsItemActive() then
                        selectedAttachment.roty = selectedAttachment.roty + 0.5 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.ArrowButton("##rotYright", 1)
                    if ImGui.IsItemActive() then
                        selectedAttachment.roty = selectedAttachment.roty - 0.5 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.Dummy(5, 1); ImGui.SameLine()
                    ImGui.ArrowButton("##rotZup", 2)
                    if ImGui.IsItemActive() then
                        selectedAttachment.rotz = selectedAttachment.rotz + 0.5 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                    ImGui.SameLine()
                    ImGui.ArrowButton("##rotZdown", 3)
                    if ImGui.IsItemActive() then
                        selectedAttachment.rotz = selectedAttachment.rotz - 0.5 * axisMult
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            selected_att, target, attachBone, selectedAttachment.posx,
                            selectedAttachment.posy, selectedAttachment.posz, selectedAttachment.rotx,
                            selectedAttachment.roty, selectedAttachment.rotz, false, false, false, false, 2, true, 1
                        )
                    end
                end
            end
            ImGui.Dummy(1, 5)
            if attachedToSelf and attached_props[1] ~= nil then
                if ImGui.Button(string.format("  %s  ##obj", _T("GENERIC_SAVE_BTN_"))) then
                    UI.widgetSound("Select")
                    ImGui.OpenPopup("persist props")
                end
                ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
                ImGui.SetNextWindowBgAlpha(0.8)
                if ImGui.BeginPopupModal("persist props", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
                    ImGui.Dummy(1, 5); ImGui.Text("Give your creation a name and save it."); ImGui.Dummy(1, 5)
                    saved_props_name, _ = ImGui.InputTextWithHint("##persistpropname", "Name", saved_props_name, 64)
                    is_typing = ImGui.IsItemActive()
                    ImGui.Dummy(1, 5)
                    if ImGui.Button(string.format("  %s  ##obj2", _T("GENERIC_SAVE_BTN_"))) then
                        local timer = 0
                        if saved_props_name ~= "" then
                            if persist_attachments[1] ~= nil then
                                for _, v in pairs(persist_attachments) do
                                    if saved_props_name == v.name then
                                        UI.widgetSound("Error")
                                        YimToast:ShowError("Samurai's Scripts",
                                            "You already have an outfit with the same name.")
                                        return
                                    end
                                end
                            end
                            UI.widgetSound("Select")
                            prop_creation.name  = saved_props_name
                            prop_creation.props = attached_props
                            table.insert(persist_attachments, prop_creation)
                            CFG:SaveItem("persist_attachments", persist_attachments)
                            YimToast:ShowSuccess("Samurai's Scripts",
                                string.format("Your [ %s ] has been saved", saved_props_name))
                            repeat
                                timer = timer + 1
                            until timer >= 50
                            prop_creation       = { name = "", props = {} }
                            persist_prop_index  = 0
                            saved_props_name    = ""
                            persist_attachments = CFG:ReadItem("persist_attachments")
                            if spawned_props[1] ~= nil then
                                script.run_in_fiber(function()
                                    for _, p in ipairs(spawned_props) do
                                        if ENTITY.DOES_ENTITY_EXIST(p.entity) then
                                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(p.entity, true, true)
                                            ENTITY.DELETE_ENTITY(p.entity)
                                        end
                                    end
                                end)
                            end
                        else
                            UI.widgetSound("Error")
                            YimToast:ShowError("Samurai's Scripts", "Please enter a name")
                        end
                        ImGui.CloseCurrentPopup()
                    end
                    ImGui.SameLine(); ImGui.Dummy(50, 1); ImGui.SameLine()
                    if ImGui.Button(_T("GENERIC_CANCEL_BTN_")) then
                        UI.widgetSound("Cancel")
                        saved_props_name = ""
                        ImGui.CloseCurrentPopup()
                    end
                    ImGui.EndPopup()
                end
            end
        end
        ImGui.EndTabItem()
    end
    if ImGui.BeginTabItem("Saved Creations") then
        if persist_attachments[1] ~= nil then
            ImGui.PushItemWidth(360)
            ShowPersistProps()
            ImGui.PopItemWidth()
            local persist_prop_info = filteredPersistProps[persist_prop_index + 1]
            ImGui.Dummy(1, 5)
            if spawned_persist_T[1] == nil then
                if ImGui.Button(_T("GENERIC_SPAWN_BTN_"), 80, 32) then
                    UI.widgetSound("Select")
                    script.run_in_fiber(function(pers)
                        for _, p in ipairs(persist_prop_info.props) do
                            if Game.RequestModel(p.hash) then
                                local persist_prop = OBJECT.CREATE_OBJECT(p.hash, 0.0, 0.0, 0.0, true, true, false)
                                pers:sleep(200)
                                if ENTITY.DOES_ENTITY_EXIST(persist_prop) then
                                    table.insert(spawned_persist_T, persist_prop)
                                    ENTITY.ATTACH_ENTITY_TO_ENTITY(persist_prop, Self.GetPedID(),
                                        PED.GET_PED_BONE_INDEX(Self.GetPedID(), p.bone), p.posx, p.posy, p.posz, p.rotx,
                                        p.roty, p.rotz,
                                        false, false, false, false, 2, true, 1)
                                end
                            end
                        end
                    end)
                end
            else
                if ImGui.Button(string.format("%s##persist_props", _T("GENERIC_DELETE_BTN_")), 80, 32) then
                    UI.widgetSound("Delete")
                    script.run_in_fiber(function(del)
                        for _, p in ipairs(spawned_persist_T) do
                            if ENTITY.DOES_ENTITY_EXIST(p) then
                                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(p, true, true)
                                del:sleep(100)
                                ENTITY.DELETE_ENTITY(p)
                            end
                        end
                    end)
                end
            end
            ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine()
            if UI.ColoredButton(string.format("%s##vcreator", _T("VC_DELETE_PERSISTENT_")), "#E40000", "#FF3F3F", "#FF8080", 0.87) then
                UI.widgetSound("Focus_In")
                ImGui.OpenPopup("Remove Persistent Props")
            end
            ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
            ImGui.SetNextWindowSizeConstraints(200, 100, 400, 400)
            ImGui.SetNextWindowBgAlpha(0.7)
            if ImGui.BeginPopupModal("Remove Persistent Props", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
                UI.ColoredText(_T("CONFIRM_PROMPT_"), "yellow", 0.91, 35)
                ImGui.Dummy(1, 20)
                if ImGui.Button(string.format("   %s   ##selfprops", _T("GENERIC_YES_"))) then
                    for key, value in ipairs(persist_attachments) do
                        if persist_prop_info == value then
                            table.remove(persist_attachments, key)
                            CFG:SaveItem("persist_attachments", persist_attachments)
                        end
                    end
                    UI.widgetSound("Select")
                    ImGui.CloseCurrentPopup()
                end
                ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
                if ImGui.Button(string.format("   %s   ##selfprops", _T("GENERIC_NO_"))) then
                    UI.widgetSound("Cancel")
                    ImGui.CloseCurrentPopup()
                end
                ImGui.End()
            end
        else
            ImGui.Dummy(1, 10); UI.WrappedText(
                "Attach some objects to yourself then save them to be able to spawn them from this tab.", 20)
        end
        ImGui.EndTabItem()
    end
    ImGui.EndTabBar()
end
