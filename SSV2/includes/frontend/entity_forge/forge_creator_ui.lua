-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local DrawRotationControls      = require("includes.frontend.entity_forge.rotation_axis_ui")
local DrawMovementControls      = require("includes.frontend.entity_forge.movement_axis_ui")
local EntityForge               = require("includes.features.extra.entity_forge.EntityForge")
local World                     = require("includes.modules.World")
local t_PedScenarios <const>    = require("includes.data.actions.scenarios")
local Refs <const>              = require("includes.data.refs")
local PedBones <const>          = Refs.t_PedBones
local VehBones <const>          = Refs.t_VehicleBones
local selectedPedBone           = PedBones[1]
local selectedVehBone           = VehBones[1]
local selectedChildIndex        = 1
local attachCandidate           = 1
local selectedParentIndex       = 1
local newEntityNameBuffer       = ""
local AttachCandidates <const>  = { "EF_SPAWNED_ENTITIES", "GENERIC_YOU" }

---@type array<string>
local filteredVehBones          = {}
local drawChildPedCustomization = false
local drawAxisWindow            = false

---@type integer|string
local unk_AttachBone

---@type ForgeEntity?
local selectedChild

---@type ForgeEntity?
local t_SelectedParent

---@type ForgeEntity?
local t_ForgeCustomizationTarget

---@type ForgeEntity?
local t_SelectedCanvasChild

---@type string?
local selectedForgeScenario

local function DrawPedBones()
	ImGui.SetNextItemWidth(-1)
	if (ImGui.BeginCombo("##pedBones", selectedPedBone.name)) then
		for _, v in ipairs(PedBones) do
			if (ImGui.Selectable(v.name, (v == selectedPedBone))) then
				selectedPedBone = v
			end
		end
		ImGui.EndCombo()
	end
end

local function UpdateVehBones()
	if (not t_SelectedParent or t_SelectedParent.m_type ~= Enums.eEntityType.Vehicle) then
		return
	end

	filteredVehBones = {}
	ThreadManager:Run(function()
		for _, bone in ipairs(VehBones) do
			local bone_idx = Game.GetEntityBoneIndexByName(t_SelectedParent.m_handle, bone)
			if (bone_idx and bone_idx ~= -1) then
				table.insert(filteredVehBones, bone)
			end
		end
	end)
end

local function DrawVehBones()
	ImGui.SetNextItemWidth(-1)
	if (ImGui.BeginCombo("##vehBones", selectedVehBone)) then
		for _, v in ipairs(filteredVehBones) do
			if (ImGui.Selectable(v, (v == selectedVehBone))) then
				selectedVehBone = v
			end
		end
		ImGui.EndCombo()
	end
end

---@param T ForgeEntity
local function DrawAlphaSlider(T)
	ImGui.SetNextItemWidth(-1)
	local clicked      = false
	T.m_alpha, clicked = ImGui.SliderInt("##childvis", T.m_alpha, 0, 255, _T("EF_ALPHA"))

	if (clicked) then
		ThreadManager:Run(function()
			ENTITY.SET_ENTITY_ALPHA(T.m_handle, T.m_alpha, false)
		end)
	end
end

local function DrawChildCandidates()
	local regionWidth = ImGui.GetContentRegionAvail()
	local child_width = (regionWidth / 2) - (ImGui.GetStyle().ItemSpacing.x * 2) - 60
	ImGui.BeginChildEx("##ChildList",
		vec2:new(child_width, GVars.ui.window_size.y * 0.4),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)
	ImGui.SeparatorText(_T("EF_CHILD_CANDIDATES"))

	if (ImGui.BeginListBox("##children", -1, -1)) then
		local cildArray = EntityForge.childCandidates
		for i = 1, #cildArray do
			local child_selected = (selectedChildIndex == i)
			local s_NameBuffer = _F("%s [%s]",
				cildArray[i].m_name,
				cildArray[i].m_handle
			)

			if (ImGui.Selectable(s_NameBuffer, child_selected)) then
				selectedChildIndex = i
				selectedChild      = cildArray[selectedChildIndex]
				EntityForge:UpdateAttachmentCandidates(selectedChild)
			end

			local selectable_width, _ = ImGui.CalcTextSize(s_NameBuffer)
			if (selectable_width > (ImGui.GetWindowWidth() - 5)) then
				GUI:Tooltip(s_NameBuffer)
			end
		end
		ImGui.EndListBox()
	end
	ImGui.EndChild()
end

local function SetupAttachCandidates()
	if (attachCandidate == 2) then
		if (selectedPedBone) then
			unk_AttachBone = selectedPedBone.ID
		end

		if (not t_SelectedParent or t_SelectedParent.m_handle ~= -1 or t_SelectedParent.m_model_hash ~= -1) then
			t_SelectedParent = EntityForge:GetPlayerInstance()
		end
	else
		local parents = EntityForge.parentCandidates
		if (not parents[selectedParentIndex]) then
			t_SelectedParent = nil
			return
		end

		t_SelectedParent = parents[selectedParentIndex]
		if (t_SelectedParent and t_SelectedParent.m_type == Enums.eEntityType.Vehicle) then
			unk_AttachBone = selectedVehBone
		elseif (t_SelectedParent and t_SelectedParent.m_type == Enums.eEntityType.Ped) then
			unk_AttachBone = selectedPedBone.ID
		end
	end
end

local function DrawMidSection()
	ImGui.SetNextWindowBgAlpha(0.0)

	ImGui.BeginChild("##midpart", 120, GVars.ui.window_size.y * 0.4)
	if (selectedChild and (selectedChild.m_type == Enums.eEntityType.Ped) and not selectedChild.m_is_player) then
		ImGui.Dummy(1, 10)
		ImGui.BeginDisabled(drawChildPedCustomization)
		if (GUI:Button("Customize")) then
			t_ForgeCustomizationTarget = selectedChild
			ThreadManager:Run(function()
				t_ForgeCustomizationTarget.m_properties.components = Game.GetPedComponents(
					t_ForgeCustomizationTarget.m_handle
				)
			end)

			drawChildPedCustomization = true
			GUI:Close(true)
			gui.override_mouse(true)
		end
		ImGui.EndDisabled()
	end

	ImGui.Spacing()
	ImGui.SetCursorPosY((ImGui.GetWindowHeight() / 2) - 40)
	ImGui.BeginDisabled(not t_SelectedParent or not selectedChild)
	if (GUI:Button(_F("%s ->", _T("GENERIC_ATTACH")), { size = vec2:new(100, 40) })) then
		if (t_SelectedParent and selectedChild and (t_SelectedParent ~= selectedChild)) then
			ThreadManager:Run(function()
				EntityForge:AttachEntity(
					selectedChild,
					t_SelectedParent,
					unk_AttachBone,
					vec3:zero(),
					vec3:zero()
				)
			end)
		end
	end

	if (attachCandidate == 1) then
		if (t_SelectedParent) then
			if (t_SelectedParent.m_type == Enums.eEntityType.Vehicle) then
				ImGui.Text("Attachment\nBone:")
				DrawVehBones()
			elseif t_SelectedParent.m_type == Enums.eEntityType.Ped then
				ImGui.Text("Attachmen\nBone:")
				DrawPedBones()
			end
		end
	elseif (attachCandidate == 2) then
		ImGui.Text("Attachment\nBone:")
		DrawPedBones()
	end

	ImGui.EndDisabled()
	ImGui.EndChild()
end

local function DrawCandidatesCombo()
	ImGui.SetNextItemWidth(-1)
	if (ImGui.BeginCombo("##attach_candidates", _T(AttachCandidates[attachCandidate]))) then
		for i, v in ipairs(AttachCandidates) do
			if (ImGui.Selectable(_T(v), attachCandidate == i)) then
				attachCandidate = i
			end

			if (ImGui.IsItemClicked(0)) then
				UpdateVehBones()
			end
		end
		ImGui.EndCombo()
	end
end

local function DrawParentList()
	ImGui.BeginChildEx("##ParentList",
		vec2:new(0, GVars.ui.window_size.y * 0.4),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)
	ImGui.SeparatorText(_T("EF_PARENT_CANDIDATES"))
	DrawCandidatesCombo()

	if (attachCandidate == 1) then
		if (ImGui.BeginListBox("##parents", -1, -1)) then
			for _, parent in ipairs(EntityForge.parentCandidates) do
				local name = _F("%s [%s]", parent.m_name, parent.m_handle)
				if (ImGui.Selectable(name, (t_SelectedParent == parent))) then
					t_SelectedParent = parent
				end

				local selectable_width, _ = ImGui.CalcTextSize(name)
				if (selectable_width > ImGui.GetContentRegionAvail()) then
					GUI:Tooltip(name)
				end
			end
			ImGui.EndListBox()
		end
	elseif (attachCandidate == 2) then
		ImGui.Dummy(1, 40)
		ImGui.TextWrapped(_T("EF_SELF_ATTACH_HINT"))
	end

	ImGui.EndChild()
end

local function DrawChildStuff()
	ImGui.Text(_T("EF_CHILD_ITEMS"))
	if (ImGui.BeginListBox("##ChildItems", -1, 0)) then
		local children = EntityForge.currentParent.m_children
		for i = 1, #children do
			local child       = children[i]
			local name        = _F("%s##%d", child.m_name, i)
			local is_selected = (t_SelectedCanvasChild == child)

			if ImGui.Selectable(name, is_selected) then
				t_SelectedCanvasChild = child
			end

			local label_width, _ = ImGui.CalcTextSize(name)
			if label_width > 401 then
				GUI:Tooltip(name)
			end
		end
		ImGui.EndListBox()
	end

	if (not t_SelectedCanvasChild) then
		return
	end

	ImGui.Dummy(1, 10)
	if (t_SelectedCanvasChild.m_type == Enums.eEntityType.Ped) then
		ImGui.BeginDisabled(drawChildPedCustomization)
		if (GUI:Button(_T("GENERIC_CUSTOMIZE"))) then
			t_ForgeCustomizationTarget = t_SelectedCanvasChild
			ThreadManager:Run(function()
				t_ForgeCustomizationTarget.m_properties.components = Game.GetPedComponents(t_ForgeCustomizationTarget.m_handle)
			end)

			drawChildPedCustomization = true
			gui.toggle(false)
			GUI:Close()
			gui.override_mouse(true)
		end
		ImGui.EndDisabled()
		ImGui.SameLine()
	end

	if (GUI:Button(_T("GENERIC_DETACH"))) then
		EntityForge:DetachEntity(EntityForge.currentParent, t_SelectedCanvasChild)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_DELETE"))) then
		EntityForge:DeleteEntity(t_SelectedCanvasChild)
	end

	if (EntityForge.currentParent and #EntityForge.currentParent.m_children > 1) then
		if GUI:Button(_T("GENERIC_DETACH_ALL")) then
			EntityForge:DetachAllEntities(EntityForge.currentParent)
		end

		ImGui.SameLine()

		if GUI:Button(_T("GENERIC_DELETE_ALL")) then
			EntityForge:Cleanup()
		end
	end

	DrawAlphaSlider(t_SelectedCanvasChild)

	ImGui.BeginDisabled(not EntityForge.currentParent)
	if (EntityForge.currentParent and EntityForge.currentParent.m_is_forged) then
		if (GUI:Button("Overwrite", { size = vec2:new(100, 35) })) then
			ImGui.OpenPopup("Overwrite Data?")
		end

		if (ImGui.DialogBox("Overwrite Data?")) then
			EntityForge:OverwriteSavedAbomination()
		end
	else
		if (GUI:Button(_T("GENERIC_SAVE"), { size = vec2:new(100, 35) })) then
			ImGui.OpenPopup("confirm save creation")
		end
	end
	ImGui.EndDisabled()

	if ImGui.BeginPopupModal("confirm save creation",
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.AlwaysAutoResize
		) then
		ImGui.Spacing()
		ImGui.SetNextItemWidth(400)
		newEntityNameBuffer, _ = ImGui.InputTextWithHint("##newcreationname", "Name", newEntityNameBuffer, 128)

		ImGui.Spacing()
		ImGui.Text(_T("EF_NEW_NAME_HINT"))
		ImGui.Dummy(1, 10)

		if (ImGui.Button(_T("GENERIC_CONFIRM"), 80, 30)) then
			if (EntityForge.SavedForges[newEntityNameBuffer]) then
				Notifier:ShowError("EntityForge", _T("EF_NAME_EXISTS_ERR"))
				return
			end

			local new_creation = EntityForge.currentParent:serialize()
			new_creation.name  = newEntityNameBuffer

			ThreadManager:Run(function(s)
				---@param vehicleEntity ForgeEntityPlainTable
				local function GetVehicleProperties(vehicleEntity)
					if (vehicleEntity.type == Enums.eEntityType.Vehicle) then
						vehicleEntity.properties.mods = Vehicle(vehicleEntity.handle):GetMods()
					end

					if (vehicleEntity.children) then
						for _, child in ipairs(vehicleEntity.children) do
							GetVehicleProperties(child)
						end
					end

					return true
				end

				while (not GetVehicleProperties(new_creation)) do
					yield()
				end

				EntityForge.SavedForges[new_creation.name] = new_creation
				EntityForge:ParseForges()
				Notifier:ShowSuccess("EntityForge", _F(_T("EF_NEW_FORGE_SUCCESS"), newEntityNameBuffer))

				s:sleep(300)
				newEntityNameBuffer = ""
				EntityForge:Cleanup()
			end)
			ImGui.CloseCurrentPopup()
		end

		ImGui.SameLine()

		if (GUI:Button(_T("GENERIC_CANCEL"), { vec2:new(80, 30) })) then
			newEntityNameBuffer = ""
			ImGui.CloseCurrentPopup()
		end
		ImGui.EndPopup()
	end
end

local function DrawLowerSection()
	if (not EntityForge.currentParent) then
		return
	end

	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##lowerpart", 0, GVars.ui.window_size.y * 0.5)
	ImGui.Spacing()

	local regionWidth = ImGui.GetContentRegionAvail()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("MoveXYZ", regionWidth * 0.25, 0)
	DrawMovementControls(t_SelectedCanvasChild)
	ImGui.Dummy(1, 10)
	ImGui.BeginDisabled(not t_SelectedCanvasChild)
	drawAxisWindow, _ = GUI:CustomToggle(_T("EF_AXIS_WINDOW"), drawAxisWindow, {
		onClick = function(v)
			if (v) then
				GUI:Close(true)
				gui.override_mouse(true)
			end
		end
	})
	ImGui.EndDisabled()
	GUI:Tooltip(_T("EF_AXIS_WINDOW_TT"))
	ImGui.EndChild()

	ImGui.SameLine()
	ImGui.BeginChildEx("##current_parent",
		vec2:new(regionWidth * 0.45, 0),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)

	local isPlayer = EntityForge.currentParent.m_is_player
	ImGui.SetWindowFontScale(1.05)
	ImGui.SeparatorText(_F("Parent: %s", isPlayer and "You" or EntityForge.currentParent.m_name))
	ImGui.SetWindowFontScale(1.0)

	ImGui.BeginDisabled(isPlayer)
	DrawAlphaSlider(EntityForge.currentParent)
	ImGui.EndDisabled()
	if (isPlayer) then
		GUI:Tooltip(_T("EF_ALPHA_PLAYER_NOT_ALLOWED"))
	end

	ImGui.Spacing()
	DrawChildStuff()
	ImGui.EndChild()

	ImGui.SameLine()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("RotateXYZ", regionWidth * 0.25, 0)
	DrawRotationControls(t_SelectedCanvasChild)
	ImGui.EndChild()

	ImGui.EndChild()
end

local function ControlMouseCursor()
	ImGui.Text(_F(_T("EF_MOUSE_CURSOR_HINT"), "I", gui.mouse_override() and _T("GENERIC_DISABLE") or _T("GENERIC_ENABLE")))
	if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.I)) then
		gui.override_mouse(not gui.mouse_override())
	end
end

local function ForgeAxisWindow()
	if not (drawAxisWindow and t_SelectedCanvasChild) then
		return
	end

	World:MarkSelectedEntity(t_SelectedCanvasChild.m_handle, -1.0)
	ImGui.SetNextWindowBgAlpha(0.4)
	ImGui.Begin(
		"Axis Window",
		ImGuiWindowFlags.NoTitleBar |
		ImGuiWindowFlags.AlwaysAutoResize
	)

	if (ImGui.Button(_T("GENERIC_CLOSE"))) then
		drawAxisWindow = false
		if (not GUI:IsOpen()) then
			GUI:Toggle()
		end
	end

	ControlMouseCursor()

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0.0)
	if ImGui.BeginChildEx("##axis_movement",
			vec2:new(220, 340),
			ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
		) then
		DrawMovementControls(t_SelectedCanvasChild)
		ImGui.EndChild()
	end

	ImGui.SameLine()

	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChildEx("##axis_rotation", vec2:new(220, 340), ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding)
	DrawRotationControls(t_SelectedCanvasChild)
	ImGui.EndChild()

	ImGui.Spacing()
	ImGui.TextWrapped(_F("Selected Entity: %s [%s]", t_SelectedCanvasChild.m_name, t_SelectedCanvasChild.m_handle))
	ImGui.End()
end

local function ForgeChildCustomizationWindow()
	if not (drawChildPedCustomization and t_ForgeCustomizationTarget) then
		return
	end

	local handle = t_ForgeCustomizationTarget.m_handle
	World:MarkSelectedEntity(handle, -0.1)

	ImGui.Begin("##childPedCustomization",
		ImGuiWindowFlags.NoTitleBar |
		ImGuiWindowFlags.AlwaysAutoResize
	)

	if (GUI:Button(_T("GENERIC_CLOSE"))) then
		drawChildPedCustomization = false
		if (not GUI:IsOpen()) then
			GUI:Toggle()
		end
	end

	ControlMouseCursor()

	ImGui.Dummy(1, 10)
	if (ImGui.BeginTabBar("ForgeChildCustomization")) then
		if (ImGui.BeginTabItem("Components")) then
			local components    = t_ForgeCustomizationTarget.m_properties.components
			local comonentCount = #components
			if (components) then
				ImGui.SetNextWindowBgAlpha(0.0)
				if ImGui.BeginChild("##Names", 160, comonentCount * 20) then
					for i = 1, comonentCount do
						if (components[i].max_drawables > 0) then
							ImGui.BulletText(Refs.t_PedComponents[i])
							ImGui.Dummy(1, 3)
						end
					end
					ImGui.EndChild()
				end

				ImGui.SameLine()

				ImGui.SetNextWindowBgAlpha(0.0)
				if (ImGui.BeginChild("components", 300, comonentCount * 20)) then
					for i = 1, comonentCount do
						local this = components[i]
						if (this.max_drawables > 0) then
							ImGui.PushID(i)
							ImGui.SetNextItemWidth(-1)
							this.drawable = ImGui.SliderInt("##ped_component", this.drawable, 0, this.max_drawables)
							ImGui.PopID()
						end
					end
					ImGui.EndChild()
				end

				if (GUI:Button(_T("GENERIC_APPLY"))) then
					ThreadManager:Run(function()
						Game.ApplyPedComponents(handle, components)
					end)
				end

				ImGui.SameLine()
			end

			if (GUI:Button(_T("GENERIC_RANDOM"))) then
				ThreadManager:Run(function()
					PED.SET_PED_RANDOM_COMPONENT_VARIATION(handle, 0)
					t_ForgeCustomizationTarget.m_properties.components = Game.GetPedComponents(handle)
				end)
			end
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Scenarios")) then
			if (ImGui.BeginListBox("##forgescenarios", 400, 300)) then
				for _, v in ipairs(t_PedScenarios) do
					if (ImGui.Selectable(v.label, (selectedForgeScenario == v.scenario))) then
						selectedForgeScenario = v.scenario
					end
				end
				ImGui.EndListBox()
			end

			ImGui.Dummy(1, 10)

			ImGui.BeginDisabled(not selectedForgeScenario)
			if (ImGui.Button("Add & Play")) then
				if (not selectedForgeScenario) then
					return
				end

				t_ForgeCustomizationTarget.m_properties.action = {
					scenario = selectedForgeScenario
				}

				ThreadManager:Run(function()
					TASK.CLEAR_PED_TASKS_IMMEDIATELY(handle)
					TASK.TASK_START_SCENARIO_IN_PLACE(handle, selectedForgeScenario, -1, false)
				end)
			end

			ImGui.SameLine()
			ImGui.Spacing()
			ImGui.SameLine()

			if (ImGui.Button("Stop & Clear")) then
				t_ForgeCustomizationTarget.m_properties.action = nil
				ThreadManager:Run(function(clear)
					if (not PED.IS_PED_USING_ANY_SCENARIO(handle)) then
						return
					end

					TASK.CLEAR_PED_TASKS_IMMEDIATELY(handle)
					if (t_ForgeCustomizationTarget.m_is_attached) then
						EntityForge:ResetEntityPosition(t_ForgeCustomizationTarget)
						clear:sleep(100)
						PED.SET_PED_KEEP_TASK(handle, false)
						TASK.TASK_STAND_STILL(handle, -1)
						clear:sleep(200)
						EntityForge:AttachEntity(
							t_ForgeCustomizationTarget,
							t_ForgeCustomizationTarget.m_parent,
							t_ForgeCustomizationTarget.m_parent_bone,
							t_ForgeCustomizationTarget.m_attach_pos,
							t_ForgeCustomizationTarget.m_attach_rot
						)
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

GUI:RegisterIndependentGUI(ForgeChildCustomizationWindow)
GUI:RegisterIndependentGUI(ForgeAxisWindow)

return function()
	if (EntityForge:IsEmpty()) then
		ImGui.Dummy(1, 10)
		ImGui.TextWrapped(_T("EF_NONE_SPAWNED_HINT"))
		return
	end

	DrawChildCandidates()
	SetupAttachCandidates()

	ImGui.SameLine()
	DrawMidSection()
	ImGui.SameLine()

	DrawParentList()

	if (EntityForge.currentParent) then
		DrawLowerSection()
	end
end
