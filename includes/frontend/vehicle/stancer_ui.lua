local PV                = Self:GetVehicle()
local Stancer           = PV.m_stance_mgr
local frontStanceDeltas = Stancer.m_deltas[Stancer.eWheelSide.FRONT]
local backStanceDeltas  = Stancer.m_deltas[Stancer.eWheelSide.BACK]

local ref <const>       = {
	m_camber      = { label = "VEH_STANCE_CAMBER", fmt = "%.2f°", min = -1.0, max = 1.0 },
	m_track_width = { label = "VEH_STANCE_TRACK_WIDTH", fmt = "%.2f", min = -0.5, max = 0.5 },
	m_wheel_width = { label = "VEH_STANCE_WHEEL_WIDTH", fmt = "%.2f", min = -0.5, max = 1.5, drawdata_only = true, tooltip = "VEH_STANCE_NON_STOCK" },
	m_wheel_size  = { label = "VEH_STANCE_WHEEL_SIZE", fmt = "%.2f", min = -0.5, max = 1.5, drawdata_only = true, tooltip = "VEH_STANCE_NON_STOCK" },
}

---@param key string
---@param deltaTable table
---@param side integer
local function DrawSlider(key, deltaTable, side)
	local meta     = ref[key]
	local disabled = (meta.drawdata_only and not Stancer:CanApplyDrawData())

	if (disabled) then
		ImGui.BeginDisabled()
	end
	deltaTable[key], _ = ImGui.SliderFloat(
		_F("%s##%d", _T(meta.label), side),
		deltaTable[key],
		meta.min,
		meta.max, meta.fmt
	)
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

	ImGui.SeparatorText(_T("VEH_STANCE_REAR_AXLE"))
	DrawSlider("m_camber", backStanceDeltas, Stancer.eWheelSide.BACK)
	DrawSlider("m_track_width", backStanceDeltas, Stancer.eWheelSide.BACK)

	if (GUI:Button(_T("VEH_STANCE_COPY_FB"))) then
		backStanceDeltas.m_camber      = frontStanceDeltas.m_camber
		backStanceDeltas.m_track_width = frontStanceDeltas.m_track_width
	end

	ImGui.SeparatorText(_T("VEH_STANCE_GEN_OPTIONS"))
	Stancer.m_suspension_height.m_current, _ = ImGui.SliderFloat(
		_T("VEH_STANCE_RIDE_HEIGHT"),
		Stancer.m_suspension_height.m_current,
		-0.2,
		0.2
	)

	DrawSlider("m_wheel_width", frontStanceDeltas, Stancer.eWheelSide.FRONT)
	DrawSlider("m_wheel_size", frontStanceDeltas, Stancer.eWheelSide.FRONT)

	if (GUI:Button(_T("GENERIC_RESET"))) then
		Stancer:Reset()
		ThreadManager:Run(function()
			if (not PV:IsValid()) then
				return
			end
			VEHICLE.RESET_VEHICLE_WHEELS(PV:GetHandle(), true)
		end)
	end

	ImGui.Dummy(1, 10)
end
