local Memory = require('includes.ssv2.core.vehicle_memory')
local Assets = require('includes.ssv2.core.assets')
local Geometry = require('includes.ssv2.core.geometry')
local flight_controls = { 72, 75, 87, 88, 89, 90, 106, 107, 108, 109, 110, 111, 112 }
local function vehicle_mg(ped)
    local base = memory.handle_to_ptr(ped)
    if base:is_null() then return false end
    local manager = base:add(0x10B8):deref()
    if manager:is_null() then return false end
    local info = manager:add(0x70):deref()
    return not info:is_null() and info:add(0x10):get_dword() ~= 0 and info:add(0x170):get_int() == 21
end
return function(ctx)
    local root = 'features.vehicle.'
    local f = {
        id = 'aircraft',
        category = 'vehicle',
        scope = 'vehicle',
        mode = 0,
        assets = Assets.new(),
        controls = {
            { kind = 'toggle', path = root .. 'fast_jets',                   label = 'VEH_FAST_JETS' },
            { kind = 'float',  path = root .. 'fast_jets_speed',             label = 'VEH_FAST_JETS',           min = 100,                             max = 300 },
            { kind = 'toggle', path = root .. 'no_jet_stall',                label = 'VEH_NO_JET_STALL' },
            { kind = 'toggle', path = root .. 'no_turbulence',               label = 'VEH_NO_TURBULENCE' },
            { kind = 'toggle', path = root .. 'aircraft_mg.triggerbot',      label = 'VEH_MG_TRIGGERBOT' },
            { kind = 'toggle', path = root .. 'aircraft_mg.enemies_only',    label = 'VEH_MG_TRIGGERBOT_ENEMY', tooltip = 'VEH_MG_TRIGGERBOT_ENEMY_TT' },
            { kind = 'float',  path = root .. 'aircraft_mg.tiggerbot_range', label = 'VEH_MG_TRIGGERBOT_RANGE', min = 100,                             max = 1000 },
            { kind = 'toggle', path = root .. 'aircraft_mg.manual_aim',      label = 'VEH_MG_MANUAL_AIM' },
            { kind = 'float',  path = root .. 'aircraft_mg.marker_size',     label = 'VEH_MG_MARKER_SIZE',      min = 1,                               max = 10 },
            { kind = 'color4', path = root .. 'aircraft_mg.marker_color',    label = 'VEH_MG_MARKER_COL' },
        }
    }
    local function cfg(key) return ctx.settings:get(root .. key) end
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready(state) return state.alive and state.driving and state.aircraft end

    function f:stop_autopilot()
        if self.mode ~= 0 and self.ped and ENTITY.DOES_ENTITY_EXIST(self.ped) then
            TASK.CLEAR_PED_TASKS(self.ped); TASK.CLEAR_PED_SECONDARY_TASK(self.ped)
        end
        self.mode, self.started_mode = 0, nil
    end

    function f:restore_turbulence()
        for _, lease in ipairs(self.turbulence or {}) do lease:restore() end
        if self.turbulence and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(
                self.identity, 1)
        end
        self.turbulence = nil
    end

    function f:cleanup()
        self:stop_autopilot(); self:restore_turbulence(); self.assets:reset()
    end

    function f:enter(state) self.ped = state.handle end

    function f:start_autopilot(state)
        local destination
        if self.mode == 1 then
            destination = ctx.game.waypoint()
        elseif self.mode == 2 then
            destination = ctx.game.objective()
        else
            destination = Vector3.new(math.random(-2000, 2000), math.random(-3000, 3500), math.random(0, 100))
        end
        if not destination then
            self:stop_autopilot(); ctx.notifier:error('Autopilot', 'No destination was found'); return
        end
        TASK.CLEAR_PED_TASKS(state.handle); TASK.CLEAR_PED_SECONDARY_TASK(state.handle)
        local handle = state.vehicle_handle
        self.initial_nozzle = VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(handle)
        if state.plane then
            TASK.TASK_PLANE_MISSION(state.handle, handle, 0, 0, destination.x, destination.y, destination.z + 800, 4, 100,
                0, 90, 5000, 200, true)
        else
            TASK.TASK_HELI_MISSION(state.handle, handle, 0, 0, destination.x, destination.y, destination.z,
                4, VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(handle), 4, -1, -1, 100, 100, 0)
        end
        self.started_mode = self.mode
    end

    function f:shoot(state, target, src, dest, enemies_only)
        if enemies_only and target ~= 0 then
            local enemy = ENTITY.IS_ENTITY_A_PED(target) and ctx.game.is_enemy(state.handle, target)
            if ENTITY.IS_ENTITY_A_VEHICLE(target) then
                local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(target, -1, false)
                enemy = driver ~= 0 and ctx.game.is_enemy(state.handle, driver)
            end
            if not enemy then return end
        end
        if target ~= 0 and not ENTITY.IS_ENTITY_DEAD(target, false) then
            VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(state.handle, target, dest.x, dest.y, dest.z)
        end
        if self.assets:weapon(3800181289) then
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(src.x, src.y, src.z, dest.x, dest.y, dest.z,
                1000, true, 3800181289, state.handle, true, false, 300)
        end
    end

    function f:machine_guns(state)
        if not (cfg('aircraft_mg.triggerbot') or cfg('aircraft_mg.manual_aim')) or not vehicle_mg(state.handle) then return end
        local src = state.ped:get_position()
        local manual = cfg('aircraft_mg.manual_aim')
        local rotation = manual and CAMERA.GET_GAMEPLAY_CAM_ROT(2) or ENTITY.GET_ENTITY_ROTATION(state.vehicle_handle, 2)
        local direction = Geometry.direction(rotation)
        local distance = manual and 200 or cfg('aircraft_mg.tiggerbot_range')
        local dest = Vector3.new(src.x + direction.x * distance, src.y + direction.y * distance,
            src.z + direction.z * distance)
        local hit, endpoint, entity = ctx.game.raycast(src, dest, -1, state.vehicle_handle)
        if hit and cfg('aircraft_mg.triggerbot') and (ENTITY.IS_ENTITY_A_PED(entity) or ENTITY.IS_ENTITY_A_VEHICLE(entity)) then
            local nearest, minimum = 0, 50
            for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                if ped ~= state.handle and not PED.IS_PED_A_PLAYER(ped) and ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped, false) then
                    local pos = ENTITY.GET_ENTITY_COORDS(ped, true); local range = Geometry.distance(endpoint, pos)
                    if range < minimum then nearest, minimum = ped, range end
                end
            end
            if nearest ~= 0 then
                self:shoot(state, nearest, src, ENTITY.GET_ENTITY_COORDS(nearest, true),
                    cfg('aircraft_mg.enemies_only'))
            end
            local vehicle = ctx.game.closest_vehicle(endpoint, 50, state.vehicle_handle)
            if vehicle ~= 0 then
                self:shoot(state, vehicle, src, ENTITY.GET_ENTITY_COORDS(vehicle, true),
                    cfg('aircraft_mg.enemies_only'))
            end
        end
        if manual then
            local target = hit and endpoint or
                Vector3.new(src.x + direction.x * 1000, src.y + direction.y * 1000, src.z + direction.z * 1000)
            if PAD.IS_CONTROL_PRESSED(0, 70) then self:shoot(state, 0, src, target, false) end
            local marker = hit and endpoint or
                Vector3.new(src.x + direction.x * 50, src.y + direction.y * 50, src.z + direction.z * 50 + 1)
            local size, color = cfg('aircraft_mg.marker_size'), cfg('aircraft_mg.marker_color')
            GRAPHICS.DRAW_MARKER_EX(3, marker.x, marker.y, marker.z, 0, 0, 0, 0, 0, 0, size, size, size,
                math.floor(color[1] * 255), math.floor(color[2] * 255), math.floor(color[3] * 255),
                math.floor(color[4] * 255),
                false, true, 1, false, nil, nil, true, true, false)
        end
    end

    function f:update(state)
        self.plane = state.plane
        self.aircraft = state.aircraft
        local handle = state.vehicle_handle
        if cfg('fast_jets') and state.plane and VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(handle) ~= 1 then
            local speed, limit = ENTITY.GET_ENTITY_SPEED(handle), cfg('fast_jets_speed')
            if speed >= 70 and speed < limit and PAD.IS_CONTROL_PRESSED(0, 87) and VEHICLE.GET_LANDING_GEAR_STATE(handle) == 4 then
                local pitch = ENTITY.GET_ENTITY_ROTATION(handle, 2).x
                local multiplier = pitch >= 60 and 2 or pitch >= 30 and 1.4 or 1
                local thrust = math.min(10000, 25000 * multiplier * (1 - math.min(1, speed / limit)))
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(handle, 1, 0, thrust, 0, false, true, false, false)
            end
        end
        if cfg('no_jet_stall') and VEHICLE.IS_VEHICLE_DRIVEABLE(handle, false) and VEHICLE.GET_VEHICLE_ENGINE_HEALTH(handle) > 350
            and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) > 5 and not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, false)
        end
        if cfg('no_turbulence') and state.plane then
            if not self.turbulence then
                self.turbulence = {}
                for _, offset in ipairs({ 0x94, 0x58 }) do
                    local field = offset
                    self.turbulence[#self.turbulence + 1] = Memory.float_lease(handle,
                        function(vehicle) return Memory.subhandling(vehicle):add(field) end, 0)
                end
                VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(handle, 0)
            end
        elseif self.turbulence then
            self:restore_turbulence()
        end
        self:machine_guns(state)
        if self.mode ~= 0 then
            if self.started_mode ~= self.mode then self:start_autopilot(state) end
            for _, control in ipairs(flight_controls) do
                if PAD.IS_CONTROL_PRESSED(0, control) then
                    self:stop_autopilot(); ctx.notifier:warn('Autopilot', 'Pilot input returned control to you'); break
                end
            end
            if self.mode ~= 0 and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) > 15 then
                local gear = VEHICLE.GET_LANDING_GEAR_STATE(handle)
                if gear ~= 4 and gear ~= 1 then VEHICLE.CONTROL_LANDING_GEAR(handle, 1) end
                if VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(handle) ~= self.initial_nozzle then
                    VEHICLE.SET_VEHICLE_FLIGHT_NOZZLE_POSITION(handle, self.initial_nozzle)
                end
            end
        end
    end

    function f:draw()
        ImGui.Spacing(); ImGui.SeparatorText(ctx.translator:text('VEH_AUTOPILOT'))
        local eligible = self.active and self.aircraft or false
        ImGui.BeginDisabled(not eligible)
        local labels = {}; for i, key in ipairs({ 'GENERIC_NONE', 'GENERIC_WAYPOINT', 'GENERIC_OBJECTIVE', 'GENERIC_RANDOM' }) do
            labels[i] =
                ctx.translator:text(key)
        end
        local value, changed = ImGui.Combo(eligible and '##autopilotdest' or ctx.translator:text('GENERIC_NOT_IN_PLANE'),
            self.mode, labels, 4)
        if changed and eligible then
            ctx.runtime:run('autopilot',
                function() if value == 0 then self:stop_autopilot() else self.mode = value end end)
        end
        ImGui.EndDisabled()
    end

    return f
end
