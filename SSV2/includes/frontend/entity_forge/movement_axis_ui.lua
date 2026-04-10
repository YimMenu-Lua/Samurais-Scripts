local attachmentMovementModifier = 1.0

---@param forgeEntity ForgeEntity?
return function(forgeEntity)
	if (not forgeEntity) then
		return
	end

	ImGui.SeparatorText(_T("EF_MOVE_OBJECT"))
	ImGui.Dummy(1, 10)
	ImGui.SetNextItemWidth(-1)
	attachmentMovementModifier = ImGui.SliderFloat(
		"##f_amvm",
		attachmentMovementModifier,
		1.0,
		100.0,
		_T("EF_MULTIPLIER_LABEL")
	)

	ImGui.Dummy(1, 10)
	ImGui.PushButtonRepeat(true)
	ImGui.Text("X: ")
	ImGui.SameLine()
	if ImGui.ArrowButton("##left", 0) then
		EntityForge:MoveAttachment(
			forgeEntity,
			-0.001 * attachmentMovementModifier,
			0, 0
		)
	end

	ImGui.SameLine()
	if ImGui.ArrowButton("##right", 1) then
		EntityForge:MoveAttachment(
			forgeEntity,
			0.001 * attachmentMovementModifier,
			0,
			0
		)
	end

	ImGui.Text("Y: ")
	ImGui.SameLine()
	if ImGui.ArrowButton("##front", 2) then
		EntityForge:MoveAttachment(
			forgeEntity,
			0,
			0.001 * attachmentMovementModifier,
			0
		)
	end

	ImGui.SameLine()
	if ImGui.ArrowButton("##back", 3) then
		EntityForge:MoveAttachment(
			forgeEntity,
			0,
			-0.001 * attachmentMovementModifier,
			0
		)
	end

	ImGui.Text("Z: ")
	ImGui.SameLine()
	if ImGui.ArrowButton("##Up", 2) then
		EntityForge:MoveAttachment(
			forgeEntity,
			0,
			0,
			0.001 * attachmentMovementModifier
		)
	end

	ImGui.SameLine()
	if ImGui.ArrowButton("##Down", 3) then
		EntityForge:MoveAttachment(
			forgeEntity,
			0,
			0,
			-0.001 * attachmentMovementModifier
		)
	end

	ImGui.PopButtonRepeat()
	ImGui.Dummy(1, 10)
	ImGui.TextWrapped("Movement is relative to the attachment bone.")
end
