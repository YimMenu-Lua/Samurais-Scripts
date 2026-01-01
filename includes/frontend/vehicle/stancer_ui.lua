local PV = Self:GetVehicle()
local Stancer = PV.m_stance_mgr
local stanceQueue = Stancer.m_queue

local ref <const> = {
	m_front_track_width_queue = { label = "Front Track Width", fmt = "%.3f", min = 0.1, max = 1.0 },
	m_rear_track_width_queue  = { label = "Rear Track Width", fmt = "%.3f", min = 0.1, max = 1.0 },
	m_front_camber_queue      = { label = "Front Camber", fmt = "%.2f°", min = -1.0, max = 1.0 },
	m_rear_camber_queue       = { label = "Rear Camber", fmt = "%.2f°", min = -1.0, max = 1.0 },
	m_wheel_width_queue       = { label = "Wheel Width", fmt = "%.2f", min = 0.1, max = 2.0 },
	m_wheel_size_queue        = { label = "Wheel Size", fmt = "%.2f", min = 0.1, max = 2.0 },
}

local ref_order <const> = {
	"m_front_camber_queue",
	"m_rear_camber_queue",
	"m_front_track_width_queue",
	"m_rear_track_width_queue",
	"m_wheel_width_queue",
	"m_wheel_size_queue",
}

return function()
	if (self.get_veh() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	elseif (not Stancer.m_is_active) then
		ImGui.Text(_T("GENERIC_CARS_ONLY"))
		return
	end

	for i = 1, #ref_order do
		local k = ref_order[i]
		local should_disable = (k == "m_wheel_width_queue" or k == "m_wheel_size_queue") and not PV:HasWheelDrawData()

		if (should_disable) then
			ImGui.BeginDisabled()
		end
		stanceQueue[k], _ = ImGui.SliderFloat(ref[k].label, stanceQueue[k], ref[k].min, ref[k].max, ref[k].fmt)
		if (should_disable) then
			ImGui.EndDisabled()
		end
		if (should_disable) then
			GUI:Tooltip("You can not modify wheel diameter and width on stock wheels.")
		end
	end

	ImGui.Dummy(1, 10)
	ImGui.TextDisabled("Work In Progress.")
end
