-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local t_AnimList                 = require("includes.data.actions.animations")
local t_PedScenarios             = require("includes.data.actions.scenarios")
local t_SyncedScenes             = require("includes.data.actions.synchronized_scenes")
local t_MovementClipsets         = require("includes.data.actions.movement_clipsets")
local t_GamePeds                 = require("includes.data.peds")
local Action                     = require("includes.structs.Action")
local PreviewService             = require("includes.services.PreviewService")
local i_AnimSortByIndex          = 0
local i_MovementCategory         = 0
local i_SelectedRecentIndex      = 1
local i_SelectedAnimIndex        = 1
local i_SelectedScenarioIndex    = 1
local i_SelectedSceneIndex       = 1
local i_SelectedSidebarItem      = 1
local i_CompanionIndex           = 1
local i_CompanionActionCategory  = -1
local s_SelectedPed              = ""
local s_SearchBuffer             = ""
local s_MovementSearchBuffer     = ""
local s_PedSearchBuffer          = ""
local s_SelectedFavoriteName     = ""
local s_NewCommandBuffer         = ""
local s_MovementClipsetsGitHub   = "https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json"
local s_GitHubLinkColor          = "#0000EE"
local b_DataListsSorted          = false
local b_MovementListCreated      = false
local b_SearchBarUsed            = false
local b_PreviewPeds              = false
local b_SpawnInvincible          = false
local b_SpawnArmed               = false

---@type Action?
local t_SelectedAction           = nil
local t_SelectedMovementClipset  = nil
local s_CurrentTab               = nil
local s_PreviousTab              = nil
local i_HoveredPedModelThisFrame = nil
local unk_SelectedCompanion      = nil
local t_MovementClipsetsJson     = {}
local hwnd_PedSpawnWindow        = { should_draw = false }
local hwnd_NewCommandWindow      = { should_draw = false }
local CompanionMgr               = YimActions.CompanionManager
local t_AnimSortbyList <const>   = {
	"All",
	"Actions",
	"Activities",
	"Gestures",
	"In-Vehicle",
	"Movements",
	"MISC",
	"NSFW",
}

local t_AnimFlags <const>        = {
	looped = {
		label = "Looped",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.LOOPING
	},
	upperbody = {
		label = "Upper Body Only",
		enabled = false,
		wasClicked =
			false,
		bit = Enums.eAnimFlags.UPPERBODY
	},
	secondary = {
		label = "Secondary",
		enabled = false,
		wasClicked =
			false,
		bit = Enums.eAnimFlags.SECONDARY
	},
	hideWeapon = {
		label = "Hide Weapon",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.HIDE_WEAPON
	},
	endsInDeath = {
		label = "Ends In Death",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.ENDS_IN_DEAD_POSE
	},
	holdLastFrame = {
		label = "Hold Last Frame",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.HOLD_LAST_FRAME
	},
	uninterruptable = {
		label = "Uninterruptible",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.NOT_INTERRUPTABLE
	},
	additive = {
		label = "Additive",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.ADDITIVE
	},
	nocollision = {
		label = "No Collision",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.TURN_OFF_COLLISION
	},
	forceStart = {
		label = "Force Start",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.FORCE_START
	},
	processAttachments = {
		label = "Process Attachments",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.PROCESS_ATTACHMENTS_ON_START
	},
	alternateFpAnim = {
		label = "Alt First Person Anim",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.USE_ALTERNATIVE_FP_ANIM
	},
	useFullBlending = {
		label = "Use Full Blending",
		enabled = false,
		wasClicked = false,
		bit = Enums.eAnimFlags.USE_FULL_BLENDING
	},
}

local compatFlag                 = (Backend:GetAPIVersion() == Enums.eAPIVersion.V2) and
	ImGuiChildFlags.AlwaysUseWindowPadding or true

local function OnTabItemSwitch()
	if (s_CurrentTab ~= s_PreviousTab) then
		GUI:PlaySound(GUI.Sounds.Nav)
		s_PreviousTab     = s_CurrentTab
		s_SearchBuffer    = ""
		i_AnimSortByIndex = 0
		t_SelectedAction  = nil
	end
end

local function BuildDataLists()
	ThreadManager:Run(function()
		table.sort(t_AnimList, function(a, b)
			return a.label < b.label
		end)
		table.sort(t_PedScenarios, function(a, b)
			return a.label < b.label
		end)
		table.sort(t_MovementClipsets, function(a, b)
			return a.Name < b.Name
		end)
		table.sort(t_GamePeds, function(a, b)
			return a < b
		end)

		b_DataListsSorted = true
	end)
end

local function DrawNewCommandWindow()
	if (not t_SelectedAction) then
		return
	end

	if (hwnd_NewCommandWindow.should_draw) then
		local windowSize = vec2:new(400, 200)
		local _, pos = GUI:GetNewWindowSizeAndCenterPos(0.5, 0.5, windowSize)
		ImGui.SetNextWindowSize(420, 200)
		ImGui.SetNextWindowPos(pos.x, pos.y, ImGuiCond.Always)
		if (ImGui.Begin("#yav3_new_command",
				ImGuiWindowFlags.NoMove
				| ImGuiWindowFlags.NoResize
				| ImGuiWindowFlags.NoTitleBar
				| ImGuiWindowFlags.NoSavedSettings
				| ImGuiWindowFlags.AlwaysAutoResize)
			) then
			ImGui.Dummy(0, 20)
			ImGui.SetNextItemWidth(-1)
			s_NewCommandBuffer, _ = ImGui.InputTextWithHint("##cmd",
				"command name (ex: /sitdown)",
				s_NewCommandBuffer,
				64
			)
			Backend.disable_input = ImGui.IsItemActive()

			if (not s_NewCommandBuffer:isempty()) then
				s_NewCommandBuffer = s_NewCommandBuffer:lower():replace(" ", "_")
			end

			ImGui.Dummy(0, 40)

			ImGui.BeginDisabled(s_NewCommandBuffer:isempty())
			if (ImGui.Button(_T("GENERIC_CONFIRM"))) then
				ThreadManager:Run(function()
					YimActions:AddCommandAction(
						s_NewCommandBuffer,
						---@diagnostic disable-next-line
						{ label = t_SelectedAction.data.label, type = t_SelectedAction.action_type }
					)
					s_NewCommandBuffer = ""
				end)

				hwnd_NewCommandWindow.should_draw = false
			end
			ImGui.EndDisabled()

			ImGui.SameLine()

			if (ImGui.Button(_T("GENERIC_CANCEL"))) then
				s_NewCommandBuffer = ""
				hwnd_NewCommandWindow.should_draw = false
			end

			ImGui.End()
		end
	end
end

local function DrawAnims()
	if ImGui.BeginListBox("##animlist", -1, -1) then
		if not b_DataListsSorted then
			ImGui.Dummy(1, 60)
			ImGui.Text(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL"), 7, ImGuiSpinnerStyle.SCAN))
		else
			for i, action in ipairs(t_AnimList) do
				if (i_AnimSortByIndex > 0 and action.category ~= t_AnimSortbyList[i_AnimSortByIndex + 1]) then
					goto continue
				end

				if (not s_SearchBuffer:isempty() and not action.label:lower():find(s_SearchBuffer:lower())) then
					goto continue
				end

				local is_selected = (i == i_SelectedAnimIndex)
				local is_favorite = YimActions:DoesFavoriteExist("anims", action.label)
				local has_command = GVars.features.yim_actions.action_commands[action.label] ~= nil
				local label       = action.label

				if (is_favorite) then
					label = _F("* %s", action.label)
					ImGui.PushStyleColor(ImGuiCol.Text, 0.8, 0.8, 0.4, 0.8)
				end

				if ImGui.Selectable(label, is_selected) then
					i_SelectedAnimIndex = i
				end

				if (is_favorite) then
					ImGui.PopStyleColor()
				end

				if (not hwnd_NewCommandWindow.should_draw) then
					GUI:Tooltip(_F("Right click for more options."))
				end

				if (is_selected) then
					t_SelectedAction = Action.new(
						t_AnimList[i_SelectedAnimIndex],
						Enums.eActionType.ANIM
					)
				end

				if (ImGui.IsItemHovered() and ImGui.IsItemClicked(1)) then
					GUI:PlaySound("Click")
					ImGui.OpenPopup("##context_" .. i)
					i_SelectedAnimIndex = i
				end

				if ImGui.BeginPopup("##context_" .. i) then
					if is_favorite then
						if ImGui.MenuItem("Remove From Favorites") then
							GUI:PlaySound("Click")
							YimActions:RemoveFromFavorites("anims", action.label)
						end
					else
						if ImGui.MenuItem("Add To Favorites") then
							GUI:PlaySound("Click")
							YimActions:AddToFavorites(
								"anims",
								action.label,
								action,
								Enums.eActionType.ANIM
							)
						end
					end

					if (has_command) then
						if ImGui.MenuItem("Remove Command") then
							GUI:PlaySound("Click")
							YimActions:RemoveCommandAction(action.label)
						end
					else
						if ImGui.MenuItem("Create Command") then
							GUI:PlaySound("Click")
							hwnd_NewCommandWindow.should_draw = true
						end
					end

					ImGui.EndPopup()
				end

				::continue::
			end
		end
		ImGui.EndListBox()
	end
end

local function DrawScenarios()
	if ImGui.BeginListBox("##scenarios", -1, -1) then
		for i, action in ipairs(t_PedScenarios) do
			if (not s_SearchBuffer:isempty() and not action.label:lower():find(s_SearchBuffer:lower())) then
				goto continue
			end

			local is_selected = (i_SelectedScenarioIndex == i)
			local is_favorite = YimActions:DoesFavoriteExist("scenarios", action.label)
			local has_command = GVars.features.yim_actions.action_commands[action.label] ~= nil
			local label       = action.label

			if (is_favorite) then
				label = _F("* %s", action.label)
				ImGui.PushStyleColor(ImGuiCol.Text, 0.8, 0.8, 0.4, 0.8)
			end

			if ImGui.Selectable(label, is_selected) then
				i_SelectedScenarioIndex = i
			end

			if (is_favorite) then
				ImGui.PopStyleColor()
			end

			if (not hwnd_NewCommandWindow.should_draw) then
				GUI:Tooltip(_F("Right click for more options."))
			end

			if (is_selected) then
				t_SelectedAction = Action.new(
					t_PedScenarios[i_SelectedScenarioIndex],
					Enums.eActionType.SCENARIO
				)
			end

			if (ImGui.IsItemHovered() and ImGui.IsItemClicked(1)) then
				GUI:PlaySound("Click")
				ImGui.OpenPopup("##context_" .. i)
			end

			if ImGui.BeginPopup("##context_" .. i) then
				if is_favorite then
					if ImGui.MenuItem("Remove From Favorites") then
						GUI:PlaySound("Click")
						YimActions:RemoveFromFavorites("scenarios", action.label)
					end
				else
					if ImGui.MenuItem("Add To Favorites") then
						GUI:PlaySound("Click")
						YimActions:AddToFavorites(
							"scenarios",
							action.label,
							action,
							Enums.eActionType.SCENARIO
						)
					end
				end

				if (has_command) then
					if ImGui.MenuItem("Remove Command") then
						GUI:PlaySound("Click")
						YimActions:RemoveCommandAction(action.label)
					end
				else
					if ImGui.MenuItem("Create Command") then
						GUI:PlaySound("Click")
						hwnd_NewCommandWindow.should_draw = true
					end
				end

				ImGui.EndPopup()
			end

			::continue::
		end
		ImGui.EndListBox()
	end
end

local function DrawScenes()
	if (not Backend.debug_mode) then
		ImGui.Dummy(1, 60)
		ImGui.SetWindowFontScale(1.2)
		ImGui.Text("Coming soon.")
		ImGui.SetWindowFontScale(1.0)
		return
	end

	if (ImGui.BeginListBox("##synced_scenes", -1, -1)) then
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
	if not GVars.features.yim_actions.favorites or not GVars.features.yim_actions.favorites[category] then
		return
	end

	if next(GVars.features.yim_actions.favorites[category]) == nil then
		ImGui.TextWrapped(_F("You don't have any saved %s.", category or "actions of this type"))
		return
	end

	if ImGui.BeginListBox(_F("##favorite_", category), -1, -1) then
		for label, data in pairs(GVars.features.yim_actions.favorites[category]) do
			local is_selected = (s_SelectedFavoriteName == label)

			if ImGui.Selectable(data.label, is_selected) then
				s_SelectedFavoriteName = label
			end

			GUI:Tooltip("Right click to remove from favorites.")

			if is_selected then
				t_SelectedAction = Action.new(
					data,
					data.type
				)
			end

			if ImGui.IsItemHovered() and ImGui.IsItemClicked(1) then
				GUI:PlaySound("Click")
				ImGui.OpenPopup("##context_" .. label)
			end

			if ImGui.BeginPopup("##context_" .. label) then
				if ImGui.MenuItem("Remove") then
					GUI:PlaySound("Click")
					YimActions:RemoveFromFavorites(category, label)
				end

				ImGui.EndPopup()
			end
		end
		ImGui.EndListBox()
	end
end

local function DrawFavoriteActions()
	if not GVars.features.yim_actions.favorites or next(GVars.features.yim_actions.favorites) == nil then
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
			ImGui.Text(_T("GENERIC_UNAVAILABLE"))
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
			local label = _F("%s  [%s]", action.data.label, action:TypeAsString())

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
	},
	{
		label = "Scenarios",
		callback = DrawScenarios,
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
	ImGui.BeginChild("##actios_sidebar", 160, GVars.ui.window_size.y * 0.7)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	ImGui.Dummy(1, 100)

	for i, tab in ipairs(t_ActionsSidebarItems) do
		local is_selected = (i_SelectedSidebarItem == i)
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (is_selected and 30 or 0))

		if is_selected then
			local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
			ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
		end

		if ImGui.Button(tab.label, 120, 35) then
			GUI:PlaySound("Nav")
			if i_SelectedSidebarItem ~= i then
				s_SearchBuffer = ""
				t_SelectedAction = nil
			end
			i_SelectedSidebarItem = i
		end

		if is_selected then
			ImGui.PopStyleColor()
		end
	end

	ImGui.PopStyleVar(2)
	ImGui.SetWindowFontScale(0.75)
	local region        = vec2:new(ImGui.GetContentRegionAvail())
	local s_SidebarTip  = _F(_T("YAV3_STOP_BTN_HINT"), GVars.keyboard_keybinds.stop_anim)
	local _, textHeight = ImGui.CalcTextSize(s_SidebarTip, false, region.x)
	ImGui.SetCursorPos(0.0, ImGui.GetCursorPosY() + region.y - textHeight - 10)
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
	i_AnimSortByIndex, _ = ImGui.Combo(_T("GENERIC_LIST_FILTER"), i_AnimSortByIndex, t_AnimSortbyList, #t_AnimSortbyList)
	ImGui.EndDisabled()

	if (s_CurrentTab ~= "companion_anims") then
		local opts_lbl          = _T("GENERIC_OPTIONS_LABEL")
		local opts_lbl_width    = ImGui.CalcTextSize(opts_lbl)
		local style             = ImGui.GetStyle()
		local padding           = style.FramePadding.x * 2
		local opts_button_width = opts_lbl_width + padding + style.WindowPadding.x

		ImGui.SameLine()
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - opts_button_width)

		ImGui.BeginDisabled(not t_SelectedAction)
		if (GUI:Button(_T("GENERIC_OPTIONS_LABEL"))) then
			ImGui.OpenPopup("##animflags")
		end
		ImGui.EndDisabled()

		if (t_SelectedAction and ImGui.BeginPopupModal("##animflags",
				ImGuiWindowFlags.NoTitleBar
				| ImGuiWindowFlags.AlwaysAutoResize)
			) then
			GUI:QuickConfigWindow(opts_lbl, function()
				ImGui.SetNextWindowBgAlpha(0)
				ImGui.BeginChild("##flagsChild", 500, 400)
				ImGui.SeparatorText(_T("GENERIC_GENERAL_LABEL"))
				GVars.features.yim_actions.disable_props, _ = GUI:CustomToggle(_T("YAV3_DISABLE_PROPS"),
					GVars.features.yim_actions.disable_props
				)

				GVars.features.yim_actions.disable_ptfx, _ = GUI:CustomToggle(_T("YAV3_DISABLE_PTFX"),
					GVars.features.yim_actions.disable_ptfx
				)

				GVars.features.yim_actions.disable_sfx, _ = GUI:CustomToggle(_T("YAV3_DISABLE_SFX"),
					GVars.features.yim_actions.disable_sfx
				)

				ImGui.Spacing()
				ImGui.SeparatorText(_T("YAV3_ANIM_FLAGS"))
				-- ImGui.Columns was causing a resoure deadlock in YimLuaAPI.
				-- The Columns API is deprecated anyway so if we want to draw nicely alined chechboxes
				-- then we'll have to either use GridRenderer or do it manually.

				-- ImGui.Columns(2)
				-- ImGui.SetColumnWidth(0, 250)

				for name, flag in pairs(t_AnimFlags) do
					ImGui.PushID(_F("##flag_%s", name))
					flag.enabled, flag.wasClicked = ImGui.Checkbox(flag.label,
						Bit.is_set(t_SelectedAction.data.flags, flag.bit))
					ImGui.PopID()

					if (flag.bit == Enums.eAnimFlags.ENDS_IN_DEAD_POSE) then
						GUI:Tooltip("This will not do anything if the animation is looped.")
					end

					-- ImGui.NextColumn()

					if flag.wasClicked then
						GUI:PlaySound("Nav")
						local bitwiseOp = flag.enabled and Bit.set or Bit.clear
						t_SelectedAction.data.flags = bitwiseOp(t_SelectedAction.data.flags, flag.bit)
					end
				end
				-- ImGui.Columns(0)
				ImGui.EndChild()
			end, ImGui.CloseCurrentPopup)
			ImGui.EndPopup()
		end
	end
end

local function DrawPlayerTabItem()
	ImGui.BeginGroup()
	DrawActionsSidebar()
	ImGui.SameLine()
	ImGui.BeginChildEx("##main_player",
		vec2:new(0, GVars.ui.window_size.y * 0.7),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)

	if (i_SelectedSidebarItem == 1) or (i_SelectedSidebarItem == 2) then
		ImGui.SetNextItemWidth(-1)
		s_SearchBuffer, b_SearchBarUsed = ImGui.InputTextWithHint(
			"##search",
			_T("GENERIC_SEARCH_HINT"),
			s_SearchBuffer,
			128
		)
		Backend.disable_input = ImGui.IsItemActive() and not hwnd_NewCommandWindow.should_draw
	end

	DrawSidebarItems()
	ImGui.EndChild()
	ImGui.EndGroup()

	ImGui.Separator()

	ImGui.SetNextWindowBgAlpha(0.69)
	ImGui.BeginChildEx("##player_footer",
		vec2:new(0, 65),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)
	ImGui.BeginDisabled(not t_SelectedAction or YimActions:IsPlayerBusy())
	if ImGui.Button("Play", 80, 35) then
		GUI:PlaySound("Select")
		ThreadManager:Run(function()
			---@diagnostic disable-next-line
			YimActions:Play(t_SelectedAction, self.get_ped())
		end)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()

	ImGui.BeginDisabled(not YimActions:IsPedPlaying())
	if ImGui.Button("Stop", 80, 35) then
		GUI:PlaySound("Cancel")
		ThreadManager:Run(function()
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
end

local function GetMovementClipsetsFromJson()
	b_MovementListCreated = false
	if not io.exists("movementClipsetsCompact.json") then
		Notifier:ShowError(
			"Samurai's Scripts",
			"Movement Clipsets file not found!",
			true
		)
		return
	end

	local jsonFile = io.open("movementClipsetsCompact.json", "r")
	if not jsonFile then
		Notifier:ShowError(
			"Samurai's Scripts",
			"Failed to read Json!",
			true
		)
		return
	end

	local content = jsonFile:read("*all")
	jsonFile:close()

	if not content or (#content == 0) then
		Notifier:ShowError(
			"Samurai's Scripts",
			"Failed to read Json data! The file is either empty or corrupted.",
			true
		)
		return
	end

	local temp = Serializer:Decode(content)
	if (not temp or type(temp)) ~= "table" then
		Notifier:ShowError("YimActions",
			"Failed to read clipset data from Json. Are you use you have the correct file?",
			true, 5
		)
		return
	end

	ThreadManager:Run(function()
		for _, v in ipairs(temp) do
			table.insert(t_MovementClipsetsJson, v)
			yield()
		end

		table.sort(t_MovementClipsetsJson, function(a, b)
			return a.Name < b.Name
		end)
		b_MovementListCreated = (#t_MovementClipsetsJson > 0)
		temp = nil
	end)
end

local function DrawCustomMovementClipsets()
	ImGui.BeginListBox("##customMvmts", -1, -1)
	for i = 1, #t_MovementClipsets do
		local label = t_MovementClipsets[i].Name
		if (not s_MovementSearchBuffer:isempty() and not label:lower():find(s_MovementSearchBuffer:lower())) then
			goto continue
		end

		local is_selected = (t_SelectedMovementClipset == t_MovementClipsets[i])
		local is_favorite = YimActions:DoesFavoriteExist("clipsets", t_MovementClipsets[i].Name)

		if (is_favorite) then
			label = _F("* %s", t_MovementClipsets[i].Name)
			ImGui.PushStyleColor(ImGuiCol.Text, 0.8, 0.8, 0.4, 0.8)
		end

		if ImGui.Selectable(label, is_selected) then
			t_SelectedMovementClipset = t_MovementClipsets[i]
		end

		if (is_favorite) then
			ImGui.PopStyleColor()
		end

		GUI:Tooltip(_F("Right click to %s favorites.", is_favorite and "remove from" or "add to"))

		if GUI:IsItemClicked(1) then
			ImGui.OpenPopup("##custom_mvmt_" .. i)
			t_SelectedMovementClipset = t_MovementClipsets[i]
		end

		if ImGui.BeginPopup("##custom_mvmt_" .. i) then
			if is_favorite then
				if ImGui.MenuItem("Remove From Favorites") then
					GUI:PlaySound("Click")
					YimActions:RemoveFromFavorites(
						"clipsets",
						t_MovementClipsets[i].Name
					)
				end
			else
				if ImGui.MenuItem("Add To Favorites") then
					GUI:PlaySound("Click")
					YimActions:AddToFavorites(
						"clipsets",
						t_MovementClipsets[i].Name,
						t_MovementClipsets[i],
						Enums.eActionType.CLIPSET
					)
				end
			end

			ImGui.EndPopup()
		end

		::continue::
	end
	ImGui.EndListBox()
end

local function DrawJsonMovementClipsets()
	if (#t_MovementClipsetsJson == 0) then
		local exists = io.exists("movementClipsetsCompact.json")
		if not exists then
			ImGui.TextWrapped("You must download the clipsets Json file and save it to the 'scripts_config' folder.")
			ImGui.SetWindowFontScale(0.8)
			GUI:Text(s_MovementClipsetsGitHub, Color(s_GitHubLinkColor))
			ImGui.SetWindowFontScale(1.0)
			GUI:Tooltip("Right click to copy the link.")

			if ImGui.IsItemHovered() then
				s_GitHubLinkColor = "#551A8B"
			else
				s_GitHubLinkColor = "#0000EE"
			end

			if GUI:IsItemClicked(1) then
				GUI:PlaySound("Click")
				GUI:SetClipBoardText(s_MovementClipsetsGitHub)
			end
		end

		ImGui.Dummy(1, 10)

		ImGui.BeginDisabled(not exists)
		if ImGui.Button("Read From Json") then
			GUI:PlaySound("Select")
			GetMovementClipsetsFromJson()
		end
		ImGui.EndDisabled()
	else
		ImGui.BeginListBox("##jsonmvmts", -1, -1)
		if not b_MovementListCreated then
			ImGui.Text(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL"), 7.5, ImGuiSpinnerStyle.SCAN))
			ImGui.Spacing()
		end

		for i = 1, #t_MovementClipsetsJson do
			local label = t_MovementClipsetsJson[i].Name
			if (not s_MovementSearchBuffer:isempty() and not label:lower():find(s_MovementSearchBuffer:lower())) then
				goto continue
			end

			local is_selected = (t_SelectedMovementClipset == t_MovementClipsetsJson[i])
			local is_favorite = YimActions:DoesFavoriteExist("clipsets", t_MovementClipsetsJson[i].Name)

			if (is_favorite) then
				label = _F("* %s", t_MovementClipsetsJson[i].Name)
				ImGui.PushStyleColor(ImGuiCol.Text, 0.8, 0.8, 0.4, 0.8)
			end

			ImGui.BeginDisabled(not b_MovementListCreated)
			if ImGui.Selectable(label, is_selected) then
				t_SelectedMovementClipset = t_MovementClipsetsJson[i]
			end
			ImGui.EndDisabled()

			if (is_favorite) then
				ImGui.PopStyleColor()
			end

			if (b_MovementListCreated) then
				GUI:Tooltip(_F("Right click to %s favorites.", is_favorite and "remove from" or "add to"))
			end

			if GUI:IsItemClicked(1) then
				GUI:PlaySound("Click")
				ImGui.OpenPopup("##context_" .. i)
				t_SelectedMovementClipset = t_MovementClipsetsJson[i]
			end

			if ImGui.BeginPopup("##context_" .. i) then
				if is_favorite then
					if ImGui.MenuItem("Remove From Favorites") then
						GUI:PlaySound("Click")
						YimActions:RemoveFromFavorites(
							"clipsets",
							t_MovementClipsetsJson[i].Name
						)
					end
				else
					if ImGui.MenuItem("Add To Favorites") then
						GUI:PlaySound("Click")
						YimActions:AddToFavorites(
							"clipsets",
							t_MovementClipsetsJson[i].Name,
							t_MovementClipsetsJson[i],
							Enums.eActionType.CLIPSET
						)
					end
				end

				ImGui.EndPopup()
			end

			::continue::
		end
		ImGui.EndListBox()
	end
end

local function DrawFavoriteMovementClipsets()
	if not GVars.features.yim_actions.favorites or not GVars.features.yim_actions.favorites.clipsets then
		return
	end

	local favs = GVars.features.yim_actions.favorites.clipsets
	if next(favs) == nil then
		ImGui.TextWrapped(("You don't have any saved clipsets."))
		return
	end

	if ImGui.BeginListBox(("##favorite_clipsets"), -1, -1) then
		for label, data in pairs(favs) do
			local is_selected = (t_SelectedMovementClipset == data)

			if ImGui.Selectable(data.Name, is_selected) then
				t_SelectedMovementClipset = data
			end

			GUI:Tooltip("Right click to remove from favorites.")

			if GUI:IsItemClicked(1) then
				GUI:PlaySound("Click")
				ImGui.OpenPopup("##context_" .. label)
				t_SelectedMovementClipset = data
			end

			if ImGui.BeginPopup("##context_" .. label) then
				if ImGui.MenuItem("Remove") then
					GUI:PlaySound("Click")
					YimActions:RemoveFromFavorites("clipsets", label)
				end

				ImGui.EndPopup()
			end
		end
		ImGui.EndListBox()
	end
end

local b_CustomMvmmtClicked = false
local b_JsonMvmtClicked = false
local b_FavMvmtsClicked = false
local function DrawMovementOptions()
	ImGui.Spacing()
	ImGui.Spacing()
	i_MovementCategory, b_CustomMvmmtClicked = ImGui.RadioButton("Custom Movements", i_MovementCategory, 0)

	if b_CustomMvmmtClicked then
		GUI:PlaySound("Nav")
		s_MovementSearchBuffer = ""
	end

	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()

	i_MovementCategory, b_JsonMvmtClicked = ImGui.RadioButton("All Movement Clipsets", i_MovementCategory, 1)

	if b_JsonMvmtClicked then
		GUI:PlaySound("Nav")
		s_MovementSearchBuffer = ""
	end

	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()

	i_MovementCategory, b_FavMvmtsClicked = ImGui.RadioButton("Favorites", i_MovementCategory, 2)

	if b_FavMvmtsClicked then
		GUI:PlaySound("Nav")
		s_MovementSearchBuffer = ""
	end

	ImGui.BeginChildEx("##movementClipsets", vec2:new(0, GVars.ui.window_size.y * 0.6), ImGuiChildFlags.Borders)
	if i_MovementCategory < 2 then
		ImGui.SetNextItemWidth(-1)
		ImGui.BeginDisabled((i_MovementCategory == 1) and not b_MovementListCreated)
		s_MovementSearchBuffer, _ = ImGui.InputTextWithHint("##mvmtsearch",
			"Search",
			s_MovementSearchBuffer,
			128
		)
		ImGui.EndDisabled()
		Backend.disable_input = ImGui.IsItemActive()
	end

	if (i_MovementCategory == 0) then
		DrawCustomMovementClipsets()
	elseif (i_MovementCategory == 1) then
		DrawJsonMovementClipsets()
	elseif (i_MovementCategory == 2) then
		DrawFavoriteMovementClipsets()
	end
	ImGui.EndChild()

	ImGui.BeginChildEx("##mvmts_footer", vec2:new(0, 65), ImGuiChildFlags.Borders)
	ImGui.BeginDisabled(not t_SelectedMovementClipset)
	if ImGui.Button(_T("GENERIC_APPLY"), 80, 35) then
		GUI:PlaySound("Select")
		---@diagnostic disable-next-line
		Self:SetMovementClipset(t_SelectedMovementClipset, i_MovementCategory == 1)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()

	if ImGui.Button(_T("GENERIC_RESET"), 80, 35) then
		GUI:PlaySound("Cancel")
		Self:ResetMovementClipsets()
	end
	ImGui.EndChild()
end

local function DrawCompanionActionsSearchBar()
	ImGui.SetNextItemWidth(-1)
	s_SearchBuffer, b_SearchBarUsed = ImGui.InputTextWithHint(
		"##search_companion_anims",
		_T("GENERIC_SEARCH_HINT"),
		s_SearchBuffer,
		128
	)
	Backend.disable_input = ImGui.IsItemActive()
end

local function DrawCompanions()
	local region            = vec2:new(ImGui.GetContentRegionAvail())
	local controlButtonSize = vec2:new(160, 32)
	local style             = ImGui.GetStyle()
	local height            = region.y * 0.4
	local width             = region.x - controlButtonSize.x - (style.ItemSpacing.x * 3)

	ImGui.BeginChildEx("##spawned_companions",
		vec2:new(width, height),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)
	if next(CompanionMgr.Companions) == nil then
		ImGui.Text("No companions spawned.")
	else
		-- do we really need a searchbar for spawned peds too?
		if ImGui.BeginListBox("##spawned_companions", -1, -1) then
			for i, companion in pairs(CompanionMgr.Companions) do
				if ImGui.Selectable(_F("%s [%d]", companion.name, companion.handle), (i_CompanionIndex == i)) then
					i_CompanionIndex = i
					unk_SelectedCompanion = companion
				end

				if GUI:IsItemClicked(1) then
					ImGui.OpenPopup("##companion_controls_" .. i)
					i_CompanionIndex = i
				end

				if ImGui.BeginPopup("##companion_controls_" .. i) then
					if ImGui.MenuItem("Warp Into Vehicle") then
						ThreadManager:Run(function()
							local veh = self.get_veh()
							if (veh == 0) then
								Notifier:ShowWarning("Samurai's Scripts", "No vehicle to warp into.")
								return
							end

							GUI:PlaySound("Click")
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
	ImGui.BeginChild("##companion_controls", 0, height)
	ImGui.Dummy(1, ((height / 2) - (33 * 9)))
	if GUI:Button("Spawn Companion", { size = controlButtonSize }) then
		hwnd_PedSpawnWindow.should_draw = true
	end

	if unk_SelectedCompanion and (next(CompanionMgr.Companions) ~= nil) then
		if ImGui.Button("Remove", 160, 32) then -- AD PROFUNDIS
			GUI:PlaySound("Delete")
			ThreadManager:Run(function()
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
			GUI:PlaySound("Select")
			unk_SelectedCompanion:ToggleGodmode()
		end

		if ImGui.Button(
				("%s"):format(
					unk_SelectedCompanion.armed and "Disarm" or "Arm"
				),
				160,
				35
			) then
			GUI:PlaySound("Select")
			unk_SelectedCompanion:ToggleWeapon()
		end
		GUI:Tooltip(
			_F(
				"%s",
				unk_SelectedCompanion.armed and
				"Remove your companion's weapon." or
				"Give your companion a tactical SMG."
			)
		)

		ImGui.BeginDisabled(not t_SelectedAction)
		if ImGui.Button("Play", 160, 32) then -- AVE IMPERATOR, MORITURI TE SALUTANT
			GUI:PlaySound("Select")
			ThreadManager:Run(function()
				YimActions:Play(t_SelectedAction, unk_SelectedCompanion.handle)
			end)
		end

		ImGui.BeginDisabled(not YimActions:IsPedPlaying(unk_SelectedCompanion.handle))
		if ImGui.Button("Stop", 160, 32) then
			GUI:PlaySound("Cancel")
			ThreadManager:Run(function()
				YimActions:Cleanup(unk_SelectedCompanion.handle)
			end)
		end
		ImGui.EndDisabled()

		ImGui.BeginDisabled(#CompanionMgr.Companions <= 1)
		if ImGui.Button("All Play", 160, 32) then
			GUI:PlaySound("Select")
			ThreadManager:Run(function()
				CompanionMgr:AllCompanionsPlay(t_SelectedAction)
			end)
		end
		ImGui.EndDisabled()
		ImGui.EndDisabled()

		ImGui.BeginDisabled(#CompanionMgr.Companions <= 1 or not CompanionMgr:AreAnyCompanionsPlaying())
		if ImGui.Button("Stop All", 160, 32) then
			GUI:PlaySound("Cancel")
			ThreadManager:Run(function()
				CompanionMgr:StopAllCompanions()
			end)
		end
		ImGui.EndDisabled()

		ImGui.BeginDisabled(#CompanionMgr.Companions == 0)
		if ImGui.Button("Bring All", 160, 32) then
			GUI:PlaySound("Cancel")
			ThreadManager:Run(function()
				CompanionMgr:BringAllCompanions()
			end)
		end
		ImGui.EndDisabled()
	end
	ImGui.EndChild()

	ImGui.Spacing()
	ImGui.SeparatorText("Companion Actions")
	ImGui.BeginChildEx("##companion_actions_child",
		vec2:new(0, 335),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)

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

	ImGui.BeginChildEx("##player_footer_2",
		vec2:new(0, 65),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	if i_CompanionActionCategory > 0 and i_CompanionActionCategory <= 2 then
		ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)
		ImGui.BeginDisabled(not t_SelectedAction)
		if ImGui.Button("Play", 80, 35) then
			GUI:PlaySound("Select")
			ThreadManager:Run(function()
				YimActions:Play(t_SelectedAction)
			end)
		end
		GUI:Tooltip("Play it yourself.")
		ImGui.EndDisabled()

		ImGui.SameLine()

		ImGui.BeginDisabled(not YimActions:IsPedPlaying())
		if ImGui.Button("Stop", 80, 35) then
			GUI:PlaySound("Cancel")
			ThreadManager:Run(function()
				YimActions:Cleanup()
			end)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()

		if i_CompanionActionCategory == 1 then
			DrawAnimOptions()
		end
		ImGui.PopStyleVar()
	end

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
			GUI:PlaySound("Cancel")
			hwnd_PedSpawnWindow.should_draw = false
		end

		ImGui.Separator()
		ImGui.Dummy(1, 10)

		ImGui.BeginChildEx("##ped_spawn_list", vec2:new(440, 400), ImGuiChildFlags.Borders)
		ImGui.SetNextItemWidth(-1)
		s_PedSearchBuffer, _ = ImGui.InputTextWithHint(
			"##search",
			"Search",
			s_PedSearchBuffer,
			128
		)
		Backend.disable_input = ImGui.IsItemActive()

		if ImGui.BeginListBox("##ped_list", -1, -1) then
			for model, data in pairs(t_GamePeds) do
				if (not s_PedSearchBuffer:isempty() and not model:lower():find(s_PedSearchBuffer:lower())) then
					goto continue
				end

				if ImGui.Selectable(model, (s_SelectedPed == model)) then
					s_SelectedPed = model
				end

				if ImGui.IsItemHovered() and b_PreviewPeds then
					i_HoveredPedModelThisFrame = data.model_hash
				end

				::continue::
			end
			ImGui.EndListBox()
		end

		if b_PreviewPeds and i_HoveredPedModelThisFrame ~= 0 then
			PreviewService:OnTick(i_HoveredPedModelThisFrame, Enums.eEntityType.Ped)
		end
		ImGui.EndChild()

		ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)

		b_SpawnInvincible, _ = GUI:CustomToggle("Spawn Invincible", b_SpawnInvincible)

		ImGui.SameLine()

		b_SpawnArmed, _ = GUI:CustomToggle("Spawn Armed", b_SpawnArmed)

		ImGui.SameLine()

		b_PreviewPeds, _ = GUI:CustomToggle("Preview", b_PreviewPeds)

		ImGui.Spacing()

		ImGui.BeginDisabled(not t_GamePeds[s_SelectedPed])
		if ImGui.Button("Spawn", 80, 35) then
			GUI:PlaySound("Select")
			ThreadManager:Run(function()
				CompanionMgr:SpawnCompanion(
					t_GamePeds[s_SelectedPed].model_hash,
					s_SelectedPed,
					b_SpawnInvincible,
					b_SpawnArmed,
					false
				)

				if (GVars.features.yim_actions.auto_close_ped_window) then
					hwnd_PedSpawnWindow.should_draw = false
				end
			end)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()
		ImGui.Spacing()
		ImGui.SameLine()

		GVars.features.yim_actions.auto_close_ped_window, _ = GUI:CustomToggle(
			"Auto-Close Window",
			GVars.features.yim_actions.auto_close_ped_window
		)

		ImGui.PopStyleVar()

		if (PreviewService.m_current and (not ImGui.IsAnyItemHovered() or not b_PreviewPeds)) then
			i_HoveredPedModelThisFrame = nil
			PreviewService:Clear()
		end

		ImGui.End()
	end
end

local function YAV3UI()
	ImGui.BeginDisabled(hwnd_NewCommandWindow.should_draw)
	if ImGui.BeginTabBar("yimactionsv3") then
		if ImGui.BeginTabItem("Actions") then
			s_CurrentTab = "main_actions"
			DrawPlayerTabItem()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Movement Styles") then
			s_CurrentTab = "main_movements"
			DrawMovementOptions()
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

		if Backend.debug_mode then
			if ImGui.BeginTabItem("Debug") then
				s_CurrentTab = "yav3_dbg"
				YimActions.Debugger:Draw()
				ImGui.EndTabItem()
			end
		end

		OnTabItemSwitch()
		ImGui.EndTabBar()
	end
	ImGui.EndDisabled()

	DrawNewCommandWindow()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_EXTRA, "YimActions", YAV3UI)
BuildDataLists()
