local Feature = require('includes.ssv2.core.feature')
local Assets = require('includes.ssv2.core.assets')
local Geometry = require('includes.ssv2.core.geometry')
local bones = require('includes.ssv2.data.plane_bones')
local flare_model, flare_weapon = 0x27AF51EC, 0x47757124
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'flares',
        category = 'vehicle',
        scope = 'vehicle',
        path = 'features.vehicle.flares',
        shots = {},
        assets = Assets.new(),
        controls = { { kind = 'toggle', path = 'features.vehicle.flares', label = 'VEH_FLARES', tooltip = 'VEH_FLARES_TT' } }
    })
    function f:ready(state) return state.alive and state.driving and state.aircraft end

    function f:deploy(state)
        if #self.shots > 0 then return end
        for _, name in ipairs(bones) do
            local index = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(state.vehicle_handle, name)
            if index ~= -1 then
                self.shots[#self.shots + 1] = { bone = index, offset = 0 }
                self.shots[#self.shots + 1] = { bone = index, offset = -10 }
            end
        end
        self.next_shot = ctx.clock:elapsed_ms() + 200
    end

    function f:cleanup()
        self.shots = {}; self.assets:reset()
        if self.requested_model then STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(flare_model) end
        self.requested_model = false
    end

    function f:update(state)
        if not ctx.input.blocked() and PAD.IS_CONTROL_JUST_PRESSED(0, 51) then self:deploy(state) end
        if #self.shots == 0 then return end
        if not network.is_session_started() then
            self.requested_model = true
            if not self.assets:model(flare_model) then return end
        end
        if not self.assets:weapon(flare_weapon) then return end
        local now, handle = ctx.clock:elapsed_ms(), state.vehicle_handle
        while #self.shots > 0 and now >= self.next_shot do
            local shot = table.remove(self.shots, 1)
            -- The original indexed the queue instead of the removed shot here.
            local position = ENTITY.GET_ENTITY_BONE_POSTION(handle, shot.bone)
            local origin = ENTITY.GET_ENTITY_COORDS(handle, false)
            local function basis(x, y, z)
                local value = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, x, y, z)
                return Geometry.normalize(Vector3.new(value.x - origin.x, value.y - origin.y, value.z - origin.z))
            end
            local backward, right, up = basis(0, -1, 0), basis(1, 0, 0), basis(0, 0, 1)
            local spread_right, spread_up = (math.random() - 0.5) * 2, (math.random() - 0.5) * 2
            local direction = Geometry.normalize(Vector3.new(backward.x + right.x * spread_right + up.x * spread_up,
                backward.y + right.y * spread_right + up.y * spread_up, backward.z + right.z * spread_right +
                up.z * spread_up))
            local distance = math.random(10, 50)
            local x, y, z = position.x + shot.offset, position.y + shot.offset, position.z + shot.offset
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(x, y, z, x + direction.x * distance, y + direction.y * distance,
                z + direction.z * distance,
                1, false, flare_weapon, state.handle, true, false, 100)
            AUDIO.PLAY_SOUND_FRONTEND(-1, 'HIT_OUT', 'PLAYER_SWITCH_CUSTOM_SOUNDSET', true)
            self.next_shot = self.next_shot + 200
        end
        if #self.shots == 0 and self.requested_model then
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(flare_model); self.requested_model = false
        end
    end

    return f
end
