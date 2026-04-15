-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local companionButtonSize = vec2:new(160, 32)
local CompanionMgr        = YimActions.CompanionManager
local shouldDrawPedWindow = false
local godMode             = false
local spawnArmed          = false
local currentTabName      = ""
local previousTabName     = ""
local sharedDrawFuncs     = require("includes.frontend.yim_actions.shared_draw_funcs")
local PedBrowser          = require("includes.services.asset_browsers.PedBrowser").new({
	max_entries         = 250,
	humans_only         = false,
	show_preview        = true,
	show_gender_filters = true,
	show_type_filters   = true,
})

---@type RawPedData?
local selectedPed

---@type Companion?
local selectedCompanion

---@type Action?
local selectedAction

local function OnTabItemSwitch()
	if (currentTabName ~= previousTabName) then
		GUI:PlaySound(GUI.Sounds.Nav)
		previousTabName = currentTabName
		selectedAction  = nil
	end
end

local function DrawPedSpawnWindow()
	ImGui.Begin(
		"Companion Spawner",
		ImGuiWindowFlags.AlwaysAutoResize |
		ImGuiWindowFlags.NoTitleBar |
		ImGuiWindowFlags.NoResize |
		ImGuiWindowFlags.NoScrollbar |
		ImGuiWindowFlags.NoCollapse
	)

	if (GUI:Button(_T("GENERIC_CLOSE"))) then
		shouldDrawPedWindow = false
	end

	ImGui.Separator()
	ImGui.Dummy(1, 10)

	selectedPed = PedBrowser:Draw(vec2:new(400, 400))

	godMode = GUI:CustomToggle("Spawn Invincible", godMode)

	ImGui.SameLine()
	spawnArmed = GUI:CustomToggle("Spawn Armed", spawnArmed)

	ImGui.Spacing()
	ImGui.BeginDisabled(not selectedPed)
	if (GUI:Button("Spawn", { size = vec2:new(80, 35) })) then
		if (not selectedPed) then return end
		ThreadManager:Run(function()
			CompanionMgr:SpawnCompanion(
				selectedPed.model_hash,
				Game.GetPedModelName(selectedPed.model_hash),
				godMode,
				spawnArmed,
				false
			)

			if (GVars.features.yim_actions.auto_close_ped_window) then
				shouldDrawPedWindow = false
			end
		end)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.Spacing()
	ImGui.SameLine()

	GVars.features.yim_actions.auto_close_ped_window = GUI:CustomToggle(
		"Auto-Close Window",
		GVars.features.yim_actions.auto_close_ped_window
	)

	ImGui.End()
end

return function()
	local region = vec2:new(ImGui.GetContentRegionAvail(), GVars.ui.window_size.y)
	local style  = ImGui.GetStyle()
	local height = region.y * 0.4
	local width  = region.x - companionButtonSize.x - (style.ItemSpacing.x * 3)

	ImGui.BeginChildEx("##spawned_companions",
		vec2:new(width, height),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)
	if (next(CompanionMgr.Companions) == nil) then
		ImGui.Text("No companions spawned.")
	elseif (ImGui.BeginListBox("##spawned_companions", -1, -1)) then
		for i, companion in ipairs(CompanionMgr.Companions) do
			if (ImGui.Selectable(_F("%s [%d]", companion.name, companion.handle), (companion == selectedCompanion))) then
				selectedCompanion = companion
			end

			if (ImGui.IsItemClicked(1)) then
				ImGui.OpenPopup("##companion_controls_" .. i)
				selectedCompanion = companion
			end

			if (ImGui.BeginPopup("##companion_controls_" .. i)) then
				if (ImGui.MenuItem("Warp Into Vehicle")) then
					local veh = LocalPlayer:GetVehicleNative()
					if (veh == 0) then
						Notifier:ShowWarning("Samurai's Scripts", "No vehicle to warp into.")
						return
					end

					ThreadManager:Run(function()
						TASK.TASK_WARP_PED_INTO_VEHICLE(companion.handle, veh, -2)
					end)
				end
				ImGui.EndPopup()
			end
		end
		ImGui.EndListBox()
	end
	ImGui.EndChild()

	ImGui.SameLine()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##companion_controls", 0, height)
	ImGui.Dummy(1, ((height / 2) - (33 * 9)))
	if (GUI:Button("Spawn Companion", { size = companionButtonSize })) then
		shouldDrawPedWindow = true
	end

	if (selectedCompanion and next(CompanionMgr.Companions) ~= nil) then
		if (ImGui.Button("Remove", companionButtonSize.x, companionButtonSize.y)) then -- AD PROFUNDIS
			GUI:PlaySound("Delete")
			ThreadManager:Run(function()
				CompanionMgr:RemoveCompanion(selectedCompanion)
			end)
		end

		if (GUI:Button(_F("%s God Mode", selectedCompanion.godmode and "Disable" or "Enable"), { size = companionButtonSize })) then
			selectedCompanion:ToggleGodmode()
		end

		if (GUI:Button(_F("%s", selectedCompanion.armed and "Disarm" or "Arm"), { size = companionButtonSize })) then
			selectedCompanion:ToggleWeapon()
		end
		GUI:Tooltip(_F("%s",
			selectedCompanion.armed
			and "Remove your companion's weapon."
			or "Give your companion a tactical SMG."
		))

		ImGui.BeginDisabled(not selectedAction)
		if (GUI:Button("Play", { size = companionButtonSize })) then -- AVE IMPERATOR, MORITURI TE SALUTANT
			ThreadManager:Run(function()
				YimActions:Play(selectedAction, selectedCompanion.handle)
			end)
		end

		ImGui.BeginDisabled(not YimActions:IsPedPlaying(selectedCompanion.handle))
		if (GUI:Button("Stop", { size = companionButtonSize })) then
			ThreadManager:Run(function()
				YimActions:Cleanup(selectedCompanion.handle)
			end)
		end
		ImGui.EndDisabled()

		ImGui.BeginDisabled(#CompanionMgr.Companions <= 1)
		if (GUI:Button("All Play", { size = companionButtonSize })) then
			ThreadManager:Run(function()
				CompanionMgr:AllCompanionsPlay(selectedAction)
			end)
		end
		ImGui.EndDisabled()
		ImGui.EndDisabled()

		ImGui.BeginDisabled(#CompanionMgr.Companions <= 1 or not CompanionMgr:AreAnyCompanionsPlaying())
		if (GUI:Button("Stop All", { size = companionButtonSize })) then
			ThreadManager:Run(function()
				CompanionMgr:StopAllCompanions()
			end)
		end
		ImGui.EndDisabled()

		ImGui.BeginDisabled(#CompanionMgr.Companions == 0)
		if (GUI:Button("Bring All", { size = companionButtonSize })) then
			ThreadManager:Run(function()
				CompanionMgr:BringAllCompanions()
			end)
		end
		ImGui.EndDisabled()
	end
	ImGui.EndChild()

	ImGui.SeparatorText("Companion Actions")
	ImGui.BeginChildEx("##companion_actions_child",
		vec2:new(0, 335),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)

	ImGui.BeginTabBar("##companion_actions_tabbar")
	if (ImGui.BeginTabItem("Animations##companions")) then
		currentTabName = "companion_anims"
		selectedAction = sharedDrawFuncs.DrawAnims(currentTabName)
		ImGui.EndTabItem()
	end

	if (ImGui.BeginTabItem("Scenarios##companions")) then
		currentTabName = "companion_scenarios"
		selectedAction = sharedDrawFuncs.DrawScenarios(currentTabName)
		ImGui.EndTabItem()
	end

	OnTabItemSwitch()
	ImGui.EndTabBar()
	ImGui.EndChild()

	sharedDrawFuncs.DrawPlayerFooter(selectedAction)

	if (shouldDrawPedWindow) then
		DrawPedSpawnWindow()
	end
end
