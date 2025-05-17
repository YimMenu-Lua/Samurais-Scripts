---@diagnostic disable

local i_ActionsUIHeight <const>  = 540
local i_AnimSortByIndex          = 0
local i_MovementCategory         = 0
local i_PedIndex                 = 0
local i_HoveredPedModelThisFrame = 0
local i_SelectedAnimIndex        = 1
local i_SelectedScenarioIndex    = 1
local i_SelectedSceneIndex       = 1
local i_SelectedSidebarItem      = 1
local i_CompanionIndex           = 1
local i_CompanionActionCategory  = -1
local s_SelectedPed              = ""
local s_SearchQuery              = ""
local s_MovementSearchQuery      = ""
local s_PedSearchQuery           = ""
local s_UIStatusText             = ""
local s_SelectedFavoriteName     = ""
local s_MovementClipsetsGitHub   = "https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json"
local s_GitHubLinkColor          = "#0000EE"
local b_AnimListCreated          = false
local b_MovementListCreated      = false
local b_SearchBarUsed            = false
local b_EditAnimFlags            = false
local b_CompanionGodMode         = false
local b_CompanionArmed           = false
local b_PreviewPeds              = false
local b_SpawnInvincible          = false
local b_SpawnArmed               = false
local b_AutoCloseSpawnWindow     = false
local t_SelectedAction           = nil
local t_SelectedMovementClipset  = nil
local s_CurrentTab               = nil
local s_PreviousTab              = nil
local t_FilteredScenarios        = t_PedScenarios
local t_FilteredMovementClipsets = t_MovementOptions
local t_FilteredPeds             = t_GamePeds
local t_Anims                    = {}
local t_FilteredAnims            = {}
local t_MovementClipsetsJson     = {}
local t_SpawnedPeds              = {}
local hwnd_PedSpawnWindow        = {should_draw = false}
local CompanionMgr               = YimActions.CompanionManager
local unk_SelectedCompanion

local s_SidebarTip = string.format(
    "TIP: You can press %s to stop playing any action or hold it for one second to cleanup everything.",
    keybinds.stop_anim.name
)

local t_AnimSortbyList <const> = {
    "All",
    "Actions",
    "Activities",
    "Gestures",
    "In-Vehicle",
    "Movements",
    "MISC",
    "NSFW",
}

local t_AnimFlags <const> = {
    looped = {
        label = "Looped",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._LOOPING
    },
    upperbody = {
        label = "Upper Body Only",
        enabled = false,
        wasClicked =
        false, bit = ANIMFLAGS._UPPERBODY
    },
    secondary = {
        label = "Secondary",
        enabled = false,
        wasClicked =
        false, bit = ANIMFLAGS._SECONDARY
    },
    hideWeapon = {
        label = "Hide Weapon",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._HIDE_WEAPON
    },
    endsInDeath = {
        label = "Ends In Death",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._ENDS_IN_DEAD_POSE
    },
    holdLastFrame = {
        label = "Hold Last Frame",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._HOLD_LAST_FRAME
    },
    uninterruptable = {
        label = "Uninterruptable",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._NOT_INTERRUPTABLE
    },
    additive = {
        label = "Additive",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._ADDITIVE
    },
    nocollision = {
        label = "No Collision",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._TURN_OFF_COLLISION
    },
    forceStart = {
        label = "Force Start",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._FORCE_START
    },
    processAttachments = {
        label = "Process Attachments",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._PROCESS_ATTACHMENTS_ON_START
    },
    alternateFpAnim = {
        label = "Alt First Person Anim",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._USE_ALTERNATIVE_FP_ANIM
    },
    useFullBlending = {
        label = "Use Full Blending",
        enabled = false,
        wasClicked = false,
        bit = ANIMFLAGS._USE_FULL_BLENDING
    },
}

local function OnTabItemSwitch()
    if s_CurrentTab ~= s_PreviousTab then
        UI.WidgetSound("Nav")
        s_PreviousTab       = s_CurrentTab
        s_SearchQuery       = ""
        i_AnimSortByIndex   = 0
        t_SelectedAction    = nil
        t_FilteredScenarios = t_PedScenarios
        t_FilteredAnims     = t_Anims
    end
end

local function CreateAnimList()
    script.run_in_fiber(function()
        for _, action in ipairs(t_AnimList) do
            b_ShouldAnimateLoadingLabel = true
            s_UIStatusText = string.format("Loading Animations. Please wait %s", s_LoadingLabel)

            table.insert(t_Anims, action)
            table.sort(t_Anims, function(a, b)
                return a.label < b.label
            end)

            coroutine.yield()
        end

        t_FilteredAnims = t_Anims
        b_AnimListCreated = true
        b_ShouldAnimateLoadingLabel = false
        s_UIStatusText = ""
    end)
end

local function FilterAnimsByCategory()
    if not b_AnimListCreated then
        return
    end

    if i_AnimSortByIndex > 1 then
        t_FilteredAnims = {}

        for _, action in ipairs(t_Anims) do
            if action.category == t_AnimSortbyList[i_AnimSortByIndex + 1] then
                table.insert(t_FilteredAnims, action)
            end
        end
    else
        t_FilteredAnims = t_Anims
    end
end

local function FilterAnimsBySearchQuery()
    if not b_AnimListCreated then
        return
    end

    if #s_SearchQuery > 0 then
        t_FilteredAnims = {}

        for _, action in ipairs(t_Anims) do
            if string.find(action.label:lower(), s_SearchQuery:lower()) then
                table.insert(t_FilteredAnims, action)
            end
        end
    else
        t_FilteredAnims = t_Anims
    end
end

local function DrawAnims()
    if #t_Anims == 0 then
        CreateAnimList()
    end

    if ImGui.BeginListBox("##animlist", -1, -1) then
        if not b_AnimListCreated then
            ImGui.Dummy(1, 60)
            ImGui.Text(s_UIStatusText)
        else
            for i, action in ipairs(t_FilteredAnims) do
                local is_selected = (i == i_SelectedAnimIndex)
                local is_favorite = YimActions:DoesFavoriteExist("anims", action.label)
                local label = action.label

                if is_favorite then
                    label = string.format("%s  [ * ]", action.label)
                end

                if is_selected then
                    if is_favorite then
                        ImGui.PushStyleColor(ImGuiCol.Header, 1.0, 0.843, 0.0, 0.65)
                        ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 1.0, 0.875, 0.2, 0.85)
                        ImGui.PushStyleColor(ImGuiCol.HeaderActive, 1.0, 0.9, 0.3, 1.0)
                    else
                        ImGui.PushStyleColor(ImGuiCol.Header, 0.3, 0.3, 0.7, 0.6)
                        ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.4, 0.4, 0.8, 0.8)
                        ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.5, 0.5, 0.9, 1.0)
                    end
                end

                if ImGui.Selectable(label, is_selected) then
                    i_SelectedAnimIndex = i
                end

                UI.Tooltip(
                    string.format(
                        "Right click to %s favorites.",
                        is_favorite and "remove from" or "add to"
                    )
                )

                if is_selected then
                    ImGui.PopStyleColor(3)
                    t_SelectedAction = Action.new(
                        t_FilteredAnims[i_SelectedAnimIndex],
                        YimActions.ACTION_TYPES.ANIM
                    )
                end

                if ImGui.IsItemHovered() and ImGui.IsItemClicked(1) then
                    UI.WidgetSound("Click")
                    ImGui.OpenPopup("##context_" .. i)
                    i_SelectedAnimIndex = i
                end

                if ImGui.BeginPopup("##context_" .. i) then
                    if is_favorite then
                        if ImGui.MenuItem("Remove From Favorites") then
                            UI.WidgetSound("Click")
                            YimActions:RemoveFromFavorites("anims", action.label)
                        end
                    else
                        if ImGui.MenuItem("Add To Favorites") then
                            UI.WidgetSound("Click")
                            YimActions:AddToFavorites(
                                "anims",
                                action.label,
                                action,
                                YimActions.ACTION_TYPES.ANIM
                            )
                        end
                    end

                    ImGui.EndPopup()
                end
            end
        end
        ImGui.EndListBox()
    end
end

local function FilterScenariosBySearchQuery()
    if #s_SearchQuery > 0 then
        t_FilteredScenarios = {}

        for _, action in ipairs(t_PedScenarios) do
            if string.find(action.label:lower(), s_SearchQuery:lower()) then
                table.insert(t_FilteredScenarios, action)
            end
        end
    else
        t_FilteredScenarios = t_PedScenarios
    end
end

local function DrawScenarios()
    if ImGui.BeginListBox("##scenarios", -1, -1) then
        for i, action in ipairs(t_FilteredScenarios) do
            local is_selected = (i_SelectedScenarioIndex == i)
            local is_favorite = YimActions:DoesFavoriteExist("scenarios", action.label)
            local label = action.label

            if is_favorite then
                label = string.format("%s  [ * ]", action.label)
            end

            if is_selected then
                if is_favorite then
                    ImGui.PushStyleColor(ImGuiCol.Header, 1.0, 0.843, 0.0, 0.65)
                    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 1.0, 0.875, 0.2, 0.85)
                    ImGui.PushStyleColor(ImGuiCol.HeaderActive, 1.0, 0.9, 0.3, 1.0)
                else
                    ImGui.PushStyleColor(ImGuiCol.Header, 0.3, 0.3, 0.7, 0.6)
                    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.4, 0.4, 0.8, 0.8)
                    ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.5, 0.5, 0.9, 1.0)
                end
            end

            if ImGui.Selectable(label, is_selected) then
                i_SelectedScenarioIndex = i
            end

            UI.Tooltip(
                string.format(
                    "Right click to %s favorites.",
                    is_favorite and "remove from" or "add to"
                )
            )

            if is_selected then
                ImGui.PopStyleColor(3)
                t_SelectedAction = Action.new(
                    t_FilteredScenarios[i_SelectedScenarioIndex],
                    YimActions.ACTION_TYPES.SCENARIO
                )
            end

            if ImGui.IsItemHovered() and ImGui.IsItemClicked(1) then
                UI.WidgetSound("Click")
                ImGui.OpenPopup("##context_" .. i)
            end

            if ImGui.BeginPopup("##context_" .. i) then
                if is_favorite then
                    if ImGui.MenuItem("Remove From Favorites") then
                        UI.WidgetSound("Click")
                        YimActions:RemoveFromFavorites("scenarios", action.label)
                    end
                else
                    if ImGui.MenuItem("Add To Favorites") then
                        UI.WidgetSound("Click")
                        YimActions:AddToFavorites(
                            "scenarios",
                            action.label,
                            action,
                            YimActions.ACTION_TYPES.SCENARIO
                        )
                    end
                end

                ImGui.EndPopup()
            end
        end
        ImGui.EndListBox()
    end
end

local function DrawScenes()
    if not SS_debug then
        ImGui.Dummy(1, 60)
        ImGui.SetWindowFontScale(1.2)
        ImGui.Text("Coming soon.")
        ImGui.SetWindowFontScale(1.0)
        return
    end

    if ImGui.BeginListBox("##synced_scenes", -1, -1) then
        for i, scene in ipairs(t_SyncedScenes) do
            local is_selected = (i_SelectedSceneIndex == i)

            if ImGui.Selectable(scene.label, is_selected) then
                i_SelectedSceneIndex = i
            end

            if is_selected then
                t_SelectedAction = Action.new(
                    scene,
                    2
                )
            end
        end
        ImGui.EndListBox()
    end
end

local function ListFavoritesByCategory(category)
    if not yav3_favorites or not yav3_favorites[category] then
        return
    end

    if next(yav3_favorites[category]) == nil then
        ImGui.TextWrapped(("You don't have any saved %s."):format(category or "actions of this type"))
        return
    end

    if ImGui.BeginListBox(("##favorite_" ):format(category), -1, -1) then
        for label, data in pairs(yav3_favorites[category]) do
            local is_selected = (s_SelectedFavoriteName == label)

            if is_selected then
                ImGui.PushStyleColor(ImGuiCol.Header, 0.3, 0.3, 0.7, 0.6)
                ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.4, 0.4, 0.8, 0.8)
                ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.5, 0.5, 0.9, 1.0)
            end

            if ImGui.Selectable(data.label, is_selected) then
                s_SelectedFavoriteName = label
            end

            UI.Tooltip("Right click to remove from favorites.")

            if is_selected then
                ImGui.PopStyleColor(3)
                t_SelectedAction = Action.new(
                    data,
                    data.type
                )
            end

            if ImGui.IsItemHovered() and ImGui.IsItemClicked(1) then
                UI.WidgetSound("Click")
                ImGui.OpenPopup("##context_" .. label)
            end

            if ImGui.BeginPopup("##context_" .. label) then
                if ImGui.MenuItem("Remove") then
                    UI.WidgetSound("Click")
                    YimActions:RemoveFromFavorites(category, label)
                end

                ImGui.EndPopup()
            end
        end
        ImGui.EndListBox()
    end
end

local function DrawFavoriteActions()
    if not yav3_favorites or next(yav3_favorites) == nil then
        ImGui.Dummy(1, 80)
        ImGui.TextWrapped("Nothig saved yet.")
        return
    end

    if ImGui.BeginTabBar("##AnimationsTabBar") then
        if ImGui.BeginTabItem("Animations") then
            s_CurrentTab = "anims"
            ListFavoritesByCategory("anims")
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Scenarios") then
            s_CurrentTab = "scenarios"
            ListFavoritesByCategory("scenarios")
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Scenes") then
            s_CurrentTab = "scenes"
            -- ListFavoritesByCategory("scenes")
            ImGui.Dummy(1, 60)
            ImGui.SetWindowFontScale(1.2)
            ImGui.Text("Coming soon.")
            ImGui.SetWindowFontScale(1.0)
            ImGui.EndTabItem()
        end

        OnTabItemSwitch()
        ImGui.EndTabBar()
    end
end

local function DrawRecents()
    if next(YimActions.LastPlayed) == nil then
        ImGui.Dummy(1, 80)
        ImGui.TextWrapped("Animations, scenarios, and scenes you play will appear here for easy access.")
        return
    end

    if ImGui.BeginListBox("##recents", -1, -1) then
        for i, action in pairs(YimActions.LastPlayed) do
            local is_selected = (i_SelectedRecentIndex == i)
            local actionType = action.action_type
            local label = string.format("%s  [%s]", action.data.label, action:TypeAsString())

            if is_selected then
                ImGui.PushStyleColor(ImGuiCol.Header, 0.3, 0.3, 0.7, 0.6)
                ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.4, 0.4, 0.8, 0.8)
                ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.5, 0.5, 0.9, 1.0)
            end

            if ImGui.Selectable(label, is_selected) then
                i_SelectedRecentIndex = i
            end

            if is_selected then
                ImGui.PopStyleColor(3)
                t_SelectedAction = action
            end
        end
        ImGui.EndListBox()
    end
end

local t_ActionsSidebarItems <const> = {
    {
        label = "Animations",
        callback = DrawAnims,
        OnSearchBarUsed = FilterAnimsBySearchQuery
    },
    {
        label = "Scenarios",
        callback = DrawScenarios,
        OnSearchBarUsed = FilterScenariosBySearchQuery
    },
    -- {
    --     label = "Scenes",
    --     callback = DrawScenes
    -- },
    {
        label = "Favorites",
        callback = DrawFavoriteActions
    },
    {
        label = "Recents",
        callback = DrawRecents
    },
}

local function DrawActionsSidebar()
    ImGui.SetNextWindowBgAlpha(0.0)
    ImGui.BeginChild("##actios_sidebar", 160, i_ActionsUIHeight)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
    ImGui.Dummy(1, 80)

    for i, tab in ipairs(t_ActionsSidebarItems) do
        local is_selected = (i_SelectedSidebarItem == i)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (is_selected and 30 or 0))

        if is_selected then
            local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
            ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
        end

        if ImGui.Button(tab.label, 120, 30) then
            UI.WidgetSound("Nav")
            if i_SelectedSidebarItem ~= i then
                s_SearchQuery = ""
                t_SelectedAction = nil
            end
            i_SelectedSidebarItem = i
        end

        if is_selected then
            ImGui.PopStyleColor()
        end
    end

    ImGui.PopStyleVar(2)
    ImGui.SetCursorPosX(0.0)
    ImGui.Dummy(1, 80)
    ImGui.SetWindowFontScale(0.7)
    ImGui.TextWrapped(s_SidebarTip)
    ImGui.SetWindowFontScale(1.0)
    ImGui.EndChild()
end

local function DrawSidebarItems()
    local t_SelectedTab = t_ActionsSidebarItems[i_SelectedSidebarItem]

    if t_SelectedTab then
        t_SelectedTab.callback()
        if b_SearchBarUsed and t_SelectedTab.OnSearchBarUsed then
            t_SelectedTab.OnSearchBarUsed()
        end
    end
end

local function DrawAnimOptions()
    ImGui.BeginDisabled(not t_SelectedAction)
        ImGui.SetNextItemWidth(120)
        i_AnimSortByIndex, bSortUsed = ImGui.Combo("Category", i_AnimSortByIndex, t_AnimSortbyList, #t_AnimSortbyList)

        if bSortUsed then
            UI.WidgetSound("Nav")
            FilterAnimsByCategory()
        end

        ImGui.SameLine()

        if s_CurrentTab ~= "companion_anims" then
            b_EditAnimFlags, _ = ImGui.Checkbox("Edit Flags", b_EditAnimFlags)
        end

        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav2")
        end

    ImGui.EndDisabled()
end

local function DrawPlayerTabItem()
    ImGui.BeginGroup()
        DrawActionsSidebar()
        ImGui.SameLine()
        ImGui.BeginChild("##main_player", 400, i_ActionsUIHeight, true)

            if (i_SelectedSidebarItem == 1) or (i_SelectedSidebarItem == 2) then
                ImGui.SetNextItemWidth(-1)
                s_SearchQuery, b_SearchBarUsed = ImGui.InputTextWithHint(
                    "##search",
                    _T("GENERIC_SEARCH_HINT_"),
                    s_SearchQuery,
                    128
                )
                b_IsTyping = ImGui.IsItemActive()
            end

            DrawSidebarItems()
        ImGui.EndChild()
    ImGui.EndGroup()

    ImGui.Separator()

    ImGui.SetNextWindowBgAlpha(0.69)
    ImGui.BeginChild("##player_footer", 0, 65, true, ImGuiWindowFlags.NoScrollbar)
        
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)
        ImGui.BeginDisabled(not t_SelectedAction or YimActions:IsPlayerBusy())
            if ImGui.Button("Play", 80, 35) then
                UI.WidgetSound("Select")
                script.run_in_fiber(function()
                    YimActions:Play(t_SelectedAction, self.get_ped())
                end)
            end
        ImGui.EndDisabled()

        ImGui.SameLine()

        ImGui.BeginDisabled(not YimActions:IsPedPlaying())
            if ImGui.Button("Stop", 80, 35) then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function()
                    YimActions:Cleanup(self.get_ped())
                end)
            end
        ImGui.EndDisabled()

        ImGui.SameLine()

        if i_SelectedSidebarItem == 1 then
            DrawAnimOptions()
        end
        ImGui.PopStyleVar()

    ImGui.EndChild()
    
    if (i_SelectedSidebarItem == 1) and t_SelectedAction and b_EditAnimFlags then
        ImGui.BeginChild("##anim_options", 0, 200, true)
            ImGui.Columns(2)
            ImGui.SetColumnWidth(0, 250)
            for i, flag in pairs(t_AnimFlags) do
                ImGui.PushID(("##animflag_"):format(i))
                flag.enabled, flag.wasClicked = ImGui.Checkbox(flag.label, Lua_fn.has_bit(t_SelectedAction.data.flags, flag.bit))
                ImGui.PopID()

                if flag.bit == ANIMFLAGS._ENDS_IN_DEAD_POSE then
                    UI.Tooltip("This will not do anything if the animation is looped.")
                end

                ImGui.NextColumn()

                if flag.wasClicked then
                    UI.WidgetSound("Nav2")
                    local bitwiseOp = flag.enabled and Lua_fn.set_bit or Lua_fn.clear_bit
                    t_SelectedAction.data.flags = bitwiseOp(t_SelectedAction.data.flags, flag.bit)
                end
            end
            ImGui.Columns(0)
        ImGui.EndChild()
    end
end

local function GetMovementClipsetsFromJson()
    b_MovementListCreated = false
    if not io.exists("movementClipsetsCompact.json") then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Movement Clipsets file not found!",
            true
        )
        return
    end

    local jsonFile = io.open("movementClipsetsCompact.json", "r")
    if not jsonFile then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Failed to read Json!",
            true
        )
        return
    end

    local content = jsonFile:read("*all")
    jsonFile:close()

    if not content or (#content == 0) then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Failed to read Json data! The file is either empty or corrupted.",
            true
        )
        return
    end

    local temp = CFG:Decode(content)
    script.run_in_fiber(function()
        for _, v in ipairs(temp) do
            table.insert(t_MovementClipsetsJson, v)
            table.sort(t_MovementClipsetsJson, function(a, b)
                return a.Name < b.Name
            end)
            yield()
        end
        b_MovementListCreated = (#t_MovementClipsetsJson > 0)
        temp = nil
    end)
end

local function FilterMovementsBySearchQuery(t)
    if #s_MovementSearchQuery > 0 then
        t_FilteredMovementClipsets = {}

        for _, v in ipairs(t) do
            if string.find(v.Name:lower(), s_MovementSearchQuery:lower()) then
                table.insert(t_FilteredMovementClipsets, v)
            end
        end
    else
        t_FilteredMovementClipsets = t
    end
end

local function DrawCustomMovementClipsets()
    if bIsSearchingMvmts then
        FilterMovementsBySearchQuery(t_MovementOptions)
    end

    ImGui.BeginListBox("##customMvmts", -1, -1)
        if not t_FilteredMovementClipsets then
            return
        end

        for i = 1, #t_FilteredMovementClipsets do
            local is_selected = (i_MovementIndex == i)
            local is_favorite = YimActions:DoesFavoriteExist("clipsets", t_FilteredMovementClipsets[i].Name)
            local label = t_FilteredMovementClipsets[i].Name

            if is_favorite then
                label = string.format("%s  [ * ]", t_FilteredMovementClipsets[i].Name)
            end

            if is_selected then
                if is_favorite then
                    ImGui.PushStyleColor(ImGuiCol.Header, 1.0, 0.843, 0.0, 0.65)
                    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 1.0, 0.875, 0.2, 0.85)
                    ImGui.PushStyleColor(ImGuiCol.HeaderActive, 1.0, 0.9, 0.3, 1.0)
                else
                    ImGui.PushStyleColor(ImGuiCol.Header, 0.3, 0.3, 0.7, 0.6)
                    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.4, 0.4, 0.8, 0.8)
                    ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.5, 0.5, 0.9, 1.0)
                end
            end

            if ImGui.Selectable(label, is_selected) then
                i_MovementIndex = i
            end

            UI.Tooltip("Left click to apply or right click to add to favorites.")

            if is_selected then
                ImGui.PopStyleColor(3)
            end

            if UI.IsItemClicked("lmb") then
                SS.SetMovement(t_FilteredMovementClipsets[i], false)
            end

            if UI.IsItemClicked("rmb") then
                ImGui.OpenPopup("##custom_mvmt_" .. i)
                i_MovementIndex = i
            end

            if ImGui.BeginPopup("##custom_mvmt_" .. i) then
                if is_favorite then
                    if ImGui.MenuItem("Remove From Favorites") then
                        UI.WidgetSound("Click")
                        YimActions:RemoveFromFavorites(
                            "clipsets",
                            t_FilteredMovementClipsets[i].Name
                        )
                    end
                else
                    if ImGui.MenuItem("Add To Favorites") then
                        UI.WidgetSound("Click")
                        YimActions:AddToFavorites(
                            "clipsets",
                            t_FilteredMovementClipsets[i].Name,
                            t_FilteredMovementClipsets[i],
                            YimActions.ACTION_TYPES.UNK
                        )
                    end
                end

                ImGui.EndPopup()
            end
        end
    ImGui.EndListBox()
end

local function DrawJsonMovementClipsets()
    if (#t_MovementClipsetsJson == 0) then
        local exists = io.exists("movementClipsetsCompact.json")
        if not exists then
            ImGui.TextWrapped("You must download the clipsets Json file and save it to the 'scripts_config' folder.")
            ImGui.SetWindowFontScale(0.8)
            UI.ColoredText(s_MovementClipsetsGitHub, s_GitHubLinkColor)
            ImGui.SetWindowFontScale(1.0)
            UI.Tooltip("Right click to copy the link.")

            if ImGui.IsItemHovered() then
                s_GitHubLinkColor = "#551A8B"
            else
                s_GitHubLinkColor = "#0000EE"
            end

            if UI.IsItemClicked("rmb") then
                UI.WidgetSound("Click")
                UI.SetClipBoardText(s_MovementClipsetsGitHub, true)
            end
        end

        ImGui.Dummy(1, 10)

        ImGui.BeginDisabled(not exists)
        if ImGui.Button("Read From Json") then
            UI.WidgetSound("Select")
            GetMovementClipsetsFromJson()
        end
        ImGui.EndDisabled()
    else
        if bIsSearchingMvmts then
            FilterMovementsBySearchQuery(t_MovementClipsetsJson)
        end

        ImGui.BeginDisabled(not b_MovementListCreated)
        ImGui.BeginListBox("##jsonmvmts", -1, -1)
            if not t_FilteredMovementClipsets then
                return
            end

            for i = 1, #t_FilteredMovementClipsets do
                local is_selected = (i_MovementIndex == i)
                local is_favorite = YimActions:DoesFavoriteExist("clipsets", t_FilteredMovementClipsets[i].Name)
                local label = t_FilteredMovementClipsets[i].Name

                if is_favorite then
                    label = string.format("%s  [ * ]", t_FilteredMovementClipsets[i].Name)
                end
                
                if is_selected then
                    if is_favorite then
                        ImGui.PushStyleColor(ImGuiCol.Header, 1.0, 0.843, 0.0, 0.65)
                        ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 1.0, 0.875, 0.2, 0.85)
                        ImGui.PushStyleColor(ImGuiCol.HeaderActive, 1.0, 0.9, 0.3, 1.0)
                    else
                        ImGui.PushStyleColor(ImGuiCol.Header, 0.3, 0.3, 0.7, 0.6)
                        ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.4, 0.4, 0.8, 0.8)
                        ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.5, 0.5, 0.9, 1.0)
                    end
                end

                if ImGui.Selectable(label, is_selected) then
                    i_MovementIndex = i
                end

                UI.Tooltip("Left click to apply or right click to add to favorites.")

                if is_selected then
                    ImGui.PopStyleColor(3)
                end

                if UI.IsItemClicked("lmb") then
                    SS.SetMovement(t_FilteredMovementClipsets[i], true)
                end

                if UI.IsItemClicked("rmb") then
                    UI.WidgetSound("Click")
                    ImGui.OpenPopup("##context_" .. i)
                    i_MovementIndex = i
                end
    
                if ImGui.BeginPopup("##context_" .. i) then
                    if is_favorite then
                        if ImGui.MenuItem("Remove From Favorites") then
                            UI.WidgetSound("Click")
                            YimActions:RemoveFromFavorites(
                                "clipsets",
                                t_FilteredMovementClipsets[i].Name
                            )
                        end
                    else
                        if ImGui.MenuItem("Add To Favorites") then
                            UI.WidgetSound("Click")
                            YimActions:AddToFavorites(
                                "clipsets",
                                t_FilteredMovementClipsets[i].Name,
                                t_FilteredMovementClipsets[i],
                                YimActions.ACTION_TYPES.UNK
                            )
                        end
                    end
    
                    ImGui.EndPopup()
                end
            end
        ImGui.EndListBox()
        ImGui.EndDisabled()
    end
end

local function DrawFavoriteMovementClipsets()
    if not yav3_favorites or not yav3_favorites["clipsets"] then
        return
    end

    if next(yav3_favorites["clipsets"]) == nil then
        ImGui.TextWrapped(("You don't have any saved clipsets."))
        return
    end

    if ImGui.BeginListBox(("##favorite_clipsets"), -1, -1) then
        for label, data in pairs(yav3_favorites["clipsets"]) do
            local is_selected = (s_SelectedFavoriteName == label)

            if is_selected then
                ImGui.PushStyleColor(ImGuiCol.Header, 0.3, 0.3, 0.7, 0.6)
                ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.4, 0.4, 0.8, 0.8)
                ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.5, 0.5, 0.9, 1.0)
            end

            if ImGui.Selectable(data.Name, is_selected) then
                s_SelectedFavoriteName = label
            end

            UI.Tooltip("Right click to remove from favorites.")

            if is_selected then
                ImGui.PopStyleColor(3)
            end

            if UI.IsItemClicked("lmb") then
                SS.SetMovement(data, (data.wmvmt ~= nil))
            end

            if UI.IsItemClicked("rmb") then
                UI.WidgetSound("Click")
                ImGui.OpenPopup("##context_" .. label)
                s_SelectedFavoriteName = label
            end

            if ImGui.BeginPopup("##context_" .. label) then
                if ImGui.MenuItem("Remove") then
                    UI.WidgetSound("Click")
                    YimActions:RemoveFromFavorites("clipsets", label)
                end

                ImGui.EndPopup()
            end
        end
        ImGui.EndListBox()
    end
end

local function DrawMovemenOptions()
    ImGui.Spacing()
    ImGui.Spacing()
    i_MovementCategory, b_CustomMvmmt = ImGui.RadioButton("Custom Movements", i_MovementCategory, 0)

    if b_CustomMvmmt then
        UI.WidgetSound("Nav")
        s_MovementSearchQuery = ""
        t_FilteredMovementClipsets = t_MovementOptions
    end

    ImGui.SameLine()
    ImGui.Dummy(10, 1)
    ImGui.SameLine()

    i_MovementCategory, b_JsonMvmt = ImGui.RadioButton("All Movement Clipsets", i_MovementCategory, 1)

    if b_JsonMvmt then
        UI.WidgetSound("Nav")
        s_MovementSearchQuery = ""
        t_FilteredMovementClipsets = t_MovementClipsetsJson
    end

    ImGui.SameLine()
    ImGui.Dummy(10, 1)
    ImGui.SameLine()
    
    i_MovementCategory, b_FavMvmts = ImGui.RadioButton("Favorites", i_MovementCategory, 2)

    if b_FavMvmts then
        UI.WidgetSound("Nav")
        s_MovementSearchQuery = ""
        t_FilteredMovementClipsets = yav3_favorites["clipsets"]
    end

    ImGui.SetNextWindowBgAlpha(0.0)
    ImGui.BeginChild("##mvmtsDummy", 50, 100)
    ImGui.EndChild()

    ImGui.SameLine()

    ImGui.BeginChild("##movementClipsets", 440, i_ActionsUIHeight, true)
        if i_MovementCategory < 2 then
            ImGui.SetNextItemWidth(-1)
            ImGui.BeginDisabled((i_MovementCategory == 1) and not b_MovementListCreated)
            s_MovementSearchQuery, bIsSearchingMvmts = ImGui.InputTextWithHint("##mvmtsearch", "Search", s_MovementSearchQuery, 128)
            ImGui.EndDisabled()
            b_IsTyping = ImGui.IsItemActive()
        end

        if i_MovementCategory == 0 then
            DrawCustomMovementClipsets()
        elseif i_MovementCategory == 1 then
            DrawJsonMovementClipsets()
        elseif i_MovementCategory == 2 then
            DrawFavoriteMovementClipsets()
        end
    ImGui.EndChild()

    ImGui.SetNextWindowBgAlpha(0.0)
    ImGui.BeginChild("##mvmtsDummy2", 50, 65)
    ImGui.EndChild()

    ImGui.SameLine()

    ImGui.BeginChild("##mvmts_footer", 440, 65, true)
        if ImGui.Button("Reset", 80, 35) then
            UI.WidgetSound("Cancel")
            SS.ResetMovement()
        end
    ImGui.EndChild()
end

local function FilterPedsBySearchQuery()
    if #s_PedSearchQuery > 0 then
        t_FilteredPeds = {}
        for _, ped in ipairs(t_GamePeds) do
            if string.find(ped:lower(), s_PedSearchQuery:lower()) then
                table.insert(t_FilteredPeds, ped)
            end
        end
    else
        t_FilteredPeds = t_GamePeds
    end
end

local function DrawCompanionActionsSearchBar()
    ImGui.SetNextItemWidth(-1)
    s_SearchQuery, b_SearchBarUsed = ImGui.InputTextWithHint(
        "##search_companion_anims",
        _T("GENERIC_SEARCH_HINT_"),
        s_SearchQuery,
        128
    )
    b_IsTyping = ImGui.IsItemActive()

    if b_SearchBarUsed then
        if i_CompanionActionCategory == 1 then
            FilterAnimsBySearchQuery()
        elseif i_CompanionActionCategory == 2 then
            FilterScenariosBySearchQuery()
        end
    end 
end

local function DrawCompanions()
    ImGui.BeginChild("##spawned_companions", 380, i_ActionsUIHeight * 0.7, true)
        if next(CompanionMgr.Companions) == nil then
            ImGui.Text("No companions spawned.")
        else
            -- do we really need a searchbar for spawned peds too?
            if ImGui.BeginListBox("##spawned_companions", -1, -1) then
                for i, companion in pairs(CompanionMgr.Companions) do
                    if ImGui.Selectable(string.format("%s [%d]", companion.name, companion.handle), (i_CompanionIndex == i)) then
                        i_CompanionIndex = i
                        unk_SelectedCompanion = companion
                    end

                    if UI.IsItemClicked("rmb") then
                        ImGui.OpenPopup("##companion_controls_" .. i)
                        i_CompanionIndex = i
                    end

                    if ImGui.BeginPopup("##companion_controls_" .. i) then
                        if ImGui.MenuItem("Warp Into Vehicle") then
                            script.run_in_fiber(function()
                                local veh = self.get_veh()

                                if veh == 0 then
                                    YimToast:ShowWarning(
                                        "Samurai's Scripts",
                                        "No vehicle to warp into."
                                    )
                                    return
                                end

                                UI.WidgetSound("Click")
                                TASK.TASK_WARP_PED_INTO_VEHICLE(companion.handle, veh, -2)
                            end)
                        end
                        ImGui.EndPopup()
                    end
                end
                ImGui.EndListBox()
            end
        end
    ImGui.EndChild()

    ImGui.SameLine()

    ImGui.SetNextWindowBgAlpha(0)
    ImGui.BeginChild("##companion_controls", 180, i_ActionsUIHeight * 0.7)
        ImGui.Dummy(1, ((i_ActionsUIHeight * 0.7 / 2) - (32 * 9)))
        if ImGui.Button("Spawn Companion", 160, 32) then
            UI.WidgetSound("Select")
            hwnd_PedSpawnWindow.should_draw = true
        end

        if unk_SelectedCompanion and (next(CompanionMgr.Companions) ~= nil) then
            if ImGui.Button("Remove", 160, 32) then -- AD PROFUNDIS
                UI.WidgetSound("Delete")
                script.run_in_fiber(function()
                    CompanionMgr:RemoveCompanion(unk_SelectedCompanion)
                end)
            end

            if ImGui.Button(
                ("%s God Mode"):format(
                    unk_SelectedCompanion.godmode and "Disable" or "Enable"
                ),
                160,
                35
            ) then
                UI.WidgetSound("Select")
                unk_SelectedCompanion:ToggleGodmode()
            end

            if ImGui.Button(
                ("%s"):format(
                    unk_SelectedCompanion.armed and "Disarm" or "Arm"
                ),
                160,
                35
            ) then
                UI.WidgetSound("Select")
                unk_SelectedCompanion:ToggleWeapon()
            end
            UI.Tooltip(
                string.format(
                    "%s",
                    unk_SelectedCompanion.armed and
                    "Remove your companion's weapon." or
                    "Give your companion a tactical SMG."
                )
            )

            ImGui.BeginDisabled(not t_SelectedAction)
                if ImGui.Button("Play", 160, 32) then -- AVE IMPERATOR, MORITURI TE SALUTANT
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function()
                        YimActions:Play(t_SelectedAction, unk_SelectedCompanion.handle)
                    end)
                end

                ImGui.BeginDisabled(not YimActions:IsPedPlaying(unk_SelectedCompanion.handle))
                    if ImGui.Button("Stop", 160, 32) then
                        UI.WidgetSound("Cancel")
                        script.run_in_fiber(function()
                            YimActions:Cleanup(unk_SelectedCompanion.handle)
                        end)
                    end
                ImGui.EndDisabled()

                ImGui.BeginDisabled(#CompanionMgr.Companions <= 1)
                    if ImGui.Button("All Play", 160, 32) then -- I hate how *All Play* sounds 😒
                        UI.WidgetSound("Select")
                        script.run_in_fiber(function()
                            CompanionMgr:AllCompanionsPlay(t_SelectedAction)
                        end)
                    end
                ImGui.EndDisabled()
            ImGui.EndDisabled()

            ImGui.BeginDisabled(#CompanionMgr.Companions <= 1 or not CompanionMgr:AreAnyCompanionsPlaying())
                if ImGui.Button("Stop All", 160, 32) then
                    UI.WidgetSound("Cancel")
                    script.run_in_fiber(function()
                        CompanionMgr:StopAllCompanions()
                    end)
                end
            ImGui.EndDisabled()

            ImGui.BeginDisabled(#CompanionMgr.Companions == 0)
                if ImGui.Button("Bring All", 160, 32) then
                    UI.WidgetSound("Cancel")
                    script.run_in_fiber(function()
                        CompanionMgr:BringAllCompanions()
                    end)
                end
            ImGui.EndDisabled()
        end
    ImGui.EndChild()

    ImGui.Spacing()
    ImGui.SeparatorText("Companion Actions")
    ImGui.BeginChild("##companion_actions_child", 0, 335, true)
        ImGui.BeginTabBar("##companion_actions_tabbar")
            if ImGui.BeginTabItem("Animations##companions") then
                s_CurrentTab = "companion_anims"
                i_CompanionActionCategory = 1
                DrawCompanionActionsSearchBar()
                DrawAnims()
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Scenarios##companions") then
                s_CurrentTab = "companion_scnearios"
                i_CompanionActionCategory = 2
                DrawCompanionActionsSearchBar()
                DrawScenarios()
                ImGui.EndTabItem()
            end

            OnTabItemSwitch()
        ImGui.EndTabBar()
    ImGui.EndChild()
    ImGui.BeginChild("##player_footer_2", 0, 65, true, ImGuiWindowFlags.NoScrollbar)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)
        if i_CompanionActionCategory > 0 and i_CompanionActionCategory <= 2 then
            ImGui.BeginDisabled(not t_SelectedAction or YimActions:IsPlayerBusy())
            if ImGui.Button("Play", 80, 35) then
                UI.WidgetSound("Select")
                script.run_in_fiber(function()
                    YimActions:Play(t_SelectedAction)
                end)
            end
            UI.Tooltip("Play it yourself.")
            ImGui.EndDisabled()

            ImGui.SameLine()

            ImGui.BeginDisabled(not YimActions:IsPedPlaying())
            if ImGui.Button("Stop", 80, 35) then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function()
                    YimActions:Cleanup()
                end)
            end
            ImGui.EndDisabled()

            ImGui.SameLine()

            if i_CompanionActionCategory == 1 then
                DrawAnimOptions()
            end
        end
        ImGui.PopStyleVar()

    ImGui.EndChild()
end

local function DrawPedSpawnWindow()
    if hwnd_PedSpawnWindow.should_draw then
        ImGui.Begin(
            "Companion Spawner",
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.NoResize |
            ImGuiWindowFlags.NoScrollbar |
            ImGuiWindowFlags.NoCollapse
        )

        if ImGui.Button("Close") then
            UI.WidgetSound("Cancel")
            hwnd_PedSpawnWindow.should_draw = false
        end

        ImGui.Separator()
        ImGui.Dummy(1, 10)

        ImGui.BeginChild("##ped_spawn_list", 440, 400, true)
            ImGui.SetNextItemWidth(-1)
            s_PedSearchQuery, b_PedSearch_used = ImGui.InputTextWithHint(
                "##search",
                "Search",
                s_PedSearchQuery,
                128
            )
            b_IsTyping = ImGui.IsItemActive()
        
            if b_PedSearch_used then
                FilterPedsBySearchQuery()
            end

            if ImGui.BeginListBox("##ped_list", -1, -1) then
                for i = 1, #t_FilteredPeds do

                    if ImGui.Selectable(t_FilteredPeds[i], (i_PedIndex == i)) then
                        i_PedIndex = i
                    end

                    if ImGui.IsItemHovered() and b_PreviewPeds then
                        i_HoveredPedModelThisFrame = joaat(t_FilteredPeds[i])
                    end
                end
                ImGui.EndListBox()
            end

            if b_PreviewPeds and i_HoveredPedModelThisFrame ~= 0 then
                PreviewService:OnTick(i_HoveredPedModelThisFrame, 2)
            end
        ImGui.EndChild()

        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)

        b_SpawnInvincible, _ = ImGui.Checkbox("Spawn Invincible", b_SpawnInvincible)

        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav2")
        end

        ImGui.SameLine()

        b_SpawnArmed, _ = ImGui.Checkbox("Spawn Armed", b_SpawnArmed)

        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav2")
        end

        ImGui.SameLine()
        
        b_PreviewPeds, _ = ImGui.Checkbox("Preview", b_PreviewPeds)

        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav2")
        end

        ImGui.Spacing()

        ImGui.BeginDisabled(not t_FilteredPeds[i_PedIndex])
        if ImGui.Button("Spawn", 80, 35) then
            UI.WidgetSound("Select")
            script.run_in_fiber(function()
                CompanionMgr:SpawnCompanion(
                    joaat(t_FilteredPeds[i_PedIndex]),
                    t_FilteredPeds[i_PedIndex],
                    b_SpawnInvincible,
                    b_SpawnArmed,
                    false
                )

                if b_AutoCloseSpawnWindow then
                    hwnd_PedSpawnWindow.should_draw = false
                end
            end)
        end

        ImGui.SameLine()
        ImGui.Spacing()
        ImGui.SameLine()
        b_AutoCloseSpawnWindow, _ = ImGui.Checkbox("Auto-Close Window", b_AutoCloseSpawnWindow)

        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav2")
        end

        ImGui.EndDisabled()

        ImGui.PopStyleVar()

        if PreviewService.current and (not ImGui.IsAnyItemHovered() or not b_PreviewPeds) then
            i_HoveredPedModelThisFrame = nil
            PreviewService:Clear()
        end

        ImGui.End()
    end
end

function YimActionsV3UI()
    if ImGui.BeginTabBar("yimactionsv3") then
        if ImGui.BeginTabItem("Actions") then
            s_CurrentTab = "main_actions"
            DrawPlayerTabItem()
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Movement Styles") then
            s_CurrentTab = "main_movements"
            DrawMovemenOptions()
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Companions") then
            s_CurrentTab = "main_companions"
            DrawCompanions()

            if hwnd_PedSpawnWindow.should_draw then
                DrawPedSpawnWindow()
            end
            ImGui.EndTabItem()
        end

        if SS_debug then
            if ImGui.BeginTabItem("Debug") then
                s_CurrentTab = "yav3_dbg"
                YimActions.Debugger:Draw()
                ImGui.EndTabItem()
            end
        end

        OnTabItemSwitch()
        ImGui.EndTabBar()
    end
end
