local Assets = require('includes.ssv2.core.assets')
local options = {
    { 'phone_anims',         'SELF_PHONE_ANIMS' }, { 'mc_alt_bike_anims', 'SELF_MC_BIKE_ANIMS' },
    { 'disable_action_mode', 'SELF_ACTION_MODE' }, { 'allow_headprops_in_vehicles', 'SELF_HEADPROPS' },
    { 'stand_on_veh_roof', 'SELF_STAND_ON_VEHS' }, { 'no_carjacking', 'SELF_NO_CARJACKING' },
    { 'crouch',            'SELF_CROUCH' }, { 'hands_up', 'SELF_HANDS_UP' },
    { 'sprint_inside_interiors', 'SELF_SPRINT_INSIDE' }, { 'jacking_always_lockpick_anim', 'SELF_LOCKPICK_ANIM' },
}
local flags = {
    no_carjacking = { 26, 177, 398 },
    jacking_always_lockpick_anim = { 426 },
    sprint_inside_interiors = { 427 },
    mc_alt_bike_anims = { 424 }
}
local hands_dict, hands_anim = 'mp_missheist_countrybank@lift_hands', 'lift_hands_in_air_outro'
local phone_dict = 'anim@scripted@freemode@ig19_mobile_phone@male@'
local cell_inputs = { { 172, 1 }, { 173, 2 }, { 174, 3 }, { 175, 4 }, { 176, 5 }, { 177, 5 }, { 178, 5 }, { 179, 5 }, { 180, 1 }, { 181, 2 } }
return function(ctx)
    local f = {
        id = 'self_misc',
        category = 'self',
        controls = {},
        flags = {},
        crouching = false,
        hands_up = false,
        phone = false,
        assets = Assets.new()
    }
    local function enabled(key) return ctx.settings:get('features.self.' .. key) end
    for _, option in ipairs(options) do
        f.controls[#f.controls + 1] = {
            kind = 'toggle',
            path = 'features.self.' .. option[1],
            label = option[2],
            tooltip = option[2] .. '_TT'
        }
    end
    function f:enabled()
        for _, option in ipairs(options) do if enabled(option[1]) then return true end end
        return false
    end

    function f:disable() for _, option in ipairs(options) do ctx.settings:set('features.self.' .. option[1], false) end end

    function f:ready(state) return state.alive end

    function f:flag(id, value, own)
        if own then
            if self.flags[id] == nil then self.flags[id] = PED.GET_PED_CONFIG_FLAG(self.identity, id, true) end
            PED.SET_PED_CONFIG_FLAG(self.identity, id, value)
        elseif self.flags[id] ~= nil then
            PED.SET_PED_CONFIG_FLAG(self.identity, id, self.flags[id]); self.flags[id] = nil
        end
    end

    function f:uncrouch()
        if not self.crouching then return end
        PED.RESET_PED_MOVEMENT_CLIPSET(self.identity, 0.35)
        PED.RESET_PED_STRAFE_CLIPSET(self.identity)
        PED.SET_PED_CAN_PLAY_AMBIENT_ANIMS(self.identity, true)
        PED.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(self.identity, true)
        TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(self.identity, false, true)
        self.crouching = false
    end

    function f:hands_down()
        if self.hands_up then
            TASK.CLEAR_PED_TASKS(self.identity)
            self.hands_up = false
        end
    end

    function f:reset_phone()
        if self.phone and TASK.IS_PLAYING_PHONE_GESTURE_ANIM(self.identity) then
            TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(self.identity, 0.25)
        end
        self.phone = false
        for flag = 242, 244 do self:flag(flag, true, false) end
    end

    function f:cleanup()
        if self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            self:uncrouch(); self:hands_down(); self:reset_phone()
            for id, value in pairs(self.flags) do PED.SET_PED_CONFIG_FLAG(self.identity, id, value) end
        end
        self.flags, self.phone, self.crouching, self.hands_up, self.pending = {}, false, false, false, nil
        self.assets:reset()
    end

    function f:can_interact(state)
        local actions = ctx.features.yim_actions
        return not ctx.input.blocked() and not ctx.activity:busy() and not HUD.IS_PAUSE_MENU_ACTIVE()
            and not HUD.IS_MP_TEXT_CHAT_TYPING() and not PED.IS_PED_USING_ANY_SCENARIO(state.handle)
            and not (actions and (actions.playing[state.handle] or actions:busy(state.handle)))
    end

    function f:update_phone(state)
        local actions = ctx.features.yim_actions
        if not enabled('phone_anims') or not network.is_session_started()
            or actions and actions.playing[state.handle]
            or PED.IS_PED_USING_ANY_SCENARIO(state.handle)
            or PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET(state.handle) ~= 0 then
            self:reset_phone(); return
        end
        for flag = 242, 244 do self:flag(flag, false, true) end
        self.phone = true
        if AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
            if self.assets:animation(phone_dict) then
                TASK.TASK_PLAY_PHONE_GESTURE_ANIMATION(state.handle, phone_dict, 'base',
                    'BONEMASK_HEAD_NECK_AND_R_ARM', 0.25, 0.25, true, false)
            end
        elseif TASK.IS_PLAYING_PHONE_GESTURE_ANIM(state.handle) then
            TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(state.handle, 0.25)
        end
        if scripts.is_active('CELLPHONE_FLASHHAND') then
            GTA.CELL_HORIZONTAL_MODE_TOGGLE(scripts.is_active('APPMPEMAIL'))
            for _, input in ipairs(cell_inputs) do
                if PAD.IS_CONTROL_JUST_PRESSED(0, input[1]) then GTA.CELL_SET_INPUT(input[2]) end
            end
        end
    end

    function f:update(state)
        if PED.IS_PED_RAGDOLL(state.handle) then
            self:uncrouch(); self:hands_down(); self:reset_phone(); self.pending = nil
            return
        end
        self:update_phone(state)
        for key, list in pairs(flags) do
            local value = enabled(key) and (key ~= 'mc_alt_bike_anims' or network.is_session_started())
            for _, id in ipairs(list) do self:flag(id, true, value) end
        end
        if enabled('sprint_inside_interiors') and not ctx.game.outside(state.handle) then
            for _, id in ipairs({ 46, 47, 102, 362 }) do PED.SET_PED_RESET_FLAG(state.handle, id, false) end
            PED.SET_PED_MAX_MOVE_BLEND_RATIO(state.handle, 3)
        end
        for key, id in pairs({ disable_action_mode = 200, allow_headprops_in_vehicles = 337, stand_on_veh_roof = 274 }) do
            if enabled(key) then PED.SET_PED_RESET_FLAG(state.handle, id, true) end
        end
        local can_interact = self:can_interact(state)
        if not enabled('crouch') or not state.on_foot then self:uncrouch() end
        if not enabled('hands_up') or not state.on_foot then self:hands_down() end
        if enabled('crouch') then
            PAD.DISABLE_CONTROL_ACTION(0, 36, true)
            if state.on_foot and can_interact and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 36) then
                if self.crouching then
                    self:uncrouch(); self.pending = nil
                else
                    self.pending = 'crouch'
                end
            end
        end
        if enabled('hands_up') then
            PAD.DISABLE_CONTROL_ACTION(0, 29, true)
            if (state.on_foot or state.car) and can_interact and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
                if self.hands_up then
                    self:hands_down(); self.pending = nil
                else
                    self.pending = 'hands'
                end
            end
        end
        if self.pending == 'crouch' then
            if not enabled('crouch') or not state.on_foot or not can_interact then
                self.pending = nil
            elseif self.assets:clipset('move_ped_crouched') and self.assets:clipset('move_aim_strafe_crouch_2h') then
                self:hands_down()
                PED.SET_PED_MOVEMENT_CLIPSET(state.handle, 'move_ped_crouched', 0.3)
                PED.SET_PED_STRAFE_CLIPSET(state.handle, 'move_aim_strafe_crouch_2h')
                PED.SET_PED_CAN_PLAY_AMBIENT_ANIMS(state.handle, false)
                PED.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(state.handle, false)
                TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(state.handle, true, true)
                self.crouching, self.pending = true, nil
            end
        elseif self.pending == 'hands' then
            if not enabled('hands_up') or not (state.on_foot or state.car) or not can_interact then
                self.pending = nil
            elseif self.assets:animation(hands_dict) then
                self:uncrouch()
                TASK.TASK_PLAY_ANIM(state.handle, hands_dict, hands_anim, 4, -4, -1, 50, 1, false, false, false)
                self.hands_up, self.pending = true, nil
            end
        end
    end

    return f
end
