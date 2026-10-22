local Memory = require('includes.ssv2.core.vehicle_memory')
local Wheels = require('includes.ssv2.core.wheels')
local Settings = require('includes.ssv2.core.settings')
local models_by_hash = require('includes.ssv2.data.vehicle_hashmap')
local specs = {
    { key = 'm_toe',         offset = 4,     label = 'VEH_STANCE_TOE',         min = -0.25,     max = 0.25 },
    { key = 'm_camber',      offset = 8,     label = 'VEH_STANCE_CAMBER',      min = -1,        max = 1 },
    { key = 'm_track_width', offset = 0x30,  label = 'VEH_STANCE_TRACK_WIDTH', min = -0.5,      max = 0.5 },
    { key = 'm_susp_comp',   offset = 0x13C, label = 'VEH_STANCE_SUSP_COMP',   same_side = true },
}
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
local function deltas()
    local result = { {}, {} }
    for _, axle in ipairs(result) do for _, spec in ipairs(specs) do axle[spec.key] = 0 end end
    result[1].m_wheel_width = 0; result[1].m_wheel_size = 0
    return result
end
return function(ctx)
    local f = {
        id = 'stancer',
        category = 'vehicle',
        scope = 'vehicle',
        controls = {
            { kind = 'toggle', path = 'ui.show_stancer',                           label = 'SUBTAB_STANCER' },
            { kind = 'toggle', path = 'features.vehicle.stancer.auto_apply_saved', label = 'VEH_STANCE_AUTOAPPLY' },
        },
        queue = {},
        deltas = deltas(),
        height = 0,
        bounce = false,
        bounce_phase = 0
    }
    f.storage = Settings.new({ models = {} }, 'ssv2/stancer.json')
    if not FileMgr.DoesFileExist('ssv2/stancer.json') and not FileMgr.DoesFileExist('ssv2/stancer.json.bak') then
        local old = f.storage:read('stancer.json')
        if old then
            f.storage:set('models', old); f.storage:save()
        end
    end
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() f.storage:save() end
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready(state) return state.car end

    function f:valid()
        return self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) and
            Memory.identity(self.identity) == self.base
    end

    function f:lock(owner) self.locked = owner end

    function f:unlock(owner) if not owner or self.locked == owner then self.locked = nil end end

    function f:capture()
        self.wheels = {}; self.bases = { {}, {} }
        local count = Wheels.count(self.identity)
        assert(count > 0 and count <= 32, 'Stancer: invalid wheel count')
        for index = 1, count do
            local wheel = Wheels.pointer(self.identity, index)
            local flags = wheel:add(0x204):get_dword()
            local left = bit.band(flags, 2) ~= 0
            local axle = bit.band(flags, 4) ~= 0 and 2 or 1
            local saved = { index = index, address = wheel:get_address(), axle = axle, left = left, values = {} }
            for _, spec in ipairs(specs) do
                local value = wheel:add(spec.offset):get_float()
                saved.values[spec.offset] = value
                if left or self.bases[axle][spec.key] == nil then self.bases[axle][spec.key] = value end
            end
            saved.values[0x10] = wheel:add(0x10):get_float()
            self.wheels[#self.wheels + 1] = saved
        end
        local draw = Wheels.draw(self.identity)
        self.visual = draw and
            { address = draw:get_address(), width = draw:add(0xBA0):get_float(), size = draw:add(8):get_float() } or nil
        local ride = Wheels.ride_height(self.identity)
        self.ride = { address = ride:get_address(), original = ride:get_float() }
        self.wheel_mod = VEHICLE.GET_VEHICLE_WHEEL_TYPE(self.identity) .. ':' ..
            VEHICLE.GET_VEHICLE_MOD(self.identity, 23)
            .. ':' .. tostring(VEHICLE.GET_VEHICLE_MOD_VARIATION(self.identity, 23))
        self.custom = VEHICLE.GET_VEHICLE_MOD(self.identity, 23) ~= -1 and draw ~= nil
        self.next_wheels = util.time() + 2000
    end

    function f:enter(state)
        self.base = Memory.identity(self.identity); self.model = models_by_hash[state.vehicle:get_model() % 4294967296] or
            'NULL'
        self.deltas = deltas(); self.height = 0; self:capture()
        local queued = self.queue[self.base]
        if queued then
            self.deltas = copy(queued.deltas); self.height = queued.height
        end
        if ctx.settings:get('features.vehicle.stancer.auto_apply_saved') then self:load(self.model) end
    end

    function f:restore()
        if not self:valid() then return end
        for _, saved in ipairs(self.wheels or {}) do
            if saved.index <= Wheels.count(self.identity) then
                local wheel = Wheels.pointer(self.identity, saved.index)
                if wheel:get_address() == saved.address then
                    for offset, value in pairs(saved.values) do wheel:add(offset):set_float(value) end
                end
            end
        end
        local draw = Wheels.draw(self.identity)
        if self.visual and draw and draw:get_address() == self.visual.address then
            draw:add(0xBA0):set_float(self.visual.width); draw:add(8):set_float(self.visual.size)
        end
        local ride = Wheels.ride_height(self.identity)
        if self.ride and ride:get_address() == self.ride.address then ride:set_float(self.ride.original) end
    end

    function f:cleanup()
        if self.base then self.queue[self.base] = { deltas = copy(self.deltas), height = self.height } end
        self:restore(); self.air = nil; self:bounce_stop(); self.wheels = nil
    end

    function f:reset()
        self:restore(); self:bounce_stop(); self.air = nil; self.deltas = deltas(); self.height = 0
        VEHICLE.RESET_VEHICLE_WHEELS(self.identity, true); VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.identity, 5)
    end

    function f:save()
        assert(self.active and self.model and self.model ~= 'NULL', 'No stancer vehicle to save')
        local models = copy(self.storage:get('models'))
        models[self.model] = copy(self.deltas); models[self.model][1].m_suspension_height = self.height
        self.storage:set('models', models); return self.storage:save()
    end

    function f:load(model)
        local saved = self.storage:get('models')[model]
        if type(saved) ~= 'table' then return false end
        local front, rear = saved[1] or saved['1'], saved[2] or saved['2']
        if type(front) ~= 'table' or type(rear) ~= 'table' then return false end
        for index, source in ipairs({ front, rear }) do
            for _, spec in ipairs(specs) do
                local value = source[spec.key]
                if type(value) == 'number' and value == value and math.abs(value) < math.huge then
                    self.deltas[index][spec.key] =
                        value
                end
            end
        end
        for _, key in ipairs({ 'm_wheel_width', 'm_wheel_size' }) do
            if type(front[key]) == 'number' and math.abs(front[key]) <= 0.5 then self.deltas[1][key] = front[key] end
        end
        if type(front.m_suspension_height) == 'number' and math.abs(front.m_suspension_height) <= 0.2 then
            self.height =
                front.m_suspension_height
        end
        PHYSICS.ACTIVATE_PHYSICS(self.identity); return true
    end

    function f:remove(model)
        local models = copy(self.storage:get('models')); models[model] = nil
        self.storage:set('models', models); return self.storage:save()
    end

    function f:bounce_stop()
        if self.bounce_saved then
            self.deltas[1].m_susp_comp = self.bounce_saved[1]; self.deltas[2].m_susp_comp = self.bounce_saved[2]
        end
        self.bounce, self.bounce_saved = false, nil
    end

    function f:air_suspension(target, step)
        local front, rear = self.deltas[1].m_susp_comp, self.deltas[2].m_susp_comp
        self.air = {
            axle = 1,
            target = target,
            next = 0,
            cursors = { front, rear },
            steps = { step or (front < target and 0.01 or -0.01), step or (rear < target and 0.01 or -0.01) }
        }
    end

    function f:update(state)
        if not self:valid() then error('Vehicle pointer changed while stancer was active') end
        self.storage:update()
        self.frontend:update()
        local now = util.time()
        if now >= self.next_wheels then
            local current = VEHICLE.GET_VEHICLE_WHEEL_TYPE(self.identity) ..
                ':' .. VEHICLE.GET_VEHICLE_MOD(self.identity, 23)
                .. ':' .. tostring(VEHICLE.GET_VEHICLE_MOD_VARIATION(self.identity, 23))
            if current ~= self.wheel_mod then
                local draw = Wheels.draw(self.identity)
                local visual = draw and
                    { address = draw:get_address(), width = draw:add(0xBA0):get_float(), size = draw:add(8):get_float() } or
                    nil
                self:restore()
                if visual and draw:get_address() == visual.address then
                    draw:add(0xBA0):set_float(visual.width); draw:add(8):set_float(visual.size)
                end
                self:capture()
            end
            self.next_wheels = now + 2000
        end
        if self.bounce then
            if VEHICLE.GET_VEHICLE_CLASS(self.identity) ~= 2 then
                self:bounce_stop(); ctx.notifier:error('Stancer', ctx.translator:text('VEH_STANCE_BOUNCE_MODE_UNAVAIL'))
            else
                self.bounce_saved = self.bounce_saved or { self.deltas[1].m_susp_comp, self.deltas[2].m_susp_comp }
                self.bounce_phase = self.bounce_phase + MISC.GET_FRAME_TIME() * 0.988
                local n = math.abs(2 * (self.bounce_phase - math.floor(self.bounce_phase + 0.5)))
                local value = (2 * n * n * (3 - 2 * n) - 1) * 0.09
                self.deltas[1].m_susp_comp = value; self.deltas[2].m_susp_comp = value
                if ENTITY.GET_ENTITY_SPEED(self.identity) <= 0.1 then PHYSICS.ACTIVATE_PHYSICS(self.identity) end
            end
        elseif self.bounce_saved then
            self:bounce_stop()
        end
        if self.air and now >= self.air.next then
            local air = self.air; air.delta = air.delta or MISC.GET_FRAME_TIME()
            while air.axle <= 2 do
                local axle, current, step = air.axle, air.cursors[air.axle], air.steps[air.axle]
                if step > 0 and current <= air.target or step < 0 and current >= air.target then
                    self.deltas[axle].m_susp_comp = current + step * math.sin(air.delta)
                    air.cursors[axle] = current + step; air.next = now + 30
                    if VEHICLE.IS_VEHICLE_STOPPED(self.identity) then PHYSICS.ACTIVATE_PHYSICS(self.identity) end
                    break
                end
                self.deltas[axle].m_susp_comp = air.target; air.axle = axle + 1
            end
            if air.axle > 2 then self.air = nil end
        end
        for _, saved in ipairs(self.wheels) do
            local wheel = Wheels.pointer(self.identity, saved.index)
            if wheel:get_address() ~= saved.address then
                self:restore(); self:capture(); return
            end
            for _, spec in ipairs(specs) do
                local value = self.bases[saved.axle][spec.key] + self.deltas[saved.axle][spec.key]
                if not spec.same_side and not saved.left then value = -value end
                wheel:add(spec.offset):set_float(value)
                if spec.key == 'm_camber' then wheel:add(0x10):set_float(-value) end
            end
        end
        if self.custom and self.visual then
            local draw = Wheels.draw(self.identity)
            if draw and draw:get_address() == self.visual.address then
                draw:add(0xBA0):set_float(self.visual.width + self.deltas[1].m_wheel_width)
                draw:add(8):set_float(self.visual.size + self.deltas[1].m_wheel_size)
            end
        end
        local ride = Wheels.ride_height(self.identity)
        if ride:get_address() == self.ride.address then ride:set_float(self.height) end
        self.queue[self.base] = { deltas = copy(self.deltas), height = self.height }
    end

    f.frontend = require('includes.ssv2.core.stancer_view').new(ctx, f)
    f.owns_controls = true
    function f:draw() self.frontend:draw() end

    return f
end
