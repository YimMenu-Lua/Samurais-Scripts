local Feature = require('includes.ssv2.core.feature')
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'autoheal',
        category = 'self',
        path = 'features.self.autoheal.enabled',
        last_update = 0,
        armour_credit = 0,
        controls = {
            { kind = 'toggle', path = 'features.self.autoheal.enabled',     label = 'SELF_AUTOHEAL',    tooltip = 'SELF_AUTOHEAL_TT' },
            { kind = 'int',    path = 'features.self.autoheal.regen_speed', label = 'SELF_REGEN_SPEED', min = 1,                     max = 100 },
        }
    })
    function f:ready(state) return state.alive end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        local speed = math.max(1, math.min(100, ctx.settings:get('features.self.autoheal.regen_speed')))
        if now - self.last_update < math.floor(1000 / speed) then return end
        local health, max_health = state.ped:get_health(), state.ped:get_max_health()
        if health > 0 and health < max_health then
            local gain = PED.IS_PED_IN_COVER(state.handle, false) and 10 or 1
            ENTITY.SET_ENTITY_HEALTH(state.handle, math.min(max_health, health + gain), 0, 0)
        end
        local armour, max_armour = state.ped:get_armour(), PLAYER.GET_PLAYER_MAX_ARMOUR(state.player_id)
        if armour < max_armour then
            -- Preserve the original half-point rate with an integer native binding.
            self.armour_credit = self.armour_credit + 0.5
            local gain = math.floor(self.armour_credit)
            if gain > 0 then
                PED.ADD_ARMOUR_TO_PED(state.handle, math.min(gain, max_armour - armour))
                self.armour_credit = self.armour_credit - gain
            end
        else
            self.armour_credit = 0
        end
        self.last_update = now
    end

    function f:cleanup() self.armour_credit = 0 end

    return f
end
