local Stancer = Self:GetVehicle().m_stance_mgr
local stanceQueue = Stancer.m_object_queue

return function()
	if (self.get_veh() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	end

	for i, obj in ipairs(stanceQueue) do
		if (i < 3 and i % 2 == 0) then
			obj.m_front_camber, _ = ImGui.SliderFloat("Front Camber", obj.m_front_camber, -1.0, 1.0, "%.2f°")
			obj.m_front_track_width, _ = ImGui.SliderFloat("Front Track Width",
				obj.m_front_track_width,
				0.1,
				1.5,
				"%.3f"
			)
			stanceQueue[i - 1].m_front_camber = obj.m_front_camber
			stanceQueue[i - 1].m_front_track_width = obj.m_front_track_width
		elseif (i >= 3 and i % 2 ~= 0) then
			obj.m_rear_camber, _ = ImGui.SliderFloat("Rear Camber", obj.m_rear_camber, -1.0, 1.0, "%.2f°")
			obj.m_rear_track_width, _ = ImGui.SliderFloat("Rear Track Width",
				obj.m_rear_track_width,
				0.1,
				1.5,
				"%.3f"
			)
			if (#stanceQueue > 3) then
				stanceQueue[i + 1].m_rear_camber = obj.m_rear_camber
				stanceQueue[i + 1].m_rear_track_width = obj.m_rear_track_width
			end
		end
	end

	ImGui.Dummy(1, 10)
	ImGui.TextDisabled("Work In Progress.")
end
