local Input = {}
Input.__index = Input
local reserved_keyboard = {
    [1] = true,
    [7] = true,
    [10] = true,
    [11] = true,
    [27] = true,
    [36] = true,
    [44] = true,
    [45] = true,
    [70] = true,
    [91] = true,
    [92] = true,
    [94] = true
}
local reserved_controller = { [23] = true, [24] = true, [25] = true, [71] = true, [75] = true }
-- Original registered Keybind callbacks fire on release. Features that poll
-- IsKeybindJustPressed (mines, towing, gearbox, stopping actions) fire on press.
local release_callbacks = {
    gui_toggle = true,
    commands_console_toggle = true,
    kill_all_enemies = true,
    enemies_flee = true,
    cobra_maneuver = true,
    laser_sights = true,
    minigamehack = true,
    veh_ram_fwd = true,
    veh_ram_left = true,
    veh_ram_right = true
}

function Input.new(settings, runtime)
    local self = setmetatable({
        settings = settings,
        runtime = runtime,
        bindings = {},
        held = {},
        consumed = {},
        blocked = function() return false end
    }, Input)
    event.register_handler(menu_event.WndProc, function(_, message, key, detail)
        if message == 8 then
            self.held = {}; self.consumed = {}; self.capture = nil; return
        end -- WM_KILLFOCUS
        local mouse_keys = { [513] = 1, [514] = 1, [516] = 2, [517] = 2, [519] = 4, [520] = 4 }
        if mouse_keys[message] then
            key = mouse_keys[message]
        elseif message == 523 or message == 524 then
            key = bit.rshift(key, 16) == 1 and 0x10020 or 0x20040
        end
        local generic, alias
        if key == 16 then
            generic, key = 16, bit.band(bit.rshift(detail or 0, 16), 255) == 54 and 161 or 160
        elseif key == 17 then
            generic, key = 17, bit.band(detail or 0, 0x1000000) ~= 0 and 163 or 162
        elseif key == 18 then
            generic, key = 18, bit.band(detail or 0, 0x1000000) ~= 0 and 165 or 164
        elseif key >= 160 and key <= 165 then
            generic = math.floor((key - 160) / 2) + 16
        end
        if key == 0x10020 then alias = 5 elseif key == 0x20040 then alias = 6 end
        if message == 256 or message == 260 or message == 513 or message == 516
            or message == 519 or message == 523 then
            if self.held[key] then return end
            self.held[key] = true
            if generic then self.held[generic] = true end
            if alias then self.held[alias] = true end
            if self.capture and self.capture.source == 'keyboard' then
                self:capture_key_down(generic or key, key)
                return
            end
            for _, binding in ipairs(self.bindings) do
                local code = self.settings:get('keybinds.' .. binding.id .. '.keyboard')
                if code == key or (generic and code == generic) or (alias and code == alias) then
                    local handled = binding.on_release and not self.capture or
                        not binding.on_release and self:dispatch(binding, 'keyboard')
                    if handled and binding.ui_action then
                        self.consumed[key] = true
                        if generic then self.consumed[generic] = true end
                        if alias then self.consumed[alias] = true end
                        return
                    end
                end
            end
        elseif message == 257 or message == 261 or message == 514 or message == 517
            or message == 520 or message == 524 then
            local was_held = self.held[key]
            self.held[key] = nil
            self.consumed[key] = nil
            if generic then
                local left = 160 + (generic - 16) * 2
                self.held[generic] = self.held[left] or self.held[left + 1]
                if not self.held[generic] then self.consumed[generic] = nil end
            end
            if alias then
                self.held[alias] = nil; self.consumed[alias] = nil
            end
            self:capture_key_up(generic or key)
            for _, binding in ipairs(self.bindings) do
                local code = self.settings:get('keybinds.' .. binding.id .. '.keyboard')
                if was_held and binding.on_release and not self.settings:get('keybinds.' .. binding.id .. '.repeat_on_hold')
                    and (code == key or generic and code == generic or alias and code == alias) then
                    if self:dispatch(binding, 'keyboard') and binding.ui_action then return end
                end
            end
        end
    end)
    return self
end

function Input:bind(id, callback, ui_action, always)
    self.bindings[#self.bindings + 1] = {
        id = id,
        callback = callback,
        ui_action = ui_action,
        always = always,
        on_release = release_callbacks[id] or id:match('^quick_') ~= nil
    }
end

function Input:bind_held(id)
    self.bindings[#self.bindings + 1] = { id = id, held_action = true }
end

function Input:key_name(id)
    local source = self.control_source or 'keyboard'
    local names = require(source == 'keyboard' and 'includes.ssv2.data.keyboard_keys' or
        'includes.ssv2.data.gamepad_keys')
    local root = 'keybinds.' .. id .. '.'
    local function name(code)
        for label, value in pairs(names) do if value == code then return label end end
        return code == 0 and '(NONE)' or tostring(code)
    end
    local key, modifier = self.settings:get(root .. source) or 0, self.settings:get(root .. source .. '_modifier') or 0
    return modifier == 0 and name(key) or name(modifier) .. ' + ' .. name(key)
end

function Input:listen(id, source, modifier_only)
    assert(source == 'keyboard' or source == 'controller', 'Unknown input source')
    self.capture = { id = id, source = source, modifier_only = modifier_only or false, started = util.time(), requested = true }
end

function Input:captured(key, modifier, replace)
    local capture = self.capture
    if not capture or capture.key ~= nil and not replace then return end
    capture.key = key; capture.modifier = modifier or 0; capture.conflicts = {}
    local reserved = capture.source == 'keyboard' and reserved_keyboard or reserved_controller
    capture.reserved = reserved[key] or reserved[capture.modifier] or false
    if not capture.modifier_only then
        for _, binding in ipairs(self.bindings) do
            if binding.id ~= capture.id then
                local root = 'keybinds.' .. binding.id .. '.'
                if self.settings:get(root .. capture.source) == key and (self.settings:get(root .. capture.source .. '_modifier') or 0) == capture.modifier then
                    capture.conflicts[#capture.conflicts + 1] = binding.id
                end
            end
        end
    end
end

function Input:capture_key_down(code, physical)
    local capture = self.capture
    if code == 27 then
        self.capture = nil; return
    end
    if not capture or capture.source ~= 'keyboard' or capture.ready then return end
    if not capture.first_key then
        capture.first_key, capture.first_physical = code, physical
        self:captured(code, 0)
    elseif not capture.modifier_only and code ~= capture.first_key and self.held[capture.first_physical] then
        self:captured(code, capture.first_key, true)
    end
    capture.waiting_release = not capture.reserved
    capture.ready = capture.reserved
end

function Input:capture_key_up(code)
    local capture = self.capture
    if not capture or capture.source ~= 'keyboard' or not capture.waiting_release then return end
    -- The original editor uses the first held key as the modifier when another
    -- key is released first. Releasing that first key alone binds it directly.
    if code == capture.first_key then
        self:captured(code, 0, true)
    elseif code == capture.key then
        self:captured(code, capture.first_key, true)
    else
        return
    end
    capture.waiting_release = false; capture.ready = true
end

function Input:clear_capture()
    local capture = self.capture
    if capture then
        self:listen(capture.id, capture.source, capture.modifier_only); self.capture.requested = false
    end
end

function Input:apply_capture()
    local capture = assert(self.capture, 'No binding is being captured')
    assert(capture.key ~= nil, 'No input captured')
    assert(not capture.reserved, 'This input is reserved')
    local root = 'keybinds.' .. capture.id .. '.' .. capture.source
    if capture.modifier_only then
        self.settings:set(root .. '_modifier', capture.key)
    else
        self.settings:set(root, capture.key); self.settings:set(root .. '_modifier', capture.modifier)
    end
    self.capture = nil
end

function Input:is_held(id)
    if self.blocked() or HUD.IS_PAUSE_MENU_ACTIVE() or HUD.IS_MP_TEXT_CHAT_TYPING() then return false end
    local keyboard = PAD.IS_USING_KEYBOARD_AND_MOUSE(0)
    local source = keyboard and 'keyboard' or 'controller'
    local root = 'keybinds.' .. id .. '.'
    local key, modifier = self.settings:get(root .. source), self.settings:get(root .. source .. '_modifier') or 0
    if not key or key == 0 then return false end
    if keyboard then
        return not self.consumed[key] and self.held[key] == true and
            (modifier == 0 or self.held[modifier] == true)
    end
    return (PAD.IS_CONTROL_PRESSED(0, key) or PAD.IS_DISABLED_CONTROL_PRESSED(0, key))
        and (modifier == 0 or PAD.IS_CONTROL_PRESSED(0, modifier) or PAD.IS_DISABLED_CONTROL_PRESSED(0, modifier))
end

function Input:dispatch(binding, source)
    if not self.runtime.running then return false end
    if not self.runtime:service_running('SS_KEYMGR') then return false end
    if self.capture then return false end
    if binding.held_action then return false end
    local modifier = self.settings:get('keybinds.' .. binding.id .. '.' .. (source or 'keyboard') .. '_modifier') or 0
    if modifier ~= 0 then
        if source == 'controller' then
            if not (PAD.IS_CONTROL_PRESSED(0, modifier) or PAD.IS_DISABLED_CONTROL_PRESSED(0, modifier)) then return false end
        elseif not self.held[modifier] then
            return false
        end
    end
    if binding.ui_action then
        binding.callback(); return true
    end
    self.runtime:run(binding.id, function()
        if binding.always or not self.blocked() and not HUD.IS_PAUSE_MENU_ACTIVE()
            and not HUD.IS_MP_TEXT_CHAT_TYPING() then
            binding.callback()
        end
    end)
    return true
end

-- Original SS_CTRLS behavior: typing/capturing blocks both input groups;
-- browsing blocks mouse actions while leaving movement controls available.
function Input:suppress_game(ctx)
    local blocked = ctx.console and (ctx.console.open or util.time() < (ctx.console.input_release_at or 0))
        or self.capture ~= nil or ctx.view.open and ctx.view.wants_input
    if blocked then
        PAD.DISABLE_ALL_CONTROL_ACTIONS(0); PAD.DISABLE_ALL_CONTROL_ACTIONS(1)
    elseif ctx.view.open or menu.is_open() then
        for _, control in ipairs({ 18, 24, 25, 68, 69, 70, 91, 92, 106, 114, 122, 135, 142, 144, 176, 223, 229, 237, 257, 294 }) do
            PAD.DISABLE_CONTROL_ACTION(0, control, true)
        end
    end
end

function Input:update()
    self.control_source = PAD.IS_USING_KEYBOARD_AND_MOUSE(0) and 'keyboard' or 'controller'
    if self.capture and self.capture.source == 'controller' then
        local capture = self.capture
        if capture.key ~= nil then
            capture.waiting_release = PAD.IS_CONTROL_PRESSED(0, capture.key) or
                PAD.IS_DISABLED_CONTROL_PRESSED(0, capture.key)
            capture.ready = not capture.waiting_release
        elseif not PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
            for _, code in pairs(require('includes.ssv2.data.gamepad_keys')) do
                if code ~= 0 and (PAD.IS_CONTROL_JUST_PRESSED(0, code) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, code)) then
                    self:captured(code, 0); capture.waiting_release = true; capture.ready = false; break
                end
            end
        end
        return
    end
    if self.capture then return end
    local keyboard = PAD.IS_USING_KEYBOARD_AND_MOUSE(0)
    for _, binding in ipairs(self.bindings) do
        local root = 'keybinds.' .. binding.id .. '.'
        local keyboard_binding = keyboard
        local source = keyboard_binding and 'keyboard' or 'controller'
        local code = self.settings:get(root .. source) or 0
        if code ~= 0 then
            local triggered
            local repeat_held = binding.on_release and self.settings:get(root .. 'repeat_on_hold')
            if keyboard_binding then
                triggered = repeat_held and self.held[code] == true
            elseif repeat_held then
                triggered = PAD.IS_CONTROL_PRESSED(0, code) or PAD.IS_DISABLED_CONTROL_PRESSED(0, code)
            elseif binding.on_release then
                triggered = PAD.IS_CONTROL_JUST_RELEASED(0, code) or PAD.IS_DISABLED_CONTROL_JUST_RELEASED(0, code)
            else
                triggered = PAD.IS_CONTROL_JUST_PRESSED(0, code) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, code)
            end
            if triggered then self:dispatch(binding, source) end
        end
    end
end

return Input
