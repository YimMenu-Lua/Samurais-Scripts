local options = { { 'disable_ocean_waves', 'WRLD_DISABLE_WAVES' }, { 'extend_bounds', 'WRLD_EXTEND_BOUNDS' },
    { 'disable_flight_music', 'WRLD_FLIGHT_MUSIC' }, { 'disable_wanted_music', 'WRLD_WANTED_MUSIC' } }
return function(ctx)
    local f = { id = 'world_misc', category = 'world', owned = {}, controls = {} }
    for _, option in ipairs(options) do
        f.controls[#f.controls + 1] = { kind = 'toggle', path = 'features.world.' .. option[1], label = option[2] }
    end
    local function apply(key, value)
        if key == 'extend_bounds' then
            if value then
                PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(-42069420, -42069420, -42069420)
                PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(42069420, 42069420, 42069420)
            else
                PLAYER.RESET_WORLD_BOUNDARY_FOR_PLAYER()
            end
        elseif key == 'disable_ocean_waves' then
            MISC.WATER_OVERRIDE_SET_STRENGTH(value and 1 or -1)
        else
            AUDIO.SET_AUDIO_FLAG(key == 'disable_flight_music' and 'DisableFlightMusic' or 'WantedMusicDisabled', value)
        end
    end
    function f:enabled()
        for _, option in ipairs(options) do if ctx.settings:get('features.world.' .. option[1]) then return true end end
        return false
    end

    function f:disable() for _, option in ipairs(options) do ctx.settings:set('features.world.' .. option[1], false) end end

    function f:ready() return true end

    function f:update()
        for _, option in ipairs(options) do
            local key = option[1]
            local value = ctx.settings:get('features.world.' .. key)
            if value and not self.owned[key] then
                apply(key, true); self.owned[key] = true
            elseif not value and self.owned[key] then
                apply(key, false); self.owned[key] = nil
            end
        end
    end

    function f:cleanup()
        for key in pairs(self.owned) do apply(key, false) end
        self.owned = {}
    end

    return f
end
