local Feature = require('includes.ssv2.core.feature')
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'magic_bullet',
        category = 'self',
        path = 'features.weapon.magic_bullet',
        target = 0,
        last_fired = 0,
        controls = { {
            kind = 'toggle',
            path = 'features.weapon.magic_bullet',
            label = 'SELF_MAGIC_BULLET',
            tooltip = 'SELF_MAGIC_BULLET_TT'
        } }
    })
    function f:ready(state) return state.alive and WEAPON.IS_PED_ARMED(state.handle, 4) end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        if now - self.last_fired < 150 then return end
        if PLAYER.IS_PLAYER_FREE_AIMING(state.player_id) then
            local target = ctx.game.aimed_entity(state.player_id, false)
            if target ~= 0 and ENTITY.IS_ENTITY_A_PED(target) and PED.IS_PED_HUMAN(target) then
                self.target = target
            end
        else
            self.target = 0
        end
        if self.target == 0 or not ENTITY.DOES_ENTITY_EXIST(self.target)
            or ENTITY.IS_ENTITY_DEAD(self.target, false) then
            self.target = 0; return
        end
        local weapon = ctx.game.current_weapon(state.handle)
        if not WEAPON.HAS_WEAPON_ASSET_LOADED(weapon) then WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0) end
        if WEAPON.HAS_WEAPON_ASSET_LOADED(weapon) and PAD.IS_CONTROL_PRESSED(0, 24)
            and not PED.IS_PED_RELOADING(state.handle) then
            local pos = PED.GET_PED_BONE_COORDS(self.target, 0x796E, 0, 0, 0)
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x - 1, pos.y - 1, pos.z,
                pos.x + 1, pos.y + 1, pos.z, 300, false, weapon, state.handle, true, false, -1082130432)
            self.last_fired = now
        end
    end

    function f:cleanup() self.target = 0 end

    return f
end
