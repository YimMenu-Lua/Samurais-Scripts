---@diagnostic disable: undefined-global, lowercase-global

local i_ItemHeight <const> = 520


local b_MarkSelectedEntity         = false
local b_PreviewSelectedEntity      = false
local b_VehicleListCreated         = false
local i_ObjectIndex                = 0
local i_VehicleIndex               = 0
local i_PedIndex                   = 0
local i_SpawnedEntityIndex         = 0
local i_FavoriteEntityIndex        = 0
local i_SavedEntityIndex           = 0
local i_AttachCandidate            = 0
local i_SelectedSidebarItem        = 1
local i_SelectedParentIndex        = 1
local i_SelectedChildIndex         = 1
local i_SelectedCanvasChildIndex   = 1
local i_SelectedPedBone            = 1
local i_SelectedVehBone            = 1
local i_ForgeScenarioIndex         = 1
local f_AttachmentMovementModifier = 1.0
local f_AttachmentRotationModifier = 1.0
local s_SidebarLowerText           = ""
local s_ObjectSearch               = ""
local s_VehicleSearch              = ""
local s_PedSearch                  = ""
local s_NewEntityNameBuffer        = ""
local s_EncodedShareableCreation   = ""
local s_WrappedBase64String        = ""
local t_FilteredObjects            = t_GameObjects
local t_FilteredPeds               = t_GamePeds
local t_FilteredVehicles           = {}
local t_Vehiclelist                = {}
local t_FilteredVehBones           = {}
local t_SpawnerSidebarItems        = {"Objects", "Vehicles", "Peds"}
local hwnd_AttachmentAxisWindow    = {should_draw = false}
local hwnd_ChildPedCustomization   = {should_draw = false}


local hoveredThisFrame
local s_SelectedVehBone
local unk_AttachBone
local unk_SelectedEntity
local unk_ImportedCreation
local t_SelectedPedBone
local t_SelectedSpawnedEntity
local t_SelectedFavoriteEntity
local t_SelectedSavedEntity
local t_SelectedParent
local t_SelectedChild
local t_SelectedCanvasChild
local t_ForgeCustomizationTarget
local t_SelectedForgeScenario

local function FilterObjects()
    if #s_ObjectSearch > 0 then
        t_FilteredObjects = {}
        for _, object in ipairs(t_GameObjects) do
            if string.find(object:lower(), s_ObjectSearch:lower()) then
                table.insert(t_FilteredObjects, object)
            end
        end
    else
        t_FilteredObjects = t_GameObjects
    end
end

local function FilterPeds()
    if #s_PedSearch > 0 then
        t_FilteredPeds = {}
        for _, ped in ipairs(t_GamePeds) do
            if string.find(ped:lower(), s_PedSearch:lower()) then
                table.insert(t_FilteredPeds, ped)
            end
        end
    else
        t_FilteredPeds = t_GamePeds
    end
end

local function GetAllVehicles()
    -- non-blocking execution. The list creation is visible in ImGui so I should
    -- probably hide the execution behind a "please wait" label or something
    script.run_in_fiber(function()
        local s_VehicleName
        for _, veh in ipairs(t_GameVehicles) do
            b_ShouldAnimateLoadingLabel = true
            s_SidebarLowerText = string.format("Loading Vehicles %s", s_LoadingLabel)

            if string.find(veh:lower(), "drift") then
                s_VehicleName = vehicles.get_vehicle_display_name(veh) .. " (Drift)"
            else
                s_VehicleName = vehicles.get_vehicle_display_name(veh)
            end

            table.insert(t_Vehiclelist, { hash = joaat(veh), name = s_VehicleName })
            table.sort(t_Vehiclelist, function(a, b)
                return a.name < b.name
            end)

            t_FilteredVehicles = t_Vehiclelist
            coroutine.yield()
        end

        b_VehicleListCreated = true
        b_ShouldAnimateLoadingLabel = false
        s_SidebarLowerText = ""
    end)
end

local function FilterVehicles()
    if #s_VehicleSearch > 0 then
        t_FilteredVehicles = {}
        for _, veh in ipairs(t_Vehiclelist) do
            if string.find(string.lower(veh.name), s_VehicleSearch:lower()) then
                table.insert(t_FilteredVehicles, veh)
            end
        end
    else
        t_FilteredVehicles = t_Vehiclelist
    end
end

local function DisplayPedBones()
    local t_PedBoneNames = {}

    for _, bone in ipairs(t_PedBones) do
        table.insert(t_PedBoneNames, bone.name)
    end

    i_SelectedPedBone, _ = ImGui.Combo(
        "##pedBones",
        i_SelectedPedBone,
        t_PedBoneNames,
        #t_PedBones
    )
end

local function UpdateVehBones(vehicle)
    t_FilteredVehBones = {}

    for _, bone in ipairs(t_VehicleBones) do
        local bone_idx = Game.GetEntityBoneIndexByName(vehicle, bone)
        if bone_idx and bone_idx ~= -1 then
            table.insert(t_FilteredVehBones, bone)
        end
    end
end

local function DisplayVehBones(vehicle)
    UpdateVehBones(vehicle)
    i_SelectedVehBone, _ = ImGui.Combo(
        "##vehBones",
        i_SelectedVehBone,
        t_FilteredVehBones,
        #t_FilteredVehBones
    )
end


local function DrawObjects()
    ImGui.SetNextItemWidth(-1)
    s_ObjectSearch, b_ObjectsSearch_used = ImGui.InputTextWithHint(
        "##search",
        "Search",
        s_ObjectSearch,
        128
    )
    b_IsTyping = ImGui.IsItemActive()

    if b_ObjectsSearch_used then
        FilterObjects()
    end

    ImGui.Spacing()
    if ImGui.BeginListBox("##objectlist", -1, 380) then
        local i_MaxIterableItems =  #t_FilteredObjects <= 1000 and #t_FilteredObjects or 1000

        for i = 1, i_MaxIterableItems do
            local is_selected = (i_ObjectIndex == i)

            if ImGui.Selectable(t_FilteredObjects[i], is_selected) then
                i_ObjectIndex = i
            end

            if ImGui.IsItemHovered() then
                if table.Find(t_UnsafeObjects, t_FilteredObjects[i]) then
                    UI.Tooltip(
                        string.format(
                            "%s%s",
                            _T("INVALID_OBJECT_TXT_"),
                            _T("CRASH_OBJECT_WARN_")
                        ),
                        "yellow"
                    )
                elseif table.Find(t_mpBlacklistedObjects, t_FilteredObjects[i]) then
                    UI.Tooltip(
                        string.format(
                            "%s%s",
                            _T("INVALID_OBJECT_TXT_"),
                            _T("COCKSTAR_BLACKLIST_WARN_")
                        ),
                        "red"
                    )
                end

                if b_PreviewSelectedEntity then
                    hoveredThisFrame = joaat(t_FilteredObjects[i])
                end
            end

            if is_selected then
                unk_SelectedEntity = t_FilteredObjects[i_ObjectIndex]
            end
        end
        ImGui.EndListBox()
    end

    if b_PreviewSelectedEntity and hoveredThisFrame then
        PreviewService:OnTick(hoveredThisFrame, 0)
    else
        PreviewService:Clear()
    end
end

local function DrawVehicles()
    if #t_Vehiclelist == 0 then
        GetAllVehicles()
    end

    ImGui.SetNextItemWidth(-1)
    s_VehicleSearch, b_VehicleSearch_used = ImGui.InputTextWithHint(
        "##search",
        _T("GENERIC_SEARCH_HINT_"),
        s_VehicleSearch,
        128
    )
    b_IsTyping = ImGui.IsItemActive()

    if b_VehicleSearch_used then
        FilterVehicles()
    end

    ImGui.Spacing()
    ImGui.BeginDisabled(not b_VehicleListCreated)
    if ImGui.BeginListBox("##vehiclelist", -1, 380) then
        for i = 1, #t_FilteredVehicles do
            local is_selected = (i_VehicleIndex == i)

            if ImGui.Selectable(t_FilteredVehicles[i].name, is_selected) then
                i_VehicleIndex = i
            end

            if ImGui.IsItemHovered() then
                if b_PreviewSelectedEntity then
                    hoveredThisFrame = t_FilteredVehicles[i].hash
                end
            end

            if is_selected then
                unk_SelectedEntity = t_FilteredVehicles[i_VehicleIndex]
            end
        end
        ImGui.EndListBox()
    end
    ImGui.EndDisabled()

    if b_PreviewSelectedEntity and hoveredThisFrame then
        PreviewService:OnTick(hoveredThisFrame, 1)
    else
        PreviewService:Clear()
    end
end

local function DrawPeds()
    ImGui.SetNextItemWidth(-1)
    s_PedSearch, b_PedSearch_used = ImGui.InputTextWithHint(
        "##search",
        "Search",
        s_PedSearch,
        128
    )
    b_IsTyping = ImGui.IsItemActive()

    if b_PedSearch_used then
        FilterPeds()
    end

    ImGui.Spacing()
    if ImGui.BeginListBox("##pedlist", -1, 380) then
        for i = 1, #t_FilteredPeds do
            local is_selected = (i_PedIndex == i)

            if ImGui.Selectable(t_FilteredPeds[i], is_selected) then
                i_PedIndex = i
            end

            if ImGui.IsItemHovered() then
                if b_PreviewSelectedEntity then
                    hoveredThisFrame = Game.GetPedHash(t_FilteredPeds[i])
                end
            end

            if is_selected then
                unk_SelectedEntity = t_FilteredPeds[i_PedIndex]
            end
        end
        ImGui.EndListBox()
    end

    if b_PreviewSelectedEntity and hoveredThisFrame then
        PreviewService:OnTick(hoveredThisFrame, 2)
    else
        PreviewService:Clear()
    end
end

local function DrawSpawnerSideBar()
    ImGui.SetNextWindowBgAlpha(0.0)
    ImGui.BeginChild("##sidebar", 160, i_ItemHeight)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
    ImGui.SetWindowFontScale(1.05)
    ImGui.SeparatorText("Game Entities")
    ImGui.SetWindowFontScale(1.0)
    ImGui.Dummy(1, 40)

    for i, tab in ipairs(t_SpawnerSidebarItems) do
        local is_selected = (i_SelectedSidebarItem == i)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (is_selected and 30 or 0))

        if is_selected then
            local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
            ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
        end

        if ImGui.Button(tab, 128, 30) then
            UI.WidgetSound("Nav")
            i_SelectedSidebarItem = i
        end

        if is_selected then
            ImGui.PopStyleColor()
        end
    end

    if i_SelectedSidebarItem == 1 then
        if #t_FilteredObjects > 1000 then
            s_SidebarLowerText = "The object list is truncated to only show the first 1000 items.\n\nUse the search bar above the list to find what you're looking for."
        else
            s_SidebarLowerText = ""
        end
    elseif i_SelectedSidebarItem == 3 and #s_SidebarLowerText > 0 then
        s_SidebarLowerText = ""
    end

    ImGui.PopStyleVar(2)
    ImGui.SetCursorPosX(0.0)
    ImGui.Dummy(1, 40)
    ImGui.TextWrapped(s_SidebarLowerText)
    ImGui.EndChild()
end

local function DrawSpanwerItems()
    if i_SelectedSidebarItem == 1 then
        DrawObjects()
    elseif i_SelectedSidebarItem == 2 then
        DrawVehicles()
    elseif i_SelectedSidebarItem == 3 then
        DrawPeds()
    end
end

local function DrawCreatorUI()
    if EntityForge:IsEmpty() then
        ImGui.Dummy(1, 10)
        ImGui.TextWrapped("Spawn some entities to start creating abominations.")
        return
    end

    ImGui.BeginChild("ChildList", 300, i_ItemHeight * 0.7, true)
    ImGui.SeparatorText("Child Candidates")

    if ImGui.BeginListBox("##children", -1, - 1) then
        for i = 1, #EntityForge.childCandidates do
            local child_selected = (i_SelectedChildIndex == i)
            local s_NameBuffer = string.format("%s [%s]",
                EntityForge.childCandidates[i].name,
                EntityForge.childCandidates[i].handle
            )

            if ImGui.Selectable(s_NameBuffer, child_selected) then
                i_SelectedChildIndex = i
                t_SelectedChild = EntityForge.childCandidates[i_SelectedChildIndex]
                EntityForge:UpdateAttachmentCandidates(t_SelectedChild)
            end

            local selectable_width, _ = ImGui.CalcTextSize(s_NameBuffer)
            if selectable_width > 301 then
                UI.Tooltip(s_NameBuffer)
            end
        end
        ImGui.EndListBox()
    end

    ImGui.EndChild()

    if i_AttachCandidate == 1 then

        if i_SelectedPedBone and t_PedBones[i_SelectedPedBone] then
            t_SelectedPedBone = t_PedBones[i_SelectedPedBone + 1]
            unk_AttachBone = t_SelectedPedBone.ID
        end

        if not t_SelectedParent or t_SelectedParent.handle ~= -1 or t_SelectedParent.modelHash ~= -1 then
            t_SelectedParent = EntityForge:GetPlayerInstance()
        end
    else
        if i_SelectedParentIndex and EntityForge.parentCandidates[i_SelectedParentIndex] then
            t_SelectedParent = EntityForge.parentCandidates[i_SelectedParentIndex]
            if t_SelectedParent and t_SelectedParent.type == 1 then
                if i_SelectedVehBone and t_FilteredVehBones[i_SelectedVehBone] then
                    s_SelectedVehBone = t_FilteredVehBones[i_SelectedVehBone + 1]
                    unk_AttachBone = s_SelectedVehBone
                end
            elseif t_SelectedParent and t_SelectedParent.type == 2 then
                t_SelectedPedBone = t_PedBones[i_SelectedPedBone + 1]
                unk_AttachBone = t_SelectedPedBone.ID
            end
        else
            t_SelectedParent = nil
        end
    end

    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.SetNextWindowBgAlpha(0.0)
    ImGui.BeginChild("midpart", 110, i_ItemHeight * 0.7)

    if t_SelectedChild and (t_SelectedChild.type == 2) and not t_SelectedChild.isPlayer then
        ImGui.Dummy(1, 10)

        ImGui.BeginDisabled(hwnd_ChildPedCustomization.should_draw)
        if ImGui.Button("Customize") then
            UI.WidgetSound("Select")
            t_ForgeCustomizationTarget = t_SelectedChild
            script.run_in_fiber(function()
                t_ForgeCustomizationTarget.properties.components = Game.GetPedComponents(t_ForgeCustomizationTarget.handle)
            end)
            hwnd_ChildPedCustomization.should_draw = true
            gui.toggle(false)
            gui.override_mouse(true)
            KeyManager:RegisterKeybind("I", function()
                gui.override_mouse(not gui.mouse_override())
            end)
        end
        ImGui.EndDisabled()
    end

    ImGui.Spacing()
    ImGui.SetCursorPosY((ImGui.GetWindowHeight() / 2) - 40)

    ImGui.BeginDisabled(not t_SelectedParent or not t_SelectedChild)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 30)

    if ImGui.Button(string.format("%s ->", _T("GENERIC_ATTACH_BTN_")), 100, 40) then
        if t_SelectedParent and t_SelectedChild and (t_SelectedParent ~= t_SelectedChild) then
            script.run_in_fiber(function()
                EntityForge:AttachEntity(
                    t_SelectedChild,
                    t_SelectedParent,
                    unk_AttachBone,
                    vec3:zero(),
                    vec3:zero()
                )
            end)
        end
    end

    ImGui.PopStyleVar()

    if i_AttachCandidate == 0 then
        if t_SelectedParent then
            if t_SelectedParent.type == 1 then
                ImGui.Text("Attachment\nBone:")
                ImGui.SetNextItemWidth(-1)
                DisplayVehBones(t_SelectedParent.handle)
            elseif t_SelectedParent.type == 2 then
                ImGui.Text("Attachmen\nBone:")
                ImGui.SetNextItemWidth(-1)
                DisplayPedBones()
            end
        end
    elseif i_AttachCandidate == 1 then
        ImGui.Text("Attachment\nBone:")
        ImGui.SetNextItemWidth(-1)
        DisplayPedBones()
    end

    ImGui.EndDisabled()
    ImGui.EndChild()
    ImGui.SameLine()

    ImGui.BeginChild("ParentList", 300, i_ItemHeight * 0.7, true)
    ImGui.SeparatorText("Parent Candidates")

    i_AttachCandidate, b_AttachCandidateClicked = ImGui.RadioButton("Spawned Entities", i_AttachCandidate, 0)
    ImGui.SameLine()
    i_AttachCandidate, b_AttachCandidateClicked = ImGui.RadioButton("You", i_AttachCandidate, 1)

    if b_AttachCandidateClicked then
        UI.WidgetSound("Nav")
    end

    if i_AttachCandidate == 0 then
        if ImGui.BeginListBox("##parents", -1, -1) then
            for i = 1, #EntityForge.parentCandidates do
                local parent_selected = (i_SelectedParentIndex == i)
                local s_NameBuffer = string.format("%s [%s]",
                    EntityForge.parentCandidates[i].name,
                    EntityForge.parentCandidates[i].handle
                )

                if ImGui.Selectable(s_NameBuffer, parent_selected) then
                    i_SelectedParentIndex = i
                end

                local selectable_width, _ = ImGui.CalcTextSize(s_NameBuffer)
                if selectable_width > 301 then
                    UI.Tooltip(s_NameBuffer)
                end
            end
            ImGui.EndListBox()
        end
    elseif i_AttachCandidate == 1 then
        ImGui.Dummy(1, 40)
        ImGui.TextWrapped(
            "Select a bone from the list then press the button to attach the entity to yourself."
        )
    end

    ImGui.EndChild()

    if EntityForge.currentParent then
        ImGui.SetNextWindowBgAlpha(0.0)
        ImGui.BeginChild("lowerpart", -1, i_ItemHeight / 1.1)
        ImGui.Spacing()
        ImGui.SetNextWindowBgAlpha(0.0)
        ImGui.BeginChild("MoveXYZ", 160, i_ItemHeight / 1.12)
        ImGui.SeparatorText(_T("MOVE_OBJECT_TXT_"))
        ImGui.Dummy(1, 10)
        ImGui.SetNextItemWidth(-1)
        f_AttachmentMovementModifier, _ = ImGui.SliderFloat(
            "##f_amvm",
            f_AttachmentMovementModifier,
            1.0,
            100.0,
            _T("GENERIC_MULTIPLIER_LABEL_") .. " %.2f"
        )

        ImGui.Dummy(1, 10)

        if i_SelectedCanvasChildIndex and EntityForge.currentParent.children[i_SelectedCanvasChildIndex] then
            t_SelectedCanvasChild = EntityForge.currentParent.children[i_SelectedCanvasChildIndex]
        else
            t_SelectedCanvasChild = nil
        end

        ImGui.PushButtonRepeat(true)
        ImGui.Text("X: ")
        ImGui.SameLine()
        if ImGui.ArrowButton("##left", 0) then
            if t_SelectedCanvasChild then
                EntityForge:MoveAttachment(
                    t_SelectedCanvasChild,
                    -0.001 * f_AttachmentMovementModifier,
                    0, 0
                )
            end
        end

        ImGui.SameLine()
        if ImGui.ArrowButton("##right", 1) then
            if t_SelectedCanvasChild then
                EntityForge:MoveAttachment(
                    t_SelectedCanvasChild,
                    0.001 * f_AttachmentMovementModifier,
                    0,
                    0
                )
            end
        end

        ImGui.Text("Y: ")
        ImGui.SameLine()
        if ImGui.ArrowButton("##front", 2) then
            if t_SelectedCanvasChild then
                EntityForge:MoveAttachment(
                    t_SelectedCanvasChild,
                    0,
                    0.001 * f_AttachmentMovementModifier,
                    0
                )
            end
        end

        ImGui.SameLine()
        if ImGui.ArrowButton("##back", 3) then
            if t_SelectedCanvasChild then
                EntityForge:MoveAttachment(
                    t_SelectedCanvasChild,
                    0,
                    -0.001 * f_AttachmentMovementModifier,
                    0
                )
            end
        end

        ImGui.Text("Z: ")
        ImGui.SameLine()
        if ImGui.ArrowButton("##Up", 2) then
            if t_SelectedCanvasChild then
                EntityForge:MoveAttachment(
                    t_SelectedCanvasChild,
                    0,
                    0,
                    0.001 * f_AttachmentMovementModifier
                )
            end
        end

        ImGui.SameLine()
        if ImGui.ArrowButton("##Down", 3) then
            if t_SelectedCanvasChild then
                EntityForge:MoveAttachment(
                    t_SelectedCanvasChild,
                    0,
                    0,
                    -0.001 * f_AttachmentMovementModifier
                )
            end
        end

        ImGui.PopButtonRepeat()
        ImGui.Dummy(1, 10)
        ImGui.TextWrapped("Movement is relative to the attachment bone.")
        ImGui.Dummy(1, 10)
        ImGui.BeginDisabled(not t_SelectedCanvasChild)
        hwnd_AttachmentAxisWindow.should_draw, b_AxisWindow = ImGui.Checkbox(
            "Axis Window",
            hwnd_AttachmentAxisWindow.should_draw
        )
        ImGui.EndDisabled()
        UI.Tooltip("Opens the movement and rotation controls in an independant window for better visibility.")

        if b_AxisWindow then
            gui.toggle(not hwnd_AttachmentAxisWindow.should_draw)
            gui.override_mouse(hwnd_AttachmentAxisWindow.should_draw)
            UI.WidgetSound("Nav2")
        end

        ImGui.EndChild()

        ImGui.SameLine()
        ImGui.BeginChild("current parent", 400, i_ItemHeight / 1.12, true)
        ImGui.SetWindowFontScale(1.05)
        ImGui.SeparatorText(
            string.format(
                "Parent: %s",
                EntityForge.currentParent.isPlayer and
                "You" or
                EntityForge.currentParent.name
            )
        )
        ImGui.SetWindowFontScale(1.0)

        ImGui.SetNextItemWidth(-1)
        ImGui.BeginDisabled(EntityForge.currentParent.isPlayer)
        EntityForge.currentParent.alpha, bParentVisUsed = ImGui.SliderInt(
            "##parentvis",
            EntityForge.currentParent.alpha or 255,
            0,
            255,
            "Parent Visibility: %d"
        )
        ImGui.EndDisabled()
        if EntityForge.currentParent.isPlayer then
            UI.Tooltip("Modifying visibility is not allowed for the player entity.")
        end

        if bParentVisUsed then
            script.run_in_fiber(function()
                ENTITY.SET_ENTITY_ALPHA(
                    EntityForge.currentParent.handle,
                    EntityForge.currentParent.alpha,
                    false
                )
            end)
        end

        ImGui.Spacing()
        ImGui.Text("Child Items:")

        if ImGui.BeginListBox("##ChildItems", -1, i_ItemHeight / 3.7) then
            for i = 1, #EntityForge.currentParent.children do
                local child = EntityForge.currentParent.children[i]
                local s_NameBuffer = string.format("%s##%d", child.name, i)
                local is_selected = (i_SelectedCanvasChildIndex == i)

                if ImGui.Selectable(s_NameBuffer, is_selected) then
                    i_SelectedCanvasChildIndex = i
                end

                local label_width, _ = ImGui.CalcTextSize(s_NameBuffer)
                if label_width > 401 then
                    UI.Tooltip(s_NameBuffer)
                end
            end
            ImGui.EndListBox()
        end

        if t_SelectedCanvasChild then
            ImGui.Dummy(1, 10)

            ImGui.BeginDisabled(hwnd_ChildPedCustomization.should_draw)
            if ImGui.Button("Customize") then
                UI.WidgetSound("Select")
                t_ForgeCustomizationTarget = t_SelectedCanvasChild
                script.run_in_fiber(function()
                    t_ForgeCustomizationTarget.properties.components = Game.GetPedComponents(t_ForgeCustomizationTarget.handle)
                end)
                hwnd_ChildPedCustomization.should_draw = true
                gui.toggle(false)
                gui.override_mouse(true)
                KeyManager:RegisterKeybind("I", function()
                    gui.override_mouse(not gui.mouse_override())
                end)
            end
            ImGui.EndDisabled()
            ImGui.SameLine()

            if ImGui.Button(_T("GENERIC_DETACH_BTN_")) then
                UI.WidgetSound("Cancel")
                EntityForge:DetachEntity(EntityForge.currentParent, t_SelectedCanvasChild)
            end

            ImGui.SameLine()

            if ImGui.Button(_T("GENERIC_DELETE_BTN_")) then
                UI.WidgetSound("Delete")
                EntityForge:DeleteEntity(t_SelectedCanvasChild)
            end

            if EntityForge.currentParent and #EntityForge.currentParent.children > 1 then
                if ImGui.Button("Detach All") then
                    UI.WidgetSound("Cancel")
                    EntityForge:DetachAllEntities(EntityForge.currentParent)
                end

                ImGui.SameLine()

                if ImGui.Button("Delete All") then
                    UI.WidgetSound("Delete")
                    EntityForge:Cleanup()
                end
            end

            ImGui.SetNextItemWidth(-1)
            t_SelectedCanvasChild.alpha, bChildVisUsed = ImGui.SliderInt(
                "##childvis",
                t_SelectedCanvasChild.alpha,
                0,
                255,
                "Child Visibility: %d"
            )

            if bChildVisUsed then
                script.run_in_fiber(function()
                    ENTITY.SET_ENTITY_ALPHA(
                        t_SelectedCanvasChild.handle,
                        t_SelectedCanvasChild.alpha,
                        false
                    )
                end)
            end

            ImGui.BeginDisabled(not EntityForge.currentParent)
            if EntityForge.currentParent and EntityForge.currentParent.isForged then
                if ImGui.Button("Overwrite", 100, 35) then
                    UI.WidgetSound("Select")
                    ImGui.OpenPopup("confirm overwrite")
                end
            else
                if ImGui.Button(_T("GENERIC_SAVE_BTN_"), 100, 35) then
                    UI.WidgetSound("Select")
                    ImGui.OpenPopup("confirm save creation")
                end
            end
            ImGui.EndDisabled()

            UI.ConfirmPopup(
                "confirm overwrite",
                function()
                    EntityForge:OverwriteSavedAbomination()
                end
            )

            if ImGui.BeginPopupModal(
                "confirm save creation",
                ImGuiWindowFlags.NoTitleBar |
                ImGuiWindowFlags.AlwaysAutoResize
            ) then
                ImGui.SetNextItemWidth(400)
                ImGui.Spacing()
                ImGui.TextWrapped(_T("VC_NAME_HINT_"))
                ImGui.Spacing()

                s_NewEntityNameBuffer, _ = ImGui.InputTextWithHint(
                    "##newcreationname",
                    "Name",
                    s_NewEntityNameBuffer,
                    128
                )
                b_IsTyping = ImGui.IsItemActive()

                ImGui.Spacing()
                ImGui.Text("NOTE:\n\nEverything will be deleted once you save.\nYou can spawn your creation later.")
                ImGui.Dummy(1, 10)

                if ImGui.Button(_T("GENERIC_CONFIRM_BTN_"), 80, 30) then
                    if table.MatchByKey(forged_entities, "name", s_NewEntityNameBuffer) then
                        YimToast:ShowError(
                            "EntityForge",
                            "This name already exists. Please choose a different one!"
                        )
                        return
                    end

                    UI.WidgetSound("Select")

                    local new_creation = EntityForge.currentParent:AsTable()
                    new_creation.name = s_NewEntityNameBuffer

                    script.run_in_fiber(function(save)
                        local function GetVehicleProperties(vehicleEntity)
                            if vehicleEntity.type == 1 then
                                local col1 = {}
                                local col2 = {}
                                vehicleEntity.properties.window_states = {}

                                vehicleEntity.properties.mods = Game.Vehicle.GetVehicleMods(
                                    vehicleEntity.handle
                                )
                                vehicleEntity.properties.window_tint = VEHICLE.GET_VEHICLE_WINDOW_TINT(
                                    vehicleEntity.handle
                                )

                                col1.r, col1.g, col1.b = VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
                                    vehicleEntity.handle,
                                    col1.r,
                                    col1.g,
                                    col1.b
                                )

                                col2.r, col2.g, col2.b = VEHICLE.GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(
                                    vehicleEntity.handle,
                                    col2.r,
                                    col2.g,
                                    col2.b
                                )

                                vehicleEntity.properties.primary_color = col1
                                vehicleEntity.properties.secondary_color = col2
                                vehicleEntity.properties.plate_text = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicleEntity.handle)

                                for i = 1, 4 do
                                    vehicleEntity.properties.window_states[i] = VEHICLE.IS_VEHICLE_WINDOW_INTACT(vehicleEntity.handle, i - 1)
                                end
                            end

                            if vehicleEntity.children then
                                for _, child in ipairs(vehicleEntity.children) do
                                    GetVehicleProperties(child)
                                end
                            end

                            return true
                        end

                        while not GetVehicleProperties(new_creation) do
                            coroutine.yield()
                        end

                        table.insert(forged_entities, new_creation)
                        CFG:SaveItem("forged_entities", forged_entities)
                        YimToast:ShowSuccess(
                            "EntityForge",
                            string.format(
                                "Added '%s' to Saved Creations",
                                s_NewEntityNameBuffer
                            )
                        )

                        save:sleep(300)
                        s_NewEntityNameBuffer = ""
                        EntityForge:Cleanup()
                    end)
                    ImGui.CloseCurrentPopup()
                end

                ImGui.SameLine()

                if ImGui.Button(_T("GENERIC_CANCEL_BTN_"), 80, 30) then
                    UI.WidgetSound("Cancel")
                    s_NewEntityNameBuffer = ""
                    ImGui.CloseCurrentPopup()
                end
                ImGui.EndPopup()
            end
        end

        ImGui.EndChild()

        ImGui.SameLine()
        ImGui.SetNextWindowBgAlpha(0.0)
        ImGui.BeginChild("RotateXYZ", 160, i_ItemHeight / 1.12)
        ImGui.SeparatorText(_T("ROTATE_OBJECT_TXT_"))
        ImGui.Dummy(1, 10)
        ImGui.SetNextItemWidth(-1)
        f_AttachmentRotationModifier, _ = ImGui.SliderFloat(
            "##f_arvm",
            f_AttachmentRotationModifier,
            1.0,
            100.0,
            _T("GENERIC_MULTIPLIER_LABEL_") .. " %.2f"
        )

        ImGui.Dummy(1, 10)
        if EntityForge.currentParent and i_SelectedCanvasChildIndex and EntityForge.currentParent.children[i_SelectedCanvasChildIndex] then
            t_SelectedCanvasChild = EntityForge.currentParent.children[i_SelectedCanvasChildIndex]
        else
            t_SelectedCanvasChild = nil
        end

        ImGui.PushButtonRepeat(true)
        ImGui.Text("X: ")
        ImGui.SameLine()
        if ImGui.ArrowButton("##xRot-", 2) then
            if t_SelectedCanvasChild then
                EntityForge:RotateAttachment(
                    t_SelectedCanvasChild,
                    -0.05 * f_AttachmentRotationModifier,
                    0,
                    0
                )
            end
        end

        ImGui.SameLine()
        if ImGui.ArrowButton("##xRot+", 3) then
            if t_SelectedCanvasChild then
                EntityForge:RotateAttachment(
                    t_SelectedCanvasChild,
                    0.05 * f_AttachmentRotationModifier,
                    0,
                    0
                )
            end
        end

        ImGui.Text("Y: ")
        ImGui.SameLine()
        if ImGui.ArrowButton("##yRot-", 0) then
            if t_SelectedCanvasChild then
                EntityForge:RotateAttachment(
                    t_SelectedCanvasChild,
                    0,
                    -0.05 * f_AttachmentRotationModifier,
                    0
                )
            end
        end

        ImGui.SameLine()
        if ImGui.ArrowButton("##yRot+", 1) then
            if t_SelectedCanvasChild then
                EntityForge:RotateAttachment(
                    t_SelectedCanvasChild,
                    0,
                    0.05 * f_AttachmentRotationModifier,
                    0
                )
            end
        end

        ImGui.Text("Z: ")
        ImGui.SameLine()
        if ImGui.ArrowButton("##zRot+", 2) then
            if t_SelectedCanvasChild then
                EntityForge:RotateAttachment(
                    t_SelectedCanvasChild,
                    0,
                    0,
                    0.05 * f_AttachmentRotationModifier
                )
            end
        end

        ImGui.SameLine()
        if ImGui.ArrowButton("##zRot-", 3) then
            if t_SelectedCanvasChild then
                EntityForge:RotateAttachment(
                    t_SelectedCanvasChild,
                    0,
                    0,
                    -0.05 * f_AttachmentRotationModifier
                )
            end
        end

        ImGui.PopButtonRepeat()

        ImGui.Dummy(1, 10)
        ImGui.TextWrapped("Rotation is relative to the attachment bone.")
        ImGui.EndChild()

        ImGui.EndChild()
    end
end

local function DrawSpawnedEntities()
    if #EntityForge.AllEntities == 0 then
        ImGui.Dummy(1, 10)
        ImGui.TextWrapped("Spawned and/or grabbed entities will appear here.")
        return
    end

    ImGui.BeginListBox("##SpawnedEntities", 530, 280)
    for i = 1, #EntityForge.AllEntities do
        local is_selected = (i_SpawnedEntityIndex == i)
        local name_buffer = string.format(
            "%s [%s]",
            EntityForge.AllEntities[i].name,
            EntityForge.AllEntities[i].handle == Self.GetPedID() and
            "Yourself" or
            EntityForge.AllEntities[i].handle
        )

        if EntityForge.AllEntities[i].isForged then
            name_buffer = name_buffer .. "  (Saved Creation)"
        end

        if ImGui.Selectable(name_buffer, is_selected) then
            i_SpawnedEntityIndex = i
        end

        if ImGui.IsItemHovered() and ImGui.IsItemClicked(0) then
            UI.WidgetSound("Nav")
        end

        if is_selected then
            t_SelectedSpawnedEntity = EntityForge.AllEntities[i_SpawnedEntityIndex]
        end
    end
    ImGui.EndListBox()

    b_MarkSelectedEntity, b_MarkerUsed = ImGui.Checkbox("Mark Selected Entity", b_MarkSelectedEntity)
    if b_MarkerUsed then
        UI.WidgetSound("Nav2")
    end

    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()

    EntityForge.EntityGunEnabled, HgUsed = ImGui.Checkbox("Entity Grabber", EntityForge.EntityGunEnabled)
    UI.Tooltip(_T("EF_ENTITY_GUN_DESC_"))
    if HgUsed then
        UI.WidgetSound("Nav2")
    end

    ImGui.Spacing()

    ImGui.BeginDisabled(not t_SelectedSpawnedEntity)
    if ImGui.Button(_T("GENERIC_DELETE_BTN_")) then
        UI.WidgetSound("Delete")
        if t_SelectedSpawnedEntity.isForged then
            EntityForge:DeleteAbomination(t_SelectedSpawnedEntity)
        else
            EntityForge:DeleteEntity(t_SelectedSpawnedEntity)
        end
    end
    ImGui.EndDisabled()

    ImGui.SameLine()

    ImGui.BeginDisabled(EntityForge:IsEmpty())
    if ImGui.Button("Delete All") then
        UI.WidgetSound("Delete")
        EntityForge:Cleanup()
    end
    ImGui.EndDisabled()

    if #EntityForge.WorldEntities > 0 then
        if t_SelectedSpawnedEntity and string.find(t_SelectedSpawnedEntity.name, "World ") then
            if ImGui.Button("Free From Forge Pool") then
                UI.WidgetSound("Select")
                EntityForge:ReleaseWorldEntity(t_SelectedSpawnedEntity)
            end
        end

        if #EntityForge.WorldEntities > 1 then
            ImGui.SameLine()
            if ImGui.Button("Free Up All World Entities") then
                UI.WidgetSound("Select")
                for i = #EntityForge.WorldEntities, 1, -1 do
                    EntityForge:ReleaseWorldEntity(EntityForge.AllEntities[i])
                end
            end
        end
    end

    if b_MarkSelectedEntity and t_SelectedSpawnedEntity then
        Game.World.MarkSelectedEntity(t_SelectedSpawnedEntity.handle, 0.0)
    end
end

local function DrawFavoriteEntities()
    if not favorite_entities or #favorite_entities == 0 then
        ImGui.Dummy(1, 10)
        ImGui.TextWrapped("You don't have any saved favorites.")
        return
    end

    ImGui.BeginListBox("##FavoriteEntities", 530, 280)
    for i = 1, #favorite_entities do
        local is_selected = (i_FavoriteEntityIndex == i)
        if ImGui.Selectable(favorite_entities[i].name, is_selected) then
            i_FavoriteEntityIndex = i
        end

        if ImGui.IsItemHovered() and ImGui.IsItemClicked(0) then
            UI.WidgetSound("Nav")
        end

        if is_selected then
            t_SelectedFavoriteEntity = favorite_entities[i_FavoriteEntityIndex]
        end
    end
    ImGui.EndListBox()

    ImGui.Spacing()

    ImGui.BeginDisabled(not t_SelectedFavoriteEntity)
    if ImGui.Button(_T("GENERIC_SPAWN_BTN_")) then
        UI.WidgetSound("Select")
        script.run_in_fiber(function()
            EntityForge:CreateEntity(
                t_SelectedFavoriteEntity.modelHash,
                t_SelectedFavoriteEntity.name,
                t_SelectedFavoriteEntity.type,
                ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(self.get_ped(), 1, 5, 0),
                nil,
                t_SelectedFavoriteEntity.alpha
            )
        end)
    end

    ImGui.SameLine()

    if ImGui.Button("Rename") then
        UI.WidgetSound("Select")
        s_NewEntityNameBuffer = ""
        ImGui.OpenPopup("Rename Favorite")
    end

    if ImGui.BeginPopupModal(
        "Rename Favorite",
        ImGuiWindowFlags.NoTitleBar |
        ImGuiWindowFlags.AlwaysAutoResize
    ) then
        ImGui.Spacing()
        ImGui.TextWrapped(_T("VC_NAME_HINT_"))
        ImGui.Spacing()
        ImGui.SetNextItemWidth(400)
        s_NewEntityNameBuffer, _ = ImGui.InputTextWithHint(
            "##newfavname",
            "Name",
            s_NewEntityNameBuffer,
            128
        )
        b_IsTyping = ImGui.IsItemActive()

        ImGui.Spacing()

        if ImGui.Button(_T("GENERIC_CONFIRM_BTN_"), 80, 30) then
            for i, v in ipairs(favorite_entities) do
                if v.name == s_NewEntityNameBuffer then
                    YimToast:ShowError(
                        "EntityForge",
                        "This name already exists. Please choose a different one!"
                    )
                    return
                end

                if v.name == t_SelectedFavoriteEntity.name then
                    UI.WidgetSound("Select")
                    YimToast:ShowSuccess(
                        "EntityForge",
                        string.format(
                            "Renamed '%s' to '%s'",
                            v.name,
                            s_NewEntityNameBuffer
                        )
                    )
                    favorite_entities[i].name = s_NewEntityNameBuffer
                    CFG:SaveItem("favorite_entities", favorite_entities)
                    break
                end
            end
            s_NewEntityNameBuffer = ""
            ImGui.CloseCurrentPopup()
        end

        ImGui.SameLine()
        ImGui.Spacing()
        ImGui.SameLine()

        if ImGui.Button(_T("GENERIC_CANCEL_BTN_")) then
            UI.WidgetSound("Cancel")
            s_NewEntityNameBuffer = ""
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end

    if ImGui.Button(_T("REMOVE_FROM_FAVS_")) then
        UI.WidgetSound("Delete")
        ImGui.OpenPopup("confirm remove from favorites")
    end
    ImGui.EndDisabled()

    UI.ConfirmPopup(
        "confirm remove from favorites",
        function()
            EntityForge:RemoveFromFavorites(t_SelectedFavoriteEntity)
        end
    )

    ImGui.SameLine()

    ImGui.BeginDisabled(#favorite_entities == 0)
    if ImGui.Button("Remove All Favorites") then
        UI.WidgetSound("Delete")
        ImGui.OpenPopup("confirm remove all favorites")
    end
    ImGui.EndDisabled()

    UI.ConfirmPopup(
        "confirm remove all favorites",
        function()
            EntityForge:RemoveAllFavorites()
        end
    )
end

local function DrawSavedEntities()
    if not forged_entities or #forged_entities == 0 then
        ImGui.Dummy(1, 10)
        ImGui.TextWrapped("You don't have any saved creations.")
        return
    end

    if ImGui.BeginListBox("##ForgedEntities", 530, 280) then
        for i = 1, #forged_entities do
            local is_selected = (i_SavedEntityIndex == i)

            if ImGui.Selectable(forged_entities[i].name, is_selected) then
                i_SavedEntityIndex = i
            end

            if ImGui.IsItemHovered() and ImGui.IsItemClicked(0) then
                UI.WidgetSound("Nav")
            end

            if is_selected then
                t_SelectedSavedEntity = forged_entities[i_SavedEntityIndex]
            end
        end
        ImGui.EndListBox()
    end

    ImGui.Spacing()

    ImGui.BeginDisabled(not t_SelectedSavedEntity)
    if ImGui.Button(_T("GENERIC_SPAWN_BTN_")) then
        UI.WidgetSound("Select")
        EntityForge:SpawnSavedAbomination(t_SelectedSavedEntity)
    end

    ImGui.SameLine()

    if ImGui.Button("Rename") then
        UI.WidgetSound("Select")
        s_NewEntityNameBuffer = ""
        ImGui.OpenPopup("Rename Saved Creation")
    end

    if ImGui.BeginPopupModal(
        "Rename Saved Creation",
        ImGuiWindowFlags.NoTitleBar |
        ImGuiWindowFlags.AlwaysAutoResize
    ) then
        ImGui.Spacing()
        ImGui.TextWrapped(_T("VC_NAME_HINT_"))
        ImGui.Spacing()
        ImGui.SetNextItemWidth(400)
        s_NewEntityNameBuffer, _ = ImGui.InputTextWithHint(
            "##renamesaved",
            "Name",
            s_NewEntityNameBuffer,
            128
        )
        b_IsTyping = ImGui.IsItemActive()

        ImGui.Spacing()

        if ImGui.Button(_T("GENERIC_CONFIRM_BTN_"), 80, 30) then
            for i, v in ipairs(forged_entities) do
                if v.name == s_NewEntityNameBuffer then
                    YimToast:ShowError(
                        "EntityForge",
                        "This name already exists. Please choose a different one!"
                    )
                    return
                end

                if v.name == t_SelectedSavedEntity.name then
                    UI.WidgetSound("Select")
                    YimToast:ShowSuccess(
                        "EntityForge",
                        string.format(
                            "Renamed '%s' to '%s'",
                            v.name,
                            s_NewEntityNameBuffer
                        )
                    )
                    forged_entities[i].name = s_NewEntityNameBuffer
                    CFG:SaveItem("forged_entities", forged_entities)
                    break
                end
            end
            s_NewEntityNameBuffer = ""
            ImGui.CloseCurrentPopup()
        end

        ImGui.SameLine()
        ImGui.Spacing()
        ImGui.SameLine()

        if ImGui.Button(_T("GENERIC_CANCEL_BTN_")) then
            UI.WidgetSound("Cancel")
            s_NewEntityNameBuffer = ""
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end

    ImGui.SameLine()

    if ImGui.Button("Share") then
        UI.WidgetSound("Select")
        s_EncodedShareableCreation = CFG:b64_encode(CFG:xor_(CFG:Encode(t_SelectedSavedEntity)))
        s_WrappedBase64String, _ = Lua_fn.wrap_b64_string(s_EncodedShareableCreation, 40)
        ImGui.OpenPopup("share creation")
    end
    ImGui.EndDisabled()


    if ImGui.BeginPopupModal(
        "share creation",
        ImGuiWindowFlags.AlwaysAutoResize |
        ImGuiWindowFlags.NoTitleBar
    ) then
        ImGui.Spacing()
        ImGui.BulletText(string.format("Name: %s", t_SelectedSavedEntity.name))
        ImGui.BulletText(string.format("N° Of Attachments: [ %d ]", #t_SelectedSavedEntity.children))
        ImGui.BulletText(string.format("Nested Child Attachments: [ %s ]", t_SelectedSavedEntity.children.children and "Yes" or "No"))

        ImGui.Separator()
        ImGui.Spacing()
        ImGui.Spacing()

        ImGui.Text("Forge Data: ")
        ImGui.InputTextMultiline(
            "##b64",
            s_WrappedBase64String,
            #s_EncodedShareableCreation,
            440, 150,
            ImGuiInputTextFlags.ReadOnly
        )
        b_IsTyping = ImGui.IsItemActive()

        ImGui.Spacing()
        ImGui.Spacing()

        if ImGui.Button("Copy & Exit") then
            UI.WidgetSound("Click")
            ImGui.SetClipboardText(s_EncodedShareableCreation)
            YimToast:ShowSuccess(
                "EntityForge",
                "Your saved creation was copied to clipboard. Other users of this script can now import it into their saved creations."
            )
            s_EncodedShareableCreation = ""
            s_WrappedBase64String = ""
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        ImGui.Dummy(20, 1)
        ImGui.SameLine()

        if ImGui.Button("Cancel") then
            UI.WidgetSound("Cancel")
            s_EncodedShareableCreation = ""
            s_WrappedBase64String = ""
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
    ImGui.SameLine()

    if ImGui.Button("Import") then
        UI.WidgetSound("Select")
        ImGui.OpenPopup("import creation")
    end

    if ImGui.BeginPopupModal(
        "import creation",
        ImGuiWindowFlags.AlwaysAutoResize |
        ImGuiWindowFlags.NoTitleBar
    ) then
        if unk_ImportedCreation and unk_ImportedCreation.name and unk_ImportedCreation.children then
            ImGui.Spacing()
            ImGui.BulletText(string.format("Name: %s", unk_ImportedCreation.name))
            ImGui.BulletText(string.format("N° Of Attachments: [ %d ]", #unk_ImportedCreation.children))
            ImGui.BulletText(string.format("Nested Child Attachments: [ %s ]", unk_ImportedCreation.children.children and "Yes" or "No"))

            ImGui.Separator()
            ImGui.Spacing()
            ImGui.Spacing()
        else
            ImGui.Text("Paste The Forge Data Here: ")
        end
        ImGui.InputTextMultiline(
            "##b64",
            s_WrappedBase64String,
            0xFFFF,
            440, 150,
            ImGuiInputTextFlags.ReadOnly
        )
        b_IsTyping = ImGui.IsItemActive()

        ImGui.Spacing()
        ImGui.Spacing()

        if not unk_ImportedCreation or type(unk_ImportedCreation) ~= "table" or not unk_ImportedCreation.name then
            if ImGui.Button("Paste From Clipboard") then
                UI.WidgetSound("Click")
                s_EncodedShareableCreation = ImGui.GetClipboardText()
                if type(s_EncodedShareableCreation) ~= "string" then
                    YimToast:ShowError(
                        "EntityForge",
                        "Your clipboard is empty!"
                    )
                    return
                end

                s_WrappedBase64String = Lua_fn.wrap_b64_string(s_EncodedShareableCreation, 40)
                unk_ImportedCreation = EntityForge:ImportCreation(s_EncodedShareableCreation)
            end
        else
            if ImGui.Button("Add To Saved Creations & Exit") then
                UI.WidgetSound("Select")

                if table.MatchByKey(forged_entities, "name", unk_ImportedCreation.name) then
                    YimToast:ShowWarning(
                        "EntityForge",
                        "You have a creation with the same name. An [import] tag will be added to the name. You can to rename it later."
                    )
                    unk_ImportedCreation.name = unk_ImportedCreation.name .. " [import]"
                end

                table.insert(forged_entities, unk_ImportedCreation)
                s_WrappedBase64String = ""
                s_EncodedShareableCreation = ""
                unk_ImportedCreation = nil
                YimToast:ShowSuccess(
                    "EntityForge",
                    "Import successful!"
                )
                ImGui.CloseCurrentPopup()
            end
        end

        ImGui.SameLine()
        ImGui.Dummy(20, 1)
        ImGui.SameLine()

        if ImGui.Button("Cancel") then
            UI.WidgetSound("Cancel")
            s_WrappedBase64String = ""
            s_EncodedShareableCreation = ""
            unk_ImportedCreation = nil
            ImGui.CloseCurrentPopup()
        end

        ImGui.EndPopup()
    end

    ImGui.BeginDisabled(not t_SelectedSavedEntity)
    if ImGui.Button("Remove From Saved Creations") then
        UI.WidgetSound("Delete")
        ImGui.OpenPopup("confirm remove saved creation")
    end
    ImGui.EndDisabled()

    UI.ConfirmPopup(
        "confirm remove saved creation",
        function()
            EntityForge:RemoveSavedAbomination(t_SelectedSavedEntity)
        end
    )

    ImGui.SameLine()

    ImGui.BeginDisabled(not forged_entities or #forged_entities == 0)
    if ImGui.Button("Remove All Saved Creations") then
        UI.WidgetSound("Delete")
        ImGui.OpenPopup("confirm remove all saved")
    end
    ImGui.EndDisabled()

    UI.ConfirmPopup(
        "confirm remove all saved",
        function()
            EntityForge:RemoveAllSavedAbominations()
        end
    )
end


function EntityForgeUI()
    if ImGui.BeginTabBar("##entityforge") then
        if ImGui.BeginTabItem("Spawner") then
            DrawSpawnerSideBar()
            ImGui.SameLine()
            ImGui.BeginChild("##items", 400, i_ItemHeight, true)
            DrawSpanwerItems()
            ImGui.Spacing()
            if i_SelectedSidebarItem == 2 and not b_VehicleListCreated then
                ImGui.Button(s_LoadingLabel, 120, 35)
            else
                ImGui.BeginDisabled(not unk_SelectedEntity)
                if ImGui.Button(_T("GENERIC_SPAWN_BTN_"), 120, 35) then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function()
                        local vec_Position
                        local i_ModelHash = (
                            type(unk_SelectedEntity) == "string" and
                            joaat(unk_SelectedEntity) or
                            unk_SelectedEntity.hash
                        )

                        local s_ModelName = (
                            type(unk_SelectedEntity) == "string" and
                            unk_SelectedEntity or
                            unk_SelectedEntity.name
                        )

                        if b_PreviewSelectedEntity and PreviewService.currentPosition then
                            vec_Position = PreviewService.currentPosition
                        else
                            vec_Position = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                                self.get_ped(),
                                1,
                                5,
                                0
                            )
                        end

                        EntityForge:CreateEntity(
                            i_ModelHash,
                            s_ModelName,
                            i_SelectedSidebarItem - 1,
                            vec_Position
                        )
                    end)
                end

                ImGui.SameLine()
                local text_width, _ = ImGui.CalcTextSize(_T("ADD_TO_FAVS_"))
                if ImGui.Button(_T("ADD_TO_FAVS_"), text_width + 20, 35) then
                    UI.WidgetSound("Select")
                    s_NewEntityNameBuffer = ""
                    ImGui.OpenPopup("Add Favorite")
                end
                ImGui.EndDisabled()

                if ImGui.BeginPopupModal(
                    "Add Favorite",
                    ImGuiWindowFlags.NoTitleBar |
                    ImGuiWindowFlags.AlwaysAutoResize
                ) then
                    ImGui.Spacing()
                    ImGui.TextWrapped(_T("VC_NAME_HINT_"))
                    ImGui.Spacing()
                    ImGui.SetNextItemWidth(400)
                    s_NewEntityNameBuffer, _ = ImGui.InputTextWithHint(
                        "##favname",
                        "Name",
                        s_NewEntityNameBuffer,
                        128
                    )
                    b_IsTyping = ImGui.IsItemActive()

                    ImGui.Dummy(1, 10)

                    if ImGui.Button(_T("GENERIC_CONFIRM_BTN_")) then
                        UI.WidgetSound("Select")
                        local i_ModelHash = (
                            type(unk_SelectedEntity) == "string" and
                            joaat(unk_SelectedEntity) or
                            unk_SelectedEntity.hash
                        )

                        if favorite_entities and #favorite_entities > 0 then
                            local already_saved = EntityForge:IsModelInFavorites(i_ModelHash)

                            if already_saved then
                                YimToast:ShowError(
                                    "EntityForge",
                                    string.format(
                                        "This model is already saved as '%s'. Please choose a different one!",
                                        already_saved
                                    )
                                )
                                return
                            end

                            if table.MatchByKey(forged_entities, "name", s_NewEntityNameBuffer) then
                                YimToast:ShowError(
                                    "EntityForge",
                                    "You already have a favorite with this name. Please choose a different one!"
                                )
                                return
                            end
                        end

                        table.insert(
                            favorite_entities,
                            {
                                name = s_NewEntityNameBuffer,
                                modelHash = i_ModelHash,
                                type = i_SelectedSidebarItem - 1
                            }
                        )

                        CFG:SaveItem("favorite_entities", favorite_entities)
                        YimToast:ShowSuccess(
                            "EntityForge",
                            string.format(
                                "Added '%s' to favorites.",
                                s_NewEntityNameBuffer
                            )
                        )
                        s_NewEntityNameBuffer = ""
                        ImGui.CloseCurrentPopup()
                    end

                    ImGui.SameLine()

                    if ImGui.Button(_T("GENERIC_CANCEL_BTN_")) then
                        s_NewEntityNameBuffer = ""
                        UI.WidgetSound("Cancel")
                        ImGui.CloseCurrentPopup()
                    end

                    ImGui.EndPopup()
                end
            end
            ImGui.EndChild()
            ImGui.Dummy(1, 10)
            ImGui.SeparatorText("Preferences")

            b_PreviewSelectedEntity, _ = ImGui.Checkbox(
                _T("PREVIEW_OBJECTS_CB_"),
                b_PreviewSelectedEntity
            )

            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav2")
            end

            ImGui.SameLine()
            ImGui.Spacing()
            ImGui.SameLine()

            EntityForge.EntityGunEnabled, HgUsed = ImGui.Checkbox("Entity Grabber", EntityForge.EntityGunEnabled)
            UI.Tooltip(_T("EF_ENTITY_GUN_DESC_"))
            if HgUsed then
                UI.WidgetSound("Nav2")
            end

            ImGui.SameLine()
            ImGui.Spacing()
            ImGui.SameLine()

            ImGui.BeginDisabled(EntityForge:IsEmpty())
            if ImGui.Button("Cleanup Everything") then
                UI.WidgetSound("Delete")
                EntityForge:Cleanup()
            end
            ImGui.EndDisabled()

            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Favorites") then
            DrawFavoriteEntities()
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Creator") then
            DrawCreatorUI()
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Saved Creations") then
            DrawSavedEntities()
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Spawned Entities") then
            DrawSpawnedEntities()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end

    if PreviewService.current and (not ImGui.IsAnyItemHovered() or not b_PreviewSelectedEntity) then
        hoveredThisFrame = nil
        PreviewService:Clear()
    end
end

function ForgeChildCustomizationWindow()
    if hwnd_ChildPedCustomization.should_draw then
        Game.World.MarkSelectedEntity(t_ForgeCustomizationTarget.handle, -0.1)

        ImGui.Begin("Child Ped Customization",
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.AlwaysAutoResize
        )

        if ImGui.Button(_T("GENERIC_CLOSE_BTN_")) then
            UI.WidgetSound("Cancel")
            hwnd_ChildPedCustomization.should_draw = false
            if not gui.is_open() then
                gui.override_mouse(false)
                gui.toggle(true)
            end

            KeyManager:RemoveKeybind("I")
        end

        ImGui.Text(
            string.format(
                "Press [ I ] to %s the mouse.",
                gui.mouse_override() and "disable" or "enable"
            )
        )

        ImGui.Dummy(1, 10)

        if ImGui.BeginTabBar("ForgeChildCustomization") then
            if ImGui.BeginTabItem("Components") then
                if t_ForgeCustomizationTarget.properties.components then
                    ImGui.SetNextWindowBgAlpha(0.0)
                    if ImGui.BeginChild("Names", 160, #t_ForgeCustomizationTarget.properties.components * 20) then
                        for i = 1, #t_ForgeCustomizationTarget.properties.components do
                            if t_ForgeCustomizationTarget.properties.components[i].max_drawables > 0 then
                                ImGui.BulletText(ePedComponents[i])
                                ImGui.Dummy(1, 3)
                            end
                        end
                        ImGui.EndChild()
                    end

                    ImGui.SameLine()

                    ImGui.SetNextWindowBgAlpha(0.0)
                    if ImGui.BeginChild("components", 300, #t_ForgeCustomizationTarget.properties.components * 20) then
                        for i = 1, #t_ForgeCustomizationTarget.properties.components do
                            if t_ForgeCustomizationTarget.properties.components[i].max_drawables > 0 then
                                ImGui.PushID(string.format("component slider %d", i))
                                ImGui.SetNextItemWidth(-1)
                                t_ForgeCustomizationTarget.properties.components[i].drawable, _ = ImGui.SliderInt(
                                    string.format("##component%d", i),
                                    t_ForgeCustomizationTarget.properties.components[i].drawable,
                                    0,
                                    t_ForgeCustomizationTarget.properties.components[i].max_drawables
                                )
                                ImGui.PopID()
                            end
                        end
                        ImGui.EndChild()
                    end

                    if ImGui.Button("Apply") then
                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            Game.ApplyPedComponents(
                                t_ForgeCustomizationTarget.handle,
                                t_ForgeCustomizationTarget.properties.components
                            )
                        end)
                    end

                    ImGui.SameLine()
                    ImGui.Spacing()
                    ImGui.SameLine()
                end

                if ImGui.Button("Randomize") then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function()
                        PED.SET_PED_RANDOM_COMPONENT_VARIATION(t_ForgeCustomizationTarget.handle, 0)
                        t_ForgeCustomizationTarget.properties.components = Game.GetPedComponents(t_ForgeCustomizationTarget.handle)
                    end)
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Scenarios") then
                if ImGui.BeginListBox("##forgescenarios", 400, 300) then
                    for i = 1, #t_PedScenarios do
                        local is_selected = (i_ForgeScenarioIndex == i)

                        if ImGui.Selectable(t_PedScenarios[i].name, is_selected) then
                            i_ForgeScenarioIndex = i
                        end

                        if is_selected then
                            t_SelectedForgeScenario = t_PedScenarios[i_ForgeScenarioIndex]
                        end
                    end
                    ImGui.EndListBox()
                end

                ImGui.Dummy(1, 10)

                ImGui.BeginDisabled(not t_SelectedForgeScenario)
                if ImGui.Button("Add & Play") then
                    t_ForgeCustomizationTarget.properties.action = {
                        scenario = t_SelectedForgeScenario.scenario
                    }

                    script.run_in_fiber(function()
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(t_ForgeCustomizationTarget.handle)
                        TASK.TASK_START_SCENARIO_IN_PLACE(
                            t_ForgeCustomizationTarget.handle,
                            t_SelectedForgeScenario.scenario,
                            -1,
                            false
                        )
                    end)
                end

                ImGui.SameLine()
                ImGui.Spacing()
                ImGui.SameLine()

                if ImGui.Button("Stop & Clear") then
                    t_ForgeCustomizationTarget.properties.action = nil
                    script.run_in_fiber(function(clear)
                        if PED.IS_PED_USING_ANY_SCENARIO(t_ForgeCustomizationTarget.handle) then
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(t_ForgeCustomizationTarget.handle)
                            if t_ForgeCustomizationTarget.isAttached then
                                EntityForge:ResetEntityPosition(t_ForgeCustomizationTarget)
                                clear:sleep(100)
                                PED.SET_PED_KEEP_TASK(t_ForgeCustomizationTarget.handle, false)
                                TASK.TASK_STAND_STILL(t_ForgeCustomizationTarget.handle, -1)
                                clear:sleep(200)
                                EntityForge:AttachEntity(
                                    t_ForgeCustomizationTarget,
                                    t_ForgeCustomizationTarget.parent,
                                    t_ForgeCustomizationTarget.parent_bone,
                                    t_ForgeCustomizationTarget.attach_pos,
                                    t_ForgeCustomizationTarget.attach_rot
                                )
                            end
                        end
                    end)
                end
                ImGui.EndDisabled()
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end

        ImGui.End()
    end
end

function ForgeAxisWindow()
    if hwnd_AttachmentAxisWindow.should_draw then
        if not gui.mouse_override() then
            gui.override_mouse(true)
        end

        Game.World.MarkSelectedEntity(t_SelectedCanvasChild.handle, -1.0)
        ImGui.SetNextWindowBgAlpha(0.4)
        ImGui.Begin(
            "Axis Window",
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.AlwaysAutoResize
        )

        if ImGui.Button(_T("GENERIC_CLOSE_BTN_")) then
            hwnd_AttachmentAxisWindow.should_draw = false
            if not gui.is_open() then
                gui.override_mouse(false)
                gui.toggle(true)
            end
        end

        ImGui.Dummy(1, 20)
        ImGui.SetNextWindowBgAlpha(0.0)
        if ImGui.BeginChild("axis movement", 220, 340, true) then
            ImGui.SeparatorText(_T("MOVE_OBJECT_TXT_"))
            ImGui.Dummy(1, 10)
            ImGui.SetNextItemWidth(-1)
            f_AttachmentMovementModifier, _ = ImGui.SliderFloat(
                "##f_amvm",
                f_AttachmentMovementModifier,
                1.0,
                100.0,
                _T("GENERIC_MULTIPLIER_LABEL_") .. " %.2f"
            )
            ImGui.PushButtonRepeat(true)
            ImGui.Dummy(1, 10)
            ImGui.Text("X: ")
            ImGui.SameLine()
            if ImGui.ArrowButton("##left", 0) then
                if t_SelectedCanvasChild then
                    EntityForge:MoveAttachment(
                        t_SelectedCanvasChild,
                        -0.001 * f_AttachmentMovementModifier,
                        0, 0
                    )
                end
            end

            ImGui.SameLine()
            if ImGui.ArrowButton("##right", 1) then
                if t_SelectedCanvasChild then
                    EntityForge:MoveAttachment(
                        t_SelectedCanvasChild,
                        0.001 * f_AttachmentMovementModifier,
                        0,
                        0
                    )
                end
            end

            ImGui.Text("Y: ")
            ImGui.SameLine()
            if ImGui.ArrowButton("##front", 2) then
                if t_SelectedCanvasChild then
                    EntityForge:MoveAttachment(
                        t_SelectedCanvasChild,
                        0,
                        0.001 * f_AttachmentMovementModifier,
                        0
                    )
                end
            end

            ImGui.SameLine()
            if ImGui.ArrowButton("##back", 3) then
                if t_SelectedCanvasChild then
                    EntityForge:MoveAttachment(
                        t_SelectedCanvasChild,
                        0,
                        -0.001 * f_AttachmentMovementModifier,
                        0
                    )
                end
            end

            ImGui.Text("Z: ")
            ImGui.SameLine()
            if ImGui.ArrowButton("##Up", 2) then
                if t_SelectedCanvasChild then
                    EntityForge:MoveAttachment(
                        t_SelectedCanvasChild,
                        0,
                        0,
                        0.001 * f_AttachmentMovementModifier
                    )
                end
            end

            ImGui.SameLine()
            if ImGui.ArrowButton("##Down", 3) then
                if t_SelectedCanvasChild then
                    EntityForge:MoveAttachment(
                        t_SelectedCanvasChild,
                        0,
                        0,
                        -0.001 * f_AttachmentMovementModifier
                    )
                end
            end

            ImGui.PopButtonRepeat()
            ImGui.Dummy(1, 10)
            ImGui.TextWrapped("Movement is relative to the attachment bone.")
            ImGui.EndChild()
        end

        ImGui.SameLine()

        ImGui.SetNextWindowBgAlpha(0.0)
        if ImGui.BeginChild("axis rotation", 220, 340, true) then
            ImGui.SeparatorText(_T("ROTATE_OBJECT_TXT_"))
            ImGui.Dummy(1, 10)
            ImGui.SetNextItemWidth(-1)
            f_AttachmentRotationModifier, _ = ImGui.SliderFloat(
                "##f_arvm",
                f_AttachmentRotationModifier,
                1.0,
                100.0,
                _T("GENERIC_MULTIPLIER_LABEL_") .. " %.2f"
            )
            ImGui.Dummy(1, 10)
            ImGui.PushButtonRepeat(true)
            ImGui.Text("X: ")
            ImGui.SameLine()
            if ImGui.ArrowButton("##xRot--", 2) then
                if t_SelectedCanvasChild then
                    EntityForge:RotateAttachment(
                        t_SelectedCanvasChild,
                        -0.05 * f_AttachmentRotationModifier,
                        0,
                        0
                    )
                end
            end

            ImGui.SameLine()
            if ImGui.ArrowButton("##xRot++", 3) then
                if t_SelectedCanvasChild then
                    EntityForge:RotateAttachment(
                        t_SelectedCanvasChild,
                        0.05 * f_AttachmentRotationModifier,
                        0,
                        0
                    )
                end
            end

            ImGui.Text("Y: ")
            ImGui.SameLine()
            if ImGui.ArrowButton("##yRot--", 0) then
                if t_SelectedCanvasChild then
                    EntityForge:RotateAttachment(
                        t_SelectedCanvasChild,
                        0,
                        -0.05 * f_AttachmentRotationModifier,
                        0
                    )
                end
            end

            ImGui.SameLine()
            if ImGui.ArrowButton("##yRot++", 1) then
                if t_SelectedCanvasChild then
                    EntityForge:RotateAttachment(
                        t_SelectedCanvasChild,
                        0,
                        0.05 * f_AttachmentRotationModifier,
                        0
                    )
                end
            end

            ImGui.Text("Z: ")
            ImGui.SameLine()
            if ImGui.ArrowButton("##zRot++", 2) then
                if t_SelectedCanvasChild then
                    EntityForge:RotateAttachment(
                        t_SelectedCanvasChild,
                        0,
                        0,
                        0.05 * f_AttachmentRotationModifier
                    )
                end
            end

            ImGui.SameLine()
            if ImGui.ArrowButton("##zRot--", 3) then
                if t_SelectedCanvasChild then
                    EntityForge:RotateAttachment(
                        t_SelectedCanvasChild,
                        0,
                        0,
                        -0.05 * f_AttachmentRotationModifier
                    )
                end
            end

            ImGui.PopButtonRepeat()

            ImGui.Dummy(1, 10)
            ImGui.TextWrapped("Rotation is relative to the attachment bone.")
            ImGui.EndChild()
        end

        ImGui.Spacing()
        ImGui.TextWrapped(
            string.format(
                "Selected Entity: %s [%s]",
                t_SelectedCanvasChild.name,
                t_SelectedCanvasChild.handle
            )
        )
        ImGui.End()
    end
end
