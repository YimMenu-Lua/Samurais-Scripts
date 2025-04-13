---@diagnostic disable: undefined-global, lowercase-global

local i_ScenarioIndex       = 0
local i_RecentActionIndex   = 0
local i_FavoriteActionIndex = 0
local i_MovementIndex       = 0
local i_NpcIndex            = 0
local i_AnimSortByIndex     = 0

function UpdatefilteredAnims()
    t_FilteredAnims = {}
    for _, anim in ipairs(t_AnimList) do
        if i_AnimSortByIndex == 0 then
            if string.find(string.lower(anim.name), string.lower(actions_search)) then
                table.insert(t_FilteredAnims, anim)
            end
        else
            if anim.cat == t_AnimSortbyList[i_AnimSortByIndex + 1] then
                if string.find(string.lower(anim.name), string.lower(actions_search)) then
                    table.insert(t_FilteredAnims, anim)
                end
            end
        end
    end
    table.sort(t_AnimList, function(a, b)
        return a.name < b.name
    end)
end

function DisplayFilteredAnims()
    UpdatefilteredAnims()
    local t_AnimNames = {}
    for _, anim in ipairs(t_FilteredAnims) do
        table.insert(t_AnimNames, anim.name)
    end
    i_AnimIndex, used = ImGui.ListBox("##animlistbox", i_AnimIndex, t_AnimNames, #t_FilteredAnims)
end

function UpdatefilteredScenarios()
    t_FilteredScenarios = {}
    for _, scene in ipairs(t_PedScenarios) do
        if string.find(string.lower(scene.name), string.lower(actions_search)) then
            table.insert(t_FilteredScenarios, scene)
        end
    end
end

function DisplayFilteredScenarios()
    UpdatefilteredScenarios()
    local t_ScenarioNames = {}
    for _, scene in ipairs(t_FilteredScenarios) do
        table.insert(t_ScenarioNames, scene.name)
    end
    i_ScenarioIndex, used = ImGui.ListBox("##scenarioList", i_ScenarioIndex, t_ScenarioNames, #t_FilteredScenarios)
end

local function UpdateRecentlyPlayed()
    t_FilteredRecents = {}
    for _, v in ipairs(recently_played_a) do
        if string.find(string.lower(v.name), string.lower(actions_search)) then
            table.insert(t_FilteredRecents, v)
        end
    end
end

local function DisplayRecentlyPlayed()
    UpdateRecentlyPlayed()
    local t_RecentNames = {}
    for _, v in ipairs(t_FilteredRecents) do
        local recentName = v.name
        if v.dict ~= nil then
            recentName = string.format("[Animation]  %s", recentName)
        elseif v.scenario ~= nil then
            recentName = string.format("[Scenario]    %s", recentName)
        end
        table.insert(t_RecentNames, recentName)
    end
    i_RecentActionIndex, used = ImGui.ListBox("##recentsList", i_RecentActionIndex, t_RecentNames, #t_FilteredRecents)
end

local function UpdateFavoriteActions()
    t_FilteredFavs = {}
    for _, v in ipairs(favorite_actions) do
        if string.find(string.lower(v.name), string.lower(actions_search)) then
            table.insert(t_FilteredFavs, v)
        end
    end
end

local function DisplayFavoriteActions()
    UpdateFavoriteActions()
    local t_FavNames = {}
    for _, v in ipairs(t_FilteredFavs) do
        local favName = v.name
        if v.dict ~= nil then
            favName = string.format("[Animation]  %s", favName)
        elseif v.scenario ~= nil then
            favName = string.format("[Scenario]    %s", favName)
        end
        table.insert(t_FavNames, favName)
    end
    i_FavoriteActionIndex, used = ImGui.ListBox("##favsList", i_FavoriteActionIndex, t_FavNames, #t_FilteredFavs)
end

local function DecodeJsonMovements()
    if io.exists("movementClipsetsCompact.json") then
        local jsonFile = io.open("movementClipsetsCompact.json", "r")
        if jsonFile then
            local content = jsonFile:read("*all")
            jsonFile:flush()
            jsonFile:close()

            if not content or #content == 0 then
                YimToast:ShowError(
                    "Samurai's Scripts",
                    "Failed to read Json data. The file is either empty or corrupted!"
                )
                jsonMvmt = false
                return
            end

            return CFG:Decode(content)
        end
    end
end

local function DisplayMovements()
    t_MovementNames = {}
    if jsonMvmt then
        if not jsonMvmts_t or #jsonMvmts_t == 0 then
            jsonMvmts_t = DecodeJsonMovements()
        else
            ---@diagnostic disable-next-line
            for _, v in ipairs(jsonMvmts_t) do
                if string.find((v.Name):lower(), jsonMvmtSearch:lower()) then
                    table.insert(t_MovementNames, v)
                end
            end
            ImGui.SetNextItemWidth(380)
            jsonMvmtSearch, typed = ImGui.InputTextWithHint("##mvmtsearch", "Search", jsonMvmtSearch, 128)
            is_typing = ImGui.IsItemActive()
            if ImGui.BeginListBox("##jsonmvmtNames", 400, 100) then
                for i = 1, #t_MovementNames do
                    local is_selected = (i_MovementIndex == i)
                    if ImGui.Selectable(t_MovementNames[i].Name, is_selected) then
                        i_MovementIndex = i
                    end
                    if UI.IsItemClicked("lmb") then
                        SS.SetMovement(t_MovementNames[i], true)
                    end
                end
                ImGui.EndListBox()
            end
        end
    else
        for _, v in ipairs(t_MovementOptions) do
            table.insert(t_MovementNames, v.name)
        end
        ImGui.SetNextItemWidth(220)
        i_MovementIndex, mvmtSelected = ImGui.Combo("##mvmt", i_MovementIndex, t_MovementNames, #t_MovementOptions)
        if mvmtSelected then
            SS.SetMovement(t_MovementOptions[i_MovementIndex + 1], false)
        end
    end
end

updateNpcs = function()
    filteredNpcs = {}
    for _, npc in ipairs(t_NPClist) do
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
    i_NpcIndex, used = ImGui.Combo("##npcList", i_NpcIndex, npcNames, #filteredNpcs)
end

function YimActionsUI()
    ImGui.Dummy(60, 1)
    ImGui.SameLine()
    ImGui.PushItemWidth(270)
    actions_search, used = ImGui.InputTextWithHint("##searchBar", _T("GENERIC_SEARCH_HINT_"), actions_search,
        32)
    ImGui.PopItemWidth()
    is_typing = ImGui.IsItemActive()
    ImGui.BeginTabBar("Actionz", ImGuiTabBarFlags.None)
    if ImGui.BeginTabItem(_T("ANIMATIONS_TAB_")) then
        if tab1Sound then
            UI.WidgetSound("Nav")
            tab1Sound = false
            tab2Sound = true
            tab3Sound = true
            tab4Sound = true
        end
        ImGui.Spacing(); ImGui.BulletText("Filter Animations: "); ImGui.SameLine()
        ImGui.PushItemWidth(220)
        i_AnimSortByIndex, animSortUsed = ImGui.Combo("##animCategories", i_AnimSortByIndex, t_AnimSortbyList, #t_AnimSortbyList)
        ImGui.PopItemWidth()
        if animSortUsed then
            UI.WidgetSound("Nav2")
        end
        ImGui.Spacing(); ImGui.Separator(); ImGui.PushItemWidth(420) -- whatcha smokin'?
        DisplayFilteredAnims()
        ImGui.PopItemWidth()
        if t_FilteredAnims ~= nil then
            info = t_FilteredAnims[i_AnimIndex + 1]
        end

        ImGui.Separator(); manualFlags, used = ImGui.Checkbox("Edit Flags", manualFlags)
        if used then
            CFG:SaveItem("manualFlags", manualFlags)
            UI.WidgetSound("Nav2")
        end
        UI.HelpMarker(_T("ANIM_FLAGS_DESC_"))

        ImGui.SameLine(); disableProps, used = ImGui.Checkbox("Disable Props", disableProps)
        if used then
            CFG:SaveItem("disableProps", disableProps)
            UI.WidgetSound("Nav2")
        end
        UI.HelpMarker(_T("ANIM_PROPS_DESC_"))

        if manualFlags then
            controllable, controlUsed = ImGui.Checkbox(_T("ANIM_CONTROL_CB_"), controllable)
            if controlUsed then
                CFG:SaveItem("controllable", controllable)
                UI.WidgetSound("Nav2")
            end
            UI.HelpMarker(_T("ANIM_CONTROL_DESC_"))

            ImGui.SameLine(); ImGui.Dummy(27, 1); ImGui.SameLine()
            looped, loopUsed = ImGui.Checkbox("Loop", looped)
            if loopUsed then
                CFG:SaveItem("looped", looped)
                UI.WidgetSound("Nav2")
            end
            UI.HelpMarker(_T("ANIM_LOOP_DESC_"))

            upperbody, upperbodyUsed = ImGui.Checkbox(_T("ANIM_UPPER_CB_"), upperbody)
            if upperbodyUsed then
                CFG:SaveItem("upperbody", upperbody)
                UI.WidgetSound("Nav2")
            end
            UI.HelpMarker(_T("ANIM_UPPER_DESC_"))

            ImGui.SameLine(); ImGui.Dummy(1, 1); ImGui.SameLine()
            freeze, freezeUsed = ImGui.Checkbox(_T("ANIM_FREEZE_CB_"), freeze)
            if freezeUsed then
                CFG:SaveItem("freeze", freeze)
                UI.WidgetSound("Nav2")
            end
            UI.HelpMarker(_T("ANIM_FREEZE_DESC_"))

            noCollision, noCollUsed = ImGui.Checkbox(_T("ANIM_NO_COLL_CB_"), noCollision)
            if noCollUsed then
                CFG:SaveItem("noCollision", noCollision)
                UI.WidgetSound("Nav2")
            end

            ImGui.SameLine(); ImGui.Dummy(35, 1); ImGui.SameLine()
            ImGui.BeginDisabled(looped)
            killOnEnd, koeUsed = ImGui.Checkbox(_T("ANIM_KOE_CB_"), killOnEnd)
            if koeUsed then
                CFG:SaveItem("killOnEnd", killOnEnd)
                UI.WidgetSound("Nav2")
            end
            ImGui.EndDisabled()
            UI.HelpMarker(_T("ANIM_KOE_DESC_"))
            ImGui.Separator()
        end
        if ImGui.Button(string.format("%s##anim", _T("GENERIC_PLAY_BTN_"))) then
            if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
                UI.WidgetSound("Select")
                script.run_in_fiber(function(pa)
                    local coords     = ENTITY.GET_ENTITY_COORDS(Self.GetPedID(), false)
                    local heading    = ENTITY.GET_ENTITY_HEADING(Self.GetPedID())
                    local forwardX   = ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
                    local forwardY   = ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
                    local boneIndex  = PED.GET_PED_BONE_INDEX(Self.GetPedID(), info.boneID)
                    local bonecoords = PED.GET_PED_BONE_COORDS(Self.GetPedID(), info.boneID, 0.0, 0.0, 0.0)
                    if manualFlags then
                        i_AnimFlag = SetAnimFlags()
                    else
                        i_AnimFlag = info.flag
                    end
                    playAnim(
                        info, Self.GetPedID(), i_AnimFlag, selfprop1, selfprop2, selfloopedFX, selfSexPed, boneIndex,
                        coords, heading,
                        forwardX, forwardY, bonecoords, plyrProps, selfPTFX, pa)
                    is_playing_anim = true
                    curr_playing_anim = info
                    addActionToRecents(info)
                end)
            else
                UI.WidgetSound("Error")
                YimToast:ShowError("Samurais Scripts",
                    "You can not play animations while grabbing an NPC, grabbing a vehicle, sitting or hiding.")
            end
        end
        ImGui.SameLine()
        ImGui.BeginDisabled(not is_playing_anim)
        if ImGui.Button(string.format("%s##anim", _T("GENERIC_STOP_BTN_"))) then
            if is_playing_anim then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function(cu)
                    cleanup(cu)
                    is_playing_anim = false
                end)
            else
                UI.WidgetSound("Error")
            end
        end
        UI.Tooltip(_T("ANIM_STOP_DESC_"))
        ImGui.EndDisabled()
        ImGui.SameLine()
        ImGui.Dummy(12, 1)
        ImGui.SameLine()
        if UI.ColoredButton(
            _T("ANIM_DETACH_BTN_"),
            { 104, 255, 114, 175 },
            { 104, 255, 114, 150 },
            plyrProps[1] and { 104, 247, 114, 51 } or { 225, 0, 0, 125 }
        ) then
            UI.WidgetSound(plyrProps[1] and "Cancel" or "Error")
            script.run_in_fiber(function(detachProps)
                if plyrProps[1] ~= nil then
                    for k, v in ipairs(plyrProps) do
                        if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(v, Self.GetPedID()) then
                            ENTITY.DETACH_ENTITY(v, true, true)
                            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(v)
                            table.remove(plyrProps, k)
                        end
                    end
                else
                    if all_objects == nil then
                        all_objects = entities.get_all_objects_as_handles()
                    end
                    for _, v in ipairs(all_objects) do
                        local modelHash      = ENTITY.GET_ENTITY_MODEL(v)
                        local attachedObject = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(Self.GetPedID(), modelHash)
                        if ENTITY.DOES_ENTITY_EXIST(attachedObject) then
                            ENTITY.DETACH_ENTITY(attachedObject, true, true)
                            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(attachedObject)
                            TASK.CLEAR_PED_TASKS(Self.GetPedID())
                        end
                    end
                end
                is_playing_anim = false
                if is_playing_scenario then
                    stopScenario(Self.GetPedID(), detachProps)
                end
                if ped_grabbed then
                    if i_AttachedPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(i_AttachedPed) then
                        ENTITY.FREEZE_ENTITY_POSITION(i_AttachedPed, false)
                        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_AttachedPed, false)
                        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_AttachedPed, false)
                        PED.SET_PED_TO_RAGDOLL(i_AttachedPed, 1500, 0, 0, false, false, false)
                        TASK.CLEAR_PED_TASKS(Self.GetPedID())
                        PED.SET_PED_CAN_SWITCH_WEAPON(Self.GetPedID(), true)
                    end
                    ped_grabbed = false
                else
                    if all_peds == nil then
                        all_peds = entities.get_all_peds_as_handles()
                    end
                    for _, p in ipairs(all_peds) do
                        local pedHash     = ENTITY.GET_ENTITY_MODEL(p)
                        local attachedPed = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(Self.GetPedID(), pedHash)
                        if ENTITY.DOES_ENTITY_EXIST(attachedPed) then
                            ENTITY.DETACH_ENTITY(attachedPed, true, true)
                            TASK.CLEAR_PED_TASKS(Self.GetPedID())
                            TASK.CLEAR_PED_TASKS(attachedPed)
                            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(attachedPed)
                        end
                    end
                end
            end)
        end
        UI.Tooltip(_T("ANIM_DETACH_DESC_"))
        if info ~= nil then
            if shortcut_anim.name ~= info.name then
                if ImGui.Button(_T("ANIM_HOTKEY_BTN_")) then
                    chosen_anim        = info
                    is_setting_hotkeys = true
                    UI.WidgetSound("Select2")
                    ImGui.OpenPopup("Set Shortcut")
                end
                UI.Tooltip(_T("ANIM_HOTKEY_DESC_"))
                ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
                ImGui.SetNextWindowBgAlpha(0.9)
                if ImGui.BeginPopupModal("Set Shortcut", true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
                    UI.ColoredText("Selected Animation:  ", "green", 0.9, 20)
                    ImGui.SameLine()
                    ImGui.Text(string.format("« %s »", chosen_anim.name))
                    ImGui.Dummy(1, 10)
                    if btn_name == nil then
                        start_loading_anim = true
                        UI.ColoredText(string.format("%s %s", _T("INPUT_WAIT_TXT_"), loading_label), "#FFFFFF", 0.75, 20)
                        is_pressed, btn, btn_name = SS.IsAnyKeyPressed()
                    else
                        start_loading_anim = false
                        for _, key in pairs(t_ReservedKeys.kb) do
                            if btn == key then
                                _reserved = true
                                break
                            else
                                _reserved = false
                            end
                        end
                        if not _reserved then
                            ImGui.Text("Shortcut Button: "); ImGui.SameLine(); ImGui.Text(btn_name)
                        else
                            UI.ColoredText(_T("HOTKEY_RESERVED_"), "red", 0.86, 20)
                        end
                        ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
                        if UI.ColoredButton(string.format("%s##shortcut", _T("GENERIC_CLEAR_BTN_")), "#FFDB58", "#FFFAA0", "#FFFFF0", 0.7) then
                            UI.WidgetSound("Error")
                            btn, btn_name = nil, nil
                        end
                    end
                    ImGui.Dummy(1, 10)
                    if not _reserved and btn ~= nil then
                        if ImGui.Button(string.format("%s##shortcut", _T("GENERIC_CONFIRM_BTN_"))) then
                            UI.WidgetSound("Select")
                            if manualFlags then
                                i_AnimFlag = SetAnimFlags()
                            else
                                i_AnimFlag = chosen_anim.flag
                            end
                            shortcut_anim     = chosen_anim
                            shortcut_anim.btn = btn
                            CFG:SaveItem("shortcut_anim", shortcut_anim)
                            YimToast:ShowSuccess("Samurais Scripts",
                                string.format("%s %s %s", _T("HOTKEY_SUCCESS1_"), btn_name,
                                    _T("HOTKEY_SUCCESS2_")))
                            btn, btn_name      = nil, nil
                            is_setting_hotkeys = false
                            ImGui.CloseCurrentPopup()
                        end
                        ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
                    end
                    if ImGui.Button(string.format("%s##shortcut", _T("GENERIC_CANCEL_BTN_"))) then
                        UI.WidgetSound("Cancel")
                        btn, btn_name      = nil, nil
                        start_loading_anim = false
                        is_setting_hotkeys = false
                        ImGui.CloseCurrentPopup()
                    end
                    ImGui.End()
                end
            else
                if ImGui.Button(_T("ANIM_HOTKEY_DEL_")) then
                    UI.WidgetSound("Delete")
                    shortcut_anim = {}
                    CFG:SaveItem("shortcut_anim", {})
                    YimToast:ShowSuccess("Samurais Scripts", "Animation shortcut has been reset.")
                end
                UI.Tooltip(_T("DEL_HOTKEY_DESC_"))
            end
            ImGui.SameLine(); ImGui.Dummy(4, 1); ImGui.SameLine()
            if favorite_actions[1] ~= nil then
                for _, v in ipairs(favorite_actions) do
                    if info.name == v.name then
                        fav_exists = true
                        break
                    else
                        fav_exists = false
                    end
                end
            else
                if fav_exists then
                    fav_exists = false
                end
            end
            if not fav_exists then
                if ImGui.Button(string.format("%s##anims", _T("ADD_TO_FAVS_"))) then
                    UI.WidgetSound("Select")
                    table.insert(favorite_actions, info)
                    CFG:SaveItem("favorite_actions", favorite_actions)
                end
            else
                if ImGui.Button(_T("REMOVE_FROM_FAVS_")) then
                    UI.WidgetSound("Delete")
                    for k, v in ipairs(favorite_actions) do
                        if v == info then
                            table.remove(favorite_actions, k)
                        end
                    end
                    CFG:SaveItem("favorite_actions", favorite_actions)
                end
            end
        end
        ImGui.Spacing(); ImGui.SeparatorText(_T("MVMT_OPTIONS_TXT_")); ImGui.Spacing()
        jsonMvmt, jsonMvmtUsed = ImGui.Checkbox("Read From Json", jsonMvmt)
        UI.SetClipBoard(
            "https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json",
            (ImGui.IsItemHovered() and SS.IsKeyJustPressed(0x09))
        )
        UI.Tooltip(
            "You have to place the file 'movementClipsetsCompact.json' inside the 'scripts_config' folder. Otherwise this will not do anything.\n\nYou can download the Json file from this GitHub link: https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json\n\nPress [TAB] to copy the link to clipboard."
        )
        if jsonMvmtUsed then
            UI.WidgetSound("Nav2")
            i_MovementIndex = 0
            if jsonMvmt then
                if not io.exists("movementClipsetsCompact.json") then
                    YimToast:ShowError("Samurai's Scripts", "Json file not found!")
                    jsonMvmt = false
                end
            end
        end
        DisplayMovements()
        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav")
        end
        ImGui.BeginDisabled(currentMvmt == "")
        if ImGui.Button(_T("GENERIC_RESET_BTN_")) then
            UI.WidgetSound("Cancel")
            i_MovementIndex = 0
            SS.ResetMovement()
        end
        ImGui.EndDisabled()
        ImGui.Spacing(); ImGui.SeparatorText(_T("NPC_ANIMS_TXT_"))
        ImGui.PushItemWidth(220)
        displayNpcs()
        ImGui.PopItemWidth()
        if UI.IsItemClicked("lmb") then
            UI.WidgetSound("Nav2")
        end
        ImGui.SameLine()
        npc_godMode, ngodused = ImGui.Checkbox("Invincible", npc_godMode)
        if ngodused then
            CFG:SaveItem("npc_godMode", npc_godMode)
            UI.WidgetSound("Nav")
            if spawned_npcs[1] ~= nil then
                script.run_in_fiber(function()
                    for _, npc in ipairs(spawned_npcs) do
                        if ENTITY.DOES_ENTITY_EXIST(npc) and not ENTITY.IS_ENTITY_DEAD(npc, true) then
                            ENTITY.SET_ENTITY_INVINCIBLE(npc, npc_godMode)
                        end
                    end
                end)
            end
        end
        UI.Tooltip(_T("NPC_GODMODE_DESC_"))
        if ImGui.Button(string.format("%s##anims_npc", _T("GENERIC_SPAWN_BTN_"))) then
            UI.WidgetSound("Select")
            script.run_in_fiber(function()
                local npcData     = filteredNpcs[i_NpcIndex + 1]
                local pedCoords   = ENTITY.GET_ENTITY_COORDS(Self.GetPedID(), false)
                local pedHeading  = ENTITY.GET_ENTITY_HEADING(Self.GetPedID())
                local pedForwardX = ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
                local pedForwardY = ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
                local myGroup     = PED.GET_PED_GROUP_INDEX(Self.GetPedID())
                if not PED.DOES_GROUP_EXIST(myGroup) then
                    myGroup = PED.CREATE_GROUP(0)
                end
                PED.SET_GROUP_SEPARATION_RANGE(myGroup, 16960)
                while not STREAMING.HAS_MODEL_LOADED(npcData.hash) do
                    STREAMING.REQUEST_MODEL(npcData.hash)
                    coroutine.yield()
                end
                npc = PED.CREATE_PED(npcData.group, npcData.hash, 0.0, 0.0, 0.0, 0.0, true, false)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(npc, pedCoords.x + pedForwardX * 1.4, pedCoords.y + pedForwardY * 1.4,
                    pedCoords.z, true, false, false)
                ENTITY.SET_ENTITY_HEADING(npc, pedHeading - 180)
                PED.SET_PED_AS_GROUP_MEMBER(npc, myGroup)
                PED.SET_PED_NEVER_LEAVES_GROUP(npc, true)
                npcBlip = HUD.ADD_BLIP_FOR_ENTITY(npc)
                table.insert(npc_blips, npcBlip)
                HUD.SET_BLIP_AS_FRIENDLY(npcBlip, true)
                HUD.SET_BLIP_SCALE(npcBlip, 0.8)
                HUD.SHOW_HEADING_INDICATOR_ON_BLIP(npcBlip, true)
                WEAPON.GIVE_WEAPON_TO_PED(npc, 350597077, 9999, false, true)
                PED.SET_GROUP_FORMATION(myGroup, 2)
                PED.SET_GROUP_FORMATION_SPACING(myGroup, 1.0, 1.0, 1.0)
                PED.SET_PED_CONFIG_FLAG(npc, 179, true)
                PED.SET_PED_CONFIG_FLAG(npc, 294, true)
                PED.SET_PED_CONFIG_FLAG(npc, 398, true)
                PED.SET_PED_CONFIG_FLAG(npc, 401, true)
                PED.SET_PED_CONFIG_FLAG(npc, 443, true)
                PED.SET_PED_COMBAT_ABILITY(npc, 2)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 2, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 3, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 5, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 13, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 20, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 21, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 22, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 27, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 28, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 31, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 34, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 41, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 42, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 46, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 50, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 58, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 61, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 71, true)
                if npc_godMode then
                    ENTITY.SET_ENTITY_INVINCIBLE(npc, true)
                end
                table.insert(spawned_npcs, npc)
            end)
        end
        ImGui.SameLine()
        if ImGui.Button(string.format("%s##anim_npc", _T("GENERIC_DELETE_BTN_"))) then
            UI.WidgetSound("Delete")
            script.run_in_fiber(function(cu)
                cleanupNPC(cu)
                for k, v in ipairs(spawned_npcs) do
                    if ENTITY.DOES_ENTITY_EXIST(v) then
                        PED.REMOVE_PED_FROM_GROUP(v)
                        ENTITY.DELETE_ENTITY(v)
                    end
                    table.remove(spawned_npcs, k)
                end
            end)
        end
        ImGui.SameLine()
        if ImGui.Button(string.format("%s##anim_npc", _T("GENERIC_PLAY_BTN_"))) then
            if spawned_npcs[1] ~= nil then
                UI.WidgetSound("Select")
                script.run_in_fiber(function(npca)
                    for _, v in ipairs(spawned_npcs) do
                        if ENTITY.DOES_ENTITY_EXIST(v) then
                            local npcCoords      = ENTITY.GET_ENTITY_COORDS(v, false)
                            local npcHeading     = ENTITY.GET_ENTITY_HEADING(v)
                            local npcForwardX    = ENTITY.GET_ENTITY_FORWARD_X(v)
                            local npcForwardY    = ENTITY.GET_ENTITY_FORWARD_Y(v)
                            local npcBoneIndex   = PED.GET_PED_BONE_INDEX(v, info.boneID)
                            local npcBboneCoords = PED.GET_PED_BONE_COORDS(v, info.boneID, 0.0, 0.0, 0.0)
                            if manualFlags then
                                i_AnimFlag = SetAnimFlags()
                            else
                                i_AnimFlag = info.flag
                            end
                            playAnim(
                                info, v, i_AnimFlag, npcprop1, npcprop2, npcloopedFX, npcSexPed, npcBoneIndex, npcCoords,
                                npcHeading,
                                npcForwardX, npcForwardY, npcBboneCoords, npcProps, npcPTFX, npca
                            )
                        end
                    end
                end)
            else
                UI.WidgetSound("Error")
                YimToast:ShowError("Samurais Scripts", "Spawn an NPC first!")
            end
        end
        ImGui.SameLine()
        if ImGui.Button(string.format("%s##npc_anim", _T("GENERIC_STOP_BTN_"))) then
            UI.WidgetSound("Cancel")
            script.run_in_fiber(function(npca)
                cleanupNPC(npca)
            end)
        end
        usePlayKey, upkUsed = ImGui.Checkbox("Enable Animation Hotkeys", usePlayKey)
        UI.Tooltip(_T("ANIM_HOTKEYS_DESC_"))
        if upkUsed then
            CFG:SaveItem("usePlayKey", usePlayKey)
            UI.WidgetSound("Nav2")
        end
        ImGui.EndTabItem()
    end
    if ImGui.BeginTabItem(_T("SCENARIOS_TAB_")) then
        if tab2Sound then
            UI.WidgetSound("Nav")
            tab2Sound = false
            tab1Sound = true
            tab3Sound = true
            tab4Sound = true
        end
        ImGui.PushItemWidth(420)
        DisplayFilteredScenarios()
        ImGui.PopItemWidth()
        if t_FilteredScenarios ~= nil then
            data = t_FilteredScenarios[i_ScenarioIndex + 1]
        end
        ImGui.Separator()
        if ImGui.Button(string.format("%s##scenarios", _T("GENERIC_PLAY_BTN_"))) then
            if not ped_grabbed and not vehicle_grabbed and not is_hiding then
                UI.WidgetSound("Select")
                script.run_in_fiber(function(psc)
                    if Self.IsOnFoot() then
                        if is_playing_anim then
                            cleanup(psc)
                        end
                        playScenario(data, Self.GetPedID())
                        addActionToRecents(data)
                        is_playing_scenario = true
                    else
                        YimToast:ShowError("Samurai's Scripts", "You can not play scenarios in vehicles.")
                    end
                end)
            else
                YimToast:ShowError("Samurais Scripts",
                    "You can not play scenarios while grabbing an NPC, grabbing a vehicle or hiding.")
            end
        end
        ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine()
        if ImGui.Button(string.format("%s##scenarios", _T("GENERIC_STOP_BTN_"))) then
            if is_playing_scenario then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function(stp)
                    stopScenario(Self.GetPedID(), stp)
                end)
            else
                UI.WidgetSound("Error")
            end
        end
        UI.Tooltip(_T("SCN_STOP_DESC_"))
        ImGui.Spacing()
        if favorite_actions[1] ~= nil and t_FilteredScenarios[1] ~= nil then
            for _, v in ipairs(favorite_actions) do
                if data.name == v.name then
                    fav_exists = true
                    break
                else
                    fav_exists = false
                end
            end
        else
            if fav_exists then
                fav_exists = false
            end
        end
        if not fav_exists then
            if ImGui.Button(string.format("%s##favs", _T("ADD_TO_FAVS_"))) then
                UI.WidgetSound("Select")
                table.insert(favorite_actions, data)
                CFG:SaveItem("favorite_actions", favorite_actions)
            end
        else
            if ImGui.Button(string.format("%s##favs", _T("REMOVE_FROM_FAVS_"))) then
                UI.WidgetSound("Delete")
                for k, v in ipairs(favorite_actions) do
                    if v == data then
                        table.remove(favorite_actions, k)
                    end
                end
                CFG:SaveItem("favorite_actions", favorite_actions)
            end
        end
        ImGui.Spacing(); ImGui.SeparatorText(_T("NPC_SCENARIOS_"))
        ImGui.PushItemWidth(220)
        displayNpcs()
        ImGui.PopItemWidth()
        ImGui.SameLine()
        npc_godMode, ngodused = ImGui.Checkbox("Invincible", npc_godMode)
        if ngodused then
            CFG:SaveItem("npc_godMode", npc_godMode)
            UI.WidgetSound("Nav")
            if spawned_npcs[1] ~= nil then
                script.run_in_fiber(function()
                    for _, npc in ipairs(spawned_npcs) do
                        if ENTITY.DOES_ENTITY_EXIST(npc) and not ENTITY.IS_ENTITY_DEAD(npc, true) then
                            ENTITY.SET_ENTITY_INVINCIBLE(npc, npc_godMode)
                        end
                    end
                end)
            end
        end
        UI.Tooltip(_T("NPC_GODMODE_DESC_"))
        local npcData = filteredNpcs[i_NpcIndex + 1]
        if ImGui.Button(string.format("%s##scenario_npc", _T("GENERIC_SPAWN_BTN_"))) then
            UI.WidgetSound("Select")
            script.run_in_fiber(function()
                local pedCoords = ENTITY.GET_ENTITY_COORDS(Self.GetPedID(), false)
                local pedHeading = ENTITY.GET_ENTITY_HEADING(Self.GetPedID())
                local pedForwardX = ENTITY.GET_ENTITY_FORWARD_X(Self.GetPedID())
                local pedForwardY = ENTITY.GET_ENTITY_FORWARD_Y(Self.GetPedID())
                local myGroup = PED.GET_PED_GROUP_INDEX(Self.GetPedID())
                if not PED.DOES_GROUP_EXIST(myGroup) then
                    myGroup = PED.CREATE_GROUP(0)
                end
                while not STREAMING.HAS_MODEL_LOADED(npcData.hash) do
                    STREAMING.REQUEST_MODEL(npcData.hash)
                    coroutine.yield()
                end
                npc = PED.CREATE_PED(npcData.group, npcData.hash, 0.0, 0.0, 0.0, 0.0, true, false)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(npc, pedCoords.x + pedForwardX * 1.4, pedCoords.y + pedForwardY * 1.4,
                    pedCoords.z, true, false, false)
                ENTITY.SET_ENTITY_HEADING(npc, pedHeading - 180)
                PED.SET_PED_AS_GROUP_MEMBER(npc, myGroup)
                PED.SET_PED_NEVER_LEAVES_GROUP(npc, true)
                npcBlip = HUD.ADD_BLIP_FOR_ENTITY(npc)
                HUD.SET_BLIP_AS_FRIENDLY(npcBlip, true)
                HUD.SET_BLIP_SCALE(npcBlip, 0.8)
                HUD.SHOW_HEADING_INDICATOR_ON_BLIP(npcBlip, true)
                HUD.SET_BLIP_SPRITE(npcBlip, 280)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(npc, pedCoords.x + pedForwardX * 1.4, pedCoords.y + pedForwardY * 1.4,
                    pedCoords.z, true, false, false)
                ENTITY.SET_ENTITY_HEADING(npc, pedHeading - 180)
                WEAPON.GIVE_WEAPON_TO_PED(npc, 350597077, 9999, false, true)
                PED.SET_GROUP_FORMATION(myGroup, 2)
                PED.SET_GROUP_FORMATION_SPACING(myGroup, 1.0, 1.0, 1.0)
                PED.SET_PED_CONFIG_FLAG(npc, 179, true)
                PED.SET_PED_CONFIG_FLAG(npc, 294, true)
                PED.SET_PED_CONFIG_FLAG(npc, 398, true)
                PED.SET_PED_CONFIG_FLAG(npc, 401, true)
                PED.SET_PED_CONFIG_FLAG(npc, 443, true)
                PED.SET_PED_COMBAT_ABILITY(npc, 3)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 2, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 3, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 5, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 13, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 20, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 21, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 22, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 27, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 28, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 31, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 34, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 41, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 42, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 46, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 50, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 58, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 61, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(npc, 71, true)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
                if npc_godMode then
                    ENTITY.SET_ENTITY_INVINCIBLE(npc, true)
                end
                table.insert(spawned_npcs, npc)
            end)
        end
        ImGui.SameLine()
        if ImGui.Button(string.format("%s##scenarios", _T("GENERIC_DELETE_BTN_"))) then
            UI.WidgetSound("Delete")
            script.run_in_fiber(function()
                for k, v in ipairs(spawned_npcs) do
                    if ENTITY.DOES_ENTITY_EXIST(v) then
                        PED.REMOVE_PED_FROM_GROUP(v)
                        ENTITY.DELETE_ENTITY(v)
                    end
                    table.remove(spawned_npcs, k)
                end
            end)
        end
        ImGui.SameLine()
        if ImGui.Button(string.format("%s##npc_scenarios", _T("GENERIC_PLAY_BTN_"))) then
            if spawned_npcs[1] ~= nil then
                UI.WidgetSound("Select")
                script.run_in_fiber(function(npcsc)
                    for _, npc in ipairs(spawned_npcs) do
                        if PED.IS_PED_ON_FOOT(npc) then
                            if is_playing_anim then
                                cleanupNPC(npcsc)
                                is_playing_anim = false
                            end
                            playScenario(data, npc)
                            is_playing_scenario = true
                        else
                            YimToast:ShowError("Samurai's Scripts", "Scenarios can not be played inside vehicles.")
                        end
                    end
                end)
            else
                UI.WidgetSound("Error")
            end
        end
        ImGui.SameLine()
        if ImGui.Button(string.format("%s##npc_scenarios", _T("GENERIC_STOP_BTN_"))) then
            if is_playing_scenario then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function(stp)
                    for _, npc in ipairs(spawned_npcs) do
                        stopScenario(npc, stp)
                        is_playing_scenario = false
                    end
                end)
            end
        end
        ImGui.EndTabItem()
    end
    if ImGui.BeginTabItem(_T("FAVORITES_TAB_")) then
        if tab3Sound then
            UI.WidgetSound("Nav")
            tab3Sound = false
            tab1Sound = true
            tab2Sound = true
            tab4Sound = true
        end
        if favorite_actions[1] ~= nil then
            ImGui.PushItemWidth(420)
            DisplayFavoriteActions()
            ImGui.PopItemWidth()
            local selected_favorite = t_FilteredFavs[i_FavoriteActionIndex + 1]
            ImGui.Spacing()
            if ImGui.Button(string.format("%s##favs", _T("GENERIC_PLAY_BTN_"))) then
                if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
                    if selected_favorite.dict then -- anim type
                        if selected_favorite.cat == "In-Vehicle" and (Self.IsOnFoot() or not Self.Vehicle.IsCar) then
                            UI.WidgetSound("Error")
                            YimToast:ShowError("Samurai's Scripts",
                                "This animation can only be played while sitting inside a vehicle (cars and trucks only).")
                        else
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function(pf)
                                local coords     = self.get_pos()
                                local heading    = Game.GetHeading(Self.GetPedID())
                                local forwardX   = Game.GetForwardX(Self.GetPedID())
                                local forwardY   = Game.GetForwardY(Self.GetPedID())
                                local boneIndex  = PED.GET_PED_BONE_INDEX(Self.GetPedID(), selected_favorite.boneID)
                                local bonecoords = PED.GET_PED_BONE_COORDS(Self.GetPedID(), selected_favorite.boneID, 0.0,
                                    0.0, 0.0)
                                playAnim(
                                    selected_favorite, Self.GetPedID(), selected_favorite.flag, selfprop1, selfprop2,
                                    selfloopedFX,
                                    selfSexPed, boneIndex, coords, heading, forwardX, forwardY, bonecoords, plyrProps,
                                    selfPTFX, pf
                                )
                                curr_playing_anim = selected_favorite
                                is_playing_anim   = true
                            end)
                        end
                    elseif selected_favorite.scenario then -- scenario type
                        UI.WidgetSound("Select")
                        playScenario(selected_favorite, Self.GetPedID())
                        is_playing_scenario = true
                    end
                    addActionToRecents(selected_favorite)
                else
                    UI.WidgetSound("Error")
                    YimToast:ShowError("Samurais Scripts",
                        "You can not play animations while grabbing an NPC, grabbing a vehicle, sitting or hiding.")
                end
            end
            ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine()
            if ImGui.Button(string.format("%s##favs", _T("GENERIC_STOP_BTN_"))) then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function(fav)
                    if is_playing_anim then
                        cleanup(fav)
                        is_playing_anim = false
                    elseif is_playing_scenario then
                        stopScenario(Self.GetPedID(), fav)
                        is_playing_scenario = false
                    end
                end)
            end
            ImGui.SameLine(); ImGui.Dummy(37, 1); ImGui.SameLine()
            if UI.ColoredButton(string.format("%s##favs", _T("REMOVE_FROM_FAVS_")), "#FF0000", "#B30000", "#FF8080") then
                UI.WidgetSound("Delete")
                for k, v in ipairs(favorite_actions) do
                    if v == selected_favorite then
                        table.remove(favorite_actions, k)
                    end
                end
                CFG:SaveItem("favorite_actions", favorite_actions)
            end
        else
            ImGui.Dummy(1, 5)
            UI.WrappedText(_T("FAVS_NIL_TXT_"), 20)
        end
        ImGui.EndTabItem()
    end
    if ImGui.BeginTabItem(_T("RECENTS_TAB_")) then
        if tab4Sound then
            UI.WidgetSound("Nav")
            tab4Sound = false
            tab1Sound = true
            tab2Sound = true
            tab3Sound = true
        end
        if recently_played_a[1] ~= nil then
            ImGui.PushItemWidth(420)
            DisplayRecentlyPlayed()
            ImGui.PopItemWidth()
            local selected_recent = t_FilteredRecents[i_RecentActionIndex + 1]
            if ImGui.Button(string.format("%s##recents", _T("GENERIC_PLAY_BTN_"))) then
                if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
                    if selected_recent.dict ~= nil then -- animation type
                        if selected_recent.cat == "In-Vehicle" and (Self.IsOnFoot() or not Self.Vehicle.IsCar) then
                            UI.WidgetSound("Error")
                            YimToast:ShowError("Samurai's Scripts",
                                "This animation can only be played while sitting inside a vehicle (cars and trucks only).")
                        else
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function(pr)
                                local coords     = self.get_pos()
                                local heading    = Game.GetHeading(Self.GetPedID())
                                local forwardX   = Game.GetForwardX(Self.GetPedID())
                                local forwardY   = Game.GetForwardY(Self.GetPedID())
                                local boneIndex  = PED.GET_PED_BONE_INDEX(Self.GetPedID(), selected_recent.boneID)
                                local bonecoords = PED.GET_PED_BONE_COORDS(Self.GetPedID(), selected_recent.boneID, 0.0,
                                    0.0, 0.0)
                                playAnim(
                                    selected_recent, Self.GetPedID(), selected_recent.flag, selfprop1, selfprop2,
                                    selfloopedFX, selfSexPed,
                                    boneIndex, coords, heading, forwardX, forwardY, bonecoords, plyrProps, selfPTFX, pr
                                )
                                curr_playing_anim = selected_recent
                                is_playing_anim   = true
                            end)
                        end
                    elseif selected_recent.scenario ~= nil then -- scenario type
                        UI.WidgetSound("Select")
                        playScenario(selected_recent, Self.GetPedID())
                        is_playing_scenario = true
                    end
                else
                    UI.WidgetSound("Error")
                    YimToast:ShowError("Samurais Scripts",
                        "You can not play animations while grabbing an NPC, grabbing a vehicle, sitting or hiding.")
                end
            end
            ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine()
            if ImGui.Button(string.format("%s##recents", _T("GENERIC_STOP_BTN_"))) then
                UI.WidgetSound("Cancel")
                script.run_in_fiber(function(recent)
                    if is_playing_anim then
                        cleanup(recent)
                        is_playing_anim = false
                    elseif is_playing_scenario then
                        stopScenario(Self.GetPedID(), recent)
                        is_playing_scenario = false
                    end
                end)
            end
        else
            ImGui.Dummy(1, 5); UI.WrappedText(_T("RECENTS_NIL_TXT_"), 20)
        end
        ImGui.EndTabItem()
    end
    ImGui.EndTabBar()
end
