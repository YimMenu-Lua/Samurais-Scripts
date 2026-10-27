local Pool = require('includes.ssv2.core.entity_pool')
local Wompus = {}; Wompus.__index = Wompus
local emitter = 'SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_01_LEFT'
function Wompus.new(ctx, actions)
    local self = setmetatable({ ctx = ctx, actions = actions, pool = Pool.new(ctx) }, Wompus)
    return self
end

function Wompus:clear()
    self.serial = (self.serial or 0) + 1
    if self.camera then
        CAMERA.RENDER_SCRIPT_CAMS(false, true, 500, true, false, 0); CAMERA.DESTROY_CAM(self.camera, false); self.camera = nil
    end
    if self.weather then
        MISC.CLEAR_OVERRIDE_WEATHER(); self.weather = false
    end
    if self.effect then
        GRAPHICS.ANIMPOSTFX_STOP('PPGREEN'); self.effect = false
    end
    if self.emitting then
        AUDIO.SET_EMITTER_RADIO_STATION(emitter, 'RADIO_30_DLC_HEI4_MIX1_REVERB'); AUDIO.SET_STATIC_EMITTER_ENABLED(
            emitter, false); self.emitting = false
    end
    if self.relationships then
        local r = self.relationships
        PED.SET_RELATIONSHIP_BETWEEN_GROUPS(r[3], r[1], r[2]); PED.SET_RELATIONSHIP_BETWEEN_GROUPS(r[4], r[2], r[1]); self.relationships = nil
    end
    self.running = false; self.screen = nil; self.actor = nil; self.pool:clear()
end

function Wompus:start()
    if self.running then return end
    assert(not NETWORK.NETWORK_IS_ACTIVITY_SESSION() and self.ctx.game.outside(PLAYER.PLAYER_PED_ID()),
        'Summon Wompus outdoors in freemode')
    self.running = true
    self.serial = (self.serial or 0) + 1; local serial = self.serial
    self.actions:run('wompus_sequence', function(valid)
        local ok, err = pcall(function()
            local player = PLAYER.PLAYER_PED_ID()
            local function current()
                return self.running and self.serial == serial and valid() and
                    (not self.actor or self.pool:exists(self.actor))
            end
            local function wait(delay)
                script.yield(delay); return current()
            end
            local position = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player, 0, 10, 20)
            local actor = self.pool:create('ped', require('includes.ssv2.data.peds').a_c_boar_02.model_hash, position,
                ENTITY.GET_ENTITY_HEADING(player) - 180, current)
            if not actor or not current() then return end
            self.actor = actor
            local handle = self.actor.handle
            ENTITY.FREEZE_ENTITY_POSITION(handle, true); ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
            PED.SET_PED_KEEP_TASK(handle, false); TASK.CLEAR_PED_TASKS_IMMEDIATELY(handle); TASK.TASK_STAND_STILL(handle,
                -1)
            local machete, rpg = util.joaat('WEAPON_MACHETE'), util.joaat('WEAPON_RPG')
            WEAPON.GIVE_WEAPON_TO_PED(handle, machete, 1, false, true)
            PED.SET_PED_CONFIG_FLAG(handle, 118, false); PED.SET_PED_CONFIG_FLAG(handle, 294, true); PED
                .SET_PED_COMBAT_ATTRIBUTES(handle, 63, false)
            for _, flag in ipairs({ 1, 2, 3, 4, 5, 13, 20, 21, 22, 27, 28, 31, 34, 38, 41, 42, 46, 50, 54, 55, 58, 61, 68, 71 }) do
                PED.SET_PED_COMBAT_ATTRIBUTES(handle, flag, true)
            end
            self.camera = CAMERA.CREATE_CAM('DEFAULT_SCRIPTED_CAMERA', true)
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player, 0, 1, 1); local rot = ENTITY
                .GET_ENTITY_ROTATION(player, 2)
            CAMERA.SET_CAM_PARAMS(self.camera, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 80, 0, 1, 1, 2)
            AUDIO.SET_STATIC_EMITTER_ENABLED(emitter, true); AUDIO.SET_EMITTER_RADIO_STATION(emitter,
                'HIDDEN_RADIO_04_PUNK')
            AUDIO.LINK_STATIC_EMITTER_TO_ENTITY(emitter, handle); self.emitting = true
            CAMERA.POINT_CAM_AT_ENTITY(self.camera, handle, 0, 0, 0, true); self.ctx.view:play_sound('Focus_out')
            CAMERA.RENDER_SCRIPT_CAMS(true, true, 500, true, false, 0)
            MISC.SET_OVERRIDE_WEATHER('THUNDER'); self.weather = true
            GRAPHICS.ANIMPOSTFX_PLAY('PPGREEN', 25000, false); self.effect = true
            if not self.pool:wait('weapon', rpg, current) then return end
            if not wait(2500) then return end
            local high = ENTITY.GET_ENTITY_COORDS(handle, false)
            AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE('GENERIC_INSULT_HIGH', 'S_M_Y_BLACKOPS_01_BLACK_MINI_01',
                high.x, high.y, high.z, 'SPEECH_PARAMS_FORCE_HELI')
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(high.x, high.y, high.z, high.x, high.y, high.z - 0.1, 0, false, rpg,
                player, true, false, -1)
            if not wait(2500) then return end
            local deadline = util.time() + 5000
            while current() and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) > 1 and util.time() < deadline do
                local pos = ENTITY.GET_ENTITY_COORDS(handle, false); local delta = math.min(1, MISC.GET_FRAME_TIME() * 10)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(handle, pos.x, pos.y, pos.z - delta, false, false, false)
                if not wait(0) then return end
            end
            CAMERA.SHAKE_CAM(self.camera, 'LARGE_EXPLOSION_SHAKE', 0.5)
            while current() and not self.ctx.particles:burst(handle, 'scr_xs_dr', 'scr_xs_dr_emp', { 0 }, 1, { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }) do if not wait(0) then return end end
            if not wait(2000) then return end
            local pos = ENTITY.GET_ENTITY_COORDS(handle, false)
            AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE('GENERIC_WAR_CRY', 'S_M_Y_BLACKOPS_01_BLACK_MINI_01', pos.x,
                pos.y, pos.z, 'SPEECH_PARAMS_FORCE_HELI')
            self.ctx.notifier:info('MINIMUS WOMPUS MERIDIUS',
                '« And thus began the chronicles of Minimus Wompus Meridius:\nProtector of funk, destroyer of HUDs, sniffer of drift tires. »',
                10)
            local animal, owner = PED.GET_PED_RELATIONSHIP_GROUP_HASH(handle),
                PED.GET_PED_RELATIONSHIP_GROUP_HASH(player)
            self.relationships = { animal, owner, PED.GET_RELATIONSHIP_BETWEEN_GROUPS(animal, owner), PED
                .GET_RELATIONSHIP_BETWEEN_GROUPS(owner, animal) }
            PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, animal, owner); PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, owner, animal)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true); TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(
                handle, true)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(handle); PED.SET_PED_KEEP_TASK(handle, true); TASK.TASK_COMBAT_PED(handle,
                player, 0, 16)
            ENTITY.FREEZE_ENTITY_POSITION(handle, false)
            CAMERA.RENDER_SCRIPT_CAMS(false, true, 500, true, false, 0); CAMERA.DESTROY_CAM(self.camera, false); self.camera = nil
            deadline = util.time() + 10000
            while current() and not ENTITY.IS_ENTITY_DEAD(player, false) and util.time() < deadline do
                local pos = ENTITY.GET_ENTITY_COORDS(handle, false); local output = memory.allocate(8)
                assert(output and output:get_address() ~= 0, 'Cannot allocate Wompus screen coordinates')
                local ok, x, y = pcall(function()
                    GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z, output, output:add(4))
                    return output:get_float(), output:add(4):get_float()
                end)
                memory.free(output); if not ok then error(x) end
                self.screen = x and { x = x, y = y } or nil
                if self.screen then
                    self.ctx.game.text(x - 0.025, y - 0.09, 'MINIMUS  WOMPUS  MERIDIUS', 255, 255, 255,
                        220, 0.1, 0.3, 4)
                end
                if not wait(0) then return end
            end
            if current() then
                local pos = ENTITY.GET_ENTITY_COORDS(handle, false); ENTITY.SET_ENTITY_INVINCIBLE(handle, false)
                if not wait(10) then return end
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 0.1, pos.x, pos.y, pos.z, 999, false, rpg,
                    player, true, false, -1)
                self.pool:release(handle); self.actor = nil
                self.actions.props.emitters:clear()
                self.ctx.notifier:info('MINIMUS WOMPUS MERIDIUS',
                    'The prophecy has been fulfilled! Wompus shall rise. Wompus shall rave. Wompus shall rupture.', 10)
            end
        end)
        if self.serial == serial then self:clear() end
        if not ok then error(err) end
    end)
end

return Wompus
