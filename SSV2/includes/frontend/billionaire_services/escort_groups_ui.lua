-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BSV2             = require("includes.features.extra.billionaire_services.BillionaireServicesV2")
local measureTextWidth = require("includes.frontend.helpers.measure_text_width")
local newGroupVehs     = require("includes.data.bsv2_data").NewGroupVehicles
local WeaponBrowser    = require("includes.services.asset_browsers.WeaponBrowser").new()
local PedBrowser       = require("includes.services.asset_browsers.PedBrowser").new({
	max_entries         = 100,
	humans_only         = true,
	show_gender_filters = false,
	show_type_filters   = false,
	show_preview        = false,
})

local drivingStyle     = {
	index      = 1,
	normal     = false,
	aggressive = false
}

local newGroup         = {
	---@type RawEscortGroupData
	---@diagnostic disable-next-line
	buffer             = {},
	stage              = 1,
	vehicle_index      = 1,
	nameBuffer         = "",
	memberNameBuffer   = "",
	memberWeaponBuffer = 0,
	---@type RawPedData?
	memberPedBuffer    = nil,
	can_progress       = false
}

---@type array<integer>
local labelWidths      = {}

---@type RawEscortGroupData?
local selectedGroup    = nil
local godMode          = false
local noRagdoll        = false
local searchBuffer     = ""
local currentTab       = ""
local currentFooter    = nil
local groupHeader      = nil


---@param buff RawEscortGroupData
---@return boolean
local function validateGroupBuffer(buff)
	if (not buff.name or not buff.vehicleModel or not buff.members) then
		return false
	end

	local members    = buff.members
	local memberSize = members and #buff.members or 0
	if (memberSize ~= 3) then return false end

	for _, member in ipairs(buff.members) do
		if (not member.modelHash) then
			return false
		end
	end

	return true
end

local function clearNewGroupBuffer()
	newGroup = {
		buffer                   = {},
		stage                    = 1,
		vehicle_index            = 1,
		nameBuffer               = "",
		memberNameBuffer         = "",
		membermemberWeaponBuffer = 0,
		---@type RawPedData?
		memberPedBuffer          = nil,
		can_progress             = false
	}
end

local function drawSpawner()
	ImGui.SetNextItemWidth(-1)
	searchBuffer = ImGui.SearchBar("##searchEscorts", searchBuffer, 0, -1, 128)
	searchBuffer = searchBuffer:lower()
	local groups = BSV2:GetEscortGroupList()

	if (ImGui.BeginListBox("##escortGroupList", -1, -1)) then
		for name, group in pairs(groups) do
			if (not searchBuffer:isempty() and not searchBuffer:contains(name:lower())) then
				goto continue
			end

			if (ImGui.Selectable(name, (selectedGroup == group))) then
				selectedGroup = group
			end

			::continue::
		end

		ImGui.EndListBox()
	end
end

local function drawSpawnerFooter()
	ImGui.Dummy(1, 10)
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##escortGroupFooter", 0, 160)
	ImGui.SetWindowFontScale(1.12)
	ImGui.SeparatorText(_T("GENERIC_PREFERENCES_LABEL"))
	ImGui.SetWindowFontScale(1.0)

	ImGui.Dummy(1, 5)
	ImGui.BeginDisabled(not selectedGroup or next(selectedGroup) == nil)
	godMode = GUI:CustomToggle(_T("GENERIC_INVINCIBLE"), godMode)

	ImGui.SameLine()
	noRagdoll = GUI:CustomToggle(_T("GENERIC_NORAGDOLL"), noRagdoll)

	ImGui.Spacing()
	ImGui.Separator()

	local lang_index = GVars.backend.language_index
	local labelWidth = labelWidths[lang_index]
	if (not labelWidth) then
		labelWidth = measureTextWidth({
			_T("BSV2_CALL"),
			_T("GENERIC_DELETE"),
		}, 10)

		labelWidths[lang_index] = labelWidth
	end

	local buttonSize = vec2:new(labelWidth, 40)
	if (GUI:Button(_T("BSV2_CALL"), { size = buttonSize })) then
		if (not selectedGroup) then return end
		BSV2:SpawnEscortGroup(selectedGroup, godMode, noRagdoll)
	end

	if (selectedGroup and selectedGroup.JSON) then
		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_DELETE"), { size = buttonSize })) then
			if (KeyManager:IsKeyPressed(eVirtualKeyCodes.SHIFT)) then
				BSV2:RemoveSavedEscortGroup(selectedGroup.name)
				selectedGroup = nil
			else
				ImGui.OpenPopup(selectedGroup.name)
			end
		end
	end
	ImGui.EndDisabled()

	if (selectedGroup and ImGui.DialogBox(
			selectedGroup.name,
			_T("BSV2_CONFIRM_DELETE_GROUP"),
			ImGuiDialogBoxStyle.WARN)
		) then
		BSV2:RemoveSavedEscortGroup(selectedGroup.name)
		selectedGroup = nil
	end
	ImGui.EndChild()
end

local function drawSpawnedGroups()
	if (next(BSV2.EscortGroups) == nil) then
		ImGui.Text(_T("BSV2_ES_SPAWNED_NONE"))
		return
	end

	for _, group in pairs(BSV2.EscortGroups) do
		local isOpen = (groupHeader == group.name)

		if (ImGui.Selectable(_F("[%s] %s", isOpen and "-" or "+", group.name), isOpen)) then
			groupHeader = group.name
		end

		GUI:Tooltip(group:GetTaskAsString())

		if (GUI:IsItemClicked(0)) then
			GUI:PlaySound("Click")
			if (isOpen) then
				groupHeader = nil
			else
				groupHeader = group.name
			end
		end

		if (isOpen) then
			ImGui.Indent()
			ImGui.Text(_F("Vehicle: %s", group.vehicle.name))
			ImGui.Text(_F("Group Task: %s", group:GetTaskAsString()))
			ImGui.SeparatorText(_F("Group Members (%d):", #group.members))

			for _, member in ipairs(group.members) do
				if (member.name) then
					ImGui.BulletText(member.name)
					GUI:HelpMarker(member:GetTaskAsString())
				end
			end

			ImGui.Spacing()

			if (GUI:Button(_F("Repair Vehicle##%s", group.name))) then
				ThreadManager:Run(function()
					group:RepairGroupVehicle()
				end)
			end

			ImGui.SameLine()

			local playerInVeh = group.vehicle:IsPlayerInEscortVehicle()
			ImGui.BeginDisabled(playerInVeh)
			if (GUI:Button(_F("Go To##%s", group.name))) then
				group:BringPlayer()
			end

			ImGui.SameLine()

			if (GUI:Button(_F("%s##%s", _T("GENERIC_BRING"), group.name))) then
				group:Bring()
			end

			ImGui.SameLine()

			if (GUI:Button(_F("%s##%s", _T("GENERIC_RESPAWN"), group.name))) then
				BSV2:RespawnEscortGroup(group, godMode, noRagdoll)
			end
			ImGui.EndDisabled()

			if (playerInVeh) then
				local popupName = _F("escort driving options##%s", group.name)
				if (GUI:Button(_F("%s >##%s", _T("BSV2_ES_DRIVING_OPTIONS"), group.name))) then
					ImGui.OpenPopup(popupName)
				end

				if (ImGui.BeginPopup(popupName)) then
					if (ImGui.MenuItem(_F("%s##%s", _T("GENERIC_WANDER"), group.name))) then
						ThreadManager:Run(function() group:Wander() end)
						ImGui.CloseCurrentPopup()
					end

					if (ImGui.MenuItem(_F("%s##%s", _T("BSV2_ES_DRIVE_WP"), group.name))) then
						ThreadManager:Run(function()
							local v_Pos = Game.GetWaypointCoords()
							if (not v_Pos) then
								GUI:PlaySound("Error")
								Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
								return
							end

							GUI:PlaySound("Select")
							group:GoTo(v_Pos)
						end)
						ImGui.CloseCurrentPopup()
					end

					if (ImGui.MenuItem(_F("%s##%s", _T("BSV2_ES_DRIVE_OBJ"), group.name))) then
						ThreadManager:Run(function()
							local b_Found, v_Pos = Game.GetObjectiveBlipCoords()
							if (not b_Found) then
								GUI:PlaySound("Error")
								Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
								return
							end

							GUI:PlaySound("Select")
							group:GoTo(v_Pos)
						end)
						ImGui.CloseCurrentPopup()
					end

					ImGui.BeginDisabled(group:IsIdle())
					if (ImGui.MenuItem(_F("%s##%s", _T("GENERIC_STOP"), group.name))) then
						ThreadManager:Run(function() group:StopTheVehicle() end)
						ImGui.CloseCurrentPopup()
					end
					ImGui.EndDisabled()

					ImGui.Spacing()
					ImGui.SeparatorText(_T("GENERIC_DRIVING_STYLE"))
					ImGui.Spacing()

					drivingStyle.index, drivingStyle.normal = ImGui.RadioButton(_T("GENERIC_DRIVING_STYLE_NORMAL"), drivingStyle.index, 1)

					ImGui.SameLine()

					drivingStyle.index, drivingStyle.aggressive = ImGui.RadioButton(_T("GENERIC_DRIVING_STYLE_AGGRO"), drivingStyle.index, 2)

					if (drivingStyle.normal or drivingStyle.aggressive) then
						GUI:PlaySound("Nav")
						group:SetDrivingStyle(drivingStyle.index)
					end
					ImGui.EndPopup()
				end
				ImGui.SameLine()
			end

			ImGui.BeginDisabled(group.wasDismissed)
			if (GUI:Button(_F("%s##%s", _T("GENERIC_DISMISS"), group.name))) then
				BSV2:DismissEscortGroup(group.name)
			end
			ImGui.EndDisabled()
			ImGui.Unindent()
		end

		ImGui.Separator()
	end
end

local function drawSpawnedGroupsFooter()
	local groupSize = table.getlen(BSV2.EscortGroups)
	if (groupSize <= 1) then return end

	ImGui.Dummy(1, 10)
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##SpawnedGroupsFooter", 0, 0)
	ImGui.Spacing()
	ImGui.Separator()
	ImGui.Spacing()
	if (GUI:Button(_T("GENERIC_DISMISS_ALL"))) then
		BSV2:Dismiss(BSV2.SERVICE_TYPE.ESCORT)
	end
	ImGui.EndChild()
end

local function drawGroupCreatorHelp()
	if (ImGui.BeginPopupModal(
			"##newGroupHelp",
			true,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.NoSavedSettings)
		) then
		ImGui.Spacing()
		ImGui.PushTextWrapPos(ImGui.GetFontSize() * 40)
		for i = 1, 3 do
			local translationKey = _F("BSV2_ES_NEW_GROUP_HELP_%d", i)
			ImGui.Text(_T(translationKey))
		end

		ImGui.Indent()
		for i = 1, 5 do
			local step3Key = _F("BSV2_ES_NEW_GROUP_HELP_3.%d", i)
			-- BulletText ignores TextWrapPos
			ImGui.Bullet()
			ImGui.SameLine()
			ImGui.Text(_T(step3Key))
		end
		ImGui.Unindent()

		ImGui.Spacing()
		ImGui.Text(_T("BSV2_ES_NEW_GROUP_HELP_4"))
		ImGui.Text(_T("BSV2_ES_NEW_GROUP_HELP_5"))
		ImGui.PopTextWrapPos()

		ImGui.EndPopup()
	end
end

local function drawGroupCreatorStep1()
	ImGui.Dummy(0, 15)
	local groups  = BSV2:GetEscortGroupList()
	local exists  = groups[newGroup.nameBuffer] ~= nil
	local isValid = string.isvalid(newGroup.buffer.name) and not exists
	local text    = isValid and _F(_T("BSV2_ES_NEW_GROUP_NEXT"), "[ > ]") or _T("BSV2_ES_NEW_GROUP_NAME")
	ImGui.Text(text)

	ImGui.Spacing()
	newGroup.nameBuffer = ImGui.InputTextWithHint("*##groupName", _T("GENERIC_NAME"), newGroup.nameBuffer, 128)

	if (exists) then
		ImGui.TextColored(1, 0, 0, 1, _T("BSV2_ES_NEW_GROUP_NAME_ERR"))
		newGroup.buffer.name = nil
	else
		newGroup.buffer.name = newGroup.nameBuffer
	end

	newGroup.can_progress = isValid
end

local function drawGroupCreatorStep2()
	ImGui.Dummy(0, 15)
	local isValid = newGroup.buffer.vehicleModel ~= nil
	local text    = isValid and _F(_T("BSV2_ES_NEW_GROUP_NEXT"), "[ > ]") or _T("BSV2_ES_NEW_GROUP_VEH")
	ImGui.Text(text)

	ImGui.Spacing()
	local previewVal = Game.GetVehicleDisplayName(newGroupVehs[newGroup.vehicle_index])
	if (ImGui.BeginCombo("*##newGroupVehicle", previewVal)) then
		for i, hash in ipairs(newGroupVehs) do
			local name = Game.GetVehicleDisplayName(hash)
			if (ImGui.Selectable(name, (i == newGroup.vehicle_index))) then
				newGroup.vehicle_index       = i
				newGroup.buffer.vehicleModel = hash
			end
		end
		ImGui.EndCombo()
	end

	newGroup.can_progress = isValid
end

local function drawGroupCreatorStep3()
	newGroup.buffer.members = newGroup.buffer.members or {}
	local style             = ImGui.GetStyle()
	local regionX, regionY  = ImGui.GetContentRegionAvail()
	local members           = newGroup.buffer.members
	local count             = #members
	local membersFull       = count == 3

	ImGui.Spacing()
	local infoText = membersFull and "BSV2_ES_NEW_GROUP_MEMBERS_DONE" or "BSV2_ES_NEW_GROUP_MEMBERS"
	ImGui.Text(_T(infoText))
	ImGui.Spacing()
	ImGui.BulletText(_F(_T("BSV2_ES_NEW_GROUP_MEMBERS_COUNT"), count))

	local removeDisabled = not math.is_inrange(count, 1, 3)
	ImGui.SameLine()
	ImGui.BeginDisabled(removeDisabled)
	if (GUI:Button(" - ")) then
		table.remove(members, count)
	end
	ImGui.EndDisabled()
	if (not removeDisabled) then
		GUI:Tooltip(_T("BSV2_ES_NEW_GROUP_MEMBERS_REMOVE"))
	end

	local ped = newGroup.memberPedBuffer
	local addDisabled = (not ped or count == 3)
	ImGui.SameLine()
	ImGui.BeginDisabled(addDisabled)
	if (GUI:Button(" + ")) then
		if (not ped or not ped.model_hash) then return end
		members[count + 1] = {
			modelHash = ped.model_hash,
			name      = newGroup.memberNameBuffer,
			weapon    = newGroup.memberWeaponBuffer,
		}
		newGroup.memberNameBuffer = ""
	end
	ImGui.EndDisabled()
	if (not addDisabled) then
		GUI:Tooltip(_T("BSV2_ES_NEW_GROUP_MEMBERS_ADD"))
	end

	if (count < 3) then
		ImGui.SeparatorText(_F("%s *", _T("BSV2_ES_NEW_GROUP_PED_MODEL")))
		newGroup.memberPedBuffer = PedBrowser:Draw(vec2:new(regionX, regionY * 0.3))

		ImGui.SeparatorText(_T("BSV2_ES_NEW_GROUP_PED_NAME"))
		local randomLabel     = _T("GENERIC_RANDOM")
		local randomLabelSize = ImGui.CalcTextSize(randomLabel) + (style.FramePadding.x * 2)
		ImGui.SetNextItemWidth(regionX - randomLabelSize - style.ItemSpacing.x)
		newGroup.memberNameBuffer = ImGui.InputTextWithHint("##memberName", _T("GENERIC_NAME"), newGroup.memberNameBuffer, 256)

		ImGui.SameLine()
		if (GUI:Button(randomLabel)) then
			if (not ped or not ped.ped_gender) then return end
			newGroup.memberNameBuffer = BSV2:GetRandomPedName(ped.ped_gender)
		end

		ImGui.SeparatorText(_T("BSV2_ES_NEW_GROUP_PED_WEAPON"))
		newGroup.memberWeaponBuffer = WeaponBrowser:Draw()
	end

	newGroup.can_progress = membersFull
end

local function drawGroupCreator()
	local style        = ImGui.GetStyle()
	local btnSize      = vec2:new(40, 30)

	local prevDisabled = newGroup.stage <= 1
	ImGui.BeginDisabled(prevDisabled)
	if (GUI:Button("<", { size = btnSize })) then
		newGroup.stage = math.max(1, newGroup.stage - 1)
	end
	ImGui.EndDisabled()
	if (not prevDisabled) then
		GUI:Tooltip(_T("GENERIC_PREVIOUS"))
	end

	local stage = newGroup.stage
	ImGui.SameLine()
	ImGui.ValueBar(
		"",
		stage / 3.0,
		vec2:new(ImGui.GetContentRegionAvail() - btnSize.x - style.ItemSpacing.x, btnSize.y),
		ImGuiValueBarFlags.NONE,
		{ fmt = _F(_T("BSV2_ES_NEW_GROUP_STEP_LABEL"), stage) }
	)

	ImGui.SameLine()
	if (newGroup.stage < 3) then
		local nextDisabled = (newGroup.stage > 3 or not newGroup.can_progress)
		ImGui.BeginDisabled(nextDisabled)
		if (GUI:Button(">", { size = btnSize })) then
			newGroup.stage = math.min(3, newGroup.stage + 1)
		end
		ImGui.EndDisabled()
		if (not nextDisabled) then
			GUI:Tooltip(_T("GENERIC_NEXT"))
		end
	elseif (newGroup.stage == 3) then
		local isValid = validateGroupBuffer(newGroup.buffer)
		ImGui.BeginDisabled(not isValid)
		if (GUI:Button("OK", { size = btnSize })) then
			ImGui.OpenPopup("##confirmNewGroup")
		end
		ImGui.EndDisabled()
		if (isValid) then
			GUI:Tooltip(_T("GENERIC_CONFIRM"))
		end

		if (ImGui.DialogBox("##confirmNewGroup", _F(_T("BSV2_ES_NEW_GROUP_PROMPT"), newGroup.buffer.name), ImGuiDialogBoxStyle.INFO)) then
			BSV2:AddNewEscortGroup(table.copy(newGroup.buffer))
			clearNewGroupBuffer()
		end
	end

	if (newGroup.stage == 1) then
		drawGroupCreatorStep1()
	elseif (newGroup.stage == 2) then
		drawGroupCreatorStep2()
	elseif (newGroup.stage == 3) then
		drawGroupCreatorStep3()
	end

	if (newGroup.stage < 3) then
		local labelHeight  = ImGui.GetTextLineHeightWithSpacing()
		local windowHeight = ImGui.GetWindowHeight()
		ImGui.SetCursorPosY(windowHeight - labelHeight - style.WindowPadding.y - style.FramePadding.y)
	end
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	if (GUI:Button(" ( ? ) ")) then
		ImGui.OpenPopup("##newGroupHelp")
	end
	ImGui.PopStyleVar()
	GUI:Tooltip(_T("GENERIC_HELP_LABEL"))

	drawGroupCreatorHelp()
end

---@return string tabName, function? footer
return function()
	if (ImGui.BeginTabBar("##escortsUI")) then
		if (ImGui.BeginTabItem(_T("GENERIC_SPAWN"))) then
			drawSpawner()
			currentTab    = "ES_SPAWN"
			currentFooter = drawSpawnerFooter
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("BSV2_ES_SPAWNED_TAB"))) then
			drawSpawnedGroups()
			currentTab    = "ES_SPAWNED"
			currentFooter = drawSpawnedGroupsFooter
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("+ Group Creator")) then
			currentTab    = "ES_CREATOR"
			currentFooter = nil
			drawGroupCreator()
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end

	return currentTab, currentFooter
end
