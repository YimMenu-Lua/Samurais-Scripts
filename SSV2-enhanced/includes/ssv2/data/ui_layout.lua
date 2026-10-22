-- Navigation and control order from SSV2/includes/frontend. GPL-3.0-or-later.
local function item(path, options, draw) return { path = path, options = options or {}, draw = draw } end
local self, vehicle, weapon = 'features.self.', 'features.vehicle.', 'features.weapon.'
return {
    categories = { 'self', 'vehicle', 'world', 'online', 'extra', 'settings' },
    pages = {
        self = { { label = 'TAB_SELF', grid = 'self' } },
        vehicle = {
            {
                label = 'SUBTAB_CARS',
                tabs = {
                    { label = 'SUBTAB_CARS',            grid = 'cars' },
                    { label = 'SUBTAB_HANDLING_EDITOR', feature = 'flag_editor' },
                    { label = 'SUBTAB_STANCER',         feature = 'stancer' },
                    { label = 'VEH_ENGINE_SWAP',        feature = 'engine_swaps' },
                    { label = 'SUBTAB_PAINTS',          feature = 'paints' },
                }
            },
            { label = 'SUBTAB_AIRCRAFT', grid = 'aircraft' },
            { label = 'SUBTAB_FLATBED',  feature = 'flatbed' },
        },
        world = { { label = 'TAB_WORLD', grid = 'world' } },
        online = {
            { label = 'Business Manager',         feature = 'businesses' },
            { label = 'Casino Pacino',            feature = 'casino' },
            { label = 'Heist Editor [WIP]',       feature = 'heists' },
            { label = 'SUBTAB_MPSTAT_CONTROLLER', feature = 'stat_controller' },
        },
        extra = {
            { label = 'YimActions',           feature = 'yim_actions' },
            { label = 'Billionaire Services', feature = 'billionaire_services' },
            { label = 'EntityForge',          feature = 'entity_forge' },
        },
        settings = { { label = 'GENERIC_GENERAL_LABEL', settings = true } },
    },
    grids = {
        self = {
            item(self .. 'autoheal.enabled', { self .. 'autoheal.regen_speed' }),
            item(self .. 'phone_anims'), item(self .. 'mc_alt_bike_anims'), item(self .. 'disable_action_mode'),
            item(self .. 'allow_headprops_in_vehicles'), item(self .. 'stand_on_veh_roof'), item(self .. 'no_carjacking'),
            item(self .. 'crouch'), item(self .. 'hands_up'), item(self .. 'sprint_inside_interiors'),
            item(self .. 'jacking_always_lockpick_anim'),
            item(self .. 'rod', { self .. 'ragdoll_sound' }), item(self .. 'clumsy', { self .. 'ragdoll_sound' }),
            item(weapon .. 'magic_bullet'),
            item(weapon .. 'laser_sights.enabled', { weapon .. 'laser_sights.color', weapon .. 'laser_sights.ray_length' }),
            item(weapon .. 'katana.enabled', nil, 'katana'),
        },
        cars = {
            item('features.speedometer.enabled', nil, 'speedometer'),
            item(vehicle .. 'abs_lights'), item(vehicle .. 'fast_vehicles', { vehicle .. 'fast_vehicles_speed' }),
            item(vehicle .. 'nos.enabled',
                { vehicle .. 'nos.power', vehicle .. 'nos.screen_effect', vehicle .. 'nos.sound_effect', vehicle ..
                'nos.can_damage_engine' }),
            item(vehicle .. 'nos.purge'),
            item(vehicle .. 'burble_tune', { vehicle .. 'bangs_rpm_min', vehicle .. 'bangs_rpm_max' }),
            item(vehicle .. 'drift.enabled', { vehicle .. 'drift.mode', vehicle .. 'drift.power', vehicle ..
            'drift.intensity',
                vehicle .. 'drift.smoke_fx.enabled', vehicle .. 'drift.smoke_fx.color' }),
            item(vehicle .. 'drift_minigame.enabled', { vehicle .. 'drift_minigame.score_sound' }, 'drift_minigame'),
            item(vehicle .. 'subwoofer'), item(vehicle .. 'horn_beams'), item(vehicle .. 'auto_brake_lights'),
            item(vehicle .. 'unbreakable_windows'), item(vehicle .. 'strong_crash'),
            item(vehicle .. 'rgb_lights.enabled', { vehicle .. 'rgb_lights.speed' }),
            item(vehicle .. 'flappy_doors'), item(vehicle .. 'auto_lock_doors'),
            item(vehicle .. 'launch_control', { vehicle .. 'launch_control_mode' }),
            item(vehicle .. 'iv_exit'), item(vehicle .. 'no_wheel_recenter'),
            item(vehicle .. 'mines.enabled', nil, 'mines'), item(vehicle .. 'default_station.enabled', nil,
            'vehicle_misc'),
            item(vehicle .. 'manual_gearbox.enabled', nil, 'manual_gearbox'),
        },
        aircraft = {
            item(vehicle .. 'fast_jets', { vehicle .. 'fast_jets_speed' }), item(vehicle .. 'no_jet_stall'), item(
            vehicle .. 'no_turbulence'),
            item(vehicle .. 'flares'),
            item(vehicle .. 'aircraft_mg.triggerbot',
                { vehicle .. 'aircraft_mg.enemies_only', vehicle .. 'aircraft_mg.tiggerbot_range' }),
            item(vehicle .. 'aircraft_mg.manual_aim',
                { vehicle .. 'aircraft_mg.marker_size', vehicle .. 'aircraft_mg.marker_color' }),
            item(vehicle .. 'cobra_maneuver'),
        },
        world = {
            item('features.world.disable_ocean_waves'), item('features.world.extend_bounds'),
            item('features.world.disable_flight_music'), item('features.world.disable_wanted_music'),
            item('features.world.hide_n_seek'), item('features.world.carpool'),
        },
    },
}
