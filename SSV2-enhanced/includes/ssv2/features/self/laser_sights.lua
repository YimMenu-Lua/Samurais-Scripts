local Feature = require('includes.ssv2.core.feature')
local exclusions = { [0x34A67B97] = true, [0xBA536372] = true, [0x184140A1] = true, [0x060EC506] = true }
local bones = { 'WAPLasr', 'WAPLasr_2', 'WAPFlshLasr', 'WAPFlshLasr_2', 'WAPFlsh', 'WAPFlsh_2', 'gun_barrels',
    'gun_muzzle' }
return function(ctx)
    local root = 'features.weapon.laser_sights'
    local f = Feature.new(ctx, {
        id = 'laser_sights',
        category = 'self',
        path = root .. '.enabled',
        controls = {
            { kind = 'toggle', path = root .. '.enabled',    label = 'SELF_LASER_SIGHTS',        tooltip = 'SELF_LASER_SIGHTS_TT' },
            { kind = 'color',  path = root .. '.color',      label = 'SELF_LASER_SIGHTS_COL' },
            { kind = 'int',    path = root .. '.ray_length', label = 'SELF_LASER_SIGHTS_LENGTH', min = 100,                       max = 1000 },
        }
    })
    ctx.input:bind('laser_sights', function()
        local state = ctx.state:read()
        if not state or not PLAYER.IS_PLAYER_FREE_AIMING(state.player_id) then return end
        ctx.settings:set(f.path, not ctx.settings:get(f.path))
        AUDIO.PLAY_SOUND_FRONTEND(-1, 'TARGET_COUNTER_TICK', 'DLC_SM_GENERIC_MISSION_SOUNDS', false)
    end)
    function f:ready(state)
        return state.alive and state.on_foot and WEAPON.IS_PED_ARMED(state.handle, 4)
            and PLAYER.IS_PLAYER_FREE_AIMING(state.player_id)
    end

    function f:update(state)
        if exclusions[ctx.game.current_weapon(state.handle)] then return end
        local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(state.handle, false)
        if weapon == 0 or not ENTITY.DOES_ENTITY_EXIST(weapon) then return end
        local bone = 0
        for _, name in ipairs(bones) do
            local index = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(weapon, name)
            if index ~= -1 then
                bone = index; break
            end
        end
        local src = ENTITY.GET_ENTITY_BONE_POSTION(weapon, bone)
        local rotation = CAMERA.GET_GAMEPLAY_CAM_ROT(0)
        local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
        local length = ctx.settings:get(root .. '.ray_length')
        local horizontal = math.abs(math.cos(pitch))
        local dest = Vector3.new(src.x - math.sin(yaw) * horizontal * length,
            src.y + math.cos(yaw) * horizontal * length, src.z + math.sin(pitch) * length)
        local hit, endpoint = ctx.game.raycast(src, dest, -1, state.handle)
        if not hit then endpoint = dest end
        local color = ctx.settings:get(root .. '.color')
        if color[4] < 0.499 then
            ctx.settings:set(root .. '.color', { color[1], color[2], color[3], 1 })
            color = ctx.settings:get(root .. '.color')
        end
        local r, g, b, a = math.floor(color[1] * 255), math.floor(color[2] * 255),
            math.floor(color[3] * 255), math.floor(color[4] * 255)
        for i = 0, 18 do
            local offset = i % 9 == 0 and i * 0.0001 or -i * 0.0001
            GRAPHICS.DRAW_LINE(src.x + offset, src.y, src.z, endpoint.x, endpoint.y, endpoint.z, r, g, b, a)
        end
        if hit then GRAPHICS.DRAW_LIGHT_WITH_RANGE(endpoint.x, endpoint.y, endpoint.z, r, g, b, 1, 0.5) end
    end

    return f
end
