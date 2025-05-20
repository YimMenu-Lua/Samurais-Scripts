---@diagnostic disable: lowercase-global, undefined-global

if not saved_escort_groups then
    saved_escort_groups = CFG:ReadItem("saved_escort_groups")
    or SS.default_config.saved_escort_groups
end

local i_BSUIHeight <const> = 540

local i_SelectedSidebarItem      = 1
local i_WeaponCategoryIndex      = 1
local i_WeaponIndex              = 1
local i_LimoDrivingStyle         = 1
local i_EscortDrivingStyle       = 1
local i_HeliPresetDestIndex      = 1
local i_JetAirportIndex          = 1
local i_PedListIndex             = 0
local i_EscortGroupIndex         = 0
local i_SpawnedBodyguardIndex    = 0
local i_PedSortByIndex           = 0
local i_SelectedBodyguardWeapon  = 0
local i_SelectedHeliModel        = 0
local i_SelectedJetModel         = 0
local s_SearchBuffer             = ""
local s_BodyguardNameBuffer      = ""
local s_CurrentTab               = ""
local s_PreviousTab              = ""
local s_LimoIndex                = ""
local s_HeliIndex                = ""
local s_JetIndex                 = ""
local b_BodyguardGodmode         = false
local b_BodyguardNoRagdoll       = false
local b_BodyguardAllWeapons      = false
local b_PedPreview               = false
local b_HeliGodMode              = false
local b_LimoWasCalled            = false
local b_SearchBarUsed            = false
local b_BodyguardInputText1      = false
local b_BodyguardInputText2      = false
local i_HoveredPedModelThisFrame = nil
local unk_EscortGroupHeaderName  = nil
local unk_JetAirportData         = nil
local t_CustomPedList            = {}
local t_FilteredPedList          = {}
local t_SelectedPed              = {}
local t_SelectedLimo             = {}
local t_WeaponList               = {}
local t_MainUIfooter             = {}
local t_SelectedEscortGroup      = {}
local t_WeaponCategories         = {
    {name = "None"},
    {name = "Melee",          groupHash = 2685387236},
    {name = "Pistols",        groupHash = 416676503},
    {name = "SMGs",           groupHash = 3337201093},
    {name = "Shotguns",       groupHash = 860033945},
    {name = "Assault Rifles", groupHash = 970310034},
    {name = "Machine Guns",   groupHash = 1159398588},
    {name = "Sniper Rifles",  groupHash = 3082541095},
    {name = "Heavy Weapons",  groupHash = 2725924767},
    {name = "Throwables",     groupHash = 1548507267},
    {name = "Miscellaneous",  groupHash = 4257178988},
}
local t_NewEscortGroup           = {
    name = "N/A",
    vehicleModel = 0,
    members = {
        {
            modelHash = 0,
            name = "N/A",
            weapon = 0,
        },
        {
            modelHash = 0,
            name = "N/A",
            weapon = 0,
        },
        {
            modelHash = 0,
            name = "N/A",
            weapon = 0,
        },
    }
}

local BS = BillionaireServices
local t_FilteredEscortGroups = saved_escort_groups
local t_SelectedHeliPresetDest = PrivateHeli.PresetDestinations[i_HeliPresetDestIndex]

---@type Bodyguard
-- spawned bodyguard
local unk_SelectedBodyguard


local function CreatePedList()
    script.run_in_fiber(function()
        for _, ped in ipairs(t_GamePeds) do
            local gender = Game.GetPedGenderFromModel(ped)
            if (Game.GetPedTypeFromModel(ped) ~= PED_TYPE._ANIMAL) and gender ~= "unknown" then
                table.insert(
                    t_CustomPedList,
                    {
                        modelName = ped,
                        modelHash = Game.GetPedHash(ped),
                        gender = gender,
                    }
                )
            end
        end
        t_FilteredPedList = t_CustomPedList
    end)
end

local function FilterPedsBySearchQuery()
    if #s_SearchBuffer > 0 then
        t_FilteredPedList = {}
        for _, ped in ipairs(t_CustomPedList) do
            if string.find(ped.modelName:lower(), s_SearchBuffer:lower()) then
                table.insert(t_FilteredPedList, ped)
            end
        end
    else
        t_FilteredPedList = t_CustomPedList
    end
end

local function FilterEscortsBySearchQuery()
    if #s_SearchBuffer > 0 then
        t_FilteredEscortGroups = {}

        for _, group in ipairs(saved_escort_groups) do
            if string.find(group.name:lower(), s_SearchBuffer:lower()) then
                table.insert(t_FilteredEscortGroups, group)
            end
        end
    else
        t_FilteredEscortGroups = saved_escort_groups
    end
end

local function FilterPedsByGender()
    t_FilteredPedList = {}

    local genderKeyword

    if i_PedSortByIndex == 1 then
        genderKeyword = "male"
    elseif i_PedSortByIndex == 2 then
        genderKeyword = "female"
    end

    if genderKeyword then
        for _, ped in ipairs(t_CustomPedList) do
            if ped.gender == genderKeyword then
                table.insert(t_FilteredPedList, ped)
            end
        end
    else
        t_FilteredPedList = t_CustomPedList
    end
end

local function OnTabItemSwitch()
    if s_CurrentTab ~= s_PreviousTab then
        UI.WidgetSound("Nav")
        s_PreviousTab     = s_CurrentTab
        s_SearchBuffer    = ""
        i_PedListIndex    = 0
        i_PedSortByIndex  = 0
        t_SelectedPed     = nil
        t_FilteredPedList = t_CustomPedList
        t_FilteredAnims   = t_Anims
    end

    if t_MainUIfooter[s_CurrentTab] and type(t_MainUIfooter[s_CurrentTab]) == "function" then
        t_MainUIfooter[s_CurrentTab]()
    end
end

local function BodyguardSpawnFooter()
    ImGui.SetNextWindowBgAlpha(0)
    ImGui.BeginChild("##bgFooter", 0, i_BSUIHeight * 0.6)
        ImGui.SetWindowFontScale(1.12)
        ImGui.SeparatorText("Bodyguard Preferences")
        ImGui.SetWindowFontScale(1.0)

        ImGui.Dummy(1, 5)
        ImGui.BeginDisabled(not t_SelectedPed)
            ImGui.BulletText("Name: ")
            ImGui.SameLine()

            ImGui.SetNextItemWidth(280)
            s_BodyguardNameBuffer, _ = ImGui.InputTextWithHint(
                "##bgname",
                "Bodyguard Name",
                s_BodyguardNameBuffer,
                128
            )
            b_BodyguardInputText2 = ImGui.IsItemActive()

            ImGui.SameLine()

            if ImGui.Button("Random") then
                UI.WidgetSound("Select")
                s_BodyguardNameBuffer = BS:GetRandomPedName(t_SelectedPed.gender)
            end

            b_BodyguardGodmode, _ = ImGui.Checkbox("God Mode", b_BodyguardGodmode)
            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav2")
            end

            ImGui.SameLine()

            b_BodyguardNoRagdoll, _ = ImGui.Checkbox("No Ragdoll", b_BodyguardNoRagdoll)
            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav2")
            end

            ImGui.Spacing()

            ImGui.SeparatorText("Weapons")

            ImGui.Spacing()

            if not b_BodyguardAllWeapons then
                ImGui.PushItemWidth(200)
                if ImGui.BeginCombo("Category", t_WeaponCategories[i_WeaponCategoryIndex].name) then
                    for i, cat in ipairs(t_WeaponCategories) do
                        if cat.groupHash then
                            local is_selected = (i_WeaponCategoryIndex == i)

                            if ImGui.Selectable(cat.name, is_selected) then
                                i_WeaponCategoryIndex = i
                            end

                            if UI.IsItemClicked("lmb") then
                                UI.WidgetSound("Nav")
                                t_WeaponList = weapons.get_all_weapons_of_group_type(cat.groupHash)
                            end

                            if is_selected then
                                ImGui.SetItemDefaultFocus()
                            end
                        end
                    end
                    ImGui.EndCombo()
                end

                if #t_WeaponList > 0 then
                    ImGui.SameLine()

                    if ImGui.BeginCombo("Weapon", weapons.get_weapon_display_name(t_WeaponList[i_WeaponIndex])) then
                        for i, wpn in ipairs(t_WeaponList) do
                            local is_selected = (i_WeaponIndex == i)
                            local wpn_name = weapons.get_weapon_display_name(wpn)

                            if ImGui.Selectable(wpn_name, is_selected) then
                                i_WeaponIndex = i
                            end

                            if UI.IsItemClicked("lmb") then
                                UI.WidgetSound("Nav")
                                i_SelectedBodyguardWeapon = joaat(t_WeaponList[i_WeaponIndex])
                            end

                            if is_selected then
                                ImGui.SetItemDefaultFocus()
                            end
                        end
                        ImGui.EndCombo()
                    end
                end

                ImGui.PopItemWidth()
            end

            b_BodyguardAllWeapons, _ = ImGui.Checkbox("Give All Weapons", b_BodyguardAllWeapons)
            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav2")
            end

            ImGui.Spacing()

            ImGui.Separator()

            if ImGui.Button("Call", 80, 35) then
                UI.WidgetSound("Select")
                BS:SpawnBodyguard(
                    t_SelectedPed.modelHash,
                    #s_BodyguardNameBuffer > 0
                    and s_BodyguardNameBuffer
                    or BS:GetRandomPedName(t_SelectedPed.gender),
                    nil,
                    not b_BodyguardAllWeapons
                    and i_SelectedBodyguardWeapon
                    or b_BodyguardAllWeapons,
                    b_BodyguardGodmode,
                    b_BodyguardNoRagdoll,
                    1
                )
                s_BodyguardNameBuffer = ""
            end
        ImGui.EndDisabled()
    ImGui.EndChild()
end

local function SpawnedBodyguardsFooter()
    unk_SelectedBodyguard = BS.Bodyguards[i_SpawnedBodyguardIndex]
    if unk_SelectedBodyguard then
        ImGui.Dummy(1, 10)
        ImGui.SetNextWindowBgAlpha(0)
        ImGui.BeginChild("##SpawnedGgFooter", 0, i_BSUIHeight * 0.25)
            ImGui.SetWindowFontScale(1.12)
            ImGui.SeparatorText(unk_SelectedBodyguard.name)
            ImGui.SetWindowFontScale(1.0)

            ImGui.Dummy(1, 5)

            ImGui.BulletText(string.format("Status: %s", unk_SelectedBodyguard:GetTaskAsString()))

            ImGui.Spacing()

            ImGui.BeginDisabled(unk_SelectedBodyguard.wasDismissed)
                if ImGui.Button("Dismiss", 80, 35) then
                    UI.WidgetSound("Cancel")
                    BS:DismissBodyguard(unk_SelectedBodyguard)
                end
            ImGui.EndDisabled()

            ImGui.SameLine()

            ImGui.BeginDisabled(table.GetLength(BS.Bodyguards) <= 1)
                if ImGui.Button("Dismiss All", 100, 35) then
                    UI.WidgetSound("Cancel")
                    BS:Dismiss(BS.SERVICE_TYPE.BODYGUARD)
                end
            ImGui.EndDisabled()
        ImGui.EndChild()
    end
end

local function EscortGroupSpawnFooter()
    ImGui.Dummy(1, 10)
    ImGui.SetNextWindowBgAlpha(0)
    ImGui.BeginChild("##escortGroupFooter", 0, i_BSUIHeight * 0.3)
        ImGui.SetWindowFontScale(1.12)
        ImGui.SeparatorText("Member Preferences")
        ImGui.SetWindowFontScale(1.0)

        ImGui.Dummy(1, 5)
        ImGui.BeginDisabled(next(t_SelectedEscortGroup) == nil)
            b_BodyguardGodmode, _ = ImGui.Checkbox("God Mode##escorts", b_BodyguardGodmode)
            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav2")
            end

            ImGui.SameLine()

            b_BodyguardNoRagdoll, _ = ImGui.Checkbox("No Ragdoll##escorts", b_BodyguardNoRagdoll)
            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav2")
            end

            ImGui.Spacing()

            ImGui.Separator()

            if ImGui.Button("Summon##escorts", 90, 40) then
                UI.WidgetSound("Select")
                BS:SpawnEscortGroup(
                    t_SelectedEscortGroup,
                    b_BodyguardGodmode,
                    b_BodyguardNoRagdoll
                )
            end
        ImGui.EndDisabled()
    ImGui.EndChild()
end

local function SpawnedEscortGroupsFooter()
    if next(BS.EscortGroups) ~= nil then
        ImGui.Dummy(1, 10)
        ImGui.SetNextWindowBgAlpha(0)
        ImGui.BeginChild("##SpawnedGroupsFooter", 0, i_BSUIHeight * 0.2)
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()
            ImGui.BeginDisabled(table.GetLength(BS.EscortGroups) <= 1)
                if ImGui.Button("Dismiss All", 100, 35) then
                    UI.WidgetSound("Cancel")
                    BS:Dismiss(BS.SERVICE_TYPE.ESCORT)
                end
            ImGui.EndDisabled()
        ImGui.EndChild()
    end
end

local function DrawBodyguards()
    b_IsTyping = b_BodyguardInputText1 or b_BodyguardInputText2

    if ImGui.BeginTabBar("bodyguards UI") then
        if ImGui.BeginTabItem("Spawn") then
            if #t_CustomPedList == 0 then
                CreatePedList()
                return
            end

            s_CurrentTab = "Spawn Bodyguards"
            t_MainUIfooter[s_CurrentTab] = BodyguardSpawnFooter

            ImGui.SetNextItemWidth(-1)
            s_SearchBuffer, b_SearchBarUsed = ImGui.InputTextWithHint(
                "##searchPeds",
                _T("GENERIC_SEARCH_HINT_"),
                s_SearchBuffer,
                128
            )
            b_BodyguardInputText1 = ImGui.IsItemActive()

            ImGui.BulletText("Gender: ")
            ImGui.SameLine()
            i_PedSortByIndex, bAll = ImGui.RadioButton("All", i_PedSortByIndex, 0)
            ImGui.SameLine()
            i_PedSortByIndex, bMale = ImGui.RadioButton("Male", i_PedSortByIndex, 1)
            ImGui.SameLine()
            i_PedSortByIndex, bFemale = ImGui.RadioButton("Female", i_PedSortByIndex, 2)

            b_PedPreview, _ = ImGui.Checkbox("Preview", b_PedPreview)
            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav2")
            end

            if bAll or bMale or bFemale then
                UI.WidgetSound("Nav")
                FilterPedsByGender()
            end

            if ImGui.BeginListBox("##pedlist", -1, -1) then
                for i, ped in ipairs(t_FilteredPedList) do
                    local is_selected = (i_PedListIndex == i)
                    if ImGui.Selectable(ped.modelName, is_selected) then
                        i_PedListIndex = i
                    end

                    if ImGui.IsItemHovered() and b_PedPreview then
                        i_HoveredPedModelThisFrame = ped.modelHash
                    end

                    if UI.IsItemClicked("lmb") then
                        UI.WidgetSound("Nav")
                    end

                    if is_selected then
                        t_SelectedPed = ped
                    end
                end
                ImGui.EndListBox()
            end

            if b_PedPreview and i_HoveredPedModelThisFrame ~= 0 then
                PreviewService:OnTick(i_HoveredPedModelThisFrame, 2)
            end
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Spawned Bodyguards") then
            s_CurrentTab = "Spawned Bodyguards"
            t_MainUIfooter[s_CurrentTab] = SpawnedBodyguardsFooter

            if next(BS.Bodyguards) == nil then
                ImGui.Text("You haven't spawned any bodyguards.")
                return
            end

            if ImGui.BeginListBox("##guardlist", -1, -1) then
                for i, guard in pairs(BS.Bodyguards) do
                    local is_selected = (i_SpawnedBodyguardIndex == i)

                    if ImGui.Selectable(guard.name, is_selected) then
                        i_SpawnedBodyguardIndex = i
                    end
                    UI.Tooltip("Right click for more options")

                    if UI.IsItemClicked("lmb") then
                        UI.WidgetSound("Nav")
                    end

                    if UI.IsItemClicked("rmb") then
                        UI.WidgetSound("Click")
                        ImGui.OpenPopup(("bodyguard_options##"):format(i))
                    end

                    if is_selected then
                        unk_SelectedBodyguard = guard
                        ImGui.SetItemDefaultFocus()
                    end

                    if ImGui.BeginPopup(("bodyguard_options##"):format(i)) then
                        if ImGui.MenuItem("Bring") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                guard:Bring(nil, true)
                            end)
                        end

                        if ImGui.MenuItem("Warp Into Vehicle") then
                            script.run_in_fiber(function()
                                guard:WarpIntoPlayerVeh()
                            end)
                        end

                        if ImGui.MenuItem("Kill") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                ENTITY.SET_ENTITY_HEALTH(guard.handle, 0, 0, 0)
                            end)
                        end

                        if ImGui.MenuItem("Dismiss") then
                            UI.WidgetSound("Cancel")
                            BS:DismissBodyguard(guard)
                        end
                        ImGui.EndPopup()
                    end
                end
                ImGui.EndListBox()
            end
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

local function DrawEscorts()
    if ImGui.BeginTabBar("escorts UI") then
        if ImGui.BeginTabItem("Spawn##escorts") then
            s_CurrentTab = "Spawn Escorts"
            t_MainUIfooter[s_CurrentTab] = EscortGroupSpawnFooter

            ImGui.SetNextItemWidth(-1)
            s_SearchBuffer, b_SearchBarUsed = ImGui.InputTextWithHint(
                "##searchEscorts",
                _T("GENERIC_SEARCH_HINT_"),
                s_SearchBuffer,
                128
            )
            b_IsTyping = ImGui.IsItemActive()

            if ImGui.BeginListBox("##escortGroupList", -1, -1) then
                for i, group in ipairs(t_FilteredEscortGroups) do
                    local is_selected = (i_EscortGroupIndex == i)

                    if ImGui.Selectable(group.name, is_selected) then
                        i_EscortGroupIndex = i
                    end

                    if UI.IsItemClicked("lmb") then
                        UI.WidgetSound("Nav")
                    end

                    if is_selected then
                        t_SelectedEscortGroup = group
                    end
                end

                ImGui.EndListBox()
            end
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Spawned Groups") then
            s_CurrentTab = "Spawned Escort Groups"
            t_MainUIfooter[s_CurrentTab] = SpawnedEscortGroupsFooter

            if next(BS.EscortGroups) == nil then
                ImGui.Text("You haven't spawned any escort groups.")
                return
            end

            for _, group in pairs(BS.EscortGroups) do
                if group then
                    local isOpen = (unk_EscortGroupHeaderName == group.name)

                    if ImGui.Selectable(
                        string.format(
                            "[%s] %s",
                            isOpen and "-" or "+",
                            group.name
                        ),
                        isOpen
                    ) then
                        unk_EscortGroupHeaderName = group.name
                    end

                    UI.Tooltip(group:GetTaskAsString())

                    if UI.IsItemClicked("lmb") then
                        UI.WidgetSound("Click")
                        if isOpen then
                            unk_EscortGroupHeaderName = nil
                        else
                            unk_EscortGroupHeaderName = group.name
                        end
                    end

                    if isOpen then
                        ImGui.Indent()
                            ImGui.Text(string.format("Vehicle: %s", group.vehicle.name))
                            ImGui.Text(string.format("Group Task: %s", group:GetTaskAsString()))
                            ImGui.SeparatorText(string.format("Group Members (%d):", #group.members))

                            for _, member in ipairs(group.members) do
                                if member and member.name then
                                    ImGui.BulletText(member.name)
                                    UI.HelpMarker(member:GetTaskAsString())
                                end
                            end

                            ImGui.Spacing()

                            if ImGui.Button(string.format("Repair Vehicle##", group.name)) then
                                UI.WidgetSound("Select")
                                script.run_in_fiber(function()
                                    group:RepairGroupVehicle()
                                end)
                            end

                            ImGui.SameLine()

                            ImGui.BeginDisabled(group.vehicle:IsPlayerInEscortVehicle())
                                if ImGui.Button(string.format("Go To##", group.name)) then
                                    UI.WidgetSound("Select")
                                    group:BringPlayer()
                                end

                                ImGui.SameLine()

                                if ImGui.Button(string.format("Bring##", group.name)) then
                                    UI.WidgetSound("Select")
                                    group:Bring()
                                end

                                ImGui.SameLine()

                                if ImGui.Button(string.format("Respawn##", group.name)) then
                                    UI.WidgetSound("Select")
                                    BS:RespawnEscortGroup(
                                        group,
                                        b_BodyguardGodmode,
                                        b_BodyguardNoRagdoll
                                    )
                                end
                            ImGui.EndDisabled()

                            if group.vehicle:IsPlayerInEscortVehicle() then
                                if ImGui.Button(("Driving Options >"):format(group.name)) then
                                    UI.WidgetSound("Click")
                                    ImGui.OpenPopup(("escort driving options##"):format(group.name))
                                end

                                if ImGui.BeginPopup(("escort driving options##"):format(group.name)) then
                                    if ImGui.MenuItem(("Wander"):format(group.name)) then
                                        script.run_in_fiber(function()
                                            group:Wander()
                                        end)
                                        ImGui.CloseCurrentPopup()
                                    end

                                    if ImGui.MenuItem(("To Waypoint"):format(group.name)) then
                                        script.run_in_fiber(function()
                                            local v_Pos = Game.GetWaypointCoords()
                                            if not v_Pos then
                                                UI.WidgetSound("Error")
                                                YimToast:ShowError(
                                                    "Samurai's Scripts",
                                                    "[Escort Service]: No waypoint found!"
                                                )
                                                return
                                            end
                                            UI.WidgetSound("Select")
                                            group:GoTo(v_Pos)
                                        end)
                                        ImGui.CloseCurrentPopup()
                                    end

                                    if ImGui.MenuItem(("To Objective"):format(group.name)) then
                                        script.run_in_fiber(function()
                                            local b_Found, v_Pos = Game.GetObjectiveBlipCoords()
                                            if not b_Found then
                                                UI.WidgetSound("Error")
                                                YimToast:ShowError(
                                                    "Samurai's Scripts",
                                                    "[Escort Service]: No objective found!"
                                                )
                                                return
                                            end
                                            UI.WidgetSound("Select")
                                            group:GoTo(v_Pos)
                                        end)
                                        ImGui.CloseCurrentPopup()
                                    end

                                    ImGui.BeginDisabled(group:IsIdle())
                                        if ImGui.MenuItem(("Stop"):format(group.name)) then
                                            script.run_in_fiber(function()
                                                group:StopTheVehicle()
                                            end)
                                            ImGui.CloseCurrentPopup()
                                        end
                                    ImGui.EndDisabled()

                                    ImGui.Spacing()
                                    ImGui.SeparatorText("Driving Style")
                                    ImGui.Spacing()

                                    i_EscortDrivingStyle, b_DSnormal = ImGui.RadioButton("Normal", i_EscortDrivingStyle, 1)

                                    ImGui.SameLine()

                                    i_EscortDrivingStyle, b_DSaggressive = ImGui.RadioButton("Aggressive", i_EscortDrivingStyle, 2)

                                    if b_DSnormal or b_DSaggressive then
                                        UI.WidgetSound("Nav")
                                        group:SetDrivingStyle(i_EscortDrivingStyle)
                                    end
                                    ImGui.EndPopup()
                                end
                                ImGui.SameLine()
                            end

                            ImGui.BeginDisabled(group.wasDismissed)
                                if ImGui.Button(string.format("Dismiss##", group.name)) then
                                    UI.WidgetSound("Cancel")
                                    BS:DismissEscortGroup(group.name)
                                end
                            ImGui.EndDisabled()
                        ImGui.Unindent()
                    end

                    ImGui.Separator()
                end
            end
            ImGui.EndTabItem()
        end

        -- if ImGui.BeginTabItem("+ Group Creator") then
        --     s_CurrentTab = "Escort Group Creator"
        --     t_MainUIfooter[s_CurrentTab] = nil

        --     if ImGui.Button("[ ! ] Tutorial") then
        --         UI.WidgetSound("Select")
        --         ImGui.OpenPopup("HowToCreateEscorts")
        --         ImGui.SetNextWindowSizeConstraints(600, 600, 600, 800)
        --         ImGui.SetNextWindowPos(Game.ScreenResolution.x / 2 - 300, Game.ScreenResolution.y / 2 - 200)
        --     end

        --     if ImGui.BeginPopupModal(
        --         "HowToCreateEscorts",
        --         ImGuiWindowFlags.NoMove
        --         | ImGuiWindowFlags.NoTitleBar
        --         | ImGuiWindowFlags.NoScrollbar
        --         | ImGuiWindowFlags.AlwaysAutoResize
        --     ) then
        --         if ImGui.Button("Close") then
        --             UI.WidgetSound("Cancel")
        --             ImGui.CloseCurrentPopup()
        --         end

        --         ImGui.Spacing()
        --         ImGui.Separator()
        --         ImGui.Spacing()

        --         ImGui.TextWrapped(BS.EscortCreatorTutorialText)
        --         ImGui.EndPopup()
        --     end

        --     ImGui.Spacing()
        --     ImGui.SeparatorText("New Group")
        --     ImGui.Spacing()

        --     ImGui.Text("Group Name:")
        --     ImGui.SameLine()

        --     t_NewEscortGroup.name, _ = ImGui.InputTextWithHint("##groupName", "Group Name", t_NewEscortGroup.name, 128)

        --     -- TODO: too tired to finish this

        --     ImGui.EndTabItem()
        -- end
        ImGui.EndTabBar()
    end
end

local function SpawnedLimoFooter()
    local limo = BS.ActiveServices.limo
    if not limo then
        return
    end

    ImGui.SetWindowFontScale(1.12)
    ImGui.SeparatorText(limo.name)
    ImGui.SetWindowFontScale(1.0)
    ImGui.Spacing()

    ImGui.BulletText(string.format("Driver: %s", limo.driverName))
    ImGui.BulletText(string.format("Status: %s", limo:GetTaskAsString()))
    ImGui.Dummy(1, 5)

    if SS.debug then
        if ImGui.Button("Parse Vehicle Mods") then
            script.run_in_fiber(function()
                local t = Game.Vehicle.GetVehicleMods(limo.handle)
                local toPrint = {}

                for i, v in ipairs(t) do
                    if v ~= -1 then
                        toPrint[i] = v
                    end
                end

                local wheeltype, _ = Game.Vehicle.GetCustomWheels(limo.handle)
                SS.debug(string.format("\nMods = %s\nWheel Type = %s", table.Serialize(toPrint, 2), wheeltype))
            end)
        end
        ImGui.SameLine()
        if ImGui.Button("Cleanup") then
            BS:RemoveLimo()
            b_LimoWasCalled = false
        end
    end

    if ImGui.Button("Repair", 100, 35) then
        UI.WidgetSound("Select")
        script.run_in_fiber(function()
            limo:Repair()
        end)
    end

    ImGui.SameLine()

    if ImGui.Button("Dismiss", 100, 35) then
        UI.WidgetSound("Cancel")
        BS:Dismiss(BS.SERVICE_TYPE.LIMO)
        b_LimoWasCalled = false
    end
end

local function DrawLimousineService()
    s_CurrentTab = "Limousine"
    t_MainUIfooter[s_CurrentTab] = SpawnedLimoFooter

    local limo = BS.ActiveServices.limo

    if not limo then
        ImGui.SeparatorText("Available Limousines")
        ImGui.Spacing()

        if ImGui.BeginListBox("##limosList", -1, i_BSUIHeight * 0.5) then
            for name, data in pairs(PrivateLimo.Limos) do
                local is_selected = (s_LimoIndex == name)

                if ImGui.Selectable(name, is_selected) then
                    s_LimoIndex = name
                end
                UI.Tooltip(data.description or "")

                if UI.IsItemClicked("lmb") then
                    UI.WidgetSound("Nav")
                end

                if is_selected then
                    t_SelectedLimo = data
                end
            end
            ImGui.EndListBox()
        end

        ImGui.Dummy(1, 5)
        ImGui.Separator()
        ImGui.Dummy(1, 5)

        ImGui.BeginDisabled((next(t_SelectedLimo) == nil) or b_LimoWasCalled)
            if ImGui.Button("Dispatch", 100, 40) then
                UI.WidgetSound("Select")
                BS:CallPrivateLimo(t_SelectedLimo)
                b_LimoWasCalled = true
            end
        ImGui.EndDisabled()
    else
        local v_ButtonSize = vec2:new(180, 35)
        ImGui.Dummy(1, 5)

        if not limo:IsPlayerInLimo() and not limo.isRemoteControlled then
            if ImGui.Button("Warp Into The Limo", v_ButtonSize.x, v_ButtonSize.y) then
                UI.WidgetSound("Select")
                limo:WarpPlayer()
            end

            ImGui.Text("Get in the limousine to see more options.")
        end

        if limo:IsPlayerInLimo() or limo.isRemoteControlled then
            ImGui.BeginDisabled(limo.isRemoteControlled)
                ImGui.Spacing()
                ImGui.SeparatorText("Driving Style")
                ImGui.Spacing()

                i_LimoDrivingStyle, b_DSnormal = ImGui.RadioButton("Normal", i_LimoDrivingStyle, 1)

                ImGui.SameLine()

                i_LimoDrivingStyle, b_DSaggressive = ImGui.RadioButton("Aggressive", i_LimoDrivingStyle, 2)

                if b_DSnormal or b_DSaggressive then
                    UI.WidgetSound("Nav")
                    limo:SetDrivingStyle(i_LimoDrivingStyle)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Commands")
                ImGui.Spacing()

                ImGui.BeginDisabled(Self.Vehicle.Speed <= 0.1 and limo:IsIdle())
                    if ImGui.Button("Stop The Limo", v_ButtonSize.x, v_ButtonSize.y) then
                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            limo:Stop()
                        end)
                    end

                    ImGui.SameLine()

                    if ImGui.Button("Emergency Stop", v_ButtonSize.x, v_ButtonSize.y) then
                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            limo:EmergencyStop()
                        end)
                    end
                ImGui.EndDisabled()

                if ImGui.Button("Drive To Waypoint", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function(s)
                        local v_Pos = Game.GetWaypointCoords()

                        if not v_Pos then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Samurai's Scripts",
                                "[Limousine Service]: No waypoint found!"
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        limo:GoTo(v_Pos, s)
                    end)
                end

                ImGui.SameLine()

                if ImGui.Button("Drive To Objective", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function(s)
                        local b_Found, v_Pos = Game.GetObjectiveBlipCoords()

                        if not b_Found then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Samurai's Scripts",
                                "[Limousine Service]: No objective found!"
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        limo:GoTo(v_Pos, s)
                    end)
                end

                if ImGui.Button("Wander", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function(s)
                        limo:Wander(s)
                    end)
                end
            ImGui.EndDisabled()

            local isControlled = limo.isRemoteControlled
            local verb         = isControlled and "Give" or "Take"
            local callback     = isControlled and limo.ReleaseControl or limo.TakeControl
            local clickSound   = isControlled and "Cancel" or "Select"
            local tt           = isControlled and "Give control of the limousine back to the chauffeur."
            or "Allows you to remotely control the limousine from the comfort of your backseat."

            ImGui.SameLine()
            if ImGui.Button(string.format("%s Control", verb), v_ButtonSize.x, v_ButtonSize.y) then
                UI.WidgetSound(clickSound)
                callback(limo)
            end
            UI.Tooltip(tt)

            ImGui.BeginDisabled(limo.isRemoteControlled)
                ImGui.Spacing()
                ImGui.SeparatorText("Seat Controls")
                ImGui.Spacing()

                if ImGui.Button("< Previous Seat", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    limo:ShuffleSeats(-1)
                end

                ImGui.SameLine()

                if ImGui.Button("Next Seat >", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    limo:ShuffleSeats(1)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Radio Controls")
                ImGui.Spacing()

                if ImGui.Button(limo.radio.isOn and "Turn Off" or "Turn On") then
                    UI.WidgetSound("Click")
                    script.run_in_fiber(function()
                        AUDIO.SET_VEH_RADIO_STATION(
                            limo.handle,
                            limo.radio.isOn
                            and "OFF"
                            or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
                        )
                    end)
                end

                if limo.radio.isOn then
                    ImGui.SameLine()
                    UI.VehicleRadioCombo(limo.handle, "limoRadioStations", limo.radio.stationName)
                end
            ImGui.EndDisabled()
        end
    end
end

local function SpawnedHeliFooter()
    local heli = BS.ActiveServices.heli

    if not heli then
        return
    end

    ImGui.SetWindowFontScale(1.12)
    ImGui.SeparatorText(heli.name)
    ImGui.SetWindowFontScale(1)
    ImGui.Spacing()

    ImGui.BulletText(string.format("Pilot: %s", heli.pilotName))
    ImGui.BulletText(string.format("Status: %s", heli:GetTaskAsString()))
    ImGui.Dummy(1, 5)

    ImGui.BeginDisabled(not heli.isReady)
        if ImGui.Button("Repair", 100, 35) then
            UI.WidgetSound("Select")
            heli:Repair()
        end

        ImGui.SameLine()

        if ImGui.Button("Dismiss", 100, 35) then
            UI.WidgetSound("Cancel")
            BS:Dismiss(BS.SERVICE_TYPE.HELI)
        end
    ImGui.EndDisabled()
end

local function DrawHeliService()
    s_CurrentTab = "Heli"
    t_MainUIfooter[s_CurrentTab] = SpawnedHeliFooter
    local heli = BS.ActiveServices.heli

    if not heli then
        ImGui.SeparatorText("Available Helicopters")
        ImGui.Spacing()

        if ImGui.BeginListBox("##heliList", -1, i_BSUIHeight * 0.7) then
            for name, model in pairs(PrivateHeli.Helis) do
                local is_selected = (s_HeliIndex == name)

                if ImGui.Selectable(name, is_selected) then
                    s_HeliIndex = name
                end

                if UI.IsItemClicked("lmb") then
                    UI.WidgetSound("Nav")
                end

                if is_selected then
                    i_SelectedHeliModel = model
                end
            end
            ImGui.EndListBox()
        end

        ImGui.Dummy(1, 5)
        ImGui.Separator()
        ImGui.Dummy(1, 5)

        b_HeliGodMode, _ = ImGui.Checkbox("God Mode", b_HeliGodMode)

        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav")
        end

        ImGui.SameLine()

        ImGui.BeginDisabled(i_SelectedHeliModel == 0)
            if ImGui.Button("Dispatch", 100, 40) then
                UI.WidgetSound("Select")
                BS:CallPrivateHeli(i_SelectedHeliModel, b_HeliGodMode)
            end
        ImGui.EndDisabled()
    else
        local v_ButtonSize = vec2:new(180, 35)
        ImGui.Dummy(1, 5)

        if not heli:IsPlayerInHeli() then
            ImGui.BeginDisabled(heli.isPlayerRappelling or not heli.isReady)
                if ImGui.Button("Warp Into The Heli", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    heli:WarpPlayer()
                end

                ImGui.SameLine()

                ImGui.BeginDisabled(not heli.isFarAway)
                    if ImGui.Button("Bring", v_ButtonSize.x, v_ButtonSize.y) then
                        UI.WidgetSound("Select")
                        script.run_in_fiber(function(s)
                            heli:Bring(s)
                        end)
                    end
                ImGui.EndDisabled()
            ImGui.EndDisabled()

            if heli.isPlayerRappelling or not heli.isReady then
                ImGui.Text("Please wait!")
            else
                ImGui.Text("Get in the helicopter to see more options.")
            end
        else
            ImGui.BeginDisabled(heli.isPlayerRappelling)
                ImGui.Spacing()
                ImGui.SeparatorText("Commands")
                ImGui.Spacing()

                ImGui.BeginDisabled((heli.task == eVehicleTask.HOVER_IN_PLACE) or heli.altitude <= 3)
                    if ImGui.Button("Hover Here", v_ButtonSize.x, v_ButtonSize.y) then
                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            heli:HoverInPlace()
                        end)
                    end
                ImGui.EndDisabled()

                ImGui.SameLine()

                ImGui.BeginDisabled(heli.altitude <= 3)
                    if ImGui.Button("Land Here", v_ButtonSize.x, v_ButtonSize.y) then
                        script.run_in_fiber(function()
                            heli:LandHere()
                        end)
                    end
                ImGui.EndDisabled()

                if ImGui.Button("Fly To Waypoint", v_ButtonSize.x, v_ButtonSize.y) then
                    script.run_in_fiber(function()
                        local v_Pos = Game.GetWaypointCoords()

                        if not v_Pos then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Samurai's Scripts",
                                "[Heli Service]: No waypoint found!"
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        heli:FlyTo(v_Pos)
                    end)
                end

                ImGui.SameLine()

                if ImGui.Button("Fly To Objective", v_ButtonSize.x, v_ButtonSize.y) then
                    script.run_in_fiber(function()
                        local b_Found, v_Pos = Game.GetObjectiveBlipCoords()

                        if not b_Found then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Samurai's Scripts",
                                "[Heli Service]: No objective found!"
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        heli:FlyTo(v_Pos)
                    end)
                end

                ImGui.BeginDisabled(heli.task ~= eVehicleTask.GOTO)
                    if ImGui.Button("Skip Trip", v_ButtonSize.x, v_ButtonSize.y) then
                        script.run_in_fiber(function(s)
                            heli:SkipTrip(s)
                        end)
                    end
                ImGui.EndDisabled()

                ImGui.SameLine()

                if heli.allowsRappelling then
                    ImGui.SameLine()
                    ImGui.BeginDisabled((heli.task ~= eVehicleTask.HOVER_IN_PLACE) or (heli.altitude < 5) or heli.isPlayerRappelling)
                        if ImGui.Button("Rappell Down", v_ButtonSize.x, v_ButtonSize.y) then
                            script.run_in_fiber(function()
                                if Game.GetPedVehicleSeat(Self.GetPedID()) < 1 then
                                    UI.WidgetSound("Error")
                                    YimToast:ShowError(
                                        "Private Heli",
                                        "You can not rappell down from this seat. Please switch to one of the back seats!",
                                        false,
                                        3
                                    )
                                    return
                                end

                                UI.WidgetSound("Select")
                                TASK.TASK_RAPPEL_FROM_HELI(Self.GetPedID(), 5.0)
                            end)
                        end
                    ImGui.EndDisabled()
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Preset Destinations")
                ImGui.Spacing()

                if ImGui.BeginCombo("##heliPresetDestinations", t_SelectedHeliPresetDest.name) then
                    for i, data in ipairs(PrivateHeli.PresetDestinations) do
                        if ImGui.Selectable(data.name, i_HeliPresetDestIndex == i) then
                            i_HeliPresetDestIndex = i
                        end

                        if UI.IsItemClicked("lmb") then
                            UI.WidgetSound("Nav")
                            t_SelectedHeliPresetDest = data
                        end
                    end
                    ImGui.EndCombo()
                end

                ImGui.SameLine()

                ImGui.BeginDisabled(not t_SelectedHeliPresetDest.pos)
                    if ImGui.Button("Fly To") then
                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            heli:FlyTo(t_SelectedHeliPresetDest.pos, true)
                        end)
                    end
                ImGui.EndDisabled()

                ImGui.Spacing()
                ImGui.SeparatorText("Seat Controls")
                ImGui.Spacing()

                if ImGui.Button("< Previous Seat", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    heli:ShuffleSeats(-1)
                end

                ImGui.SameLine()

                if ImGui.Button("Next Seat >", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    heli:ShuffleSeats(1)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Radio Controls")
                ImGui.Spacing()

                if ImGui.Button(heli.radio.isOn and "Turn Off" or "Turn On") then
                    script.run_in_fiber(function()
                        AUDIO.SET_VEH_RADIO_STATION(
                            heli.handle,
                            heli.radio.isOn
                            and "OFF"
                            or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
                        )
                        heli.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(heli.handle)
                        heli.radio.stationName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
                    end)
                end

                if heli.radio.isOn then
                    ImGui.SameLine()
                    UI.VehicleRadioCombo(heli.handle, "limoRadioStations", heli.radio.stationName)
                end
            ImGui.EndDisabled()
        end
    end
end

local function DrawAirportCombo()
    if ImGui.BeginCombo("##airportCombo", PrivateJet.Airports[i_JetAirportIndex].name) then
        for i, aiportData in ipairs(PrivateJet.Airports) do
            local is_selected = (i_JetAirportIndex == i)

            if ImGui.Selectable(PrivateJet.Airports[i].name, is_selected) then
                i_JetAirportIndex = i
                unk_JetAirportData = aiportData
            end

            if UI.IsItemClicked("lmb") then
                UI.WidgetSound("Nav")
            end
        end
        ImGui.EndCombo()
    end
end

local function SpawnedJetFooter()
    local jet = BS.ActiveServices.jet

    if not jet then
        return
    end

    ImGui.SetWindowFontScale(1.12)
    ImGui.SeparatorText(jet.name)
    ImGui.SetWindowFontScale(1)
    ImGui.Spacing()

    ImGui.BulletText(string.format("Pilot: %s", jet.pilotName))
    ImGui.BulletText(string.format("Co-Pilot: %s", jet.copilotName))
    ImGui.BulletText(string.format("Status: %s", jet:GetTaskAsString()))
    ImGui.Dummy(1, 5)

    if ImGui.Button("Repair", 100, 35) then
        UI.WidgetSound("Select")
        jet:Repair()
    end

    ImGui.SameLine()

    if ImGui.Button("Dismiss", 100, 35) then
        UI.WidgetSound("Cancel")
        BS:Dismiss(BS.SERVICE_TYPE.JET)
    end
end

local function DrawJetService()
    s_CurrentTab = "Jet"
    t_MainUIfooter[s_CurrentTab] = SpawnedJetFooter
    local jet = BS.ActiveServices.jet

    if not jet then
        ImGui.SeparatorText("Available Jets")
        ImGui.Spacing()

        if ImGui.BeginListBox("##jetList", -1, i_BSUIHeight * 0.5) then
            for name, data in pairs(PrivateJet.Jets) do
                local is_selected = (s_JetIndex == name)

                if ImGui.Selectable(name, is_selected) then
                    s_JetIndex = name
                end
                UI.Tooltip(data.description)

                if UI.IsItemClicked("lmb") then
                    UI.WidgetSound("Nav")
                end

                if is_selected then
                    i_SelectedJetModel = data.model
                end
            end
            ImGui.EndListBox()
        end

        ImGui.Spacing()
        ImGui.SeparatorText("Airports")
        ImGui.Spacing()

        DrawAirportCombo()

        ImGui.Dummy(1, 5)
        ImGui.Separator()
        ImGui.Dummy(1, 5)

        local JetSpawnDataNotSelected = (i_SelectedJetModel == 0) or not unk_JetAirportData
        ImGui.BeginDisabled(JetSpawnDataNotSelected)
            if ImGui.Button("Dispatch", 100, 40) and unk_JetAirportData then
                UI.WidgetSound("Select")
                BS:CallPrivateJet(i_SelectedJetModel, unk_JetAirportData)
            end
        ImGui.EndDisabled()

        if JetSpawnDataNotSelected then
            UI.Tooltip("Select a jet model and an airport.")
        end

        UI.HelpMarker("[! NOTE] Calling the jet while too far away from the airport may cause it to become invisible. Either use the button in this UI to directly warp into the jet (which will force it to become visible) or just call your jet when you're close to the airport.")
    else
        local v_ButtonSize = vec2:new(180, 35)
        ImGui.Dummy(1, 5)

        if not jet:IsPlayerInJet() then
            ImGui.BeginDisabled(not jet.canWarpPlayer)
                if ImGui.Button("Warp Into The Jet", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    jet:WarpPlayer()
                end
            ImGui.EndDisabled()

            ImGui.Spacing()
            ImGui.Text("Get in the jet to see more options.")
        else
            ImGui.Spacing()
            ImGui.SeparatorText("Commands")
            ImGui.Spacing()

            ImGui.BeginDisabled(jet.task == eVehicleTask.TAKE_OFF)
                if ImGui.Button("Fly To Waypoint", v_ButtonSize.x, v_ButtonSize.y) then
                    script.run_in_fiber(function(s)
                        local v_Pos = Game.GetWaypointCoords()

                        if not v_Pos then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Samurai's Scripts",
                                "[Heli Service]: No waypoint found!"
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        jet:FlyTo(v_Pos, s)
                    end)
                end

                ImGui.SameLine()

                if ImGui.Button("Fly To Objective", v_ButtonSize.x, v_ButtonSize.y) then
                    script.run_in_fiber(function(s)
                        local b_Found, v_Pos = Game.GetObjectiveBlipCoords()

                        if not b_Found then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Samurai's Scripts",
                                "[Heli Service]: No objective found!"
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            jet:FlyTo(v_Pos, s)
                        end)
                    end)
            end
            ImGui.EndDisabled()

            ImGui.BeginDisabled(jet.task ~= eVehicleTask.GOTO)
                if ImGui.Button("Skip Trip", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function()
                        jet:SkipTrip()
                    end)
                end
            ImGui.EndDisabled()

            ImGui.SameLine()

            ImGui.BeginDisabled(jet.task ~= eVehicleTask.LAND)
                if ImGui.Button("Skip Landing", v_ButtonSize.x, v_ButtonSize.y) then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function()
                        jet:FinishLanding()
                    end)
                end
            ImGui.EndDisabled()

            ImGui.Spacing()
            ImGui.SeparatorText("Landing Destinations")
            ImGui.Spacing()

            DrawAirportCombo()

            ImGui.SameLine()

            ImGui.BeginDisabled(not unk_JetAirportData or not unk_JetAirportData.landingApproach)
                if ImGui.Button(" Go ") then
                    script.run_in_fiber(function(s)
                        if not unk_JetAirportData then
                            return
                        end

                        if jet.departureAirport and (jet.departureAirport.name == unk_JetAirportData.name) then
                            UI.WidgetSound("Error")
                            YimToast:ShowError(
                                "Private Jet",
                                string.format(
                                    "You are already at %s.",
                                    unk_JetAirportData.name
                                )
                            )
                            return
                        end

                        UI.WidgetSound("Select")
                        jet.arrivalAirport = unk_JetAirportData
                        YimToast:ShowMessage(
                            "Private Jet",
                            string.format(
                                "Flying towards %s. Enjoy your flight.",
                                unk_JetAirportData.name
                            )
                        )
                        jet:FlyTo(unk_JetAirportData.landingApproach.pos, s)
                    end)
                end
            ImGui.EndDisabled()

            ImGui.Spacing()
            ImGui.SeparatorText("Seat Controls")
            ImGui.Spacing()

            if ImGui.Button("< Previous Seat", v_ButtonSize.x, v_ButtonSize.y) then
                UI.WidgetSound("Select")
                jet:ShuffleSeats(-1)
            end

            ImGui.SameLine()

            if ImGui.Button("Next Seat >", v_ButtonSize.x, v_ButtonSize.y) then
                UI.WidgetSound("Select")
                jet:ShuffleSeats(1)
            end

            ImGui.Spacing()
            ImGui.SeparatorText("Radio Controls")
            ImGui.Spacing()

            if ImGui.Button(jet.radio.isOn and "Turn Off" or "Turn On") then
                script.run_in_fiber(function()
                    AUDIO.SET_VEH_RADIO_STATION(
                        jet.handle,
                        jet.radio.isOn
                        and "OFF"
                        or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
                    )
                    jet.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(jet.handle)
                    jet.radio.stationName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
                end)
            end

            if jet.radio.isOn then
                ImGui.SameLine()
                UI.VehicleRadioCombo(jet.handle, "limoRadioStations", jet.radio.stationName)
            end
        end
    end
end

local t_BillionareSidebarItems <const> = {
    {
        label = "Bodyguards",
        callback = DrawBodyguards,
        OnSearchBarUsed = FilterPedsBySearchQuery
    },
    {
        label = "Escorts",
        callback = DrawEscorts,
        OnSearchBarUsed = FilterEscortsBySearchQuery
    },
    {
        label = "Limousine",
        callback = DrawLimousineService
    },
    {
        label = "Private Heli",
        callback = DrawHeliService
    },
    {
        label = "Private Jet",
        callback = DrawJetService
    },
}

local function DrawSidebarItems()
    local t_SelectedTab = t_BillionareSidebarItems[i_SelectedSidebarItem]

    if t_SelectedTab and t_SelectedTab.callback then
        t_SelectedTab.callback()

        if b_SearchBarUsed and t_SelectedTab.OnSearchBarUsed then
            t_SelectedTab.OnSearchBarUsed()
        end
    end
end

local function DrawMainSidebar()
    ImGui.SetNextWindowBgAlpha(0.0)
    ImGui.BeginChild("##main_sidebar", 160, i_BSUIHeight)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
    ImGui.Dummy(1, 80)

    for i, tab in ipairs(t_BillionareSidebarItems) do
        local is_selected = (i_SelectedSidebarItem == i)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (is_selected and 30 or 0))

        if is_selected then
            local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
            ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
        end

        if ImGui.Button(tab.label, 120, 30) then
            UI.WidgetSound("Nav")
            if i_SelectedSidebarItem ~= i then
                s_SearchBuffer = ""
                t_SelectedPed = nil
            end
            i_SelectedSidebarItem = i
        end

        if is_selected then
            ImGui.PopStyleColor()
        end
    end

    ImGui.PopStyleVar(2)
    ImGui.Dummy(1, 140)
    ImGui.SetCursorPosX(20.0)

    if BS:GetServiceCount() > 1 then
        if UI.ColoredButton(" Dismiss All ", "#FF0000", "#EE4B2B", "#880808") then
            BS:Dismiss(BS.SERVICE_TYPE.ALL)
        end
    else
        ImGui.TextDisabled("Dismiss All")
    end
    UI.Tooltip("Dismiss all services at once.")

    ImGui.EndChild()
end

function BSV2UI()
    ImGui.BeginGroup()
        DrawMainSidebar()
        ImGui.SameLine()
        ImGui.BeginChild("##main", 400, i_BSUIHeight, true)
            DrawSidebarItems()
        ImGui.EndChild()
    ImGui.EndGroup()

    OnTabItemSwitch()

    if PreviewService.current and (not ImGui.IsAnyItemHovered() or not b_PedPreview) then
        i_HoveredPedModelThisFrame = nil
        PreviewService:Clear()
    end
end
