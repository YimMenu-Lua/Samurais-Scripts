local data_keys = {
    'MPPLY_CASINO_CHIPS_WON_GD', 'MPPLY_CASINO_CHIPS_WONTIM', 'MPPLY_CASINO_GMBLNG_GD', 'MPPLY_CASINO_BAN_TIME',
    'MPPLY_CASINO_CHIPS_PURTIM', 'MPPLY_CASINO_CHIPS_PUR_GD', 'MPPLY_CASINO_CHIPS_SOLD', 'MPPLY_CASINO_CHIPS_SELTIM',
}
local prizes = { 18, 11, 19, 15, 17, 4, 8 }
local prize_labels = { 'CP_LUCKY_WHEEL_GIVE_VEHICLE', 'CP_LUCKY_WHEEL_GIVE_MYSTERY', 'CP_LUCKY_WHEEL_GIVE_CASH',
    'CP_LUCKY_WHEEL_GIVE_CHIPS', 'CP_LUCKY_WHEEL_GIVE_RP', 'CP_LUCKY_WHEEL_GIVE_DISCOUNT', 'CP_LUCKY_WHEEL_GIVE_CLOTHING',
    'CP_LUCKY_WHEEL_GIVE_SURPRISE' }
local Widgets = require('includes.ssv2.core.widgets')
local Game = require('includes.ssv2.core.game')
return function(ctx)
    local root = 'features.dunk.'
    local data = ctx.script_data
    local f = {
        id = 'casino',
        category = 'online',
        scope = 'player',
        owns_controls = true,
        next_status = 0,
        next_spin = 0,
        controls = {
            { kind = 'toggle', path = 'ui.show_casino',                      label = 'Casino Pacino' },
            { kind = 'toggle', path = root .. 'bypass_casino_bans',          label = 'CP_COOLDOWN_BYPASS_ENABLE' },
            { kind = 'toggle', path = root .. 'force_poker_cards',           label = 'CP_POKER_FORCE_ROYAL_FLUSH' },
            { kind = 'toggle', path = root .. 'set_dealers_poker_cards',     label = 'CP_POKER_FORCE_BAD_BEAT' },
            { kind = 'toggle', path = root .. 'force_roulette_wheel',        label = 'CP_ROULETTE_FORCE_RED_18' },
            { kind = 'toggle', path = root .. 'rig_slot_machine',            label = 'CP_SLOT_MACHINES_RIG' },
            { kind = 'toggle', path = root .. 'autoplay_slots',              label = 'CP_SLOT_MACHINES_AUTOPLAY' },
            { kind = 'toggle', path = root .. 'cap_slot_machine_chips',      label = 'CP_SLOT_MACHINES_CAP_CHIPS' },
            { kind = 'int',    path = root .. 'slot_machine_cap',            label = 'Chips cap',                    min = 1000, max = 100000 },
            { kind = 'int',    path = root .. 'autoplay_slots_delay',        label = 'CP_AUTOPLAY_SLOTS_TIME_DELAY', min = 500,  max = 10000 },
            { kind = 'toggle', path = root .. 'autoplay_slots_delay_random', label = 'Random spin delay' },
        }
    }
    local function cfg(key) return ctx.settings:get(root .. key) end
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready() return network.is_session_started() and not NETWORK.NETWORK_IS_ACTIVITY_SESSION() end

    function f:current(script_name, generation, option)
        return ctx.runtime.running and ctx.runtime.generation == generation and self:enabled() and self:ready()
            and ctx.build.compatible and scripts.is_active(script_name) and (not option or cfg(option))
    end

    function f:restore_slots()
        if self.slots and ctx.build.compatible then
            local current = data:local_value('slots_random_result_table')
            if current and current:get_pointer():get_address() == self.slots.address then
                for offset, value in pairs(self.slots.values) do current:at(offset):set_int(value) end
            end
        end
        self.slots = nil
    end

    function f:cleanup()
        self:restore_slots(); self.spin_pending = nil; self.next_spin = 0; self.status = nil
    end

    function f:wheel(prize)
        assert(self:ready() and scripts.is_active('casino_lucky_wheel'), 'Stand at the lucky wheel first')
        if prize == 8 then prize = math.random(1, 7) end
        local chosen = assert(prizes[prize], 'Unknown wheel prize')
        assert(data:write_local('prize_wheel_win_state', chosen, { data:offset('prize_wheel_win_state', 1) }),
            'Lucky-wheel script is unavailable')
        data:write_local('prize_wheel_win_state', 11, { data:offset('prize_wheel_prize_state', 1) })
    end

    function f:cards(player, table_index, one, two, three)
        local size = data:value('three_card_poker_deck_size')
        local cards = data:local_value('three_card_poker_cards',
            { data:offset('three_card_poker_cards', 1), 1, table_index * size, 2 })
        local check = data:local_value('three_card_poker_anti_cheat',
            { data:offset('three_card_poker_anti_cheat', 1), 1, 1, table_index * size })
        if not cards or not check then return end
        for i, value in ipairs({ one, two, three }) do
            cards:at(i + player * 3):set_int(value); check:at(i + player * 3):set_int(value)
        end
    end

    function f:poker(state, generation)
        if not cfg('force_poker_cards') or not scripts.is_active('three_card_poker') then return end
        if not data:request_host('three_card_poker', 10000, function()
                return self:current('three_card_poker', generation,
                    'force_poker_cards')
            end) then
            return
        end
        local table_size = data:offset('three_card_poker_table', 1)
        local table_value = data:local_value('three_card_poker_table', { 1 })
        if not table_value then return end
        local current = table_value:at(state.player_id * table_size + 2):get_int()
        if current < 0 then return end
        local members = 0
        for player = 0, 31 do
            if player ~= state.player_id and table_value:at(player * table_size + 2):get_int() == current then
                members =
                    members + 1
            end
        end
        for player = 0, members do self:cards(player, current, 50, 51, 52) end
        if cfg('set_dealers_poker_cards') then self:cards(members + 1, current, 1, 8, 22) end
    end

    function f:blackjack()
        assert(self:ready() and scripts.is_active('blackjack'), 'Join a blackjack table first')
        local generation = ctx.runtime.generation
        if not data:request_host('blackjack', 10000, function() return self:current('blackjack', generation) end) then return end
        local id = PLAYER.PLAYER_ID()
        local current = data:read_local('blackjack_table_players', { 1, id * data:offset('blackjack_table_players', 1), 4 })
        if not current or current < 0 then return end
        local cards = data:local_value('blackjack_cards', { data:offset('blackjack_cards', 1), 1, current * 13 })
        if not cards then return end
        for offset, value in pairs({ [1] = 11, [2] = 12, [3] = 13, [12] = 3 }) do cards:at(offset):set_int(value) end
    end

    function f:roulette(generation)
        if not cfg('force_roulette_wheel') or not scripts.is_active('casinoroulette') then return end
        if not data:request_host('casinoroulette', 10000, function()
                return self:current('casinoroulette', generation,
                    'force_roulette_wheel')
            end) then
            return
        end
        local outcomes = data:local_value('roulette_master_table',
            { data:offset('roulette_master_table', 1), data:value('roulette_ball_table_offset') })
        if outcomes then for i = 0, 6 do outcomes:at(i):set_int(18) end end
    end

    function f:rig_slots()
        local current = data:local_value('slots_random_result_table')
        if not current then
            self.slots = nil; return
        end
        if not cfg('rig_slot_machine') then
            if self.slots then
                self:restore_slots(); return
            end
            -- Preserve the source's unrig operation for a table left rigged by a previous run.
            local sum = 0
            for offset = 3, 196 do if offset ~= 67 and offset ~= 132 then sum = sum + current:at(offset):get_int() end end
            if sum == 1152 then
                for offset = 3, 196 do if offset ~= 67 and offset ~= 132 then current:at(offset):set_int(math.random(0, 7)) end end
            end
            return
        end
        local address = current:get_pointer():get_address()
        if self.slots and self.slots.address ~= address then self.slots = nil end
        if not self.slots then self.slots = { address = address, values = {} } end
        for offset = 3, 196 do
            if offset ~= 67 and offset ~= 132 then
                local slot = current:at(offset)
                if self.slots.values[offset] == nil then self.slots.values[offset] = slot:get_int() end
                slot:set_int(6)
            end
        end
    end

    function f:autoplay()
        local now = util.time()
        if not cfg('autoplay_slots') or not scripts.is_active('casino_slots') or now < self.next_spin then
            self.spin_pending = nil; return
        end
        local current = data:local_value('slots_slot_machine_state')
        if not current then
            self.spin_pending = nil; return
        end
        local value = current:get_int()
        local allowed = bit.band(value, 1) ~= 0 and bit.band(value, bit.lshift(1, 24)) == 0
            and (not cfg('cap_slot_machine_chips') or stats.get_int('MPX_CASINO_CHIPS') < cfg('slot_machine_cap'))
        if not allowed then
            self.spin_pending = nil; return
        end
        local address = current:get_pointer():get_address()
        if self.spin_pending == address then
            current:set_int(bit.bor(value, 8)); self.spin_pending = nil
            self.next_spin = now +
                (cfg('autoplay_slots_delay_random') and math.random(500, 10000) or cfg('autoplay_slots_delay'))
        else
            self.spin_pending = address
        end
    end

    function f:card_name(index)
        if index == 0 then return 'Rolling' end
        if index < 1 or index > 52 then return tostring(index) end
        local number = index % 13
        local name = ({ [0] = 'CP_CARD_KING', [1] = 'CP_CARD_ACE', [11] = 'CP_CARD_JACK', [12] = 'CP_CARD_QUEEN' })
            [number]
        local suit = ({ 'CP_CARD_CLUBS', 'CP_CARD_DIAMONDS', 'CP_CARD_HEARTS', 'CP_CARD_SPADES' })
            [math.floor((index - 1) / 13) + 1]
        return (name and ctx.translator:text(name) or tostring(number)) .. ' of ' .. ctx.translator:text(suit)
    end

    function f:update(state)
        local generation = ctx.runtime.generation
        if cfg('bypass_casino_bans') then for _, name in ipairs(data_keys) do stats.set_int(name, 0) end end
        self:poker(state, generation)
        if generation ~= ctx.runtime.generation or not self:ready() then return end
        self:roulette(generation)
        if generation ~= ctx.runtime.generation or not self:ready() then return end
        if scripts.is_active('casino_slots') then self:rig_slots() else self.slots = nil end
        self:autoplay()
        if util.time() >= self.next_status then
            local limit = tunables.get_int('VC_CASINO_CHIP_MAX_WIN_DAILY')
            local won = stats.get_int('MPPLY_CASINO_CHIPS_WON_GD')
            local minutes = (tunables.get_int('VC_CASINO_CHIP_MAX_WIN_LOSS_COOLDOWN') - (os.time() - stats.get_int('MPPLY_CASINO_CHIPS_WONTIM'))) /
                60
            self.status = won >= limit and string.format(ctx.translator:text('CP_COOLDOWN_BYPASS_STATUS_FORMAT'), minutes)
                or ctx.translator:text('CP_COOLDOWN_BYPASS_STATUS_OFF')
            self.dealer = ctx.translator:text('CP_NOT_IN_CASINO')
            if scripts.is_active('blackjack') then
                local table_index = data:read_local('blackjack_table_players',
                    { 1, state.player_id * data:offset('blackjack_table_players', 1), 4 })
                self.dealer = ctx.translator:text('CP_NOT_PLAYING_BLACKJACK')
                if table_index and table_index >= 0 then
                    local card = data:read_local('blackjack_cards', { data:offset('blackjack_cards', 1), 1, table_index *
                    13, 1 })
                    if card then self.dealer = self:card_name(card) end
                end
            end
            self.next_status = util.time() + 500
        end
    end

    function f:draw()
        if not ctx.settings:get('ui.show_casino') then return end
        if self.failed and ImGui.Button('Retry Casino Pacino') then self.failed = false end
        if not ctx.online then
            ImGui.Text(ctx.translator:text('GENERIC_UNAVAILABLE_SP')); return
        end
        if not ctx.build.compatible then
            ImGui.Text(ctx.translator:text('GENERIC_OUTDATED')); return
        end
        local function text(key) return ctx.translator:text(key) end
        local function header(key) Widgets.header(text(key), true) end
        local function toggle(key, label, color)
            local value, changed = Widgets.toggle(ctx, text(label), cfg(key), color)
            if changed then ctx.settings:set(root .. key, value) end
        end
        ImGui.SetWindowFontScale(1.3); ImGui.Text('Casino Pacino')
        ImGui.SetWindowFontScale(0.89); ImGui.Text("It's not Al anymore, it's DUNK!"); ImGui.SetWindowFontScale(1)
        ImGui.Separator()
        if Widgets.button(ctx, ctx.translator:text('CP_TP_CASINO')) then
            ctx.runtime:run('casino_teleport', function()
                Game.teleport(ctx, { x = 924.638, y = 46.6918, z = 81.1063 })
            end)
        end
        ImGui.SameLine()
        if Widgets.button(ctx, ctx.translator:text('GENERIC_SET_WAYPOINT') .. '##casino') then
            ctx.runtime:run(
                'casino_waypoint', function() HUD.SET_NEW_WAYPOINT(924.638, 46.6918) end)
        end
        ImGui.Separator(); ImGui.Spacing()
        header('CP_COOLDOWN_BYPASS'); toggle('bypass_casino_bans', 'CP_COOLDOWN_BYPASS_ENABLE', { 1, 0, 0, 1 })
        Widgets.tooltip(ctx, text('CP_COOLDOWN_BYPASS_TOOLTIP'))
        ImGui.BulletText(text('CP_COOLDOWN_BYPASS_STATUS')); ImGui.SameLine(); ImGui.Text(self.status or '')
        header('CP_POKER_SETTINGS'); toggle('force_poker_cards', 'CP_POKER_FORCE_ROYAL_FLUSH'); toggle(
            'set_dealers_poker_cards', 'CP_POKER_FORCE_BAD_BEAT')
        header('CP_BLACKJACK_SETTINGS'); ImGui.BulletText(text('CP_BLACKJACK_DEALER_FACE_DOWN_CARD')); ImGui.SameLine(); ImGui
            .Text(self.dealer or '')
        if Widgets.button(ctx, ctx.translator:text('CP_BLACKJACK_FORCE_DEALER_BUST')) then
            ctx.runtime:run(
                'blackjack_bust', function() self:blackjack() end)
        end
        header('CP_ROULETTE_SETTINGS'); toggle('force_roulette_wheel', 'CP_ROULETTE_FORCE_RED_18')
        header('CP_SLOT_MACHINES_SETTINGS'); toggle('rig_slot_machine', 'CP_SLOT_MACHINES_RIG'); toggle('autoplay_slots',
            'CP_SLOT_MACHINES_AUTOPLAY')
        if cfg('autoplay_slots') then
            toggle('cap_slot_machine_chips', 'CP_SLOT_MACHINES_CAP_CHIPS')
            if cfg('cap_slot_machine_chips') then
                ImGui.SameLine(); local value, changed = ImGui.SliderInt('##chips_cap', cfg('slot_machine_cap'), 1000,
                    100000)
                if changed then ctx.settings:set(root .. 'slot_machine_cap', value) end
            end
            ImGui.Text(text('CP_AUTOPLAY_SLOTS_TIME_DELAY')); ImGui.SameLine()
            if not cfg('autoplay_slots_delay_random') then
                local value, changed = ImGui.SliderInt('##delay_time', cfg('autoplay_slots_delay'), 500, 10000, '%d ms')
                if changed then ctx.settings:set(root .. 'autoplay_slots_delay', value) end
                ImGui.SameLine()
            end
            toggle('autoplay_slots_delay_random', 'GENERIC_RANDOM')
        end
        header('CP_LUCKY_WHEEL_SETTINGS')
        local button_width = 0
        for _, label in ipairs(prize_labels) do
            button_width = math.max(button_width,
                ImGui.CalcTextSize(text(label)) + ImGui.GetStyle().FramePadding.x * 4)
        end
        for index, label in ipairs(prize_labels) do
            local prize = index
            if Widgets.button(ctx, text(label), button_width, 32) then
                ctx.runtime:run('lucky_wheel',
                    function() self:wheel(prize) end)
            end
            if index % 2 == 1 then ImGui.SameLine() end
        end
    end

    return f
end
