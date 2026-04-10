-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local DrawSpawner              = require("includes.frontend.entity_forge.forge_spawner_ui")
local DrawCreatorUI            = require("includes.frontend.entity_forge.forge_creator_ui")
local World                    = require("includes.modules.World")
local markSelectedEntity       = false
local spawnedEntityIndex       = 0
local favoriteEntityIndex      = 0
local newEntityNameBuffer      = ""
local encodedShareableCreation = ""
local wrappedBase64String      = ""

---@type ForgeEntityPlainTable?
local unk_ImportedCreation

---@type ForgeEntity?
local t_SelectedSpawnedEntity

local t_SelectedFavoriteEntity
---@type ForgeEntityPlainTable
local t_SelectedSavedEntity

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

	local wolrdEntitiesCount = #EntityForge.WorldEntities
	if (wolrdEntitiesCount > 0) then
		if (t_SelectedSpawnedEntity and t_SelectedSpawnedEntity.m_name:lower():contains("world ")) then
			if (GUI:Button("Free From Forge Pool")) then
				EntityForge:ReleaseWorldEntity(t_SelectedSpawnedEntity)
			end
		end

		if (wolrdEntitiesCount > 1) then
			ImGui.SameLine()
			if (GUI:Button("Free Up All World Entities")) then
				for i = wolrdEntitiesCount, 1, -1 do
					EntityForge:ReleaseWorldEntity(EntityForge.AllEntities[i])
				end
			end
		end
	end

	if (markSelectedEntity and t_SelectedSpawnedEntity) then
		World:MarkSelectedEntity(t_SelectedSpawnedEntity.m_handle, 0.0)
	end
end

local function DrawFavoriteEntities()
	local favorites = EntityForge.FavoriteModels
	local no_favs   = next(favorites) == nil
	if (no_favs) then
		ImGui.Dummy(1, 10)
		ImGui.TextWrapped("You don't have any saved favorites.")
		return
	end

	ImGui.BeginListBox("##FavoriteEntities", 530, 280)
	for hash, data in pairs(favorites) do
		local is_selected = (favoriteEntityIndex == hash)
		if ImGui.Selectable(data.name, is_selected) then
			favoriteEntityIndex = hash
		end

		if is_selected then
			t_SelectedFavoriteEntity = favorites[favoriteEntityIndex]
		end
	end
	ImGui.EndListBox()

	ImGui.Spacing()

	ImGui.BeginDisabled(not t_SelectedFavoriteEntity)
	if GUI:Button(_T("GENERIC_SPAWN")) then
		ThreadManager:Run(function()
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

		ImGui.Spacing()

		if ImGui.Button(_T("GENERIC_CONFIRM"), 80, 30) then
			EntityForge:RenameFavoriteModel(t_SelectedFavoriteEntity.modelHash, newEntityNameBuffer)
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
	local savedForges     = EntityForge.SavedForges
	local no_saved_forges = next(savedForges) == nil
	if (no_saved_forges) then
		ImGui.Dummy(1, 10)
		ImGui.TextWrapped(_T("EF_SAVED_NONE"))
		return
	end

	if (ImGui.BeginListBox("##ForgedEntities", 530, 280)) then
		for name, forged in pairs(savedForges) do
			if (ImGui.Selectable(name, (forged == t_SelectedSavedEntity))) then
				t_SelectedSavedEntity = forged
			end
		end
		ImGui.EndListBox()
	end

	ImGui.Spacing()

	ImGui.BeginDisabled(not t_SelectedSavedEntity)
	if (GUI:Button(_T("GENERIC_SPAWN"))) then
		EntityForge:SpawnSavedAbomination(t_SelectedSavedEntity)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_RENAME"))) then
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

		ImGui.Spacing()

		if ImGui.Button(_T("GENERIC_CONFIRM"), 80, 30) then
			if (savedForges[newEntityNameBuffer]) then
				Notifier:ShowError("EntityForge", _T("EF_NAME_EXISTS_ERR"))
				return
			end

			t_SelectedSavedEntity = EntityForge:RenameSavedForge(t_SelectedSavedEntity.name, newEntityNameBuffer)
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
		local encoded = Serializer:Encode(t_SelectedSavedEntity)
		if (not encoded) then
			log.warning("Encoding failed!")
			return
		end

		encodedShareableCreation = Serializer:B64Encode(Serializer:XOR(encoded))
		if (not string.isvalid(encodedShareableCreation)) then
			log.warning("Encryption failed!")
			return
		end

		wrappedBase64String = encodedShareableCreation:wrap(40)
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
		ImGui.BulletText(_F("Nested Child Attachments: [ %s ]", (t_SelectedSavedEntity.children[1] ~= nil) and "Yes" or "No"))

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
		GUI:RequestInput(ImGui.IsItemActive())

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
			ImGui.BulletText(_F("Nested Child Attachments: [ %s ]", unk_ImportedCreation.children[1] ~= nil and "Yes" or "No"))

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
		GUI:RequestInput(ImGui.IsItemActive())

		ImGui.Spacing()
		ImGui.Spacing()

		if (encodedShareableCreation:isempty()) then
			if GUI:Button(_T("EF_IMPORT_DATA_CLIPBOARD")) then
				encodedShareableCreation = ImGui.GetClipboardText()
				if (type(encodedShareableCreation) ~= "string") then
					Notifier:ShowError("EntityForge", _T("EF_IMPORT_DATA_CLIPBOARD_ERR")
					)
					return
				end

				wrappedBase64String  = encodedShareableCreation:wrap(40)
				unk_ImportedCreation = EntityForge:ImportCreation(encodedShareableCreation)
			end
		else
			if GUI:Button(_T("GENERIC_ADD")) then
				if (not unk_ImportedCreation or not unk_ImportedCreation.name) then
					return
				end

				if (savedForges[unk_ImportedCreation.name]) then
					Notifier:ShowWarning("EntityForge", _T("EF_IMPORT_DATA_NOTICE"))
					unk_ImportedCreation.name = unk_ImportedCreation.name .. " [import]"
				end

				EntityForge:AddForgedEntity(unk_ImportedCreation)
				wrappedBase64String      = ""
				encodedShareableCreation = ""
				unk_ImportedCreation     = nil
				ImGui.CloseCurrentPopup()
			end
		end

		ImGui.SameLine()
		ImGui.Dummy(20, 1)
		ImGui.SameLine()

		if GUI:Button(_T("GENERIC_CANCEL")) then
			wrappedBase64String      = ""
			encodedShareableCreation = ""
			unk_ImportedCreation     = nil
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
	if (ImGui.BeginTabBar("##entityforge_tb")) then
		if (ImGui.BeginTabItem(_T("EF_TAB_SPAWNER"))) then
			DrawSpawner()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("EF_TAB_CREATOR"))) then
			DrawCreatorUI()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("EF_TAB_SPAWNED_ENTITIES"))) then
			DrawSpawnedEntities()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("GENERIC_FAVORITES"))) then
			DrawFavoriteEntities()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("EF_TAB_SAVED_FORGES"))) then
			DrawSavedEntities()
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_EXTRA, "EntityForge", EntityForgeUI)
