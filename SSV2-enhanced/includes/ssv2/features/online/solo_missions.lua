local Feature = require('includes.ssv2.core.feature')
return function(ctx)
    local data = ctx.script_data
    local f = Feature.new(ctx,
        {
            id = 'solo_missions',
            category = 'online',
            scope = 'player',
            path = 'features.yim_heists.solo_missions',
            controls = {
                { kind = 'toggle', path = 'features.yim_heists.solo_missions', label = 'YH_SOLO_MISSIONS' },
            },
            saved = {}
        })
    function f:ready() return network.is_session_started() end

    function f:write(global, value)
        if not global then return end
        local address = global:get_pointer():get_address()
        if not self.saved[address] then
            self.saved[address] = {
                global = global,
                original = global:get_int(),
                address =
                    address
            }
        end
        global:set_int(value)
    end

    function f:cleanup()
        for _, item in pairs(self.saved) do
            if item.global:can_access() and item.global:get_pointer():get_address() == item.address then
                item.global
                    :set_int(item.original)
            end
        end
        self.saved = {}
        if self.patch then self.patch:disable() end
    end

    function f:patch_casino(enabled)
        if enabled then
            if not self.patch then
                self.patch = ScriptPatch.new('fmmc_launcher', 'ssv2_solo_casino',
                    '2D 01 03 00 00 5D ? ? ? 2A 06 56 05 00 5D ? ? ? 20 2A 06 56 05 00 5D', 5, { 0x71, 0x2E, 0x01, 0x01 })
            end
            self.patch:enable()
        elseif self.patch then
            self.patch:disable()
        end
    end

    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function()
        if f.patch then
            f.patch:remove(); f.patch = nil
        end
    end
    function f:update()
        if self.patch_enabled then self:patch_casino(true) end
        local root = 'solo_missions_global'
        for _, pair in ipairs({ { 1, 1 }, { 4, 1 }, { 6, 0 }, { 2, 1 }, { 3, 1 } }) do
            local offsets = { data:value('solo_missions_global_offset_' .. pair[1]) }
            if pair[1] == 4 or pair[1] == 6 then offsets[#offsets + 1] = 1 end
            self:write(data:global(root, offsets), pair[2])
        end
        if scripts.is_active('fmmc_launcher') then
            local variation = data:read_local('fmmc_launcher_min_players_local',
                { data:value('fmmc_launcher_mission_var_offset') })
            if variation and variation > 0 then
                data:write_local('fmmc_launcher_min_players_local', 1, { data:offset('fmmc_launcher_min_players_local', 1) })
                self:write(data:global('solo_missions_mission_header_global', {
                        data:offset('solo_missions_mission_header_global', 1), { variation, data:offset('solo_missions_mission_header_global', 2) }, 75 }),
                    1)
            end
        end
    end

    function f:mission()
        if scripts.is_active('fm_mission_controller') then
            return 'fmmc_skip_obj_local', 'fmmc_team_score_offset', 'fm_mission_controller'
        elseif scripts.is_active('fm_mission_controller_2020') then
            return 'fmmc_20_skip_obj_local', 'fmmc_20_team_score_offset', 'fm_mission_controller_2020'
        end
    end

    function f:skip()
        local key = self:mission(); if key then data:write_local_bits(key, { 17 }, true, { 2 }) end
    end

    function f:fail()
        local key = self:mission(); if key then data:write_local_bits(key, { 16, 20 }, true, { 1 }) end
    end

    function f:finish()
        local key, score_key = self:mission(); if not key then return end
        local content = data:global('solo_missions_global', { data:value('solo_missions_global_offset_5') })
        if content then for i = 0, 5 do content:at(i, 6):set_string('', 48) end end
        data:write_local(key, 5, { data:offset(key, 1) })
        data:write_local(key, bit.bor(999999, bit.lshift(1, 9), bit.lshift(1, 16)), { data:value(score_key), 1 })
    end

    function f:draw()
        ImGui.BeginDisabled(not ctx.online or not ctx.build.compatible)
        for _, action in ipairs({ { 'Skip mission objective', 'skip' }, { 'Fail mission', 'fail' }, { 'Finish mission', 'finish' } }) do
            if ImGui.Button(action[1]) then ctx.runtime:run(action[2], function() self[action[2]](self) end) end
        end
        ImGui.EndDisabled()
        if self.active then
            local enabled, changed = ImGui.Checkbox('Casino solo planning-board patch', self.patch_enabled or false)
            if changed then
                self.patch_enabled = enabled; ctx.runtime:run('solo_patch', function() self:patch_casino(enabled) end)
            end
        end
    end

    return f
end
