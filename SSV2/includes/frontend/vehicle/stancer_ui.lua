local PV                   = Self:GetVehicle()
local Stancer              = PV.m_stance_mgr
local frontStanceDeltas    = Stancer.m_deltas[Stancer.eWheelSide.FRONT]
local backStanceDeltas     = Stancer.m_deltas[Stancer.eWheelSide.BACK]
local selected_saved_model = 0
local saved_vehs_window    = { should_draw = false }
local auto_apply_clicked   = false

local ref <const>          = {
	m_camber      = { label = "VEH_STANCE_CAMBER", fmt = "%.2f°", min = -1.0, max = 1.0 },
	m_track_width = { label = "VEH_STANCE_TRACK_WIDTH", fmt = "%.2f", min = -0.5, max = 0.5 },
	m_susp_comp   = { label = "VEH_STANCE_SUSP_COMP", fmt = "%.2f", min = -0.6, max = 0.6 },
	m_wheel_width = { label = "VEH_STANCE_WHEEL_WIDTH", fmt = "%.2f", min = 0.0, max = 1.5, drawdata_only = true, tooltip = "VEH_STANCE_NON_STOCK" },
	m_wheel_size  = { label = "VEH_STANCE_WHEEL_SIZE", fmt = "%.2f", min = 0.0, max = 1.5, drawdata_only = true, tooltip = "VEH_STANCE_NON_STOCK" },
}

---@param key string
---@param deltaTable table
---@param side integer
local function DrawSlider(key, deltaTable, side)
	local meta     = ref[key]
	local disabled = (meta.drawdata_only and not Stancer:CanApplyDrawData())
	local label    = _F("%s##%d", _T(meta.label), side)
	if (disabled) then
		ImGui.BeginDisabled()
	end
	ImGui.PushButtonRepeat(true)
	if (ImGui.ArrowButton(_F("##%s_-", label), 0)) then
		deltaTable[key] = math.max(meta.min, deltaTable[key] - 0.01)
	end
	ImGui.SameLine()
	deltaTable[key], _ = ImGui.SliderFloat(
		_F("##%s", label),
		deltaTable[key],
		meta.min,
		meta.max, meta.fmt
	)
	ImGui.SameLine()
	if (ImGui.ArrowButton(_F("##%s_+", label), 1)) then
		deltaTable[key] = math.min(meta.max, deltaTable[key] + 0.01)
	end
	ImGui.PopButtonRepeat()
	ImGui.SameLine()
	ImGui.Text(_T(meta.label))
	if (disabled) then
		ImGui.EndDisabled()
		GUI:Tooltip(_T(meta.tooltip or "VEH_STANCE_INCOMPATIBLE"))
	end
end

return function()
	if (self.get_veh() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	elseif (not Stancer.m_is_active) then
		ImGui.Text(_T("GENERIC_CARS_ONLY"))
		return
	end

	ImGui.SeparatorText(_T("VEH_STANCE_FRONT_AXLE"))
	DrawSlider("m_camber", frontStanceDeltas, Stancer.eWheelSide.FRONT)
	DrawSlider("m_track_width", frontStanceDeltas, Stancer.eWheelSide.FRONT)
	DrawSlider("m_susp_comp", frontStanceDeltas, Stancer.eWheelSide.FRONT)

	ImGui.SeparatorText(_T("VEH_STANCE_REAR_AXLE"))
	DrawSlider("m_camber", backStanceDeltas, Stancer.eWheelSide.BACK)
	DrawSlider("m_track_width", backStanceDeltas, Stancer.eWheelSide.BACK)
	DrawSlider("m_susp_comp", backStanceDeltas, Stancer.eWheelSide.BACK)

	ImGui.Spacing()

	if (GUI:Button(_T("VEH_STANCE_COPY_FB"))) then
		backStanceDeltas.m_camber      = frontStanceDeltas.m_camber
		backStanceDeltas.m_track_width = frontStanceDeltas.m_track_width
	end

	ImGui.SeparatorText(_T("VEH_STANCE_GEN_OPTIONS"))

	ImGui.PushButtonRepeat(true)
	if (ImGui.ArrowButton("##rideHight-", 3)) then
		Stancer.m_suspension_height.m_current = math.min(0.2, Stancer.m_suspension_height.m_current + 0.01)
	end
	ImGui.SameLine()
	Stancer.m_suspension_height.m_current, _ = ImGui.SliderFloat(
		"##rideHeight",
		Stancer.m_suspension_height.m_current,
		-0.2,
		0.2
	)
	ImGui.SameLine()
	if (ImGui.ArrowButton("##rideHight+", 2)) then
		Stancer.m_suspension_height.m_current = math.max(-0.2, Stancer.m_suspension_height.m_current - 0.01)
	end
	ImGui.PopButtonRepeat()
	ImGui.SameLine()
	ImGui.Text(_T("VEH_STANCE_RIDE_HEIGHT"))

	DrawSlider("m_wheel_width", frontStanceDeltas, Stancer.eWheelSide.FRONT)
	DrawSlider("m_wheel_size", frontStanceDeltas, Stancer.eWheelSide.FRONT)

	ImGui.Spacing()

	if (GUI:Button(_T("GENERIC_RESET"))) then
		ThreadManager:Run(function()
			Stancer:Reset()

			if (not PV:IsValid()) then
				return
			end
			VEHICLE.RESET_VEHICLE_WHEELS(PV:GetHandle(), true)
			VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(PV:GetHandle(), 5.0)
		end)
	end

	ImGui.SameLine()

	local save_label = Stancer:IsVehicleModelSaved() and "VEH_STANCE_UPDATE_MODEL" or "VEH_STANCE_SAVE_MODEL"
	if (GUI:Button(_T(save_label))) then
		Stancer:SaveCurrentVehicle()
	end

	local saved_models = GVars.features.vehicle.stancer.saved_models
	if (next(saved_models) ~= nil) then
		GVars.features.vehicle.stancer.auto_apply_saved, auto_apply_clicked = GUI:Checkbox(
			_T("VEH_STANCE_AUTOAPPLY"),
			GVars.features.vehicle.stancer.auto_apply_saved,
			{ tooltip = _T("VEH_STANCE_AUTOAPPLY_TT") }
		)

		if (GVars.features.vehicle.stancer.auto_apply_saved and auto_apply_clicked) then
			ThreadManager:Run(function()
				Stancer:LoadSavedDeltas()
			end)
		end

		if (GUI:Button(_T("VEH_STANCE_VIEW_SAVED"))) then
			saved_vehs_window.should_draw = true
		end
	end

	if (saved_vehs_window.should_draw) then
		ImGui.Begin("##viewSavedVehicles",
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.NoMove |
			ImGuiWindowFlags.NoResize
		)
		GUI:QuickConfigWindow(_T("VEH_STANCE_VIEW_SAVED"), function()
			if (ImGui.BeginListBox("##savedVehList", -1, 360)) then
				for model_str in pairs(saved_models) do
					local model = tonumber(model_str) or 0
					local name = vehicles.get_vehicle_display_name(model)
					local is_selected = selected_saved_model == model
					if (ImGui.Selectable(name, is_selected)) then
						selected_saved_model = model
					end
				end
				ImGui.EndListBox()
			end

			ImGui.Separator()

			ImGui.BeginDisabled(selected_saved_model == 0)
			if (GUI:Button(_T("GENERIC_REMOVE"))) then
				GVars.features.vehicle.stancer.saved_models[tostring(selected_saved_model)] = nil
			end
			ImGui.EndDisabled()

			ImGui.SameLine()
			if (GUI:Button(_T("GENERIC_REMOVE_ALL"))) then
				ImGui.OpenPopup("##confirm_remove_all")
			end

			if (GUI:ConfirmPopup("##confirm_remove_all")) then
				Serializer:WithLock(function()
					GVars.features.vehicle.stancer.saved_models = {}
				end)
			end
		end, function()
			saved_vehs_window.should_draw = false
		end)

		ImGui.End()
	end

	ImGui.Spacing()
end
