-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local EntityForge                = require("includes.features.extra.entity_forge.EntityForge")
local attachmentRotationModifier = 1.0

---@param forgeEntity ForgeEntity?
return function(forgeEntity)
	if (not forgeEntity) then
		return
	end

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
	if ImGui.ArrowButton("##xRot-", 2) then
		EntityForge:RotateAttachment(
			forgeEntity,
			-0.05 * attachmentRotationModifier,
			0,
			0
		)
	end

	ImGui.SameLine()
	if ImGui.ArrowButton("##xRot+", 3) then
		EntityForge:RotateAttachment(
			forgeEntity,
			0.05 * attachmentRotationModifier,
			0,
			0
		)
	end

	ImGui.Text("Y: ")
	ImGui.SameLine()
	if ImGui.ArrowButton("##yRot-", 0) then
		EntityForge:RotateAttachment(
			forgeEntity,
			0,
			-0.05 * attachmentRotationModifier,
			0
		)
	end

	ImGui.SameLine()
	if ImGui.ArrowButton("##yRot+", 1) then
		EntityForge:RotateAttachment(
			forgeEntity,
			0,
			0.05 * attachmentRotationModifier,
			0
		)
	end

	ImGui.Text("Z: ")
	ImGui.SameLine()
	if ImGui.ArrowButton("##zRot+", 2) then
		EntityForge:RotateAttachment(
			forgeEntity,
			0,
			0,
			0.05 * attachmentRotationModifier
		)
	end

	ImGui.SameLine()
	if ImGui.ArrowButton("##zRot-", 3) then
		EntityForge:RotateAttachment(
			forgeEntity,
			0,
			0,
			-0.05 * attachmentRotationModifier
		)
	end

	ImGui.PopButtonRepeat()

	ImGui.Dummy(1, 10)
	ImGui.TextWrapped(_T("EF_ROTATION_AXIS_HINT"))
end
