local Feature = require('includes.ssv2.core.feature')
local Assets = require('includes.ssv2.core.assets')
local model = 0xE2BA016F
local replacements = { 2508868239, 1141786504, 3713923289, 2484171525 }
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'katana',
        category = 'self',
        path = 'features.weapon.katana.enabled',
        object = 0,
        weapon = 0,
        assets = Assets.new(),
        names = { 'Baseball Bat', 'Golf Club', 'Machete', 'Battle Axe' },
        controls = { {
            kind = 'toggle',
            path = 'features.weapon.katana.enabled',
            label = 'SELF_KATANA',
            tooltip = 'SELF_KATANA_TT'
        } }
    })
    function f:ready(state) return state.alive end

    function f:cleanup()
        if self.weapon ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.weapon) then
            ENTITY.SET_ENTITY_ALPHA(self.weapon, self.alpha, false)
            ENTITY.SET_ENTITY_VISIBLE(self.weapon, self.visible, false)
        end
        if self.object ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.object) then Entity.new(self.object):delete() end
        if self.object ~= 0 then ctx.owned_entities[self.object] = nil end
        if self.model_loaded then STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model) end
        self.object, self.weapon, self.model_loaded = 0, 0, false
        self.assets:reset()
    end

    function f:update(state)
        local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(state.handle, false)
        if not WEAPON.IS_PED_ARMED(state.handle, 1)
            or ctx.game.current_weapon(state.handle) ~= ctx.settings:get('features.weapon.katana.model')
            or weapon == 0 or not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(weapon, state.handle) then
            self:cleanup(); return
        end
        if self.weapon ~= 0 and self.weapon ~= weapon then self:cleanup() end
        if self.object ~= 0 and not ENTITY.DOES_ENTITY_EXIST(self.object) then self:cleanup() end
        if self.object == 0 then
            if not self.assets:model(model) then return end
            self.model_loaded = true
            self.object = OBJECT.CREATE_OBJECT(model, 0, 0, 0, true, false, true)
            assert(self.object ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.object), 'Katana creation failed')
            ctx.owned_entities[self.object] = true
            self.weapon, self.alpha, self.visible = weapon, ENTITY.GET_ENTITY_ALPHA(weapon),
                ENTITY.IS_ENTITY_VISIBLE(weapon)
            ENTITY.SET_ENTITY_COLLISION(self.object, false, false)
            ENTITY.SET_ENTITY_ALPHA(weapon, 0, false)
            ENTITY.SET_ENTITY_VISIBLE(weapon, false, false)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(self.object, weapon, 0, 0, 0, 0.025,
                0, 0, 0, false, false, false, false, 2, true, 0)
        end
    end

    function f:draw()
        if self.language ~= ctx.settings:get('backend.language_index') then
            self.language = ctx.settings:get('backend.language_index')
            ctx.runtime:run('katana weapon labels', function()
                for i, hash in ipairs(replacements) do self.names[i] = ctx.game.weapon_name(hash) end
            end)
        end
        local selected, names = 0, self.names
        for i, hash in ipairs(replacements) do
            if hash == ctx.settings:get('features.weapon.katana.model') then selected = i - 1 end
        end
        local index, changed = ImGui.Combo(ctx.translator:text('SELF_KATANA_REPLACE_MODEL'), selected, names, #names)
        if changed then
            local hash = replacements[index + 1]
            ctx.settings:set('features.weapon.katana.model', hash)
            ctx.runtime:run('select katana weapon', function()
                local state = ctx.state:read()
                if not state or not state.on_foot or not ctx.game.outside(state.handle) then return end
                if WEAPON.IS_PED_ARMED(state.handle, 7) then WEAPON.SET_CURRENT_PED_WEAPON(state.handle, 0xA2719263, true) end
                if WEAPON.HAS_PED_GOT_WEAPON(state.handle, hash, false) then
                    local generation = ctx.runtime.generation
                    script.yield(300)
                    local current = ctx.state:read()
                    if ctx.runtime.running and generation == ctx.runtime.generation and current
                        and current.handle == state.handle and current.on_foot then
                        WEAPON.SET_CURRENT_PED_WEAPON(current.handle, hash, true)
                    end
                end
            end)
        end
    end

    return f
end
