local raw = require('includes.ssv2.data.heist_definitions')
local properties = require('includes.ssv2.data.mp_properties')
local Managed = require('includes.ssv2.core.managed_value')
local apartment_ids = { 'ROOT_ID_HASH_THE_FLECCA_JOB', 'ROOT_ID_HASH_THE_PRISON_BREAK',
    'ROOT_ID_HASH_THE_HUMANE_LABS_RAID',
    'ROOT_ID_HASH_SERIES_A_FUNDING', 'ROOT_ID_HASH_THE_PACIFIC_STANDARD_JOB' }
local apartment_names = { 'HTITLE_TUT', 'HTITLE_PRISON', 'HTITLE_HUMANE', 'HTITLE_NARC', 'HTITLE_ORNATE' }
local function bit_value(name, index) return bit.band(stats.get_int(name), bit.lshift(1, index)) ~= 0 end
local function flip(name, index) stats.set_int(name, bit.bxor(stats.get_int(name), bit.lshift(1, index))) end
return function(ctx)
    local data = ctx.script_data
    local f = {
        id = 'heists',
        category = 'online',
        scope = 'player',
        selected = 0,
        entries = {},
        leases = {},
        next_update = 0,
        controls = {
            { kind = 'toggle', path = 'ui.show_heists',                         label = 'Heist Editor' },
            { kind = 'toggle', path = 'features.yim_heists.ignore_prop_req',    label = 'Ignore property requirement' },
            { kind = 'toggle', path = 'features.yim_heists.dday_cd',            label = 'Doomsday cooldown' },
            { kind = 'toggle', path = 'features.yim_heists.dre_cd',             label = 'The Contract cooldown' },
            { kind = 'toggle', path = 'features.yim_heists.cayo_cd',            label = 'Cayo Perico cooldown' },
            { kind = 'toggle', path = 'features.yim_heists.kortz_cd',           label = 'Kortz heist cooldown' },
            { kind = 'toggle', path = 'features.yim_heists.kortz_week_bypass',  label = 'Kortz weekly payout limit' },
            { kind = 'toggle', path = 'features.dunk.disable_heist_cooldown',   label = 'Casino heist cooldown' },
            { kind = 'toggle', path = 'features.dunk.zero_ai_cuts',             label = 'Zero casino crew cuts' },
            { kind = 'toggle', path = 'features.dunk.ch_cart_autograb',         label = 'Casino trolley auto-grab' },
            { kind = 'toggle', path = 'features.yim_heists.cayo_cart_autograb', label = 'Cayo trolley auto-grab' },
        }
    }
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready() return network.is_session_started() end

    function f:property(name, stat, adjust)
        local id = stats.get_int(stat) - (adjust or 0)
        return properties[name] and properties[name][id] or nil
    end

    function f:refresh_apartment(entry)
        local content = data:global('jobs_root_content_id_global')
        local current = content and content:get_int()
        entry.current_strand = nil; entry.none_unlocked = true
        for index, name in ipairs(apartment_ids) do
            local hash = tunables.get_int(name)
            if current == hash then entry.current_strand = apartment_names[index] end
            if stats.get_int('MPX_HEIST_SAVED_STRAND_' .. (index - 1)) == hash then entry.none_unlocked = false end
        end
    end

    function f:enter()
        self.serial = (self.serial or 0) + 1
        self.entries = {
            { name = 'Apartment heists', kind = 'apartment', selection = 0,                  script = 'fm_mission_controller', cuts = { 25, 25, 25, 25 } },
            { name = 'Doomsday',         kind = 'doomsday',  selection = -1,                 script = 'fm_mission_controller', property = self:property('Facilities', 'MPX_DBASE_OWNED'), cuts = { 25, 25, 25, 25 } },
            { name = 'Casino heist',     kind = 'casino',    metadata = raw.CasinoHeistData, setup = {},                       script = 'fm_mission_controller',                          property = self:property('Arcades', 'MPX_ARCADE_OWNED'), cuts = { 25, 25, 25, 25 } },
            {
                name = 'Cayo Perico',
                kind = 'cayo',
                metadata = raw.CayoPericoData,
                setup = {},
                script = 'fm_mission_controller_2020',
                owned = stats.get_int('MPX_IH_SUB_OWNED') % 4294967296 == 1336872304,
                cuts = { 25, 25, 25, 25 }
            },
            { name = 'Kortz heist',  kind = 'kortz',    metadata = raw.K26Data,   selection = stats.get_int('MPX_K26_HEIST_TARGET'), script = 'fm_mission_controller_v3' },
            { name = 'The Contract', kind = 'contract', metadata = raw.DrDreData, selection = 0,                                     script = 'fm_mission_controller_2020', property = self:property('Agencies', 'MPX_FIXER_HQ_OWNED') },
        }
        for index, name in ipairs({ 'AJ', 'MD', 'TH' }) do
            if stats.get_int('MPX_MANSION_' .. name .. '_PLANNING_ROOM') > 0 or stats.get_int('MPX_MANSION_' .. name .. '_OWNED') > 0 then
                self.entries[5].property = properties.Mansions[index]; self.entries[5].art_room = stats.get_int(
                    'MPX_MANSION_' .. name .. '_PLANNING_ROOM') > 0; break
            end
        end
        for _, entry in ipairs(self.entries) do
            if entry.metadata and entry.metadata.setup_data then
                for key, definition in pairs(entry.metadata.setup_data) do
                    local value = stats.get_int(definition.stat)
                    entry.setup[key] = math.max(0, math.min(definition.data_size - 1, value))
                end
            end
        end
        for act = 0, 2 do
            if bit_value('MPX_GANGOPS_HEIST_STATUS', act) then
                self.entries[2].selection = act; break
            end
        end
        for index = 0, 11 do if bit_value('MPX_FIXER_STORY_BS', index) then self.entries[6].selection = index end end
        self:refresh_apartment(self.entries[1])
        self.entries[6].none_unlocked = not (bit_value('MPX_FIXER_GENERAL_BS', 0) and bit_value('MPX_FIXER_GENERAL_BS', 4))
        local progress = self.entries[6].selection
        stats.set_int('MPX_FIXER_STORY_STRAND',
            progress >= 4 and progress <= 6 and 1 or progress >= 7 and progress <= 9 and 2 or 0)
        self.next_update = 0
    end

    function f:cleanup()
        self.serial = (self.serial or 0) + 1
        for _, value in pairs(self.leases) do value:clear() end
        self.leases = {}; self.entries = {}
    end

    function f:allowed(entry)
        if entry.kind == 'kortz' then
            return entry.property ~= nil and entry.art_room or
                ctx.settings:get('features.yim_heists.ignore_prop_req')
        end
        return entry.kind == 'apartment' or entry.property ~= nil or entry.kind == 'cayo' and entry.owned
            or ctx.settings:get('features.yim_heists.ignore_prop_req')
    end

    function f:secondaries(entry, reset)
        for _, pair in ipairs(entry.metadata.secondary_objectives or {}) do
            stats.set_int(pair[1], reset and 0 or pair
                [2])
        end
        if entry.kind == 'casino' and not reset then stats.set_packed_bool(26969, true) end
        if entry.kind == 'kortz' and not reset then
            stats.set_int('MPX_K26_GENERAL_BS',
                bit.bor(stats.get_int('MPX_K26_GENERAL_BS'), bit.bnot(bit.lshift(1, 28))))
        end
    end

    function f:cuts(entry, reset)
        local cuts = entry.cuts
        if reset then for i = 1, 4 do cuts[i] = 25 end end
        if entry.kind == 'apartment' then
            local sum = 0; for _, value in ipairs(cuts) do sum = sum + value end
            assert(sum <= 100, 'Apartment cuts must total at most 100 percent')
            local one = data:global('og_heists_player_cuts_global_1', { 1 })
            local two = data:global('og_heists_player_cuts_global_2', { data:offset('og_heists_player_cuts_global_2', 1) })
            if not one or not two then return end
            local serial, revision = ctx.runtime.generation, self.serial
            local total = 0; for _, value in ipairs(cuts) do total = total + value end
            one:at(0, 1):set_int(100 - total)
            for i = 1, 3 do two:at(i, 1):set_int(cuts[i + 1]) end
            script.yield(500)
            if serial ~= ctx.runtime.generation or revision ~= self.serial or not self.active then return end
            one = data:global('og_heists_player_cuts_global_1', { 1 })
            two = data:global('og_heists_player_cuts_global_2', { data:offset('og_heists_player_cuts_global_2', 1) })
            if not one or not two then return end
            local sum = 0; local values = {}
            for i = 0, 3 do
                values[i + 1] = one:at(i, 1):get_int(); sum = sum + values[i + 1]
            end
            two:at(0, 1):set_int(100 - sum)
            for i = 1, 3 do two:at(i, 1):set_int(values[i + 1]) end
        else
            local target
            if entry.kind == 'doomsday' then
                target = data:global('gb_gang_ops_planning_player_cuts',
                    { data:offset('gb_gang_ops_planning_player_cuts', 1), data:offset('gb_gang_ops_planning_player_cuts',
                        2) })
            elseif entry.kind == 'casino' then
                target = data:global('gb_casino_heist_planning',
                    { data:value('gb_casino_heist_planning_cut_offset'), data:offset(
                        'gb_casino_heist_planning_cut_offset', 1), data:offset('gb_casino_heist_planning_cut_offset', 2) })
            elseif entry.kind == 'cayo' then
                target = data:global('cayo_perico_player_cut_global',
                    { data:value('cayo_perico_player_cut_offsets'), data:offset('cayo_perico_player_cut_offsets', 1) })
            end
            if target then for i, value in ipairs(cuts) do target:at(i):set_int(value) end end
        end
    end

    function f:setup(entry, reset)
        assert(self:allowed(entry), 'Required heist property is not owned')
        if entry.kind == 'casino' or entry.kind == 'cayo' then
            for key, definition in pairs(entry.metadata.setup_data) do
                if reset then entry.setup[key] = 0 end
                stats.set_int(definition.stat, entry.setup[key])
            end
            self:cuts(entry, reset); self:secondaries(entry, reset)
            if entry.kind == 'cayo' and reset then
                stats.set_int('MPX_H4_PROGRESS',
                    bit.band(stats.get_int('MPX_H4_PROGRESS'), bit.bnot(4096)))
            end
        elseif entry.kind == 'doomsday' then
            if reset then
                self:cuts(entry, true); return
            end -- no cancel-heist implementation exists in V1
            local pairs = { { 229383, 503 }, { 229378, 240 }, { 229380, 16368 } }
            local value = assert(pairs[entry.selection + 1], 'Select a Doomsday act')
            stats.set_int('MPX_GANGOPS_HEIST_STATUS', value[1]); stats.set_int('MPX_GANGOPS_FLOW_MISSION_PROG', value[2]); stats
                .set_int('MPX_GANGOPS_FLOW_NOTIFICATIONS', 1557)
        elseif entry.kind == 'apartment' then
            self:cuts(entry, reset); if reset then stats.set_int('MPX_HEIST_PLANNING_STAGE', 0) end
        elseif entry.kind == 'kortz' then
            if reset then
                self:secondaries(entry, true); stats.set_int('MPX_K26_GENERAL_BS', 0)
                local value = data:global('k26_gen_bs_global',
                    { { PLAYER.PLAYER_ID(), data:offset('k26_gen_bs_global', 1) }, data:offset('k26_gen_bs_global', 2) })
                if value then value:set_int(bit.band(value:get_int(), bit.bnot(bit.lshift(1, 28)))) end
            else
                assert(entry.selection >= 0 and entry.selection < #entry.metadata.targets, 'Select a Kortz target')
                stats.set_int('MPX_K26_HEIST_TARGET', entry.selection); self:secondaries(entry, false)
            end
        elseif entry.kind == 'contract' then
            if reset then
                entry.selection = 3; stats.set_int('MPX_FIXER_STORY_BS', 3); stats.set_int('MPX_FIXER_STORY_STRAND', 0); return
            end
            local selection = entry.selection
            local value = 0; for i = 0, selection do value = bit.bor(value, bit.lshift(1, i)) end
            stats.set_int('MPX_FIXER_STORY_BS', value)
            stats.set_int('MPX_FIXER_STORY_STRAND',
                selection >= 4 and selection <= 6 and 1 or selection >= 7 and selection <= 9 and 2 or 0)
        end
    end

    function f:apartment_unlock(selected_only)
        for index, name in ipairs(apartment_ids) do
            if not selected_only or self.entries[1].selection == index - 1 then
                local hash = tunables.get_int(name)
                stats.set_int('MPX_HEIST_SAVED_STRAND_' .. (index - 1), hash)
                stats.set_int('MPX_HEIST_SAVED_STRAND_' .. (index - 1) .. '_L', 5)
                if not selected_only then stats.set_int('MPX_HEIST_SAVED_STRAND_' .. (index - 1) .. '_M', 5) end
                if selected_only then
                    data:global('jobs_root_content_id_global'):set_int(hash); stats.set_int('MPX_CURRENT_HEIST_STRAND',
                        index - 1)
                end
            end
        end
    end

    function f:hard(entry)
        local name, index, key = entry.kind == 'cayo' and 'MPX_H4_PROGRESS' or 'MPX_K26_GENERAL_BS',
            entry.kind == 'cayo' and 12 or 28,
            entry.kind == 'cayo' and 'h4_gen_bs_global' or 'k26_gen_bs_global'
        flip(name, index)
        local path = { { PLAYER.PLAYER_ID(), data:offset(key, 1) }, entry.kind == 'cayo' and 1 or data:offset(key, 2) }
        local value = data:global(key, path); if value then value:set_int(bit.bxor(value:get_int(), bit.lshift(1, index))) end
    end

    function f:boost(index)
        assert(ctx.settings:get('features.unsafe_feats_enabled'), 'Enable original unsafe feature controls first')
        flip('MPX_WEEKLY_BOOST_BS', index)
        local root = data:global_index(262145 + data:value('heist_boosts_global_start'))
        if root then
            if root:get_int() ~= 0 then root:set_int(0) end
            root:at(index, 1):set_int(bit_value('MPX_WEEKLY_BOOST_BS', index) and 1 or 0)
        end
    end

    function f:lease(name, definition, enabled)
        local value = self.leases[name]
        if enabled then
            if not value then
                value = Managed.new(ctx, definition); self.leases[name] = value
            end
            value:set_desired(definition.v); value:apply()
        elseif value then
            value:clear(); self.leases[name] = nil
        end
    end

    function f:update()
        if util.time() < self.next_update then return end
        local mission = false
        for _, entry in ipairs(self.entries) do
            local was_running = entry.running
            mission = mission or scripts.is_active(entry.script)
            entry.running = scripts.is_active(entry.script) and NETWORK.NETWORK_IS_ACTIVITY_SESSION()
            if was_running and not entry.running then
                if entry.cuts then for i = 1, 4 do entry.cuts[i] = 25 end end
                if entry.setup then
                    for key, definition in pairs(entry.metadata.setup_data) do
                        entry.setup[key] = math.max(0, math.min(definition.data_size - 1, stats.get_int(definition.stat)))
                    end
                end
            end
        end
        if not mission then
            for _, definition in ipairs({ { 'features.yim_heists.dday_cd', 'MPX_GANGOPS_LAUNCH_TIME', 'stat', os.time() - 2629743 },
                { 'features.yim_heists.dre_cd',           'FIXER_STORY_COOLDOWN_POSIX', 'tunable', os.time() - 2629743 },
                { 'features.yim_heists.dre_cd',           'MPX_FIXER_STORY_COOLDOWN',   'stat',    0 },
                { 'features.dunk.disable_heist_cooldown', 'MPPLY_H3_COOLDOWN',          'stat',    0 }, { 'features.dunk.disable_heist_cooldown', 'MPX_H3_COMPLETEDPOSIX', 'stat', 0 },
                { 'features.yim_heists.cayo_cd', 'MPX_H4_COOLDOWN',   'stat', 0 }, { 'features.yim_heists.cayo_cd', 'MPX_H4_COOLDOWN_HARD', 'stat', 0 },
                { 'features.yim_heists.cayo_cd', 'MPPLY_H4_COOLDOWN', 'stat', 0 }, { 'features.yim_heists.cayo_cd', 'H4_COOLDOWN_TIME', 'tunable', 0 },
                { 'features.yim_heists.cayo_cd',  'H4_COOLDOWN_HARD_TIME',  'tunable', 0 }, { 'features.yim_heists.cayo_cd', 'H4_SOLO_COOLDOWN', 'tunable', 0 },
                { 'features.yim_heists.kortz_cd', 'MPX_K26_HEIST_COOLDOWN', 'stat',    0 }, { 'features.yim_heists.kortz_cd', 'MPX_K26_HEIST_COOLDOWN_HARD', 'stat', 0 },
                { 'features.yim_heists.kortz_cd', 1182453353, 'tunable', 0 } }) do
                self:lease(tostring(definition[2]), {
                    t = definition[2],
                    kind = definition[3],
                    type = 'int',
                    v =
                        definition[4]
                }, ctx.settings:get(definition[1]))
            end
            local week = stats.get_int('MPX_K26_WEEK_ID')
            self:lease('kortz_week', { t = 1372139704, kind = 'tunable', type = 'int', v = week >= 6 and 0 or week + 1 },
                ctx.settings:get('features.yim_heists.kortz_week_bypass'))
            for _, name in ipairs(raw.CasinoHeistData.ai_cuts_tunables) do
                self:lease(name, { t = name, kind = 'tunable', type = 'int', v = 0 },
                    ctx.settings:get('features.dunk.zero_ai_cuts'))
            end
        end
        for _, definition in ipairs({ { 'fmmc_trolley_scene', 'features.dunk.ch_cart_autograb' }, { 'fmmc20_trolley_scene', 'features.yim_heists.cayo_cart_autograb' } }) do
            if ctx.settings:get(definition[2]) then
                local scene = data:local_value(definition[1])
                if scene then
                    if scene:get_int() == 3 then
                        scene:set_int(4)
                    elseif scene:get_int() == 4 then
                        scene:at(data:offset(definition[1], 1)):set_float(2)
                    end
                end
            end
        end
        self.boost_bits = stats.get_int('MPX_WEEKLY_BOOST_BS')
        self.boosted = {}
        local boosts = data:global_index(262145 + data:value('heist_boosts_global_start'))
        for i = 0, #raw.BoostableHeistNames - 1 do
            self.boosted[i] = boosts and boosts:get_int() == 0 and boosts:at(i, 1):get_int() == 0
                and bit.band(self.boost_bits, bit.lshift(1, i)) == 0 or false
        end
        local cayo = self.entries[4]
        local request = data:global('request_services_global', { 613 })
        cayo.requested = request and request:get_int() == 1 or false
        if cayo.owned then
            local submarine = data:global('gpbd', { { PLAYER.PLAYER_ID(), data:offset('gpbd', 1) }, data:offset('gpbd', 2) })
            cayo.spawned = submarine and bit.band(submarine:at(4):get_int(), bit.lshift(1, 31)) ~= 0 or false
            cayo.coords = cayo.spawned and submarine:at(13):get_vector3() or nil
            cayo.heading = cayo.spawned and submarine:at(16):get_float() or 0
        end
        self.entries[4].hard = bit_value('MPX_H4_PROGRESS', 12); self.entries[5].hard = bit_value('MPX_K26_GENERAL_BS',
            28)
        self.entries[5].lasers_active = scripts.is_active('fmmc_lasers')
        self.mission_active = mission
        for i, launcher in ipairs({ 'fmmc_launcher', 'gb_gang_ops_planning', 'gb_casino_heist_planning', 'heist_island_planning' }) do
            self.entries[i].launcher_active = scripts.is_active(launcher)
        end
        for _, index in ipairs({ 3, 5 }) do
            local entry = self.entries[index]; entry.secondaries_unlocked = true
            for _, pair in ipairs(entry.metadata.secondary_objectives) do
                if stats.get_int(pair[1]) ~= pair[2] then
                    entry.secondaries_unlocked = false; break
                end
            end
            if index == 3 then entry.secondaries_unlocked = entry.secondaries_unlocked and stats.get_packed_bool(26969) end
        end
        self.next_update = util.time() + 500
    end

    function f:run(label, callback)
        local generation, serial = ctx.runtime.generation, self.serial
        ctx.runtime:run(label,
            function() if self.active and ctx.runtime.generation == generation and self.serial == serial then callback() end end)
    end

    f.frontend = require('includes.ssv2.core.heist_view').new(ctx, f)
    f.owns_controls = true
    function f:draw() self.frontend:draw() end

    return f
end
