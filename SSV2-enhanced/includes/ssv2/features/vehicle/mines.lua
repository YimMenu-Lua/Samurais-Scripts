local Feature = require('includes.ssv2.core.feature')
local Assets = require('includes.ssv2.core.assets')
local types = { { 'Spikes', -647126932 }, { 'Slick', 1459276487 }, { 'Explosive', 1508567460 }, { 'EMP', 1776356704 }, { 'Kinetic', 1007245390 } }
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'mines',
        category = 'vehicle',
        scope = 'vehicle',
        path = 'features.vehicle.mines.enabled',
        next_deploy = 0,
        requested = false,
        assets = Assets.new(),
        controls = { { kind = 'toggle', path = 'features.vehicle.mines.enabled', label = 'VEH_MINES', tooltip = 'VEH_MINES_TT' } }
    })
    ctx.input:bind('veh_mine', function()
        local state = ctx.state:read()
        if f:enabled() and state and f:ready(state) and ctx.clock:elapsed_ms() >= f.next_deploy then f.requested = true end
    end)
    function f:ready(state) return state.alive and state.driving and state.land_vehicle end

    function f:cleanup()
        self.requested = false; self.assets:reset()
    end

    function f:update(state)
        if not self.requested then return end
        local bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(state.vehicle_handle, 'chassis_dummy')
        if bone == -1 then
            self.requested = false; return
        end
        local hash = ctx.settings:get('features.vehicle.mines.selected_type_hash')
        if not self.assets:weapon(hash) then return end
        local src = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(state.vehicle_handle, bone)
        local pos, forward = state.vehicle:get_position(), ENTITY.GET_ENTITY_FORWARD_VECTOR(state.vehicle_handle)
        local minimum, maximum = ctx.game.model_dimensions(state.vehicle:get_model())
        local offset = (maximum.y - minimum.y) / 1.6
        local found, ground = ctx.game.ground_z(pos)
        if not found then
            self.requested = false; return
        end
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(src.x - forward.x * offset, src.y - forward.y * offset, src.z,
            src.x - forward.x * offset, src.y - forward.y * offset, ground, 0, false, hash, state.handle, true, false,
            0.01)
        self.next_deploy, self.requested = ctx.clock:elapsed_ms() + 5000, false
    end

    function f:draw()
        local selected, names = 0, {}
        for i, value in ipairs(types) do
            names[i] = value[1]
            if value[2] == ctx.settings:get('features.vehicle.mines.selected_type_hash') then selected = i - 1 end
        end
        local index, changed = ImGui.Combo(ctx.translator:text('GENERIC_TYPE') .. '##mines', selected, names, #names)
        if changed then ctx.settings:set('features.vehicle.mines.selected_type_hash', types[index + 1][2]) end
    end

    return f
end
