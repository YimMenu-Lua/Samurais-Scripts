local Settings = require('includes.ssv2.core.settings')
local Forge = require('includes.ssv2.core.forge')
local Codec = require('includes.ssv2.core.codec')
local Appearance = require('includes.ssv2.core.appearance')
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
return function(ctx)
    local f = {
        id = 'entity_forge',
        category = 'extra',
        scope = 'player',
        owns_controls = true,
        name = '',
        model = '',
        spawn_kind = 0,
        parent_index = 0,
        bone = '0',
        save_name = '',
        serialized = '',
        rename = '',
        scenario_index = 0,
        alpha = 255,
        position = { 0, 0, 0 },
        rotation = { 0, 0, 0 },
        controls = {
            { kind = 'toggle', path = 'ui.show_forge',                       label = 'Entity Forge' },
            { kind = 'toggle', path = 'features.entity_forge.entity_gun',    label = 'Entity Gun' },
            { kind = 'toggle', path = 'features.entity_forge.mark_selected', label = 'Mark selected forge entity' },
        }
    }
    f.saved = Settings.new({ creations = {} }, 'ssv2/forged_entities.json')
    f.favorites = Settings.new({ models = {} }, 'ssv2/forge_favorites.json')
    f.browser = require('includes.ssv2.core.model_browser').new(ctx)
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready(state) return state.alive end

    function f:enter()
        self.forge = Forge.new(ctx, self); self.preview = ctx.preview
        self.serial = (self.serial or 0) + 1; self.selected = nil
    end

    function f:valid(serial, generation)
        return self.active and ctx.runtime.running and self.serial == serial and ctx.runtime.generation == generation
    end

    function f:run(label, callback)
        local serial, generation = self.serial, ctx.runtime.generation
        ctx.runtime:run(label,
            function() if self:valid(serial, generation) then callback(function() return self:valid(serial, generation) end) end end)
    end

    function f:cleanup()
        self.serial = (self.serial or 0) + 1
        if self.frontend then self.frontend:close_independent(false) end
        if self.preview then self.preview:clear() end
        if self.forge then self.forge:clear() end
        self.saved:save(); self.favorites:save(); self.selected = nil
    end

    function f:favorite(entry, name)
        local values = copy(self.favorites.data.models)
        values[tostring(entry.model % 4294967296)] = {
            model = entry.model,
            name = name or entry.name,
            kind = entry.kind,
            alpha =
                entry.alpha or 255
        }
        self.favorites:set('models', values); self.favorites:save()
    end

    function f:save(entry, name, overwrite)
        assert(type(name) == 'string' and name:find('%S'), 'Enter a creation name')
        local values = copy(self.saved.data.creations)
        assert(overwrite or not values[name], 'A creation already uses this name')
        values[name] = self.forge:serialize(entry); values[name].name = name
        self.saved:set('creations', values); self.saved:save()
        return values[name]
    end

    function f:update(state)
        self.saved:update(); self.favorites:update()
        for i = #self.forge.order, 1, -1 do
            local entry = self.forge.order[i]
            if entry and not self.forge:exists(entry) then self.forge:remove(entry, false) end
        end
        if ctx.settings:get('features.entity_forge.entity_gun') and not ctx.input.blocked() and WEAPON.IS_PED_ARMED(state.handle, 4) then
            self.forge:gun(state)
        else
            self.forge:drop()
        end
        local selected = self.selected
        if selected and self.forge:exists(selected) then
            if self.last_selected ~= selected then
                self.last_selected = selected; self.rename = selected.name; self.alpha = selected.alpha
                local p, r = selected.parent and selected.attach_pos or selected.position,
                    selected.parent and selected.attach_rot or selected.rotation
                self.position = { p.x, p.y, p.z }; self.rotation = { r.x, r.y, r.z }; self.components_owner = nil
            end
            if ctx.settings:get('features.entity_forge.mark_selected') then self:mark(selected, 0) end
            if util.time() >= (self.next_snapshot or 0) then
                selected.position = { x = 0, y = 0, z = 0 }; local p = ENTITY.GET_ENTITY_COORDS(selected.handle, false)
                selected.position.x, selected.position.y, selected.position.z = p.x, p.y, p.z
                local r = ENTITY.GET_ENTITY_ROTATION(selected.handle, 2); selected.rotation = {
                    x = r.x,
                    y = r.y,
                    z = r
                        .z
                }
                if selected.kind == 'ped' and not selected.player and self.components_owner ~= selected then
                    self.components = Appearance.ped(selected.handle); self.components_owner = selected
                end
                self.next_snapshot = util.time() + 500
            end
        elseif selected then
            self.selected = nil
        end
        if self.frontend then self.frontend:update() end
    end

    function f:mark(entry, offset)
        if not self.forge:exists(entry) then return end
        local min, max = Vector3.new(), Vector3.new()
        MISC.GET_MODEL_DIMENSIONS(entry.model, min, max)
        local pos = ENTITY.GET_ENTITY_COORDS(entry.handle, false)
        GRAPHICS.DRAW_MARKER(2, pos.x, pos.y, pos.z + max.z - min.z + (offset or 0.4), 0, 0, 0, 0, 180, 0,
            0.3, 0.3, 0.3, 0, 255, 0, 100, true, true, 1, false, nil, nil, false)
    end

    local function gun_binding(id, callback)
        ctx.input:bind(id, function()
            if f.active and ctx.settings:get('features.entity_forge.entity_gun') then callback() end
        end)
    end
    gun_binding('forge_add_world', function()
        if f.forge.grabbed and f.forge.grabbed.world then
            f.forge:release(f.forge.grabbed); return
        end
        local state = ctx.state:read(); if not state then return end
        local target = ctx.game.aimed_entity(state.player_id, true)
        if target ~= 0 and not f.forge.entries[target] then
            local serial, generation = f.serial, ctx.runtime.generation
            f.selected = f.forge:adopt(target, function() return f:valid(serial, generation) end)
        end
    end)
    gun_binding('forge_save_model', function()
        local entry = f.forge.grabbed; if not entry then return end
        if f.favorites.data.models[tostring(entry.model % 4294967296)] then
            ctx.notifier:error('EntityForge', 'This model is already saved. Please choose a different one!')
        else
            f:favorite(entry, entry.name .. ' [' .. entry.handle .. ']')
        end
    end)
    gun_binding('forge_delete_world', function() if f.forge.grabbed then f.forge:remove(f.forge.grabbed, false) end end)
    local function rotation_speed(increase)
        if not f.forge.grabbed or not PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) then return end
        local current = f.forge.rotation_speed
        f.forge.rotation_speed = increase and (current == 1 and 10 or current + 10) or (current <= 10 and 1 or current - 10)
        ctx.notifier:info('EntityForge', 'Rotation multiplier set to ' .. f.forge.rotation_speed)
    end
    gun_binding('forge_rotation_up', function() rotation_speed(true) end)
    gun_binding('forge_rotation_down', function() rotation_speed(false) end)
    event.register_handler(menu_event.WndProc, function(_, message, key)
        if message ~= 523 or not f.active or not ctx.settings:get('features.entity_forge.entity_gun') or ctx.input.capture then return end
        local increase = bit.rshift(key, 16) == 2
        f:run('entity gun rotation speed', function() if not ctx.input.blocked() then rotation_speed(increase) end end)
    end)
    f.frontend = require('includes.ssv2.core.forge_view').new(ctx, f)
    function f:draw() self.frontend:draw() end

    return f
end
