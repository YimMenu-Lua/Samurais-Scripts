local entries = {
    { 'SELF_ABILITY_STAM',          'STAMINA',             'SCRIPT_INCREASE_STAM' },
    { 'SELF_ABILITY_SHOOTING',      'SHOOTING_ABILITY',    'SCRIPT_INCREASE_SHO' },
    { 'SELF_ABILITY_STRENGTH',      'STRENGTH',            'SCRIPT_INCREASE_STRN' },
    { 'SELF_ABILITY_STEALTH',       'STEALTH_ABILITY',     'SCRIPT_INCREASE_STL' },
    { 'SELF_ABILITY_FLYING',        'FLYING_ABILITY',      'SCRIPT_INCREASE_FLY' },
    { 'SELF_ABILITY_DRIVING',       'WHEELIE_ABILITY',     'SCRIPT_INCREASE_DRIV' },
    { 'SELF_ABILITY_LUNG_CAPACITY', 'LUNG_CAPACITY',       'SCRIPT_INCREASE_LUNG' },
    { 'SELF_ABILITY_MENTAL_STATE',  'PLAYER_MENTAL_STATE', 'PLAYER_MENTAL_STATE', true },
}
return function(ctx)
    local f = {
        id = 'abilities',
        category = 'self',
        values = {},
        next_read = 0,
        controls = { { kind = 'toggle', path = 'ui.show_abilities', label = 'SELF_ABILITY_EDITOR' } }
    }
    function f:enabled() return ctx.settings:get('ui.show_abilities') end

    function f:disable() ctx.settings:set('ui.show_abilities', false) end

    function f:ready() return network.is_session_started() end

    function f:update()
        if util.time() < self.next_read then return end
        for i, entry in ipairs(entries) do
            self.values[i] = (entry[4] and stats.get_float or stats.get_int)('MPX_' .. entry[2])
        end
        self.next_read = util.time() + 250
    end

    function f:adjust(index, delta)
        if not network.is_session_started() then return end
        local entry = entries[index]
        local get, set = entry[4] and stats.get_float or stats.get_int, entry[4] and stats.set_float or stats.set_int
        local name = 'MPX_' .. entry[3]
        local value = get(name) + delta
        if value >= 0 and value <= 100 then set(name, value) end
        self.next_read = 0
    end

    function f:cleanup() self.values, self.next_read = {}, 0 end

    function f:draw()
        if not self:enabled() or not self.active then return end
        ImGui.PushButtonRepeat(true)
        for index, entry in ipairs(entries) do
            local i, value = index, self.values[index]
            if value ~= nil then
                ImGui.PushID(index)
                ImGui.Text(ctx.translator:text(entry[1]))
                ImGui.BeginDisabled(value <= 0)
                if ImGui.Button(' - ') then ctx.runtime:run('decrease ability', function() self:adjust(i, -1) end) end
                ImGui.EndDisabled(); ImGui.SameLine()
                ImGui.ProgressBar(value / 100, 300, 30)
                ImGui.SameLine(); ImGui.BeginDisabled(value >= 100)
                if ImGui.Button(' + ') then ctx.runtime:run('increase ability', function() self:adjust(i, 1) end) end
                ImGui.EndDisabled(); ImGui.PopID()
            end
        end
        ImGui.PopButtonRepeat()
    end

    return f
end
