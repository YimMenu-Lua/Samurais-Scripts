-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local World                      = require("includes.modules.World")
local t_GameObjects              = require("includes.data.objects")
local t_GamePeds                 = require("includes.data.ped_hashmap")
local t_GameVehicles             = require("includes.data.vehicles")
local t_PedScenarios             = require("includes.data.actions.scenarios")
local Refs                       = require("includes.data.refs")
local PreviewService             = require("includes.services.PreviewService")
local markSelectedEntity         = false
local previewSelectedEntity      = false
local vehicleListCreated         = false
local selectedSidebarItem        = Enums.eEntityType.Ped
local objectIndex                = 0
local vehicleIndex               = 0
local pedIndex                   = 0
local spawnedEntityIndex         = 0
local favoriteEntityIndex        = 0
local attachCandidate            = 0
local selectedPedBone            = 0
local selectedParentIndex        = 1
local selectedChildIndex         = 1
local selectedCanvasChildIndex   = 1
local selectedVehBone            = 1
local forgeScenarioIndex         = 1
local attachmentMovementModifier = 1.0
local attachmentRotationModifier = 1.0
local savedEntityIndex           = ""
local sidebarLowerText           = ""
local objectSearchBuffer         = ""
local vehicleSearch              = ""
local pedSearch                  = ""
local newEntityNameBuffer        = ""
local encodedShareableCreation   = ""
local wrappedBase64String        = ""
local filteredObjects            = t_GameObjects
local filteredPeds               = t_GamePeds
local filteredVehicles           = {}
local vehiclelist                = {}
local filteredVehBones           = {}
local attachmentAxisWindow       = { should_draw = false }
local childPedCustomization      = { should_draw = false }
local spawnerSidebarItems        = {
	[Enums.eEntityType.Ped]     = "Peds",
	[Enums.eEntityType.Vehicle] = "Vehicles",
	[Enums.eEntityType.Object]  = "Objects",
}


local hoveredThisFrame
local s_SelectedVehBone
local unk_AttachBone
local unk_SelectedEntity
local unk_ImportedCreation
local t_SelectedPedBone

---@type ForgeEntity?
local t_SelectedSpawnedEntity

local t_SelectedFavoriteEntity
local t_SelectedSavedEntity

---@type ForgeEntity?
local t_SelectedParent

---@type ForgeEntity?
local t_SelectedChild

---@type ForgeEntity?
local t_SelectedCanvasChild

---@type ForgeEntity?
local t_ForgeCustomizationTarget

local t_SelectedForgeScenario

local function WrapB64String(b64, index)
	local out = {}

	for i = 1, #b64, index do
		table.insert(out, b64:sub(i, i + index - 1))
	end

	return table.concat(out, "\n")
end

local function FilterObjects()
	if (#objectSearchBuffer > 0) then
		filteredObjects = {}
		for _, object in ipairs(t_GameObjects) do
			if string.find(object:lower(), objectSearchBuffer:lower()) then
				table.insert(filteredObjects, object)
			end
		end
	else
		filteredObjects = t_GameObjects
	end
end

local function FilterPeds()
	if #pedSearch > 0 then
		filteredPeds = {}
		for hash, model in ipairs(t_GamePeds) do
			if string.find(model:lower(), pedSearch:lower()) then
				filteredPeds[hash] = model
			end
		end
	else
		filteredPeds = t_GamePeds
	end
end

local function BuildVehicleList()
	script.run_in_fiber(function()
		local s_VehicleName
		for model, data in pairs(t_GameVehicles) do
			sidebarLowerText = "Loading Vehicles"
			s_VehicleName = vehicles.get_vehicle_display_name(model)
			if (s_VehicleName:isempty()) then
				goto continue
			end

			if string.find(model:lower(), "drift") then
				s_VehicleName = data.display_name .. " (Drift)"
			end

			table.insert(vehiclelist, { hash = data.model_hash, name = s_VehicleName })
			filteredVehicles = vehiclelist
			yield()

			::continue::
		end

		table.sort(filteredVehicles, function(a, b)
			return a.name < b.name
		end)
		vehicleListCreated = true
		sidebarLowerText = ""
	end)
end

local function FilterVehicles()
	if (#vehicleSearch > 0) then
		filteredVehicles = {}
		for _, veh in ipairs(vehiclelist) do
			if string.find(string.lower(veh.name), vehicleSearch:lower()) then
				table.insert(filteredVehicles, veh)
			end
		end
	else
		filteredVehicles = vehiclelist
	end
end

local function DisplayPedBones()
	local t_PedBoneNames = {}
	for _, bone in ipairs(Refs.t_PedBones) do
		table.insert(t_PedBoneNames, bone.name)
	end

	selectedPedBone, _ = ImGui.Combo(
		"##pedBones",
		selectedPedBone,
		t_PedBoneNames,
		#Refs.t_PedBones
	)
end

local function UpdateVehBones(vehicle)
	filteredVehBones = {}

	for _, bone in ipairs(Refs.t_VehicleBones) do
		local bone_idx = Game.GetEntityBoneIndexByName(vehicle, bone)
		if bone_idx and bone_idx ~= -1 then
			table.insert(filteredVehBones, bone)
		end
	end
end

local function DisplayVehBones(vehicle)
	UpdateVehBones(vehicle)
	selectedVehBone, _ = ImGui.Combo(
		"##vehBones",
		selectedVehBone,
		filteredVehBones,
		#filteredVehBones
	)
end

local b_ObjectsSearch_used = false
local function DrawObjects()
	ImGui.SetNextItemWidth(-1)
	objectSearchBuffer, b_ObjectsSearch_used = ImGui.InputTextWithHint(
		"##search",
		"Search",
		objectSearchBuffer,
		128
	)
	Backend.disable_input = ImGui.IsItemActive()

	if (b_ObjectsSearch_used) then
		FilterObjects()
	end

	ImGui.Spacing()
	if ImGui.BeginListBox("##objectlist", -1, ImGui.GetWindowHeight() * 0.75) then
		local i_MaxIterableItems = #filteredObjects <= 1000 and #filteredObjects or 1000

		for i = 1, i_MaxIterableItems do
			local is_selected = (objectIndex == i)

			if (ImGui.Selectable(filteredObjects[i], is_selected)) then
				objectIndex = i
			end

			if (ImGui.IsItemHovered() and previewSelectedEntity) then
				hoveredThisFrame = joaat(filteredObjects[i])
			end

			if is_selected then
				unk_SelectedEntity = filteredObjects[objectIndex]
			end
		end
		ImGui.EndListBox()
	end

	if (previewSelectedEntity and hoveredThisFrame) then
		PreviewService:OnTick(hoveredThisFrame, Enums.eEntityType.Object)
	else
		PreviewService:Clear()
	end
end

local b_VehicleSearch_used = false
local function DrawVehicles()
	ImGui.SetNextItemWidth(-1)
	vehicleSearch, b_VehicleSearch_used = ImGui.InputTextWithHint(
		"##search",
		_T("GENERIC_SEARCH_HINT"),
		vehicleSearch,
		128
	)
	Backend.disable_input = ImGui.IsItemActive()

	if (b_VehicleSearch_used) then
		FilterVehicles()
	end

	ImGui.Spacing()
	ImGui.BeginDisabled(not vehicleListCreated)
	if ImGui.BeginListBox("##vehiclelist", -1, ImGui.GetWindowHeight() * 0.75) then
		for i = 1, #filteredVehicles do
			local is_selected = (vehicleIndex == i)

			if ImGui.Selectable(filteredVehicles[i].name, is_selected) then
				vehicleIndex = i
			end

			if ImGui.IsItemHovered() then
				if previewSelectedEntity then
					hoveredThisFrame = filteredVehicles[i].hash
				end
			end

			if is_selected then
				unk_SelectedEntity = filteredVehicles[vehicleIndex]
			end
		end
		ImGui.EndListBox()
	end
	ImGui.EndDisabled()

	if (previewSelectedEntity and hoveredThisFrame) then
		PreviewService:OnTick(hoveredThisFrame, Enums.eEntityType.Vehicle)
	else
		PreviewService:Clear()
	end
end

local b_PedSearch_used = false
local function DrawPeds()
	ImGui.SetNextItemWidth(-1)
	pedSearch, b_PedSearch_used = ImGui.InputTextWithHint(
		"##search",
		"Search",
		pedSearch,
		128
	)
	Backend.disable_input = ImGui.IsItemActive()

	if (b_PedSearch_used) then
		FilterPeds()
	end

	ImGui.Spacing()
	if ImGui.BeginListBox("##pedlist", -1, ImGui.GetWindowHeight() * 0.75) then
		for hash, model in pairs(filteredPeds) do
			local is_selected = (pedIndex == hash)

			if ImGui.Selectable(model, is_selected) then
				pedIndex = hash
			end

			if ImGui.IsItemHovered() then
				if previewSelectedEntity then
					hoveredThisFrame = hash
				end
			end

			if is_selected then
				unk_SelectedEntity = model
			end
		end
		ImGui.EndListBox()
	end

	if previewSelectedEntity and hoveredThisFrame then
		PreviewService:OnTick(hoveredThisFrame, Enums.eEntityType.Ped)
	else
		PreviewService:Clear()
	end
end

local function DrawSpawnerSideBar()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##sidebar", 160, GVars.ui.window_size.y * 0.7)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	ImGui.SetWindowFontScale(1.05)
	ImGui.SeparatorText("Game Entities")
	ImGui.SetWindowFontScale(1.0)
	ImGui.Dummy(1, 40)

	for i, tab in ipairs(spawnerSidebarItems) do
		local is_selected = (selectedSidebarItem == i)
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (is_selected and 30 or 0))

		if is_selected then
			local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
			ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
		end

		if GUI:Button(tab, { size = vec2:new(128, 35) }) then
			selectedSidebarItem = i
		end

		if is_selected then
			ImGui.PopStyleColor()
		end
	end

	if selectedSidebarItem == Enums.eEntityType.Object then
		if #filteredObjects > 1000 then
			sidebarLowerText =
			"The object list is truncated to only show the first 1000 items.\n\nUse the search bar above the list to find what you're looking for."
		else
			sidebarLowerText = ""
		end
	elseif selectedSidebarItem == Enums.eEntityType.Ped and #sidebarLowerText > 0 then
		sidebarLowerText = ""
	end

	ImGui.PopStyleVar(2)
	ImGui.SetCursorPosX(0.0)
	ImGui.Dummy(1, 40)
	ImGui.TextWrapped(sidebarLowerText)
	ImGui.EndChild()
end

local function DrawSpanwerItems()
	if selectedSidebarItem == Enums.eEntityType.Object then
		DrawObjects()
	elseif selectedSidebarItem == Enums.eEntityType.Vehicle then
		DrawVehicles()
	elseif selectedSidebarItem == Enums.eEntityType.Ped then
		DrawPeds()
	end
end

local b_AxisWindow = false
local bParentVisUsed = false
local bChildVisUsed = false
local function DrawCreatorUI()
	if EntityForge:IsEmpty() then
		ImGui.Dummy(1, 10)
		ImGui.TextWrapped("Spawn some entities to start creating abominations.")
		return
	end

	local regionWidth = ImGui.GetContentRegionAvail()
	local child_width = (regionWidth / 2) - (ImGui.GetStyle().ItemSpacing.x * 2) - 60
	ImGui.BeginChild("ChildList", child_width, GVars.ui.window_size.y * 0.4, true)
	ImGui.SeparatorText("Child Candidates")

	if ImGui.BeginListBox("##children", -1, -1) then
		for i = 1, #EntityForge.childCandidates do
			local child_selected = (selectedChildIndex == i)
			local s_NameBuffer = _F("%s [%s]",
				EntityForge.childCandidates[i].m_name,
				EntityForge.childCandidates[i].m_handle
			)

			if ImGui.Selectable(s_NameBuffer, child_selected) then
				selectedChildIndex = i
				t_SelectedChild = EntityForge.childCandidates[selectedChildIndex]
				EntityForge:UpdateAttachmentCandidates(t_SelectedChild)
			end

			local selectable_width, _ = ImGui.CalcTextSize(s_NameBuffer)
			if selectable_width > 301 then
				GUI:Tooltip(s_NameBuffer)
			end
		end
		ImGui.EndListBox()
	end

	ImGui.EndChild()

	if attachCandidate == 1 then
		if selectedPedBone and Refs.t_PedBones[selectedPedBone] then
			t_SelectedPedBone = Refs.t_PedBones[selectedPedBone + 1]
			unk_AttachBone = t_SelectedPedBone.ID
		end

		if not t_SelectedParent or t_SelectedParent.m_handle ~= -1 or t_SelectedParent.m_model_hash ~= -1 then
			t_SelectedParent = EntityForge:GetPlayerInstance()
		end
	else
		if selectedParentIndex and EntityForge.parentCandidates[selectedParentIndex] then
			t_SelectedParent = EntityForge.parentCandidates[selectedParentIndex]
			if t_SelectedParent and t_SelectedParent.m_type == Enums.eEntityType.Vehicle then
				if selectedVehBone and filteredVehBones[selectedVehBone] then
					s_SelectedVehBone = filteredVehBones[selectedVehBone + 1]
					unk_AttachBone = s_SelectedVehBone
				end
			elseif t_SelectedParent and t_SelectedParent.m_type == Enums.eEntityType.Ped then
				t_SelectedPedBone = Refs.t_PedBones[selectedPedBone + 1]
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
	ImGui.BeginChild("midpart", 120, GVars.ui.window_size.y * 0.4)

	if (t_SelectedChild and (t_SelectedChild.m_type == Enums.eEntityType.Ped) and not t_SelectedChild.m_is_player) then
		ImGui.Dummy(1, 10)
		ImGui.BeginDisabled(childPedCustomization.should_draw)
		if GUI:Button("Customize") then
			t_ForgeCustomizationTarget = t_SelectedChild
			script.run_in_fiber(function()
				t_ForgeCustomizationTarget.m_properties.components = Game.GetPedComponents(
					t_ForgeCustomizationTarget.m_handle
				)
			end)
			childPedCustomization.should_draw = true
			gui.toggle(false)
			gui.override_mouse(true)
			KeyManager:RegisterKeybind(eVirtualKeyCodes.I, function()
				gui.override_mouse(not gui.mouse_override())
			end)
		end
		ImGui.EndDisabled()
	end

	ImGui.Spacing()
	ImGui.SetCursorPosY((ImGui.GetWindowHeight() / 2) - 40)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 30)
	ImGui.BeginDisabled(not t_SelectedParent or not t_SelectedChild)
	if GUI:Button(_F("%s ->", _T("GENERIC_ATTACH")), { size = vec2:new(100, 40) }) then
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

	if attachCandidate == 0 then
		if t_SelectedParent then
			if t_SelectedParent.m_type == Enums.eEntityType.Vehicle then
				ImGui.Text("Attachment\nBone:")
				ImGui.SetNextItemWidth(-1)
				DisplayVehBones(t_SelectedParent.m_handle)
			elseif t_SelectedParent.m_type == Enums.eEntityType.Ped then
				ImGui.Text("Attachmen\nBone:")
				ImGui.SetNextItemWidth(-1)
				DisplayPedBones()
			end
		end
	elseif attachCandidate == 1 then
		ImGui.Text("Attachment\nBone:")
		ImGui.SetNextItemWidth(-1)
		DisplayPedBones()
	end

	ImGui.EndDisabled()
	ImGui.EndChild()
	ImGui.SameLine()

	ImGui.BeginChild("ParentList", child_width, GVars.ui.window_size.y * 0.4, true)
	ImGui.SeparatorText("Parent Candidates")

	ImGui.SetNextItemWidth(-1)
	attachCandidate, _ = ImGui.Combo("##attach_candidates", attachCandidate, "Spawned Entities\0You\0")

	if attachCandidate == 0 then
		if ImGui.BeginListBox("##parents", -1, -1) then
			for i = 1, #EntityForge.parentCandidates do
				local parent_selected = (selectedParentIndex == i)
				local s_NameBuffer = _F("%s [%s]",
					EntityForge.parentCandidates[i].m_name,
					EntityForge.parentCandidates[i].m_handle
				)

				if ImGui.Selectable(s_NameBuffer, parent_selected) then
					selectedParentIndex = i
				end

				local selectable_width, _ = ImGui.CalcTextSize(s_NameBuffer)
				if selectable_width > 301 then
					GUI:Tooltip(s_NameBuffer)
				end
			end
			ImGui.EndListBox()
		end
	elseif attachCandidate == 1 then
		ImGui.Dummy(1, 40)
		ImGui.TextWrapped(
			"Select a bone from the list then press the button to attach the entity to yourself."
		)
	end

	ImGui.EndChild()

	if EntityForge.currentParent then
		ImGui.SetNextWindowBgAlpha(0.0)
		ImGui.BeginChild("lowerpart", 0, GVars.ui.window_size.y * 0.5)
		ImGui.Spacing()
		ImGui.SetNextWindowBgAlpha(0.0)
		ImGui.BeginChild("MoveXYZ", regionWidth * 0.25, 0)
		ImGui.SeparatorText(_T("EF_MOVE_OBJECT"))
		ImGui.Dummy(1, 10)
		ImGui.SetNextItemWidth(-1)
		attachmentMovementModifier, _ = ImGui.SliderFloat(
			"##f_amvm",
			attachmentMovementModifier,
			1.0,
			100.0,
			_T("EF_MULTIPLIER_LABEL")
		)

		ImGui.Dummy(1, 10)

		if selectedCanvasChildIndex and EntityForge.currentParent.m_children[selectedCanvasChildIndex] then
			t_SelectedCanvasChild = EntityForge.currentParent.m_children[selectedCanvasChildIndex]
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
					-0.001 * attachmentMovementModifier,
					0, 0
				)
			end
		end

		ImGui.SameLine()
		if ImGui.ArrowButton("##right", 1) then
			if t_SelectedCanvasChild then
				EntityForge:MoveAttachment(
					t_SelectedCanvasChild,
					0.001 * attachmentMovementModifier,
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
					0.001 * attachmentMovementModifier,
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
					-0.001 * attachmentMovementModifier,
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
					0.001 * attachmentMovementModifier
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
					-0.001 * attachmentMovementModifier
				)
			end
		end

		ImGui.PopButtonRepeat()
		ImGui.Dummy(1, 10)
		ImGui.TextWrapped("Movement is relative to the attachment bone.")
		ImGui.Dummy(1, 10)
		ImGui.BeginDisabled(not t_SelectedCanvasChild)
		attachmentAxisWindow.should_draw, b_AxisWindow = GUI:CustomToggle(
			"Axis Window",
			attachmentAxisWindow.should_draw
		)
		ImGui.EndDisabled()
		GUI:Tooltip("Opens the movement and rotation controls in an independant window for better visibility.")

		if b_AxisWindow then
			gui.toggle(not attachmentAxisWindow.should_draw)
			gui.override_mouse(attachmentAxisWindow.should_draw)
		end

		ImGui.EndChild()

		ImGui.SameLine()
		ImGui.BeginChild("current parent", regionWidth * 0.45, 0, true)
		ImGui.SetWindowFontScale(1.05)
		ImGui.SeparatorText(
			_F(
				"Parent: %s",
				EntityForge.currentParent.m_is_player and
				"You" or
				EntityForge.currentParent.m_name
			)
		)
		ImGui.SetWindowFontScale(1.0)

		ImGui.SetNextItemWidth(-1)
		ImGui.BeginDisabled(EntityForge.currentParent.m_is_player)
		EntityForge.currentParent.m_alpha, bParentVisUsed = ImGui.SliderInt(
			"##parentvis",
			EntityForge.currentParent.m_alpha or 255,
			0,
			255,
			"Parent Visibility: %d"
		)
		ImGui.EndDisabled()
		if EntityForge.currentParent.m_is_player then
			GUI:Tooltip("Modifying visibility is not allowed for the player entity.")
		end

		if bParentVisUsed then
			script.run_in_fiber(function()
				ENTITY.SET_ENTITY_ALPHA(
					EntityForge.currentParent.m_handle,
					EntityForge.currentParent.m_alpha,
					false
				)
			end)
		end

		ImGui.Spacing()
		ImGui.Text("Child Items:")

		if ImGui.BeginListBox("##ChildItems", -1, 0) then
			for i = 1, #EntityForge.currentParent.m_children do
				local child = EntityForge.currentParent.m_children[i]
				local s_NameBuffer = _F("%s##%d", child.m_name, i)
				local is_selected = (selectedCanvasChildIndex == i)

				if ImGui.Selectable(s_NameBuffer, is_selected) then
					selectedCanvasChildIndex = i
				end

				local label_width, _ = ImGui.CalcTextSize(s_NameBuffer)
				if label_width > 401 then
					GUI:Tooltip(s_NameBuffer)
				end
			end
			ImGui.EndListBox()
		end

		if t_SelectedCanvasChild then
			ImGui.Dummy(1, 10)
			if (t_SelectedCanvasChild.m_type == Enums.eEntityType.Ped) then
				ImGui.BeginDisabled(childPedCustomization.should_draw)
				if GUI:Button("Customize") then
					t_ForgeCustomizationTarget = t_SelectedCanvasChild
					script.run_in_fiber(function()
						t_ForgeCustomizationTarget.m_properties.components = Game.GetPedComponents(
							t_ForgeCustomizationTarget.m_handle
						)
					end)
					childPedCustomization.should_draw = true
					gui.toggle(false)
					GUI:Close()
					gui.override_mouse(true)
					KeyManager:RegisterKeybind("I", function()
						gui.override_mouse(not gui.mouse_override())
					end)
				end
				ImGui.EndDisabled()
				ImGui.SameLine()
			end

			if GUI:Button(_T("GENERIC_DETACH")) then
				EntityForge:DetachEntity(EntityForge.currentParent, t_SelectedCanvasChild)
			end

			ImGui.SameLine()

			if GUI:Button(_T("GENERIC_DELETE")) then
				EntityForge:DeleteEntity(t_SelectedCanvasChild)
			end

			if EntityForge.currentParent and #EntityForge.currentParent.m_children > 1 then
				if GUI:Button(_T("GENERIC_DETACH_ALL")) then
					EntityForge:DetachAllEntities(EntityForge.currentParent)
				end

				ImGui.SameLine()

				if GUI:Button(_T("GENERIC_DELETE_ALL")) then
					EntityForge:Cleanup()
				end
			end

			ImGui.SetNextItemWidth(-1)
			t_SelectedCanvasChild.m_alpha, bChildVisUsed = ImGui.SliderInt(
				"##childvis",
				t_SelectedCanvasChild.m_alpha,
				0,
				255,
				_T("EF_CHILD_ALPHA")
			)

			if bChildVisUsed then
				script.run_in_fiber(function()
					ENTITY.SET_ENTITY_ALPHA(
						t_SelectedCanvasChild.m_handle,
						t_SelectedCanvasChild.m_alpha,
						false
					)
				end)
			end

			ImGui.BeginDisabled(not EntityForge.currentParent)
			if EntityForge.currentParent and EntityForge.currentParent.m_is_forged then
				if GUI:Button("Overwrite", { size = vec2:new(100, 35) }) then
					ImGui.OpenPopup("Overwrite Data?")
				end

				if ImGui.DialogBox("Overwrite Data?") then
					EntityForge:OverwriteSavedAbomination()
				end
			else
				if GUI:Button(_T("GENERIC_SAVE"), { size = vec2:new(100, 35) }) then
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
				newEntityNameBuffer, _ = ImGui.InputTextWithHint(
					"##newcreationname",
					"Name",
					newEntityNameBuffer,
					128
				)
				Backend.disable_input = ImGui.IsItemActive()

				ImGui.Spacing()
				ImGui.Text(_T("EF_NEW_NAME_HINT"))
				ImGui.Dummy(1, 10)

				if ImGui.Button(_T("GENERIC_CONFIRM"), 80, 30) then
					if GVars.features.entity_forge.forged_entities[newEntityNameBuffer] then
						Notifier:ShowError("EntityForge", _T("EF_NAME_EXISTS_ERR"))
						return
					end

					local new_creation = EntityForge.currentParent:serialize()
					new_creation.name = newEntityNameBuffer

					script.run_in_fiber(function(save)
						local function GetVehicleProperties(vehicleEntity)
							if vehicleEntity.type == Enums.eEntityType.Vehicle then
								local col1 = {}
								local col2 = {}
								vehicleEntity.properties.window_states = {}
								vehicleEntity.properties.mods = Vehicle(vehicleEntity.handle):GetMods()
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
								vehicleEntity.properties.plate_text = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(
									vehicleEntity.handle)

								for i = 1, 4 do
									vehicleEntity.properties.window_states[i] = VEHICLE.IS_VEHICLE_WINDOW_INTACT(
										vehicleEntity.handle, i - 1)
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
							yield()
						end

						GVars.features.entity_forge.forged_entities[new_creation.name] = new_creation
						Notifier:ShowSuccess(
							"EntityForge",
							_F("Added '%s' to Saved Creations",
								newEntityNameBuffer
							)
						)

						save:sleep(300)
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

		ImGui.EndChild()

		ImGui.SameLine()
		ImGui.SetNextWindowBgAlpha(0.0)
		ImGui.BeginChild("RotateXYZ", regionWidth * 0.25, 0)
		ImGui.SeparatorText(_T("EF_ROTATE_OBJECT"))
		ImGui.Dummy(1, 10)
		ImGui.SetNextItemWidth(-1)
		attachmentRotationModifier, _ = ImGui.SliderFloat(
			"##f_arvm",
			attachmentRotationModifier,
			1.0,
			100.0,
			_T("EF_MULTIPLIER_LABEL")
		)

		ImGui.Dummy(1, 10)
		if EntityForge.currentParent and selectedCanvasChildIndex and EntityForge.currentParent.m_children[selectedCanvasChildIndex] then
			t_SelectedCanvasChild = EntityForge.currentParent.m_children[selectedCanvasChildIndex]
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
					-0.05 * attachmentRotationModifier,
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
					0.05 * attachmentRotationModifier,
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
					-0.05 * attachmentRotationModifier,
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
					0.05 * attachmentRotationModifier,
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
					0.05 * attachmentRotationModifier
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
					-0.05 * attachmentRotationModifier
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
		local is_selected = (spawnedEntityIndex == i)
		local name_buffer = _F(
			"%s [%s]",
			EntityForge.AllEntities[i].m_name,
			EntityForge.AllEntities[i].m_is_player and "Yourself" or
			EntityForge.AllEntities[i].m_handle
		)

		if (EntityForge.AllEntities[i].m_is_forged) then
			name_buffer = _F("%s  (Saved Creation)", name_buffer)
		end

		if ImGui.Selectable(name_buffer, is_selected) then
			spawnedEntityIndex = i
		end

		if is_selected then
			t_SelectedSpawnedEntity = EntityForge.AllEntities[spawnedEntityIndex]
		end
	end
	ImGui.EndListBox()

	markSelectedEntity, _ = ImGui.Checkbox("Mark Selected Entity", markSelectedEntity)
	ImGui.SameLine()
	ImGui.Spacing()
	ImGui.SameLine()

	EntityForge.EntityGunEnabled, _ = ImGui.Checkbox(_T("EF_ENTITY_GUN"), EntityForge.EntityGunEnabled)
	GUI:Tooltip(_T("EF_ENTITY_GUN_TT"))

	ImGui.Spacing()

	ImGui.BeginDisabled(not t_SelectedSpawnedEntity)
	if GUI:Button(_T("GENERIC_DELETE")) then
		if (not t_SelectedSpawnedEntity) then
			return
		end

		if t_SelectedSpawnedEntity.m_is_forged then
			EntityForge:DeleteAbomination(t_SelectedSpawnedEntity)
		else
			EntityForge:DeleteEntity(t_SelectedSpawnedEntity)
		end
	end
	ImGui.EndDisabled()

	ImGui.SameLine()

	ImGui.BeginDisabled(EntityForge:IsEmpty())
	if GUI:Button("Delete All") then
		EntityForge:Cleanup()
	end
	ImGui.EndDisabled()

	if #EntityForge.WorldEntities > 0 then
		if t_SelectedSpawnedEntity and string.find(t_SelectedSpawnedEntity.m_name, "World ") then
			if GUI:Button("Free From Forge Pool") then
				EntityForge:ReleaseWorldEntity(t_SelectedSpawnedEntity)
			end
		end

		if #EntityForge.WorldEntities > 1 then
			ImGui.SameLine()
			if GUI:Button("Free Up All World Entities") then
				for i = #EntityForge.WorldEntities, 1, -1 do
					EntityForge:ReleaseWorldEntity(EntityForge.AllEntities[i])
				end
			end
		end
	end

	if markSelectedEntity and t_SelectedSpawnedEntity then
		World:MarkSelectedEntity(t_SelectedSpawnedEntity.m_handle, 0.0)
	end
end

local function DrawFavoriteEntities()
	local no_favs = next(GVars.features.entity_forge.favorites) == nil
	if (no_favs) then
		ImGui.Dummy(1, 10)
		ImGui.TextWrapped("You don't have any saved favorites.")
		return
	end

	ImGui.BeginListBox("##FavoriteEntities", 530, 280)
	for hash, data in pairs(GVars.features.entity_forge.favorites) do
		local is_selected = (favoriteEntityIndex == hash)
		if ImGui.Selectable(data.name, is_selected) then
			favoriteEntityIndex = hash
		end

		if is_selected then
			t_SelectedFavoriteEntity = GVars.features.entity_forge.favorites[favoriteEntityIndex]
		end
	end
	ImGui.EndListBox()

	ImGui.Spacing()

	ImGui.BeginDisabled(not t_SelectedFavoriteEntity)
	if GUI:Button(_T("GENERIC_SPAWN")) then
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

	if GUI:Button("Rename") then
		newEntityNameBuffer = ""
		ImGui.OpenPopup("Rename Favorite")
	end

	if ImGui.BeginPopupModal(
			"Rename Favorite",
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.AlwaysAutoResize
		) then
		ImGui.Spacing()
		ImGui.SetNextItemWidth(400)
		newEntityNameBuffer, _ = ImGui.InputTextWithHint(
			"##newfavname",
			"Name",
			newEntityNameBuffer,
			128
		)
		Backend.disable_input = ImGui.IsItemActive()

		ImGui.Spacing()

		if ImGui.Button(_T("GENERIC_CONFIRM"), 80, 30) then
			for hash, data in pairs(GVars.features.entity_forge.favorites) do
				if data.name == newEntityNameBuffer then
					Notifier:ShowError("EntityForge", _T("EF_NAME_EXISTS_ERR"))
					return
				end

				if data.name == t_SelectedFavoriteEntity.name then
					Notifier:ShowSuccess(
						"EntityForge",
						_F(
							"Renamed '%s' to '%s'",
							data.name,
							newEntityNameBuffer
						)
					)
					GVars.features.entity_forge.favorites[hash].name = newEntityNameBuffer
					break
				end
			end
			newEntityNameBuffer = ""
			ImGui.CloseCurrentPopup()
		end

		ImGui.SameLine()
		ImGui.Spacing()
		ImGui.SameLine()

		if GUI:Button(_T("GENERIC_CANCEL")) then
			newEntityNameBuffer = ""
			ImGui.CloseCurrentPopup()
		end
		ImGui.EndPopup()
	end

	if GUI:Button(_T("GENERIC_REMOVE")) then
		ImGui.OpenPopup(_T("GENERIC_REMOVE"))
	end
	ImGui.EndDisabled()

	if ImGui.DialogBox(_T("GENERIC_REMOVE")) then
		EntityForge:RemoveFromFavorites(t_SelectedFavoriteEntity)
	end

	ImGui.SameLine()

	ImGui.BeginDisabled(no_favs)
	if GUI:Button(_T("GENERIC_REMOVE_ALL")) then
		ImGui.OpenPopup(_T("GENERIC_REMOVE_ALL"))
	end
	ImGui.EndDisabled()

	if ImGui.DialogBox(_T("GENERIC_REMOVE_ALL")) then
		EntityForge:RemoveAllFavorites()
	end
end

local function DrawSavedEntities()
	local no_saved_forges = next(GVars.features.entity_forge.forged_entities) == nil
	if (no_saved_forges) then
		ImGui.Dummy(1, 10)
		ImGui.TextWrapped(_T("EF_SAVED_NONE"))
		return
	end

	if ImGui.BeginListBox("##ForgedEntities", 530, 280) then
		for name, forged in pairs(GVars.features.entity_forge.forged_entities) do
			local is_selected = (savedEntityIndex == name)
			if ImGui.Selectable(name, is_selected) then
				savedEntityIndex = name
			end

			if is_selected then
				t_SelectedSavedEntity = forged
			end
		end
		ImGui.EndListBox()
	end

	ImGui.Spacing()

	ImGui.BeginDisabled(not t_SelectedSavedEntity)
	if GUI:Button(_T("GENERIC_SPAWN")) then
		EntityForge:SpawnSavedAbomination(t_SelectedSavedEntity)
	end

	ImGui.SameLine()

	if GUI:Button(_T("GENERIC_RENAME")) then
		newEntityNameBuffer = ""
		ImGui.OpenPopup("Rename Saved Creation")
	end

	if ImGui.BeginPopupModal(
			"Rename Saved Creation",
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.AlwaysAutoResize
		) then
		ImGui.Spacing()
		ImGui.SetNextItemWidth(400)
		newEntityNameBuffer, _ = ImGui.InputTextWithHint(
			"##renamesaved",
			"Name",
			newEntityNameBuffer,
			128
		)
		Backend.disable_input = ImGui.IsItemActive()

		ImGui.Spacing()

		if ImGui.Button(_T("GENERIC_CONFIRM"), 80, 30) then
			if (GVars.features.entity_forge.forged_entities[newEntityNameBuffer]) then
				Notifier:ShowError("EntityForge", _T("EF_NAME_EXISTS_ERR"))
				return
			end

			Notifier:ShowSuccess(
				"EntityForge",
				_F(
					"Renamed '%s' to '%s'",
					t_SelectedSavedEntity.name,
					newEntityNameBuffer
				)
			)
			local new = table.copy(GVars.features.entity_forge.forged_entities[t_SelectedSavedEntity.name])
			GVars.features.entity_forge.forged_entities[t_SelectedSavedEntity.name] = nil
			new.name = newEntityNameBuffer
			t_SelectedSavedEntity = new
			GVars.features.entity_forge.forged_entities[newEntityNameBuffer] = new
			newEntityNameBuffer = ""
			ImGui.CloseCurrentPopup()
		end

		ImGui.SameLine()
		ImGui.Spacing()
		ImGui.SameLine()

		if GUI:Button(_T("GENERIC_CANCEL")) then
			newEntityNameBuffer = ""
			ImGui.CloseCurrentPopup()
		end
		ImGui.EndPopup()
	end

	ImGui.SameLine()

	if GUI:Button(_T("GENERIC_SHARE")) then
		encodedShareableCreation = Serializer:B64Encode(Serializer:XOR(Serializer:Encode(t_SelectedSavedEntity)))
		wrappedBase64String, _ = WrapB64String(encodedShareableCreation, 40)
		ImGui.OpenPopup("share creation")
	end
	ImGui.EndDisabled()


	if ImGui.BeginPopupModal(
			"share creation",
			ImGuiWindowFlags.AlwaysAutoResize |
			ImGuiWindowFlags.NoTitleBar
		) then
		ImGui.Spacing()
		ImGui.BulletText(_F("Name: %s", t_SelectedSavedEntity.name))
		ImGui.BulletText(_F("N° Of Attachments: [ %d ]", #t_SelectedSavedEntity.children))
		ImGui.BulletText(_F("Nested Child Attachments: [ %s ]",
			t_SelectedSavedEntity.children.children and "Yes" or "No"))

		ImGui.Separator()
		ImGui.Spacing()
		ImGui.Spacing()

		ImGui.Text("Forge Data: ")
		ImGui.InputTextMultiline(
			"##b64",
			wrappedBase64String,
			#encodedShareableCreation,
			440, 150,
			ImGuiInputTextFlags.ReadOnly
		)
		Backend.disable_input = ImGui.IsItemActive()

		ImGui.Spacing()
		ImGui.Spacing()

		if GUI:Button(_T("GENERIC_COPY")) then
			ImGui.SetClipboardText(encodedShareableCreation)
			Notifier:ShowSuccess("EntityForge", _T("EF_SHARE_SUCCESS"), true, 6)
			encodedShareableCreation = ""
			wrappedBase64String = ""
			ImGui.CloseCurrentPopup()
		end
		ImGui.SameLine()
		ImGui.Dummy(20, 1)
		ImGui.SameLine()

		if GUI:Button(_T("GENERIC_CANCEL")) then
			encodedShareableCreation = ""
			wrappedBase64String = ""
			ImGui.CloseCurrentPopup()
		end
		ImGui.EndPopup()
	end
	ImGui.SameLine()

	if GUI:Button(_T("EF_IMPORT_DATA")) then
		ImGui.OpenPopup("import creation")
	end

	if ImGui.BeginPopupModal(
			"import creation",
			ImGuiWindowFlags.AlwaysAutoResize |
			ImGuiWindowFlags.NoTitleBar
		) then
		if (unk_ImportedCreation and unk_ImportedCreation.name and unk_ImportedCreation.children) then
			ImGui.Spacing()
			ImGui.BulletText(_F("Name: %s", unk_ImportedCreation.name))
			ImGui.BulletText(_F("N° Of Attachments: [ %d ]", #unk_ImportedCreation.children))
			ImGui.BulletText(_F("Nested Child Attachments: [ %s ]",
				unk_ImportedCreation.children.children and "Yes" or "No"))

			ImGui.Separator()
			ImGui.Spacing()
			ImGui.Spacing()
		else
			ImGui.Text(_T("EF_IMPORT_DATA_INSTR"))
		end
		ImGui.InputTextMultiline(
			"##b64",
			wrappedBase64String,
			0xFFFF,
			440, 150
		)
		Backend.disable_input = ImGui.IsItemActive()

		ImGui.Spacing()
		ImGui.Spacing()

		if (encodedShareableCreation:isempty()) then
			if GUI:Button(_T("EF_IMPORT_DATA_CLIPBOARD")) then
				encodedShareableCreation = ImGui.GetClipboardText()
				if type(encodedShareableCreation) ~= "string" then
					Notifier:ShowError(
						"EntityForge",
						_T("EF_IMPORT_DATA_CLIPBOARD_ERR")
					)
					return
				end

				wrappedBase64String = WrapB64String(encodedShareableCreation, 40)
				unk_ImportedCreation = EntityForge:ImportCreation(encodedShareableCreation)
			end
		else
			if GUI:Button(_T("GENERIC_ADD")) then
				if (GVars.features.entity_forge.forged_entities[unk_ImportedCreation.m_name]) then
					Notifier:ShowWarning("EntityForge", _T("EF_IMPORT_DATA_NOTICE"))
					unk_ImportedCreation.m_name = unk_ImportedCreation.m_name .. " [import]"
				end

				GVars.features.entity_forge.forged_entities[unk_ImportedCreation.m_name] = unk_ImportedCreation
				wrappedBase64String = ""
				encodedShareableCreation = ""
				unk_ImportedCreation = nil
				Notifier:ShowSuccess("EntityForge", _T("EF_IMPORT_SUCCESS"))
				ImGui.CloseCurrentPopup()
			end
		end

		ImGui.SameLine()
		ImGui.Dummy(20, 1)
		ImGui.SameLine()

		if GUI:Button(_T("GENERIC_CANCEL")) then
			wrappedBase64String = ""
			encodedShareableCreation = ""
			unk_ImportedCreation = nil
			ImGui.CloseCurrentPopup()
		end

		ImGui.EndPopup()
	end

	ImGui.BeginDisabled(not t_SelectedSavedEntity)
	if GUI:Button(_T("GENERIC_REMOVE")) then
		ImGui.OpenPopup(_T("GENERIC_REMOVE"))
	end
	ImGui.EndDisabled()

	if ImGui.DialogBox(_T("GENERIC_REMOVE")) then
		EntityForge:RemoveSavedAbomination(t_SelectedSavedEntity)
	end
	ImGui.SameLine()

	ImGui.BeginDisabled(no_saved_forges)
	if GUI:Button(_T("GENERIC_REMOVE_ALL")) then
		ImGui.OpenPopup(_T("GENERIC_REMOVE_ALL"))
	end
	ImGui.EndDisabled()

	if ImGui.DialogBox(_T("GENERIC_REMOVE_ALL")) then
		EntityForge:RemoveAllSavedAbominations()
	end
end

local function EntityForgeUI()
	if ImGui.BeginTabBar("##entityforge_tb") then
		if ImGui.BeginTabItem("Spawner") then
			DrawSpawnerSideBar()
			ImGui.SameLine()
			ImGui.BeginChild("##items", 0, GVars.ui.window_size.y * 0.7, true)
			DrawSpanwerItems()
			ImGui.Spacing()
			if selectedSidebarItem == Enums.eEntityType.Vehicle and not vehicleListCreated then
				ImGui.Text(ImGui.TextSpinner("Loading vehicle list", 8.0, ImGuiSpinnerStyle.FILL))
			else
				ImGui.BeginDisabled(not unk_SelectedEntity)
				if GUI:Button(_T("GENERIC_SPAWN"), { size = vec2:new(120, 35) }) then
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

						if previewSelectedEntity and PreviewService.m_current_pos then
							vec_Position = PreviewService.m_current_pos
						else
							vec_Position = Self:GetOffsetInWorldCoords(1, 5, 0)
						end

						EntityForge:CreateEntity(
							i_ModelHash,
							s_ModelName,
							selectedSidebarItem,
							vec_Position
						)
					end)
				end

				ImGui.SameLine()
				local text_width, _ = ImGui.CalcTextSize("Add To Favorites")
				if GUI:Button("Add To Favorites", { size = vec2:new(text_width + 20, 35) }) then
					newEntityNameBuffer = ""
					ImGui.OpenPopup("Add Favorite")
				end
				ImGui.EndDisabled()

				if ImGui.BeginPopupModal(
						"Add Favorite",
						ImGuiWindowFlags.NoTitleBar |
						ImGuiWindowFlags.AlwaysAutoResize
					) then
					ImGui.Spacing()
					ImGui.SetNextItemWidth(400)
					newEntityNameBuffer, _ = ImGui.InputTextWithHint(
						"##favname",
						"Name",
						newEntityNameBuffer,
						128
					)
					Backend.disable_input = ImGui.IsItemActive()
					ImGui.Dummy(1, 10)

					if GUI:Button(_T("GENERIC_CONFIRM")) then
						local i_ModelHash = (
							type(unk_SelectedEntity) == "string" and
							joaat(unk_SelectedEntity) or
							unk_SelectedEntity.hash
						)

						local already_saved = EntityForge:IsModelInFavorites(i_ModelHash)
						if already_saved then
							Notifier:ShowError(
								"EntityForge",
								_F("This model is already saved as '%s'. Please choose a different one!",
									already_saved
								)
							)
							return
						end

						if GVars.features.entity_forge.favorites[newEntityNameBuffer] then
							Notifier:ShowError(
								"EntityForge",
								"You already have a favorite with this name. Please choose a different one!"
							)
							return
						end

						GVars.features.entity_forge.favorites[newEntityNameBuffer] = {
							name = newEntityNameBuffer,
							modelHash = i_ModelHash,
							type = selectedSidebarItem
						}

						Notifier:ShowSuccess(
							"EntityForge",
							_F("Added '%s' to favorites.", newEntityNameBuffer)
						)
						newEntityNameBuffer = ""
						ImGui.CloseCurrentPopup()
					end

					ImGui.SameLine()

					if GUI:Button(_T("GENERIC_CANCEL")) then
						newEntityNameBuffer = ""
						ImGui.CloseCurrentPopup()
					end

					ImGui.EndPopup()
				end
			end
			ImGui.EndChild()
			ImGui.Dummy(1, 10)
			ImGui.SeparatorText("Preferences")

			previewSelectedEntity, _ = GUI:CustomToggle("Preview", previewSelectedEntity)

			ImGui.SameLine()
			ImGui.Spacing()
			ImGui.SameLine()

			EntityForge.EntityGunEnabled, _ = ImGui.Checkbox("Entity Grabber", EntityForge.EntityGunEnabled)

			ImGui.SameLine()
			ImGui.Spacing()
			ImGui.SameLine()

			ImGui.BeginDisabled(EntityForge:IsEmpty())
			if GUI:Button("Cleanup Everything") then
				EntityForge:Cleanup()
			end
			ImGui.EndDisabled()

			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Creator") then
			DrawCreatorUI()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Spawned Entities") then
			DrawSpawnedEntities()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Favorites") then
			DrawFavoriteEntities()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem("Saved Creations") then
			DrawSavedEntities()
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end

	if PreviewService.m_current and (not ImGui.IsAnyItemHovered() or not previewSelectedEntity) then
		hoveredThisFrame = nil
		PreviewService:Clear()
	end
end

local function ForgeChildCustomizationWindow()
	if childPedCustomization.should_draw and t_ForgeCustomizationTarget then
		World:MarkSelectedEntity(t_ForgeCustomizationTarget.m_handle, -0.1)

		ImGui.Begin("Child Ped Customization",
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.AlwaysAutoResize
		)

		if GUI:Button("Close") then
			childPedCustomization.should_draw = false
			if not GUI:IsOpen() then
				GUI:Toggle()
			end

			KeyManager:RemoveKeybind(eVirtualKeyCodes.I)
		end

		ImGui.Text(_F("Press [ I ] to %s the mouse.",
			gui.mouse_override() and "disable" or "enable"
		))

		ImGui.Dummy(1, 10)

		if ImGui.BeginTabBar("ForgeChildCustomization") then
			if ImGui.BeginTabItem("Components") then
				if t_ForgeCustomizationTarget.m_properties.components then
					ImGui.SetNextWindowBgAlpha(0.0)
					if ImGui.BeginChild("Names", 160, #t_ForgeCustomizationTarget.m_properties.components * 20) then
						for i = 1, #t_ForgeCustomizationTarget.m_properties.components do
							if t_ForgeCustomizationTarget.m_properties.components[i].max_drawables > 0 then
								ImGui.BulletText(Refs.t_PedComponents[i])
								ImGui.Dummy(1, 3)
							end
						end
						ImGui.EndChild()
					end

					ImGui.SameLine()

					ImGui.SetNextWindowBgAlpha(0.0)
					if ImGui.BeginChild("components", 300, #t_ForgeCustomizationTarget.m_properties.components * 20) then
						for i = 1, #t_ForgeCustomizationTarget.m_properties.components do
							if t_ForgeCustomizationTarget.m_properties.components[i].max_drawables > 0 then
								ImGui.PushID(_F("component slider %d", i))
								ImGui.SetNextItemWidth(-1)
								t_ForgeCustomizationTarget.m_properties.components[i].drawable, _ = ImGui.SliderInt(
									_F("##component%d", i),
									t_ForgeCustomizationTarget.m_properties.components[i].drawable,
									0,
									t_ForgeCustomizationTarget.m_properties.components[i].max_drawables
								)
								ImGui.PopID()
							end
						end
						ImGui.EndChild()
					end

					if GUI:Button("Apply") then
						script.run_in_fiber(function()
							Game.ApplyPedComponents(
								t_ForgeCustomizationTarget.m_handle,
								t_ForgeCustomizationTarget.m_properties.components
							)
						end)
					end

					ImGui.SameLine()
					ImGui.Spacing()
					ImGui.SameLine()
				end

				if GUI:Button("Randomize") then
					script.run_in_fiber(function()
						PED.SET_PED_RANDOM_COMPONENT_VARIATION(t_ForgeCustomizationTarget.m_handle, 0)
						t_ForgeCustomizationTarget.m_properties.components = Game.GetPedComponents(
							t_ForgeCustomizationTarget.m_handle)
					end)
				end
				ImGui.EndTabItem()
			end

			if ImGui.BeginTabItem("Scenarios") then
				if ImGui.BeginListBox("##forgescenarios", 400, 300) then
					for i = 1, #t_PedScenarios do
						local is_selected = (forgeScenarioIndex == i)

						if ImGui.Selectable(t_PedScenarios[i].label, is_selected) then
							forgeScenarioIndex = i
						end

						if is_selected then
							t_SelectedForgeScenario = t_PedScenarios[forgeScenarioIndex]
						end
					end
					ImGui.EndListBox()
				end

				ImGui.Dummy(1, 10)

				ImGui.BeginDisabled(not t_SelectedForgeScenario)
				if ImGui.Button("Add & Play") then
					t_ForgeCustomizationTarget.m_properties.action = {
						scenario = t_SelectedForgeScenario.scenario
					}

					script.run_in_fiber(function()
						TASK.CLEAR_PED_TASKS_IMMEDIATELY(t_ForgeCustomizationTarget.m_handle)
						TASK.TASK_START_SCENARIO_IN_PLACE(
							t_ForgeCustomizationTarget.m_handle,
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
					t_ForgeCustomizationTarget.m_properties.action = nil
					script.run_in_fiber(function(clear)
						if PED.IS_PED_USING_ANY_SCENARIO(t_ForgeCustomizationTarget.m_handle) then
							TASK.CLEAR_PED_TASKS_IMMEDIATELY(t_ForgeCustomizationTarget.m_handle)
							if t_ForgeCustomizationTarget.m_is_attached then
								EntityForge:ResetEntityPosition(t_ForgeCustomizationTarget)
								clear:sleep(100)
								PED.SET_PED_KEEP_TASK(t_ForgeCustomizationTarget.m_handle, false)
								TASK.TASK_STAND_STILL(t_ForgeCustomizationTarget.m_handle, -1)
								clear:sleep(200)
								EntityForge:AttachEntity(
									t_ForgeCustomizationTarget,
									t_ForgeCustomizationTarget.m_parent,
									t_ForgeCustomizationTarget.m_parent_bone,
									t_ForgeCustomizationTarget.m_attach_pos,
									t_ForgeCustomizationTarget.m_attach_rot
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

local function ForgeAxisWindow()
	if attachmentAxisWindow.should_draw and t_SelectedCanvasChild then
		if not gui.mouse_override() then
			gui.override_mouse(true)
		end

		World:MarkSelectedEntity(t_SelectedCanvasChild.m_handle, -1.0)
		ImGui.SetNextWindowBgAlpha(0.4)
		ImGui.Begin(
			"Axis Window",
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.AlwaysAutoResize
		)

		if ImGui.Button(_T("GENERIC_CLOSE")) then
			attachmentAxisWindow.should_draw = false
			if not GUI:IsOpen() then
				GUI:Toggle()
			end
		end

		ImGui.Dummy(1, 20)
		ImGui.SetNextWindowBgAlpha(0.0)
		if ImGui.BeginChild("axis movement", 220, 340, true) then
			ImGui.SeparatorText(_T("EF_MOVE_OBJECT"))
			ImGui.Dummy(1, 10)
			ImGui.SetNextItemWidth(-1)
			attachmentMovementModifier, _ = ImGui.SliderFloat(
				"##f_amvm",
				attachmentMovementModifier,
				1.0,
				100.0,
				_T("EF_MULTIPLIER_LABEL")
			)
			ImGui.PushButtonRepeat(true)
			ImGui.Dummy(1, 10)
			ImGui.Text("X: ")
			ImGui.SameLine()
			if ImGui.ArrowButton("##left", 0) then
				if t_SelectedCanvasChild then
					EntityForge:MoveAttachment(
						t_SelectedCanvasChild,
						-0.001 * attachmentMovementModifier,
						0, 0
					)
				end
			end

			ImGui.SameLine()
			if ImGui.ArrowButton("##right", 1) then
				if t_SelectedCanvasChild then
					EntityForge:MoveAttachment(
						t_SelectedCanvasChild,
						0.001 * attachmentMovementModifier,
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
						0.001 * attachmentMovementModifier,
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
						-0.001 * attachmentMovementModifier,
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
						0.001 * attachmentMovementModifier
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
						-0.001 * attachmentMovementModifier
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
			ImGui.SeparatorText(_T("EF_ROTATE_OBJECT"))
			ImGui.Dummy(1, 10)
			ImGui.SetNextItemWidth(-1)
			attachmentRotationModifier, _ = ImGui.SliderFloat(
				"##f_arvm",
				attachmentRotationModifier,
				1.0,
				100.0,
				_T("EF_MULTIPLIER_LABEL")
			)
			ImGui.Dummy(1, 10)
			ImGui.PushButtonRepeat(true)
			ImGui.Text("X: ")
			ImGui.SameLine()
			if ImGui.ArrowButton("##xRot--", 2) then
				if t_SelectedCanvasChild then
					EntityForge:RotateAttachment(
						t_SelectedCanvasChild,
						-0.05 * attachmentRotationModifier,
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
						0.05 * attachmentRotationModifier,
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
						-0.05 * attachmentRotationModifier,
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
						0.05 * attachmentRotationModifier,
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
						0.05 * attachmentRotationModifier
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
						-0.05 * attachmentRotationModifier
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
			_F(
				"Selected Entity: %s [%s]",
				t_SelectedCanvasChild.m_name,
				t_SelectedCanvasChild.m_handle
			)
		)
		ImGui.End()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_EXTRA, "EntityForge", EntityForgeUI)
GUI:RegisterIndependentGUI(ForgeAxisWindow)
GUI:RegisterIndependentGUI(ForgeChildCustomizationWindow)
BuildVehicleList()
