local function DummyVehicleTab()
    GVars.features.vehicle.abs_lights, _ = GUI:Checkbox("Brake Force Display",
        GVars.features.vehicle.abs_lights,
        { tooltip = "Flashes your brake lights when braking from high speed. Only for vehicles equipped with ABS." }
    )

    GVars.features.speedometer.enabled, _ = GUI:Checkbox("Speedometer", GVars.features.speedometer.enabled)

    if (GVars.features.speedometer.enabled) then
        ImGui.Text("Speed Unit")
        GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("M/s", GVars.features.speedometer.speed_unit, 0)
        ImGui.SameLine()
        GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("Km/h", GVars.features.speedometer.speed_unit, 1)
        ImGui.SameLine()
        GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("Mi/h", GVars.features.speedometer.speed_unit, 2)
    end

    GVars.features.vehicle.fast_vehicles, _ = GUI:Checkbox("Fast Vehicles",
        GVars.features.vehicle.fast_vehicles,
        { tooltip = "Increases the top speed of any land vehicle you drive." }
    )
end

GUI:RegisterNewTab(eTabID.TAB_VEHICLE, "Vehicle", DummyVehicleTab)
