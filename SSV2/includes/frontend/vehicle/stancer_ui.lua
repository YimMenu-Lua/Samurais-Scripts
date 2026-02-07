-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PV                   = Self:GetVehicle()
local Stancer              = PV.m_stance_mgr
local frontStanceDeltas    = Stancer.m_deltas[Stancer.eWheelSide.FRONT]
local backStanceDeltas     = Stancer.m_deltas[Stancer.eWheelSide.BACK]
local selected_saved_model = 0
local saved_vehs_window    = { should_draw = false }
local auto_apply_clicked   = false
local bounce_mode_clicked  = false

local ref <const>          = {
	m_camber      = {
		label = "VEH_STANCE_CAMBER",
		fmt = "%.2f°",
		min = function()
			return -1.0
		end,
		max = function()
			return 1.0
		end
	},
	m_track_width = {
		label = "VEH_STANCE_TRACK_WIDTH",
		fmt = "%.2f",
		min = function()
			return -0.5
		end,
		max = function()
			return 0.5
		end,
	},
	m_susp_comp   = {
		label = "VEH_STANCE_SUSP_COMP",
		fmt = "%.2f",
		min = function()
			return -Stancer.m_base_values[Stancer.eWheelSide.FRONT].m_susp_comp + 0.1
		end,
		max = function()
			return Stancer.m_base_values[Stancer.eWheelSide.FRONT].m_susp_comp - 0.1
		end,
	},
	m_wheel_width = {
		label = "VEH_STANCE_WHEEL_WIDTH",
		fmt = "%.2f",
		min = function()
			return -0.5
		end,
		max = function()
			return 0.5
		end,
		drawdata_only = true,
		tooltip = "VEH_STANCE_NON_STOCK"
	},
	m_wheel_size  = {
		label = "VEH_STANCE_WHEEL_SIZE",
		fmt = "%.2f",
		min = function()
			return -0.5
		end,
		max = function()
			return 0.5
		end,
		drawdata_only = true,
		tooltip = "VEH_STANCE_NON_STOCK"
	},
}

local function OnSuspensionReset()
	ThreadManager:Run(function()
		if (not PV:IsValid()) then
			return
		end
		VEHICLE.RESET_VEHICLE_WHEELS(PV:GetHandle(), true)
		VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(PV:GetHandle(), 5.0)
	end)
end

local function UpdatePhysics()
	ThreadManager:Run(function()
		if (not PV:IsValid()) then
			return
		end
		PHYSICS.ACTIVATE_PHYSICS(PV:GetHandle())
	end)
end

---@param current_f float
---@param max_f float
---@param step_f float
---@param current_r float
---@param max_r float
---@param step_r float
local function FakeAirSuspension(current_f, max_f, step_f, current_r, max_r, step_r)
	ThreadManager:Run(function()
		local delta = Game.GetFrameTime()
		for i = current_f, max_f, step_f do
			i = i + step_f * math.sin(delta)
			frontStanceDeltas.m_susp_comp = i
			UpdatePhysics()
			sleep(30)
		end
		frontStanceDeltas.m_susp_comp = max_f

		for i = current_r, max_r, step_r do
			i = i + step_r * math.sin(delta)
			backStanceDeltas.m_susp_comp = i
			UpdatePhysics()
			sleep(30)
		end
		backStanceDeltas.m_susp_comp = max_r
	end)
end

---@param key string
---@param deltaTable table
---@param side integer
---@param needsPhysicsUpdate? boolean
local function DrawSlider(key, deltaTable, side, needsPhysicsUpdate)
	local meta     = ref[key]
	local disabled = (meta.drawdata_only and not Stancer:CanApplyDrawData())
	local label    = _F("%s##%d", _T(meta.label), side)
	if (disabled) then
		ImGui.BeginDisabled()
	end
	ImGui.PushButtonRepeat(true)
	if (ImGui.ArrowButton(_F("##%s_-", label), 0)) then
		deltaTable[key] = math.max(meta.min(), deltaTable[key] - 0.01)
		if (needsPhysicsUpdate) then
			UpdatePhysics()
		end
	end
	ImGui.SameLine()
	deltaTable[key], _ = ImGui.SliderFloat(
		_F("##%s", label),
		deltaTable[key],
		meta.min(),
		meta.max(), meta.fmt
	)
	if (ImGui.IsItemDeactivatedAfterEdit()) then
		if (needsPhysicsUpdate) then
			UpdatePhysics()
		end
	end
	ImGui.SameLine()
	if (ImGui.ArrowButton(_F("##%s_+", label), 1)) then
		deltaTable[key] = math.min(meta.max(), deltaTable[key] + 0.01)
		if (needsPhysicsUpdate) then
			UpdatePhysics()
		end
	end
	ImGui.PopButtonRepeat()
	ImGui.SameLine()
	ImGui.Text(_T(meta.label))
	if (disabled) then
		ImGui.EndDisabled()
		GUI:HelpMarker(_T(meta.tooltip or "VEH_STANCE_INCOMPATIBLE"))
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
	ImGui.BeginDisabled(Stancer.m_bounce_mode.enabled)
	DrawSlider("m_susp_comp", frontStanceDeltas, Stancer.eWheelSide.FRONT, true)
	ImGui.EndDisabled()

	ImGui.SeparatorText(_T("VEH_STANCE_REAR_AXLE"))
	DrawSlider("m_camber", backStanceDeltas, Stancer.eWheelSide.BACK)
	DrawSlider("m_track_width", backStanceDeltas, Stancer.eWheelSide.BACK)
	ImGui.BeginDisabled(Stancer.m_bounce_mode.enabled)
	DrawSlider("m_susp_comp", backStanceDeltas, Stancer.eWheelSide.BACK, true)
	ImGui.EndDisabled()

	ImGui.Spacing()

	if (GUI:Button(_T("VEH_STANCE_COPY_FB"))) then
		backStanceDeltas.m_camber      = frontStanceDeltas.m_camber
		backStanceDeltas.m_track_width = frontStanceDeltas.m_track_width
	end

	ImGui.SeparatorText(_T("VEH_STANCE_GEN_OPTIONS"))

	ImGui.BeginDisabled(Stancer.m_bounce_mode.enabled)
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
	ImGui.EndDisabled()

	DrawSlider("m_wheel_width", frontStanceDeltas, Stancer.eWheelSide.FRONT)
	DrawSlider("m_wheel_size", frontStanceDeltas, Stancer.eWheelSide.FRONT)

	ImGui.Spacing()

	ImGui.SeparatorText(_T("VEH_STANCE_AIR_SUSPENSION"))
	local current_susp_f = frontStanceDeltas.m_susp_comp
	local current_susp_r = backStanceDeltas.m_susp_comp
	local min_susp = ref.m_susp_comp.min()
	local max_susp = ref.m_susp_comp.max()

	ImGui.BeginDisabled(Stancer.m_bounce_mode.enabled)
	ImGui.BeginDisabled((current_susp_f >= max_susp - 0.01) and (current_susp_r >= max_susp - 0.01))
	if (ImGui.Button(_T("VEH_STANCE_AIR_SUSPENSION_RAISE"))) then
		FakeAirSuspension(current_susp_f, max_susp, 0.01, current_susp_r, max_susp, 0.01)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled(math.abs(current_susp_f) == 0 and math.abs(current_susp_r) == 0)
	if (ImGui.Button(_F("%s##airsuspension", _T("GENERIC_RESET")))) then
		local step_f = current_susp_f < 0 and 0.01 or -0.01
		local step_r = current_susp_r < 0 and 0.01 or -0.01
		FakeAirSuspension(current_susp_f, 0.0, step_f, current_susp_r, 0.0, step_r)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled((current_susp_f <= min_susp + 0.01) and (current_susp_r <= min_susp + 0.01))
	if (ImGui.Button(_T("VEH_STANCE_AIR_SUSPENSION_LOWER"))) then
		FakeAirSuspension(current_susp_f, min_susp, -0.01, current_susp_r, min_susp, -0.01)
	end
	ImGui.EndDisabled()
	ImGui.EndDisabled()

	ImGui.SameLine()
	Stancer.m_bounce_mode.enabled, bounce_mode_clicked = GUI:CustomToggle(_T("VEH_STANCE_BOUNCE_MODE"),
		Stancer.m_bounce_mode.enabled,
		{ tooltip = _T("VEH_STANCE_BOUNCE_MODE_TT") }
	)

	if (bounce_mode_clicked and not Stancer.m_bounce_mode.enabled) then
		Stancer:OnBounceModeDisable()
	end

	ImGui.Separator()

	if (GUI:Button(_T("GENERIC_RESET"))) then
		ThreadManager:Run(function()
			Stancer:Reset()
			if (not PV:IsValid()) then
				return
			end
			OnSuspensionReset()
		end)
	end

	local save_label = Stancer:IsVehicleModelSaved() and "VEH_STANCE_UPDATE_MODEL" or "VEH_STANCE_SAVE_MODEL"
	if (GUI:Button(_T(save_label))) then
		Stancer:SaveCurrentVehicle()
	end

	local saved_models = GVars.features.vehicle.stancer.saved_models
	if (next(saved_models) ~= nil) then
		ImGui.SameLine()
		if (GUI:Button(_T("VEH_STANCE_VIEW_SAVED"))) then
			saved_vehs_window.should_draw = true
		end

		ImGui.SameLine()
		GVars.features.vehicle.stancer.auto_apply_saved, auto_apply_clicked = GUI:CustomToggle(
			_T("VEH_STANCE_AUTOAPPLY"),
			GVars.features.vehicle.stancer.auto_apply_saved,
			{ tooltip = _T("VEH_STANCE_AUTOAPPLY_TT") }
		)

		if (auto_apply_clicked and GVars.features.vehicle.stancer.auto_apply_saved) then
			ThreadManager:Run(function()
				Stancer:LoadSavedDeltas()
			end)
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
				ImGui.OpenPopup(_T("GENERIC_REMOVE_ALL"))
			end

			if (ImGui.DialogBox(_T("GENERIC_REMOVE_ALL"))) then
				GVars.features.vehicle.stancer.saved_models = {}
				saved_vehs_window.should_draw = false
			end
		end, function()
			saved_vehs_window.should_draw = false
		end)

		ImGui.End()
	end

	ImGui.Spacing()
end
