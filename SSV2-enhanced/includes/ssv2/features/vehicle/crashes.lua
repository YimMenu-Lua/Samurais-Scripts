local Feature = require('includes.ssv2.core.feature')
local Memory = require('includes.ssv2.core.vehicle_memory')
local collided = require('includes.ssv2.core.collision')
return function(ctx)
    local f = Feature.new(ctx,
        {
            id = 'crashes',
            category = 'vehicle',
            scope = 'vehicle',
            path = 'features.vehicle.strong_crash',
            next_check = 0,
            controls = { { kind = 'toggle', path = 'features.vehicle.strong_crash', label = 'VEH_STRONG_CRASH', tooltip = 'VEH_STRONG_CRASH_TT' } }
        })
    function f:ready(state)
        return state.alive and state.driving and state.car and not VEHICLE.IS_VEHICLE_STUCK_ON_ROOF(state.vehicle_handle)
    end

    function f:cleanup()
        if self.lease then
            self.lease:restore(); self.lease = nil
        end
        if self.steer and self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            VEHICLE.SET_VEHICLE_STEER_BIAS(
                self.identity, 0)
        end
        self.pending, self.steer, self.next_check = nil, nil, 0
    end

    function f:hit(state, level, now)
        local handle = state.vehicle_handle
        local health_loss = level == 'minor' and 10 or level == 'major' and 35 or 1000
        if level == 'major' and not GRAPHICS.ANIMPOSTFX_IS_RUNNING('ULP_PLAYERWAKEUP') then
            GRAPHICS.ANIMPOSTFX_PLAY(
                'ULP_PLAYERWAKEUP', 5000, false)
        end
        local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(state.vehicle:get_model())
        for seat = -1, seats - 2 do
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(handle, seat, false)
            if ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(ped) and (ped == state.handle or not PED.IS_PED_A_PLAYER(ped)) then
                ENTITY.SET_ENTITY_HEALTH(ped,
                    level == 'fatal' and 0 or math.max(0, ENTITY.GET_ENTITY_HEALTH(ped) - health_loss), 0, 0)
            end
        end
        if level == 'minor' then
            VEHICLE.SMASH_VEHICLE_WINDOW(handle, math.random(0, 3))
        else
            local door = math.random(0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) + 1)
            if VEHICLE.GET_IS_DOOR_VALID(handle, door) then VEHICLE.SET_VEHICLE_DOOR_BROKEN(handle, door, true) end
            if network.is_session_started() then
                local pos = state.ped:get_position()
                AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(level == 'major' and 'DEATH_HIGH_MEDIUM' or 'DYING_MOAN',
                    PED.IS_PED_MALE(state.handle) and 'WAVELOAD_PAIN_MALE' or 'WAVELOAD_PAIN_FEMALE',
                    pos.x, pos.y, pos.z, 'SPEECH_PARAMS_FORCE_SHOUTED')
            end
            if level == 'major' then
                VEHICLE.SET_VEHICLE_STEER_BIAS(handle, -0.6)
                self.steer = { until_time = now + 500, stage = 1 }
            end
        end
        self.next_check = now + (level == 'major' and 2200 or 1200)
    end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        if self.steer then
            if now >= self.steer.until_time then
                if self.steer.stage == 1 then
                    VEHICLE.SET_VEHICLE_STEER_BIAS(state.vehicle_handle, 0.6)
                    self.steer = { until_time = now + 500, stage = 2 }
                else
                    VEHICLE.SET_VEHICLE_STEER_BIAS(state.vehicle_handle, 0); self.steer = nil
                end
            end
            return
        end
        if self.pending then
            if now < self.pending.until_time then return end
            local speed = ENTITY.GET_ENTITY_SPEED(state.vehicle_handle)
            local level = speed <= self.pending.speed / 5 and 'fatal' or speed <= self.pending.speed * 0.8 and 'major' or
                'minor'
            self.pending = nil; self:hit(state, level, now); return
        end
        if now < self.next_check or not collided(state.vehicle_handle) then return end
        if not self.lease then self.lease = Memory.deformation_lease(state.vehicle_handle, 2.69420) end
        local speed = ENTITY.GET_ENTITY_SPEED(state.vehicle_handle)
        CAMERA.SHAKE_GAMEPLAY_CAM('GRENADE_EXPLOSION_SHAKE', speed / 25)
        if speed >= (ctx.settings:get('features.vehicle.fast_vehicles') and 45 or 35) then
            self.pending = { speed = speed, until_time = now + 150 }
        else
            self:hit(state, 'minor', now)
        end
    end

    return f
end
