local ranges = {
    ['backend.language_index'] = { 1, 12, true },
    ['ui.width'] = { 300, 8192 },
    ['ui.height'] = { 300, 8192 },
    ['ui.layout_revision'] = { 0, 1, true },
    ['ui.last_tab.tab_id'] = { 1, 6, true },
    ['ui.last_tab.array_index'] = { 1, 4, true },
    ['features.self.autoheal.regen_speed'] = { 1, 100, true },
    ['features.vehicle.rgb_lights.speed'] = { 1, 5, true },
    ['features.vehicle.nos.power'] = { 10, 100, true },
    ['features.vehicle.drift.power'] = { 10, 100, true },
    ['features.vehicle.drift.mode'] = { 0, 2, true },
    ['features.vehicle.drift.intensity'] = { 0, 3, true },
    ['features.vehicle.drift_minigame.player_best'] = { 0, 2147483647, true },
    ['features.vehicle.launch_control_mode'] = { 0, 1, true },
    ['features.vehicle.manual_gearbox.mode'] = { 0, 2, true },
    ['features.vehicle.fast_vehicles_speed'] = { 10, 100 },
    ['features.vehicle.fast_jets_speed'] = { 100, 300 },
    ['features.vehicle.aircraft_mg.tiggerbot_range'] = { 100, 1000 },
    ['features.vehicle.aircraft_mg.marker_size'] = { 1, 10 },
    ['features.speedometer.speed_unit'] = { 0, 2, true },
    ['features.speedometer.radius'] = { 80, 300 },
    ['features.dunk.autoplay_slots_delay'] = { 500, 10000, true },
    ['features.dunk.slot_machine_cap'] = { 0, 100000, true },
    ['features.yrv3.autofill_delay'] = { 100, 600000, true },
    ['features.vehicle.bangs_rpm_min'] = { 2000, 8000 },
    ['features.vehicle.bangs_rpm_max'] = { 3000, 9000 },
    ['features.weapon.laser_sights.ray_length'] = { 100, 1000, true },
    ['features.weapon.katana.model'] = { 0, 4294967295, true },
}
return function(path, value)
    local range = ranges[path]
    if path:match('^features%.weapon%.laser_sights%.color%.%d+$') then range = { 0, 1 } end
    if path:match('^features%.vehicle%.drift%.smoke_fx%.color%.%d+$') then range = { 0, 1 } end
    if path == 'features.weapon.laser_sights.color' and type(value) == 'table' then
        local color = {}
        for i = 1, 4 do
            local number = tonumber(value[i]) or 1
            color[i] = number == number and math.max(0, math.min(1, number)) or 1
        end
        return color
    end
    if path:match('^keybinds%..+%.keyboard') then
        range = { 0, 0x20040, true }
    elseif path:match('^keybinds%..+%.controller') then
        range = { 0, 1000, true }
    end
    if range and type(value) == 'number' then
        if value ~= value then value = range[1] end
        value = math.max(range[1], math.min(range[2], value))
        if range[3] then value = math.floor(value) end
        if path == 'keybinds.gui_toggle.keyboard' and value == 0 then value = 0x74 end
    end
    return value
end
