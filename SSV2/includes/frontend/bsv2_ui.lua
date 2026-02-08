-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PrivateHeli                = require("includes.modules.PrivateHeli")
local PrivateJet                 = require("includes.modules.PrivateJet")
local PrivateLimo                = require("includes.modules.PrivateLimo")
local t_GamePeds                 = require("includes.data.peds")
local PreviewService             = require("includes.services.PreviewService")
local Weapons                    = require("includes.data.weapons")
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

---@type array<{name: string, list?: array<hash>}>
local t_WeaponCategories         = {
	{ name = "None" },
	{ name = "Melee",          list = Weapons.Melee },
	{ name = "Pistols",        list = Weapons.Pistols },
	{ name = "SMGs",           list = Weapons.SMG },
	{ name = "Shotguns",       list = Weapons.Shotguns },
	{ name = "Assault Rifles", list = Weapons.AssaultRifles },
	{ name = "Machine Guns",   list = Weapons.MachineGuns },
	{ name = "Sniper Rifles",  list = Weapons.SniperRifles },
	{ name = "Heavy Weapons",  list = Weapons.Heavy },
	{ name = "Throwables",     list = Weapons.Throwables },
	{ name = "Miscellaneous",  list = Weapons.Misc },
}
-- local t_NewEscortGroup           = {
-- 	name = "N/A",
-- 	vehicleModel = 0,
-- 	members = {
-- 		{
-- 			modelHash = 0,
-- 			name = "N/A",
-- 			weapon = 0,
-- 		},
-- 		{
-- 			modelHash = 0,
-- 			name = "N/A",
-- 			weapon = 0,
-- 		},
-- 		{
-- 			modelHash = 0,
-- 			name = "N/A",
-- 			weapon = 0,
-- 		},
-- 	}
-- }

local BS                         = BillionaireServices
local t_FilteredEscortGroups     = GVars.features.bsv2.escort_groups
local t_SelectedHeliPresetDest   = PrivateHeli.PresetDestinations[i_HeliPresetDestIndex]

---@type Bodyguard
-- spawned bodyguard
local unk_SelectedBodyguard

local function CreatePedList()
	ThreadManager:Run(function()
		-- this whole function is retarded
		if (#t_CustomPedList > 0) then
			return
		end

		for name, ped in pairs(t_GamePeds) do
			local gender = ped.ped_gender
			if (gender < 2) then
				table.insert(
					t_CustomPedList,
					{
						modelName = name,
						modelHash = ped.model_hash,
						gender = gender,
					}
				)
			end
		end

		table.sort(t_CustomPedList, function(a, b)
			return a.modelName < b.modelName
		end)

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

		for _, group in ipairs(GVars.features.bsv2.escort_groups) do
			if string.find(group.name:lower(), s_SearchBuffer:lower()) then
				table.insert(t_FilteredEscortGroups, group)
			end
		end
	else
		t_FilteredEscortGroups = GVars.features.bsv2.escort_groups
	end
end

local function OnTabItemSwitch()
	if s_CurrentTab ~= s_PreviousTab then
		GUI:PlaySound("Nav")
		s_PreviousTab     = s_CurrentTab
		s_SearchBuffer    = ""
		i_PedListIndex    = 0
		i_PedSortByIndex  = 0
		t_SelectedPed     = nil
		t_FilteredPedList = t_CustomPedList
	end

	if t_MainUIfooter[s_CurrentTab] and type(t_MainUIfooter[s_CurrentTab]) == "function" then
		t_MainUIfooter[s_CurrentTab]()
	end
end

local function BodyguardSpawnFooter()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##bgFooter", 0, 260)
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
		GUI:PlaySound("Select")
		s_BodyguardNameBuffer = BS:GetRandomPedName(t_SelectedPed.gender)
	end

	b_BodyguardGodmode, _ = ImGui.Checkbox("God Mode", b_BodyguardGodmode)
	if GUI:IsItemClicked(0) then
		GUI:PlaySound("Nav")
	end

	ImGui.SameLine()

	b_BodyguardNoRagdoll, _ = ImGui.Checkbox("No Ragdoll", b_BodyguardNoRagdoll)
	if GUI:IsItemClicked(0) then
		GUI:PlaySound("Nav")
	end

	ImGui.SeparatorText("Weapons")

	if not b_BodyguardAllWeapons then
		ImGui.PushItemWidth(200)
		if ImGui.BeginCombo("Category", t_WeaponCategories[i_WeaponCategoryIndex].name) then
			for i, cat in ipairs(t_WeaponCategories) do
				if (not cat.list) then
					goto continue
				end

				local is_selected = (i_WeaponCategoryIndex == i)
				if ImGui.Selectable(cat.name, is_selected) then
					i_WeaponCategoryIndex = i
				end

				if GUI:IsItemClicked(0) then
					GUI:PlaySound("Nav")
					t_WeaponList = cat.list
				end

				if is_selected then
					ImGui.SetItemDefaultFocus()
				end

				::continue::
			end
			ImGui.EndCombo()
		end

		if t_WeaponList and #t_WeaponList > 0 then
			ImGui.SameLine()

			if ImGui.BeginCombo("Weapon", Game.GetWeaponDisplayName(t_WeaponList[i_WeaponIndex])) then
				for i, wpn_hash in ipairs(t_WeaponList) do
					local wpn_name = Game.GetWeaponDisplayName(wpn_hash)
					local is_selected = (i_WeaponIndex == i)
					if ImGui.Selectable(wpn_name, is_selected) then
						i_WeaponIndex = i
					end

					if GUI:IsItemClicked(0) then
						GUI:PlaySound("Nav")
						i_SelectedBodyguardWeapon = wpn_hash
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

	ImGui.SameLine()
	b_BodyguardAllWeapons, _ = GUI:CustomToggle("Give All Weapons", b_BodyguardAllWeapons)

	ImGui.Separator()

	if ImGui.Button("Call", 80, 35) then
		GUI:PlaySound("Select")
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
		ImGui.BeginChild("##SpawnedBgFooter", 0, 140)
		ImGui.SetWindowFontScale(1.12)
		ImGui.SeparatorText(unk_SelectedBodyguard.name)
		ImGui.SetWindowFontScale(1.0)

		ImGui.Dummy(1, 5)

		ImGui.BulletText(_F("Status: %s", unk_SelectedBodyguard:GetTaskAsString()))

		ImGui.Spacing()

		ImGui.BeginDisabled(unk_SelectedBodyguard.wasDismissed)
		if ImGui.Button("Dismiss", 80, 35) then
			GUI:PlaySound("Cancel")
			BS:DismissBodyguard(unk_SelectedBodyguard)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()

		ImGui.BeginDisabled(table.getlen(BS.Bodyguards) <= 1)
		if ImGui.Button("Dismiss All", 100, 35) then
			GUI:PlaySound("Cancel")
			BS:Dismiss(BS.SERVICE_TYPE.BODYGUARD)
		end
		ImGui.EndDisabled()
		ImGui.EndChild()
	end
end

local function EscortGroupSpawnFooter()
	ImGui.Dummy(1, 10)
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##escortGroupFooter", 0, 160)
	ImGui.SetWindowFontScale(1.12)
	ImGui.SeparatorText("Member Preferences")
	ImGui.SetWindowFontScale(1.0)

	ImGui.Dummy(1, 5)
	ImGui.BeginDisabled(next(t_SelectedEscortGroup) == nil)
	b_BodyguardGodmode, _ = ImGui.Checkbox("God Mode##escorts", b_BodyguardGodmode)
	if GUI:IsItemClicked(0) then
		GUI:PlaySound("Nav")
	end

	ImGui.SameLine()

	b_BodyguardNoRagdoll, _ = ImGui.Checkbox("No Ragdoll##escorts", b_BodyguardNoRagdoll)
	if GUI:IsItemClicked(0) then
		GUI:PlaySound("Nav")
	end

	ImGui.Spacing()

	ImGui.Separator()

	if ImGui.Button("Summon##escorts", 90, 40) then
		GUI:PlaySound("Select")
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
		ImGui.BeginChild("##SpawnedGroupsFooter", 0, 0)
		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()
		ImGui.BeginDisabled(table.getlen(BS.EscortGroups) <= 1)
		if ImGui.Button("Dismiss All", 100, 35) then
			GUI:PlaySound("Cancel")
			BS:Dismiss(BS.SERVICE_TYPE.ESCORT)
		end
		ImGui.EndDisabled()
		ImGui.EndChild()
	end
end

local function DrawBodyguards()
	Backend.disable_input = b_BodyguardInputText1 or b_BodyguardInputText2

	if ImGui.BeginTabBar("bodyguards UI") then
		if ImGui.BeginTabItem("Spawn") then
			if (#t_CustomPedList == 0) then
				CreatePedList()
				ImGui.EndTabItem()
				ImGui.EndTabBar()
				return
			end

			s_CurrentTab                 = "Spawn Bodyguards"
			t_MainUIfooter[s_CurrentTab] = BodyguardSpawnFooter

			ImGui.SetNextItemWidth(-1)
			s_SearchBuffer, b_SearchBarUsed = ImGui.InputTextWithHint(
				"##searchPeds",
				_T("GENERIC_SEARCH_HINT"),
				s_SearchBuffer,
				128
			)
			b_BodyguardInputText1 = ImGui.IsItemActive()

			ImGui.BulletText("Gender: ")
			ImGui.SameLine()
			i_PedSortByIndex, _ = ImGui.RadioButton("All", i_PedSortByIndex, 3)
			ImGui.SameLine()
			i_PedSortByIndex, _ = ImGui.RadioButton("Male", i_PedSortByIndex, 0)
			ImGui.SameLine()
			i_PedSortByIndex, _ = ImGui.RadioButton("Female", i_PedSortByIndex, 1)

			b_PedPreview, _ = ImGui.Checkbox("Preview", b_PedPreview)
			if GUI:IsItemClicked(0) then
				GUI:PlaySound("Nav")
			end

			if ImGui.BeginListBox("##pedlist", -1, -1) then
				for i, ped in ipairs(t_FilteredPedList) do
					if (i_PedSortByIndex < 3 and ped.gender ~= i_PedSortByIndex) then
						goto continue
					end

					local is_selected = (i_PedListIndex == i)
					if ImGui.Selectable(ped.modelName, is_selected) then
						i_PedListIndex = i
					end

					if ImGui.IsItemHovered() and b_PedPreview then
						i_HoveredPedModelThisFrame = ped.modelHash
					end

					if GUI:IsItemClicked(0) then
						GUI:PlaySound("Nav")
					end

					if is_selected then
						t_SelectedPed = ped
					end

					::continue::
				end
				ImGui.EndListBox()
			end

			if b_PedPreview and i_HoveredPedModelThisFrame ~= 0 then
				PreviewService:OnTick(i_HoveredPedModelThisFrame, Enums.eEntityType.Ped)
			end
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Spawned Bodyguards") then
			s_CurrentTab = "Spawned Bodyguards"
			t_MainUIfooter[s_CurrentTab] = SpawnedBodyguardsFooter

			if ImGui.BeginListBox("##guardlist", -1, -1) then
				if next(BS.Bodyguards) == nil then
					ImGui.Text("You haven't spawned any bodyguards.")
					ImGui.EndListBox()
					ImGui.EndTabItem()
					ImGui.EndTabBar()
					return
				end

				for i, guard in pairs(BS.Bodyguards) do
					local is_selected = (i_SpawnedBodyguardIndex == i)

					if ImGui.Selectable(guard.name, is_selected) then
						i_SpawnedBodyguardIndex = i
					end
					GUI:Tooltip("Right click for more options")

					if GUI:IsItemClicked(0) then
						GUI:PlaySound("Nav")
					end

					if GUI:IsItemClicked(1) then
						GUI:PlaySound("Click")
						ImGui.OpenPopup(_F("bodyguard_options##%d", i))
					end

					if is_selected then
						unk_SelectedBodyguard = guard
						ImGui.SetItemDefaultFocus()
					end

					if ImGui.BeginPopup(_F("bodyguard_options##%d", i)) then
						if ImGui.MenuItem("Bring") then
							GUI:PlaySound("Select")
							ThreadManager:Run(function()
								guard:Bring(nil, true)
							end)
						end

						if ImGui.MenuItem("Warp Into Vehicle") then
							ThreadManager:Run(function()
								guard:WarpIntoPlayerVeh()
							end)
						end

						if ImGui.MenuItem("Kill") then
							GUI:PlaySound("Select")
							ThreadManager:Run(function()
								ENTITY.SET_ENTITY_HEALTH(guard.m_handle, 0, 0, 0)
							end)
						end

						if ImGui.MenuItem("Dismiss") then
							GUI:PlaySound("Cancel")
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

local b_DSnormal     = false
local b_DSaggressive = false
local function DrawEscorts()
	if ImGui.BeginTabBar("escorts UI") then
		if ImGui.BeginTabItem("Spawn##escorts") then
			s_CurrentTab                 = "Spawn Escorts"
			t_MainUIfooter[s_CurrentTab] = EscortGroupSpawnFooter

			ImGui.SetNextItemWidth(-1)
			s_SearchBuffer, b_SearchBarUsed = ImGui.InputTextWithHint(
				"##searchEscorts",
				_T("GENERIC_SEARCH_HINT"),
				s_SearchBuffer,
				128
			)
			Backend.disable_input = ImGui.IsItemActive()

			if ImGui.BeginListBox("##escortGroupList", -1, -1) then
				for i, group in ipairs(t_FilteredEscortGroups) do
					local is_selected = (i_EscortGroupIndex == i)

					if ImGui.Selectable(group.name, is_selected) then
						i_EscortGroupIndex = i
					end

					if GUI:IsItemClicked(0) then
						GUI:PlaySound("Nav")
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
				ImGui.EndTabItem()
				ImGui.EndTabBar()
				return
			end

			for _, group in pairs(BS.EscortGroups) do
				if group then
					local isOpen = (unk_EscortGroupHeaderName == group.name)

					if ImGui.Selectable(
							_F("[%s] %s",
								isOpen and "-" or "+",
								group.name
							),
							isOpen
						) then
						unk_EscortGroupHeaderName = group.name
					end

					GUI:Tooltip(group:GetTaskAsString())

					if GUI:IsItemClicked(0) then
						GUI:PlaySound("Click")
						if isOpen then
							unk_EscortGroupHeaderName = nil
						else
							unk_EscortGroupHeaderName = group.name
						end
					end

					if isOpen then
						ImGui.Indent()
						ImGui.Text(_F("Vehicle: %s", group.vehicle.name))
						ImGui.Text(_F("Group Task: %s", group:GetTaskAsString()))
						ImGui.SeparatorText(_F("Group Members (%d):", #group.members))

						for _, member in ipairs(group.members) do
							if member and member.name then
								ImGui.BulletText(member.name)
								GUI:HelpMarker(member:GetTaskAsString())
							end
						end

						ImGui.Spacing()

						if ImGui.Button(_F("Repair Vehicle##%s", group.name)) then
							GUI:PlaySound("Select")
							ThreadManager:Run(function()
								group:RepairGroupVehicle()
							end)
						end

						ImGui.SameLine()

						ImGui.BeginDisabled(group.vehicle:IsPlayerInEscortVehicle())
						if ImGui.Button(_F("Go To##%s", group.name)) then
							GUI:PlaySound("Select")
							group:BringPlayer()
						end

						ImGui.SameLine()

						if ImGui.Button(_F("Bring##%s", group.name)) then
							GUI:PlaySound("Select")
							group:Bring()
						end

						ImGui.SameLine()

						if ImGui.Button(_F("Respawn##%s", group.name)) then
							GUI:PlaySound("Select")
							BS:RespawnEscortGroup(
								group,
								b_BodyguardGodmode,
								b_BodyguardNoRagdoll
							)
						end
						ImGui.EndDisabled()

						if group.vehicle:IsPlayerInEscortVehicle() then
							if ImGui.Button(_F("Driving Options >##%s", group.name)) then
								GUI:PlaySound("Click")
								ImGui.OpenPopup(_F("escort driving options##%s", group.name))
							end

							if ImGui.BeginPopup(_F("escort driving options##%s", group.name)) then
								if ImGui.MenuItem(_F("Wander##%s", group.name)) then
									ThreadManager:Run(function()
										group:Wander()
									end)
									ImGui.CloseCurrentPopup()
								end

								if ImGui.MenuItem(_F("To Waypoint##%s", group.name)) then
									ThreadManager:Run(function()
										local v_Pos = Game.GetWaypointCoords()
										if not v_Pos then
											GUI:PlaySound("Error")
											Notifier:ShowError(
												"Samurai's Scripts",
												"[Escort Service]: No waypoint found!"
											)
											return
										end
										GUI:PlaySound("Select")
										group:GoTo(v_Pos)
									end)
									ImGui.CloseCurrentPopup()
								end

								if ImGui.MenuItem(_F("To Objective##%s", group.name)) then
									ThreadManager:Run(function()
										local b_Found, v_Pos = Game.GetObjectiveBlipCoords()
										if not b_Found then
											GUI:PlaySound("Error")
											Notifier:ShowError(
												"Samurai's Scripts",
												"[Escort Service]: No objective found!"
											)
											return
										end
										GUI:PlaySound("Select")
										group:GoTo(v_Pos)
									end)
									ImGui.CloseCurrentPopup()
								end

								ImGui.BeginDisabled(group:IsIdle())
								if ImGui.MenuItem(_F("Stop##%s", group.name)) then
									ThreadManager:Run(function()
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

								i_EscortDrivingStyle, b_DSaggressive = ImGui.RadioButton("Aggressive",
									i_EscortDrivingStyle, 2)

								if b_DSnormal or b_DSaggressive then
									GUI:PlaySound("Nav")
									group:SetDrivingStyle(i_EscortDrivingStyle)
								end
								ImGui.EndPopup()
							end
							ImGui.SameLine()
						end

						ImGui.BeginDisabled(group.wasDismissed)
						if ImGui.Button(_F("Dismiss##%s", group.name)) then
							GUI:PlaySound("Cancel")
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
		--         GUI:PlaySound("Select")
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
		--             GUI:PlaySound("Cancel")
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

	ImGui.BulletText(_F("Driver: %s", limo.driverName))
	ImGui.BulletText(_F("Status: %s", limo:GetTaskAsString()))
	ImGui.Dummy(1, 5)

	if Backend.debug_mode then
		if ImGui.Button("Parse Vehicle Mods") then
			ThreadManager:Run(function()
				local t = limo:GetMods()
				local toPrint = {}

				for i, v in ipairs(t) do
					if v ~= -1 then
						toPrint[i] = v
					end
				end

				local wheeltype, _ = limo:GetCustomWheels()
				Backend:debug(_F("\nMods = %s\nWheel Type = %s", table.serialize(toPrint, 2), wheeltype))
			end)
		end
		ImGui.SameLine()
		if ImGui.Button("Cleanup") then
			BS:RemoveLimo()
			b_LimoWasCalled = false
		end
	end

	if ImGui.Button("Repair", 100, 35) then
		GUI:PlaySound("Select")
		ThreadManager:Run(function()
			limo:Repair()
		end)
	end

	ImGui.SameLine()

	if ImGui.Button("Dismiss", 100, 35) then
		GUI:PlaySound("Cancel")
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

		if ImGui.BeginListBox("##limosList", -1, 0) then
			for name, data in pairs(PrivateLimo.Limos) do
				local is_selected = (s_LimoIndex == name)

				if ImGui.Selectable(name, is_selected) then
					s_LimoIndex = name
				end
				GUI:Tooltip(data.description or "")

				if GUI:IsItemClicked(0) then
					GUI:PlaySound("Nav")
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
			GUI:PlaySound("Select")
			BS:CallPrivateLimo(t_SelectedLimo)
			b_LimoWasCalled = true
		end
		ImGui.EndDisabled()
	else
		local v_ButtonSize = vec2:new(180, 35)
		ImGui.Dummy(1, 5)

		if not limo:IsPlayerInLimo() and not limo.isRemoteControlled then
			if ImGui.Button("Warp Into The Limo", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
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
				GUI:PlaySound("Nav")
				limo:SetDrivingStyle(i_LimoDrivingStyle)
			end

			ImGui.Spacing()
			ImGui.SeparatorText("Commands")
			ImGui.Spacing()

			ImGui.BeginDisabled(Self:GetVehicle():GetSpeed() <= 0.1 and limo:IsIdle())
			if ImGui.Button("Stop The Limo", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function()
					limo:Stop()
				end)
			end

			ImGui.SameLine()

			if ImGui.Button("Emergency Stop", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function()
					limo:EmergencyStop()
				end)
			end
			ImGui.EndDisabled()

			if ImGui.Button("Drive To Waypoint", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function(s)
					local v_Pos = Game.GetWaypointCoords()

					if not v_Pos then
						GUI:PlaySound("Error")
						Notifier:ShowError(
							"Samurai's Scripts",
							"[Limousine Service]: No waypoint found!"
						)
						return
					end

					GUI:PlaySound("Select")
					limo:GoTo(v_Pos, s)
				end)
			end

			ImGui.SameLine()

			if ImGui.Button("Drive To Objective", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function(s)
					local b_Found, v_Pos = Game.GetObjectiveBlipCoords()

					if not b_Found then
						GUI:PlaySound("Error")
						Notifier:ShowError(
							"Samurai's Scripts",
							"[Limousine Service]: No objective found!"
						)
						return
					end

					GUI:PlaySound("Select")
					limo:GoTo(v_Pos, s)
				end)
			end

			if ImGui.Button("Wander", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function(s)
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
			if ImGui.Button(_F("%s Control", verb), v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound(clickSound)
				callback(limo)
			end
			GUI:Tooltip(tt)

			ImGui.BeginDisabled(limo.isRemoteControlled)
			ImGui.Spacing()
			ImGui.SeparatorText("Seat Controls")
			ImGui.Spacing()

			if ImGui.Button("< Previous Seat", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				limo:ShuffleSeats(-1)
			end

			ImGui.SameLine()

			if ImGui.Button("Next Seat >", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				limo:ShuffleSeats(1)
			end

			ImGui.Spacing()
			ImGui.SeparatorText("Radio Controls")
			ImGui.Spacing()

			if ImGui.Button(limo.radio.isOn and "Turn Off" or "Turn On") then
				GUI:PlaySound("Click")
				ThreadManager:Run(function()
					AUDIO.SET_VEH_RADIO_STATION(
						limo:GetHandle(),
						limo.radio.isOn
						and "OFF"
						or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
					)
				end)
			end

			if (limo.radio.isOn) then
				ImGui.SameLine()
				GUI:VehicleRadioCombo(limo:GetHandle(), "limoRadioStations", limo.radio.stationName)
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

	ImGui.BulletText(_F("Pilot: %s", heli.pilotName))
	ImGui.BulletText(_F("Status: %s", heli:GetTaskAsString()))
	ImGui.Dummy(1, 5)

	ImGui.BeginDisabled(not heli.isReady)
	if ImGui.Button("Repair", 100, 35) then
		GUI:PlaySound("Select")
		heli:Repair()
	end

	ImGui.SameLine()

	if ImGui.Button("Dismiss", 100, 35) then
		GUI:PlaySound("Cancel")
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

		if ImGui.BeginListBox("##heliList", -1, 0) then
			for _, pair in pairs(PrivateHeli.Models) do
				local is_selected = (s_HeliIndex == pair.first)

				if ImGui.Selectable(pair.first, is_selected) then
					s_HeliIndex = pair.first
				end

				if GUI:IsItemClicked(0) then
					GUI:PlaySound("Nav")
				end

				if is_selected then
					i_SelectedHeliModel = pair.second
				end
			end
			ImGui.EndListBox()
		end

		ImGui.Dummy(1, 5)
		ImGui.Separator()
		ImGui.Dummy(1, 5)

		b_HeliGodMode, _ = GUI:CustomToggle("God Mode", b_HeliGodMode)

		ImGui.SameLine()

		ImGui.BeginDisabled(i_SelectedHeliModel == 0)
		if ImGui.Button("Dispatch", 100, 40) then
			GUI:PlaySound("Select")
			BS:CallPrivateHeli(i_SelectedHeliModel, b_HeliGodMode)
		end
		ImGui.EndDisabled()
	else
		local v_ButtonSize = vec2:new(180, 35)
		ImGui.Dummy(1, 5)

		if not heli:IsPlayerInHeli() then
			ImGui.BeginDisabled(heli.isPlayerRappelling or not heli.isReady)
			if ImGui.Button("Warp Into The Heli", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				heli:WarpPlayer()
			end

			ImGui.SameLine()

			ImGui.BeginDisabled(not heli.isFarAway)
			if ImGui.Button("Bring", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function(s)
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

			ImGui.BeginDisabled((heli.task == Enums.eVehicleTask.HOVER_IN_PLACE) or heli.altitude <= 3)
			if ImGui.Button("Hover Here", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function()
					heli:HoverInPlace()
				end)
			end
			ImGui.EndDisabled()

			ImGui.SameLine()

			ImGui.BeginDisabled(heli.altitude <= 3)
			if ImGui.Button("Land Here", v_ButtonSize.x, v_ButtonSize.y) then
				ThreadManager:Run(function()
					heli:LandHere()
				end)
			end
			ImGui.EndDisabled()

			if ImGui.Button("Fly To Waypoint", v_ButtonSize.x, v_ButtonSize.y) then
				ThreadManager:Run(function()
					local v_Pos = Game.GetWaypointCoords()

					if not v_Pos then
						GUI:PlaySound("Error")
						Notifier:ShowError(
							"Samurai's Scripts",
							"[Heli Service]: No waypoint found!"
						)
						return
					end

					GUI:PlaySound("Select")
					heli:FlyTo(v_Pos)
				end)
			end

			ImGui.SameLine()

			if ImGui.Button("Fly To Objective", v_ButtonSize.x, v_ButtonSize.y) then
				ThreadManager:Run(function()
					local b_Found, v_Pos = Game.GetObjectiveBlipCoords()

					if not b_Found then
						GUI:PlaySound("Error")
						Notifier:ShowError(
							"Samurai's Scripts",
							"[Heli Service]: No objective found!"
						)
						return
					end

					GUI:PlaySound("Select")
					heli:FlyTo(v_Pos)
				end)
			end

			ImGui.BeginDisabled(heli.task ~= Enums.eVehicleTask.GOTO)
			if ImGui.Button("Skip Trip", v_ButtonSize.x, v_ButtonSize.y) then
				ThreadManager:Run(function(s)
					heli:SkipTrip(s)
				end)
			end
			ImGui.EndDisabled()

			ImGui.SameLine()

			if heli.allowsRappelling then
				ImGui.SameLine()
				ImGui.BeginDisabled((heli.task ~= Enums.eVehicleTask.HOVER_IN_PLACE) or (heli.altitude < 5) or
					heli.isPlayerRappelling)
				if ImGui.Button("Rappell Down", v_ButtonSize.x, v_ButtonSize.y) then
					ThreadManager:Run(function()
						if Self:GetVehicleSeat() < 1 then
							GUI:PlaySound("Error")
							Notifier:ShowError(
								"Private Heli",
								"You can not rappell down from this seat. Please switch to one of the back seats!",
								false,
								3
							)
							return
						end

						GUI:PlaySound("Select")
						TASK.TASK_RAPPEL_FROM_HELI(Self:GetHandle(), 5.0)
					end)
				end
				ImGui.EndDisabled()
			end

			ImGui.Spacing()
			ImGui.SeparatorText("Preset Destinations")
			ImGui.Spacing()

			if ImGui.BeginCombo("##heliPresetDestinations", t_SelectedHeliPresetDest.first) then
				for i, pair in ipairs(PrivateHeli.PresetDestinations) do
					if ImGui.Selectable(pair.first, i_HeliPresetDestIndex == i) then
						i_HeliPresetDestIndex = i
					end

					if GUI:IsItemClicked(0) then
						GUI:PlaySound("Nav")
						t_SelectedHeliPresetDest = pair
					end
				end
				ImGui.EndCombo()
			end

			ImGui.SameLine()

			ImGui.BeginDisabled(not t_SelectedHeliPresetDest.second)
			if ImGui.Button("Fly To") then
				GUI:PlaySound("Select")
				ThreadManager:Run(function()
					heli:FlyTo(t_SelectedHeliPresetDest.second, true)
				end)
			end
			ImGui.EndDisabled()

			ImGui.Spacing()
			ImGui.SeparatorText("Seat Controls")
			ImGui.Spacing()

			if ImGui.Button("< Previous Seat", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				heli:ShuffleSeats(-1)
			end

			ImGui.SameLine()

			if ImGui.Button("Next Seat >", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				heli:ShuffleSeats(1)
			end

			ImGui.Spacing()
			ImGui.SeparatorText("Radio Controls")
			ImGui.Spacing()

			if ImGui.Button(heli.radio.isOn and "Turn Off" or "Turn On") then
				ThreadManager:Run(function()
					AUDIO.SET_VEH_RADIO_STATION(
						heli:GetHandle(),
						heli.radio.isOn
						and "OFF"
						or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
					)
					heli.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(heli:GetHandle())
					heli.radio.stationName = Game.GetGXTLabel(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
				end)
			end

			if heli.radio.isOn then
				ImGui.SameLine()
				GUI:VehicleRadioCombo(heli:GetHandle(), "limoRadioStations", heli.radio.stationName)
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

			if GUI:IsItemClicked(0) then
				GUI:PlaySound("Nav")
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

	ImGui.BulletText(_F("Pilot: %s", jet.pilotName))
	ImGui.BulletText(_F("Co-Pilot: %s", jet.copilotName))
	ImGui.BulletText(_F("Status: %s", jet:GetTaskAsString()))
	ImGui.Dummy(1, 5)

	if ImGui.Button("Repair", 100, 35) then
		GUI:PlaySound("Select")
		jet:Repair()
	end

	ImGui.SameLine()

	if ImGui.Button("Dismiss", 100, 35) then
		GUI:PlaySound("Cancel")
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

		if ImGui.BeginListBox("##jetList", -1, 0) then
			for name, data in pairs(PrivateJet.Jets) do
				local is_selected = (s_JetIndex == name)

				if ImGui.Selectable(name, is_selected) then
					s_JetIndex = name
				end
				GUI:Tooltip(data.description)

				if GUI:IsItemClicked(0) then
					GUI:PlaySound("Nav")
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
			GUI:PlaySound("Select")
			BS:CallPrivateJet(i_SelectedJetModel, unk_JetAirportData)
		end
		ImGui.EndDisabled()

		if JetSpawnDataNotSelected then
			GUI:Tooltip("Select a jet model and an airport.")
		end

		GUI:HelpMarker(
			"[! NOTE] Calling the jet while too far away from the airport may cause it to become invisible. Either use the button in this UI to directly warp into the jet (which will force it to become visible) or just call your jet when you're close to the airport.")
	else
		local v_ButtonSize = vec2:new(180, 35)
		ImGui.Dummy(1, 5)

		if not jet:IsPlayerInJet() then
			ImGui.BeginDisabled(not jet.canWarpPlayer)
			if ImGui.Button("Warp Into The Jet", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				jet:WarpPlayer()
			end
			ImGui.EndDisabled()

			ImGui.Spacing()
			ImGui.Text("Get in the jet to see more options.")
		else
			ImGui.Spacing()
			ImGui.SeparatorText("Commands")
			ImGui.Spacing()

			ImGui.BeginDisabled(jet.task == Enums.eVehicleTask.TAKE_OFF)
			if ImGui.Button("Fly To Waypoint", v_ButtonSize.x, v_ButtonSize.y) then
				ThreadManager:Run(function(s)
					local v_Pos = Game.GetWaypointCoords()

					if not v_Pos then
						GUI:PlaySound("Error")
						Notifier:ShowError(
							"Samurai's Scripts",
							"[Heli Service]: No waypoint found!"
						)
						return
					end

					GUI:PlaySound("Select")
					jet:FlyTo(v_Pos, s)
				end)
			end

			ImGui.SameLine()

			if ImGui.Button("Fly To Objective", v_ButtonSize.x, v_ButtonSize.y) then
				ThreadManager:Run(function(s)
					local b_Found, v_Pos = Game.GetObjectiveBlipCoords()

					if not b_Found then
						GUI:PlaySound("Error")
						Notifier:ShowError(
							"Samurai's Scripts",
							"[Heli Service]: No objective found!"
						)
						return
					end

					GUI:PlaySound("Select")
					ThreadManager:Run(function()
						jet:FlyTo(v_Pos, s)
					end)
				end)
			end
			ImGui.EndDisabled()

			ImGui.BeginDisabled(jet.task ~= Enums.eVehicleTask.GOTO)
			if ImGui.Button("Skip Trip", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function()
					jet:SkipTrip()
				end)
			end
			ImGui.EndDisabled()

			ImGui.SameLine()

			ImGui.BeginDisabled(jet.task ~= Enums.eVehicleTask.LAND)
			if ImGui.Button("Skip Landing", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				ThreadManager:Run(function()
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
				ThreadManager:Run(function(s)
					if not unk_JetAirportData then
						return
					end

					if jet.departureAirport and (jet.departureAirport.name == unk_JetAirportData.name) then
						GUI:PlaySound("Error")
						Notifier:ShowError(
							"Private Jet",
							_F(
								"You are already at %s.",
								unk_JetAirportData.name
							)
						)
						return
					end

					GUI:PlaySound("Select")
					jet.arrivalAirport = unk_JetAirportData
					Notifier:ShowMessage(
						"Private Jet",
						_F(
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
				GUI:PlaySound("Select")
				jet:ShuffleSeats(-1)
			end

			ImGui.SameLine()

			if ImGui.Button("Next Seat >", v_ButtonSize.x, v_ButtonSize.y) then
				GUI:PlaySound("Select")
				jet:ShuffleSeats(1)
			end

			ImGui.Spacing()
			ImGui.SeparatorText("Radio Controls")
			ImGui.Spacing()

			if ImGui.Button(jet.radio.isOn and "Turn Off" or "Turn On") then
				ThreadManager:Run(function()
					AUDIO.SET_VEH_RADIO_STATION(
						jet:GetHandle(),
						jet.radio.isOn
						and "OFF"
						or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
					)
					jet.radio.isOn = AUDIO.IS_VEHICLE_RADIO_ON(jet:GetHandle())
					jet.radio.stationName = Game.GetGXTLabel(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
				end)
			end

			if jet.radio.isOn then
				ImGui.SameLine()
				GUI:VehicleRadioCombo(jet:GetHandle(), "limoRadioStations", jet.radio.stationName)
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

	if (t_SelectedTab and type(t_SelectedTab.callback) == "function") then
		t_SelectedTab.callback()

		if (b_SearchBarUsed and t_SelectedTab.OnSearchBarUsed) then
			t_SelectedTab.OnSearchBarUsed()
		end
	end
end

local function DrawMainSidebar()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##main_sidebar", 160, GVars.ui.window_size.y * 0.6)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	if BS:GetServiceCount() > 1 then
		if GUI:ButtonColored(" Dismiss All ", Color("#FF0000"), Color("#EE4B2B"), Color("#880808")) then
			BS:Dismiss(BS.SERVICE_TYPE.ALL)
		end
	else
		ImGui.TextDisabled("Dismiss All")
	end
	GUI:Tooltip("Dismiss all services at once.")

	ImGui.Dummy(1, 20)

	for i, tab in ipairs(t_BillionareSidebarItems) do
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
				t_SelectedPed = nil
			end
			i_SelectedSidebarItem = i
		end

		if is_selected then
			ImGui.PopStyleColor()
		end
	end

	ImGui.PopStyleVar(2)
	ImGui.EndChild()
end

local function BSV2UI()
	ImGui.BeginGroup()
	DrawMainSidebar()
	ImGui.SameLine()
	ImGui.BeginChildEx("##main",
		vec2:new(0, GVars.ui.window_size.y * 0.6),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)
	DrawSidebarItems()
	ImGui.EndChild()
	ImGui.EndGroup()

	OnTabItemSwitch()

	if PreviewService.m_current and (not ImGui.IsAnyItemHovered() or not b_PedPreview) then
		i_HoveredPedModelThisFrame = nil
		PreviewService:Clear()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_EXTRA, "Billionaire Services", BSV2UI)
