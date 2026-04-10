-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local WeaponBrowser     = require("includes.services.asset_browsers.WeaponBrowser").new()
local PedBrowser        = require("includes.services.asset_browsers.PedBrowser").new({
	max_entries         = 250,
	humans_only         = true,
	show_preview        = true,
	show_gender_filters = true,
	show_type_filters   = true,
})

local BS                = BillionaireServices
local godmode           = false
local noRagdoll         = false
local allWeapons        = false
local weaponHash        = 0
local bodyguardIdx      = 0
local nameBuff          = ""
local currentTab        = ""
local currentFooter     = nil

---@type RawPedData?
local selectedPed       = nil

---@type Bodyguard?
local selectedBodyguard = nil

local function drawSpawnFooter()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##bgFooter", 0, 280)

	ImGui.SeparatorText(_T("GENERIC_PREFERENCES_LABEL"))

	ImGui.BeginDisabled(not selectedPed)

	godmode = GUI:CustomToggle(_T("GENERIC_INVINCIBLE"), godmode)

	ImGui.SameLine()
	noRagdoll = GUI:CustomToggle(_T("GENERIC_NORAGDOLL"), noRagdoll)

	ImGui.SetNextItemWidth(280)
	nameBuff = ImGui.InputTextWithHint("##bgname", _T("GENERIC_NAME"), nameBuff, 128)

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_RANDOM")) and selectedPed) then
		nameBuff = BS:GetRandomPedName(selectedPed.ped_gender)
	end

	ImGui.SeparatorText(_T("BSV2_WEAPONS_LABEL"))

	allWeapons = GUI:CustomToggle(_T("BSV2_GIVE_ALL_WEAPONS"), allWeapons)

	if (not allWeapons) then
		weaponHash = WeaponBrowser:Draw()
	end

	ImGui.Separator()

	if (GUI:Button(_T("BSV2_CALL"), { size = vec2:new(80, 35) })) then
		if (not selectedPed) then
			return
		end

		BS:SpawnBodyguard(
			selectedPed.model_hash,
			#nameBuff > 0
			and nameBuff
			or BS:GetRandomPedName(selectedPed.ped_gender),
			nil,
			allWeapons or weaponHash,
			godmode,
			noRagdoll,
			1
		)
		nameBuff = ""
	end
	ImGui.EndDisabled()
	ImGui.EndChild()
end

local function drawSpawnedBodyguards()
	if (ImGui.BeginListBox("##guardlist", -1, -1)) then
		if (next(BS.Bodyguards) == nil) then
			ImGui.Text(_T("BSV2_BG_SPAWNED_NONE"))
			ImGui.EndListBox()
			return
		end

		for i, guard in pairs(BS.Bodyguards) do
			ImGui.PushID(i)
			local is_selected = (bodyguardIdx == i)
			if (ImGui.Selectable(guard.name, is_selected)) then
				bodyguardIdx = i
			end
			GUI:Tooltip(_T("GENERIC_RIGHT_CLICK_TT"))

			if (GUI:IsItemClicked(0)) then
				GUI:PlaySound("Nav")
			end

			if (GUI:IsItemClicked(1)) then
				GUI:PlaySound("Click")
				ImGui.OpenPopup("bodyguard_options")
			end

			if (is_selected) then
				selectedBodyguard = guard
				ImGui.SetItemDefaultFocus()
			end

			if (ImGui.BeginPopup("bodyguard_options")) then
				ImGui.BeginDisabled(guard.wasDismissed)

				if (ImGui.MenuItem(_T("GENERIC_BRING"))) then
					GUI:PlaySound("Select")
					ThreadManager:Run(function() guard:Bring(nil, true) end)
				end

				if (ImGui.MenuItem(_T("GENERIC_WARP_INTO_VEH"))) then
					ThreadManager:Run(function()
						if (LocalPlayer:IsOnFoot()) then
							Notifier:ShowError("Billionaire Services", _T("GENERIC_NOT_IN_VEH"))
							return
						end
						guard:WarpIntoPlayerVeh()
					end)
				end

				if (ImGui.MenuItem(_T("GENERIC_KILL"))) then
					GUI:PlaySound("Select")
					ThreadManager:Run(function()
						ENTITY.SET_ENTITY_HEALTH(guard.m_handle, 0, 0, 0)
					end)
				end

				if (ImGui.MenuItem(_T("GENERIC_DISMISS"))) then
					GUI:PlaySound("Cancel")
					BS:DismissBodyguard(guard)
				end

				ImGui.EndDisabled()
				ImGui.EndPopup()
			end
		end
		ImGui.EndListBox()
	end
end

local function drawSpawnedBodyguardsFooter()
	selectedBodyguard = BS.Bodyguards[bodyguardIdx]
	if (not selectedBodyguard) then
		return
	end

	ImGui.Dummy(1, 10)
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##SpawnedBgFooter", 0, 140)
	ImGui.SetWindowFontScale(1.12)
	ImGui.SeparatorText(selectedBodyguard.name)
	ImGui.SetWindowFontScale(1.0)

	ImGui.Dummy(1, 5)

	ImGui.BulletText(_F("Status: %s", selectedBodyguard:GetTaskAsString()))

	ImGui.Spacing()

	ImGui.BeginDisabled(selectedBodyguard.wasDismissed)
	if (GUI:Button(_T("GENERIC_DISMISS"), { size = vec2:new(80, 35) })) then
		BS:DismissBodyguard(selectedBodyguard)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled(table.getlen(BS.Bodyguards) <= 1)
	if (GUI:Button(_T("GENERIC_DISMISS_ALL"))) then
		BS:Dismiss(BS.SERVICE_TYPE.BODYGUARD)
	end
	ImGui.EndDisabled()
	ImGui.EndChild()
end

---@return string tabName, function? footer
return function()
	if (ImGui.BeginTabBar("##bodyguardsUI")) then
		if (ImGui.BeginTabItem(_T("GENERIC_SPAWN"))) then
			selectedPed   = PedBrowser:Draw(vec2:zero())
			currentTab    = "BG_SPAWN"
			currentFooter = drawSpawnFooter
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("BSV2_BG_SPAWNED_TAB"))) then
			drawSpawnedBodyguards()
			currentTab    = "BG_SPAWNED"
			currentFooter = drawSpawnedBodyguardsFooter
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end

	return currentTab, currentFooter
end
