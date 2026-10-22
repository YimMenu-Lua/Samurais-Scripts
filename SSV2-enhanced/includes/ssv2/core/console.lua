local Codec = require('includes.ssv2.core.codec')
local Appearance = require('includes.ssv2.core.appearance')
local Pool = require('includes.ssv2.core.entity_pool')
local Widgets = require('includes.ssv2.core.widgets')
local metadata = require('includes.ssv2.data.command_metadata')
local Console = {}; Console.__index = Console
function Console.parse(input)
    local words = {}; local token, quote = '', nil
    for i = 1, #input do
        local char = input:sub(i, i)
        if quote then
            if char == quote then quote = nil else token = token .. char end
        elseif char == '"' or char == "'" then
            quote = char
        elseif char:match('%s') then
            if #token > 0 then
                words[#words + 1] = token; token = ''
            end
        else
            token = token .. char
        end
    end
    assert(not quote, 'Unclosed command quote')
    if #token > 0 then words[#words + 1] = token end
    local name = table.remove(words, 1) or ''
    for i, value in ipairs(words) do
        if value:lower() == 'true' then
            words[i] = true
        elseif value:lower() == 'false' then
            words[i] = false
        elseif tonumber(value) then
            words[i] = tonumber(value)
        end
    end
    return name:lower(), words
end

function Console.new(ctx)
    local self = setmetatable(
        {
            ctx = ctx,
            commands = {},
            open = false,
            line = '',
            hint = '>_',
            history = {},
            history_index = 0,
            suggestion_index = 0,
            pool = Pool.new(ctx),
            feedback = '',
            clipboard = nil
        }, Console)
    ctx.input:bind('commands_console_toggle', function() self:toggle() end, true)
    menu.add_always_draw_imgui(function() self:draw() end)
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function()
        self:close(); self.pool:clear()
    end
    self:register_defaults()
    ctx.runtime:loop('SS_COMMANDS', function()
        if self.open and self.pending_input then
            local input = self.pending_input; self.pending_input = nil; self:execute(input)
        end
    end, function() self:close() end)
    return self
end

function Console:toggle()
    if self.open then
        self:close(); return
    end
    self.open = true; self.focus = true
    self.ctx.view:update_mouse()
end

function Console:close()
    if self.open then self.input_release_at = util.time() + 200 end
    self.open = false; self.show_list = false; self.dump_open = false; self.pending_input = nil; self.line = ''; self.hint =
    '>_'; self.history_index = 0; self.suggestion_index = 0
    self.ctx.view:update_mouse()
end

function Console:register(name, callback, description, aliases, args)
    local source = metadata[name]
    local entry = {
        callback = callback,
        description = source and source.description or description or 'No description.',
        name = name,
        aliases = source and source.aliases or aliases or {},
        args = source and source.args or args or {}
    }
    self.commands[name:lower()] = entry
    for _, alias in ipairs(entry.aliases) do self.commands[alias:lower()] = entry end
end

function Console:lookup(name)
    if self.commands[name] then return self.commands[name] end
    local actions = self.ctx.features.yim_actions
    if actions then
        for alias, definition in pairs(actions.commands.data.aliases) do
            if alias:lower() == name then
                local kind = definition.kind or 'action'
                return {
                    name = alias,
                    args = {},
                    aliases = {},
                    description = "YimActions Command: Plays the '" ..
                        (definition.label or definition.data and (definition.data.label or definition.data.Name) or alias) ..
                        "' " .. kind .. '.',
                    callback = function() actions:execute(alias) end
                }
            end
        end
    end
end

function Console:execute(input)
    local ok, name, args = pcall(Console.parse, input)
    if not ok then
        self.ctx.notifier:error('Console', tostring(name)); return false
    end
    local entry = self:lookup(name)
    if not entry then
        self.ctx.notifier:error('Console', 'Unknown command: ' .. name); return false
    end
    self.ctx.view:play_sound('Click')
    local generation = self.ctx.runtime.generation
    self.ctx.runtime:run('command ' .. name, function()
        if self.ctx.runtime.generation ~= generation then return end
        local ok, err = pcall(entry.callback, args,
            function() return self.ctx.runtime.running and self.ctx.runtime.generation == generation end)
        if not ok then
            self.feedback = tostring(err); self.ctx.notifier:error('Console', self.feedback); return
        end
        self.feedback = 'Executed ' .. name
        self.history[#self.history + 1] = input
        self.history_index = 0
        if self.ctx.settings:get('commands_console.auto_close') and name:sub(1, 1) ~= '!' then self:close() end
    end)
    return true
end

function Console:business()
    local manager = self.ctx.features.businesses
    assert(manager and manager.active, 'Business controls require online freemode on the supported build')
    return manager
end

function Console:vehicle()
    local state = self.ctx.state:read(); assert(state, 'Player is unavailable')
    local tracked = self.ctx.state:tracked_vehicle()
    if tracked then
        state.vehicle_handle = tracked; state.vehicle = Vehicle.new(tracked)
    elseif self.ctx.state.vehicle_control.pending then
        state.vehicle = nil
    end
    assert(state.vehicle, 'Enter a vehicle first'); return state
end

function Console:clone(model, mods, warp, valid, origin)
    local state = self.ctx.state:read(); assert(state, 'Player is unavailable')
    local tracked = self.ctx.state:tracked_vehicle()
    local entity = origin or state.vehicle_handle ~= 0 and state.vehicle_handle
        or tracked and ENTITY.DOES_ENTITY_EXIST(tracked) and tracked or state.handle
    local position = self.ctx.game.spawn_in_front(entity)
    local entry = self.pool:create('vehicle', model, position, ENTITY.GET_ENTITY_HEADING(state.handle), valid)
    if not entry then return end
    if mods and not Appearance.apply_vehicle(entry.handle, mods, valid) then
        self.pool:delete(entry.handle); return
    end
    self.pool:release(entry.handle, true)
    if warp then TASK.TASK_WARP_PED_INTO_VEHICLE(state.handle, entry.handle, -1) end
    return entry
end

function Console:register_defaults()
    local ctx = self.ctx
    self:register('!list', function() self.show_list = true end, 'List all commands', { '!ls', '!dump' })
    self:register('!help',
        function()
            ctx.notifier:info('Console',
                'Enter executes. Up/Down selects history or suggestions. Tab completes the selected command.', 15)
        end,
        'Usage help', { '!h' })
    self:register('!setautoclose',
        function(args)
            assert(type(args[1]) == 'boolean', 'Use !setautoclose true or false'); ctx.settings:set(
                'commands_console.auto_close', args[1])
        end, 'Set automatic closing after a successful command')
    self:register('!setkey', function(args)
        local key = tonumber(args[1]) or require('includes.ssv2.data.keyboard_keys')[tostring(args[1]):upper()]
        assert(key and key ~= 0, 'Unknown keyboard key'); ctx.settings:set('keybinds.commands_console_toggle.keyboard',
            key)
    end, 'Set console toggle key')
    self:register('!panique', function()
        ctx.runtime:stop()
        -- The original panic shuts down the loop manager, then dispatches
        -- the four transition cleanup events with a 100ms interval.
        for _ = 1, 4 do script.yield(100) end
        local state = ctx.state:read()
        if state then
            local p = state.ped:get_position(); AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE('ELECTROCUTION', 'MISTERK',
                p.x, p.y, p.z, 'SPEECH_PARAMS_FORCE')
        end
        notify.warn('PANIQUE!', '(Ó _ Ò )!!')
    end, 'Clean up all script-owned features and services', { '!panik', '!dammit', '!bordeldemerde', '!panicus' })
    self:register('toggle_unsafe_feats', function()
        if not NETSHOPPING.NET_GAMESERVER_USE_SERVER_TRANSACTIONS() then
            ctx.settings:set('features.unsafe_feats_enabled', true); return
        end
        local value = not ctx.settings:get('features.unsafe_feats_enabled')
        ctx.settings:set('features.unsafe_feats_enabled', value)
        ctx.notifier:add('CommandExecutor',
            ctx.translator:text(value and 'YRV3_UNSAFE_FEATS_ENABLED' or 'YRV3_UNSAFE_FEATS_DISABLED'),
            value and 'warn' or 'info')
    end, 'Toggle unsafe feature controls', { 'yolo', 'dangerzone', 'fuckit', 'ilikeitraw' })
    self:register('yrv3.fill_all_safes', function() self:business():fill_all() end, 'Fill all owned safes')
    self:register('yrv3.finish_sale', function() self:business().actions:finish_sale() end,
        'Finish a supported active sale')
    self:register('yrv3.restock_all', function() self:business():restock_all() end, 'Restock all businesses')
    self:register('yrv3.restock_hangar',
        function()
            local record = assert(self:business().lookup.hangar, 'No owned hangar'); record.auto = true
        end, 'Restock the hangar')
    for _, kind in ipairs({ 'warehouse', 'factory' }) do
        self:register('yrv3.restock_' .. kind, function(args)
            local manager = self:business(); local index = args[1]
            assert(index == 'all' or type(index) == 'number' and index == math.floor(index),
                'Enter a business index or all')
            local maximum = kind == 'warehouse' and 5 or 7
            assert(index == 'all' or index >= 1 and index <= maximum, 'Business index is out of range')
            for i = 1, maximum do
                if index == 'all' or index == i then
                    local record = manager.lookup[(kind == 'warehouse' and 'cargo_' or 'factory_') .. (i - 1)]
                    if record then if kind == 'warehouse' then record.auto = true else record:restock() end end
                end
            end
        end, 'Restock an owned ' .. kind .. ' by index, or all')
    end
    for _, definition in ipairs({ { 'factory', 'factory_' }, { 'nightclub', 'hub_' } }) do
        self:register('yrv3.toggle_' .. definition[1] .. '_production', function(args)
            assert(ctx.settings:get('features.unsafe_feats_enabled'), 'Enable unsafe feature controls first')
            local manager = self:business(); local index = args[1]
            assert(index == 'all' or type(index) == 'number' and index >= 1 and index <= 7 and index == math.floor(index),
                'Enter an index from 1 to 7, or all')
            for i = 1, 7 do
                if index == 'all' or index == i then
                    local record = manager.lookup[definition[2] .. (i - 1)]; if record then
                        record.auto = not record
                            .auto
                    end
                end
            end
        end, 'Toggle fast production by index, or all')
    end
    self:register('boss.register',
        function(args)
            assert(args[1] == -1 or args[1] == 0 or args[1] == 1, 'Boss type must be -1, 0 or 1'); self:business()
                .extras:boss_action(args[1])
        end, 'Register as CEO/VIP (0), MC president (1), or retire (-1)')
    self:register('boss.retire', function() self:business().extras:boss_action(-1) end, 'Retire from being a boss')
    for _, deposit in ipairs({ true, false }) do
        self:register(deposit and 'money.deposit' or 'money.withdraw', function(args, valid)
            local money = self:business().extras.money
            assert(type(args[1]) == 'number', 'Specify an amount, or -1 for all')
            money:transfer(deposit, args[1] == -1 and (deposit and money.wallet or money.bank) or args[1], valid)
        end, 'Transfer bank/wallet funds; -1 transfers all')
    end
    self:register('clonepv',
        function(args, valid)
            local state = self:vehicle(); self:clone(state.vehicle:get_model(), Appearance.vehicle(state.vehicle_handle),
                args[1] == true, valid, state.vehicle_handle)
        end, 'Clone current vehicle, optionally warp into it')
    self:register('lockpv', function(_, valid)
        local state = self:vehicle(); local handle = state.vehicle_handle
        local locked = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(handle) > 1
        local assets = self.pool
        local actions = ctx.features.yim_actions
        if state.alive and state.on_foot and not ctx.game.swimming(state.handle)
            and not (actions and (actions.playing[state.handle] or actions:busy(state.handle)))
            and assets:wait('animation', 'anim@mp_player_intmenu@key_fob@', function() return ctx.runtime.running end) then
            TASK.TASK_PLAY_ANIM(state.handle, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 4, -8, 800, 48, 0, false,
                false, false)
        end
        if ctx.game.lock_vehicle(ctx, handle, not locked, valid) then
            ctx.notifier:info('CommandExecutor',
                ctx.translator:text(locked and 'VEH_UNLOCKED' or 'VEH_LOCKED'))
        end
    end, 'Lock or unlock current vehicle')
    self:register('savepv', function(args)
        local state = self:vehicle(); local name = args[1]
        if type(name) ~= 'string' or not name:find('%S') then
            name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE
                .GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(state.vehicle:get_model()))
        end
        name = name:gsub('%.[^%.]+$', '')
        assert(name ~= '' and not name:find('[<>:"/\\|?*%z\1-\31]'), 'Use a valid file name without path separators')
        local path = 'ssv2/vehicles/' .. name .. '.json'; local suffix = 1
        while FileMgr.DoesFileExist(path) do
            path = 'ssv2/vehicles/' .. name .. '_' .. suffix .. '.json'; suffix = suffix + 1
        end
        FileMgr.CreateDir('ssv2/vehicles')
        local raw = Codec.encode({
            model_hash = state.vehicle:get_model(),
            mods = Appearance.vehicle(state
                .vehicle_handle)
        }, false)
        assert(FileMgr.WriteFileContent(path, raw, false) and FileMgr.ReadFileContent(path) == raw, 'Vehicle save failed')
        ctx.notifier:success('Vehicle', 'Saved ' .. path)
    end, 'Save current vehicle to JSON')
    self:register('spawnjsonveh', function(args, valid)
        assert(type(args[1]) == 'string', 'Specify a JSON file name')
        local path = args[1]; if not path:match('%.json$') then path = path .. '.json' end
        if not FileMgr.DoesFileExist(path) then path = 'ssv2/vehicles/' .. path end
        local value = Codec.decode(FileMgr.ReadFileContent(path)); assert(
            type(value) == 'table' and type(value.model_hash) == 'number', 'Invalid saved vehicle')
        self:clone(value.model_hash, value.mods, args[2] == true, valid)
    end, 'Spawn vehicle JSON, optionally warp into it')
    self:register('teleport', function(args, valid)
        local function number(value)
            return type(value) == 'number' and value or
                type(value) == 'string' and tonumber((value:gsub('f,?$', ''):gsub(',$', '')))
        end
        local x, y, z = number(args[1]), number(args[2]), number(args[3]) or 0
        if #args < 2 then
            local point = assert(ctx.game.waypoint(), 'No active waypoint'); x, y = point.x, point.y
        end
        assert(x and y, 'Specify X, Y and optional Z coordinates')
        ctx.game.teleport(ctx, { x = x, y = y, z = z }, args[4], z == 0, valid)
    end, 'Teleport to coordinates or waypoint; optional fourth argument keeps the vehicle', { 'tp' })
    self:register('copycoords', function(args)
        local state = ctx.state:read(); assert(state, 'Player is unavailable'); local p = state.ped:get_position()
        self.clipboard = string.format(args[1] == true and '%.4ff, %.4ff, %.4ff' or '%.4f, %.4f, %.4f', p.x, p.y, p.z)
    end, 'Copy player coordinates; true uses C syntax')
    self:register('playerwptp', function(args, valid)
        local id = tonumber(args[1])
        if not id and type(args[1]) == 'string' then
            for i = 0, 31 do
                local candidate = PLAYER.GET_PLAYER_NAME(i)
                if type(candidate) == 'string' and candidate:lower() == args[1]:lower() then
                    id = i; break
                end
            end
        end
        assert(id and id >= 0 and id <= 31 and NETWORK.NETWORK_GET_PLAYER_OWNS_WAYPOINT(id),
            'Player or waypoint was not found')
        PLAYER.SET_APPLY_WAYPOINT_OF_PLAYER(id, 147)
        ctx.notifier:info('CommandExecutor',
            'Teleporting to ' .. (PLAYER.GET_PLAYER_NAME(id) or tostring(id)) .. "'s waypoint.")
        script.yield(300); if not valid() then return end
        local command = assert(commandmgr.get_command('tptowaypoint'), 'Waypoint command is unavailable'); command:call()
    end, 'Teleport to a player waypoint by ID or name', { 'pwptp' })
    for _, definition in ipairs({
        { 'wrld_extend_bounds', 'features.world.extend_bounds',       'WRLD_EXTEND_BOUNDS_TT' },
        { 'wrld_flight_music',  'features.world.disable_flight_music' },
        { 'wrld_wanted_music',  'features.world.disable_wanted_music' },
        { 'wrld_hns',           'features.world.hide_n_seek',         'WRLD_HNS_TT',          { 'hidenseek', 'trashboy' } },
        { 'wrld_carpool',       'features.world.carpool',             'WRLD_CARPOOL_TT',      { 'carpool' } },
        { 'veh_pops_n_bangs',   'features.vehicle.burble_tune',       'VEH_POPS_N_BANGS_TT',  { 'vehpops' } },
        { 'veh_fast_jets',      'features.vehicle.fast_jets',         'VEH_FAST_JETS_TT' },
        { 'veh_no_jet_stall',   'features.vehicle.no_jet_stall',      'VEH_NO_JET_STALL_TT' },
    }) do
        local name, path, tooltip, aliases = unpack(definition)
        self:register(name, function()
            local value = not ctx.settings:get(path); ctx.settings:set(path, value)
            ctx.notifier:info(ctx.translator:text(name:upper()), value and 'Enabled.' or 'Disabled.')
        end, tooltip and ctx.translator:text(tooltip) or 'No description.', aliases)
    end
end

function Console:suggestions()
    local prefix = self.line:match('^(%S+)') or ''; local result = {}
    if prefix == '' then return result end
    local names = {}; for name in pairs(self.commands) do names[name] = true end
    local actions = self.ctx.features.yim_actions
    if actions then for name in pairs(actions.commands.data.aliases) do names[name:lower()] = true end end
    for name in pairs(names) do if name:find(prefix:lower(), 1, true) then result[#result + 1] = name end end
    table.sort(result); return result
end

function Console:all_commands()
    local names = {}; for name in pairs(self.commands) do names[name] = true end
    local actions = self.ctx.features.yim_actions
    if actions then for name in pairs(actions.commands.data.aliases) do names[name:lower()] = true end end
    local result = {}; for name in pairs(names) do result[#result + 1] = name end
    table.sort(result); return result
end

function Console:command_description(name)
    local entry = self:lookup(name); local args = entry.args or {}
    local text = entry.description ..
        '\n- ' .. (#args == 0 and 'Arguments: None.' or 'Arguments (' .. #args .. '): ' .. table.concat(args, ', '))
    if name == entry.name and #(entry.aliases or {}) > 0 then
        text = text ..
            '\n- Aliases: ' .. table.concat(entry.aliases, ' | ')
    end
    return text
end

function Console:command_dump()
    local lines = {}
    for _, name in ipairs(self:all_commands()) do
        local entry = self:lookup(name)
        if name == entry.name then
            local text = '* ' .. name .. ' ' .. table.concat(entry.args or {}, ', ') .. ' - ' .. entry.description
            if #(entry.aliases or {}) > 0 then text = text .. ' - Aliases: ' .. table.concat(entry.aliases, ' | ') end
            lines[#lines + 1] = text
        end
    end
    return '\n' .. table.concat(lines, '\n'), #lines
end

function Console:draw_dump(screen_width, screen_height)
    if not self.dump_open then return end
    local width, height = screen_width * 0.3, screen_height * 0.5
    ImGui.SetNextWindowSize(width, height)
    ImGui.SetNextWindowPos((screen_width - width) / 2, (screen_height - height) / 2)
    ImGui.SetNextWindowFocus()
    local open, draw = ImGui.BeginPopupModal('cmd_popup', true,
        bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoResize))
    self.dump_open = open
    if not draw then return end
    ImGui.SetNextWindowBgAlpha(0)
    if ImGui.BeginChild('##cmd_dump_upper', width * 0.93, height * 0.15, false) then
        ImGui.Dummy(1, 10)
        if Widgets.button(self.ctx, 'Close') then
            ImGui.CloseCurrentPopup(); self.dump_open = false
        end
        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        if Widgets.button(self.ctx, 'Print To Console') then
            local text = self:command_dump(); log.info(text)
            self.ctx.notifier:info('Command Executor', 'Command dump logged to console.')
        end
    end
    ImGui.EndChild()
    local _, count = self:command_dump(); ImGui.SeparatorText('Command Count: [ ' .. count .. ' ]')
    ImGui.SetNextWindowBgAlpha(0)
    if ImGui.BeginChild('##cmd_dump_lower', width * 0.965, height * 0.7, false) then
        ImGui.PushTextWrapPos(width * 0.94)
        for _, name in ipairs(self:all_commands()) do
            local entry = self:lookup(name)
            if entry.name == name then
                ImGui.BulletText(name); ImGui.Indent(); ImGui.SetWindowFontScale(0.9)
                ImGui.Text(entry.description)
                local args = entry.args or {}
                ImGui.Text(#args == 0 and '- Arguments: None.' or '- Arguments (' ..
                    #args .. '): ' .. table.concat(args, ', '))
                if #(entry.aliases or {}) > 0 then ImGui.Text('- Alias: ' .. table.concat(entry.aliases, ' | ')) end
                ImGui.SetWindowFontScale(1); ImGui.Unindent()
            end
        end
        ImGui.PopTextWrapPos()
    end
    ImGui.EndChild(); ImGui.EndPopup()
end

function Console:draw()
    if self.clipboard then
        ImGui.SetClipboardText(self.clipboard); self.clipboard = nil
    end
    if not self.open then return end
    if ImGui.IsKeyPressed(ImGuiKey.Escape, false) then
        self:close(); return
    end
    local screen_width, screen_height = ImGui.GetDisplaySize()
    local width, height = screen_width * 0.3, screen_height * 0.37
    self.ctx.theme:push()
    ImGui.SetNextWindowSize(width, height)
    ImGui.SetNextWindowPos((screen_width - width) / 2, (screen_height - height) / 2)
    ImGui.SetNextWindowBgAlpha(self.ctx.settings:get('ui.style.bg_alpha'))
    local draw = ImGui.Begin('Command Executor', nil,
        bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize,
            ImGuiWindowFlags.NoScrollbar))
    if draw then
        ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginChild('main', 0, height * 0.7, false) then
            ImGui.Spacing(); ImGui.SeparatorText('Command Executor'); ImGui.Spacing(); ImGui.SetNextItemWidth(-1)
            local up = ImGui.IsKeyPressed(ImGuiKey.UpArrow, false)
            local down = ImGui.IsKeyPressed(ImGuiKey.DownArrow, false)
            local right = ImGui.IsKeyPressed(ImGuiKey.RightArrow, false)
            local tab = ImGui.IsKeyPressed(ImGuiKey.Tab, false)
            local navigation = false
            for _, key in ipairs({ ImGuiKey.UpArrow, ImGuiKey.DownArrow, ImGuiKey.RightArrow, ImGuiKey.Enter, ImGuiKey.Tab }) do
                navigation = navigation or ImGui.IsKeyDown(key)
            end
            if not navigation or self.focus then
                ImGui.SetKeyboardFocusHere(); self.focus = false
            end
            local text, enter = Widgets.input_text_with_hint(self.ctx, '##cmd', self.hint, self.line,
                ImGuiInputTextFlags.EnterReturnsTrue)
            self.line = Widgets.validated_text(self.line, text, 128)
            local list = self:suggestions()
            if #list == 0 and self.line == '' then
                if up then
                    self.history_index = self.history_index - 1; if self.history_index < 0 then
                        self.history_index = #
                            self.history
                    end
                end
                if down then
                    self.history_index = self.history_index + 1; if self.history_index > #self.history then self.history_index = 0 end
                end
                self.hint = self.history[self.history_index] or '>_'
                if (tab or right or enter) and self.history[self.history_index] then
                    self.line = self.history[self.history_index]; self.history_index = 0; self.hint = '>_'; enter = false; self.focus = true
                end
            elseif #list > 0 then
                self.hint = '>_'
                if up then
                    self.suggestion_index = self.suggestion_index - 1; if self.suggestion_index < 1 then
                        self.suggestion_index = #
                            list
                    end
                end
                if down then
                    self.suggestion_index = self.suggestion_index + 1; if self.suggestion_index > #list then self.suggestion_index = 1 end
                end
                if tab and list[self.suggestion_index] then
                    self.line = list[self.suggestion_index] .. ' '; self.suggestion_index = 0; self.focus = true
                end
            end
            local clicked_command
            if #list > 0 then
                ImGui.SetNextWindowBgAlpha(0.45)
                if ImGui.BeginChild('##suggestions', width * 0.93, math.min(#list, 5) * ImGui.GetTextLineHeightWithSpacing(), false) then
                    for i, name in ipairs(list) do
                        local selected = self.suggestion_index == i
                        ImGui.Selectable(name, selected)
                        if selected then ImGui.SetScrollHereY(0.5) end
                        Widgets.tooltip(self.ctx,
                            'Left click to autofill this command.\n\n' .. self:command_description(name))
                        if ImGui.IsItemClicked(0) then
                            self.suggestion_index = i; self.line = name; self.hint = '>_'; self.focus = true
                            if #(self:lookup(name).args or {}) == 0 then clicked_command = name end
                        end
                    end
                end
                ImGui.EndChild()
            end
            self.bottom_text = list[self.suggestion_index] and self:command_description(list[self.suggestion_index])
                or self.history[self.history_index] and
                'Press [Right Arrow] or [TAB] or [Enter] to auto-fill this command.'
                or 'All built-in commands are prefixed with an exclamation mark <!>.'
            if clicked_command or enter and self.line:find('%S') then
                self.pending_input = clicked_command or self.line; self.line = ''; self.hint = '>_'; self.suggestion_index = 0
            end
        end
        ImGui.EndChild(); ImGui.Separator(); ImGui.Spacing(); ImGui.SetWindowFontScale(0.9)
        ImGui.PushTextWrapPos(width * 0.9); ImGui.TextDisabled(self.bottom_text or ''); ImGui.PopTextWrapPos(); ImGui
            .SetWindowFontScale(1)
        if self.show_list then
            ImGui.OpenPopup('cmd_popup'); self.show_list = false; self.dump_open = true
        end
        self:draw_dump(screen_width, screen_height)
    end
    ImGui.End(); self.ctx.theme:pop()
end

return Console
