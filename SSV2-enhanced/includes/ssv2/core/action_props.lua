local Pool = require('includes.ssv2.core.entity_pool')
local Emitters = require('includes.ssv2.core.emitters')
local Props = {}; Props.__index = Props
local zero = { x = 0, y = 0, z = 0 }
function Props.new(ctx)
    return setmetatable({ ctx = ctx, pool = Pool.new(ctx), owners = {}, emitters = Emitters.new() }, Props)
end

function Props:owner(ped)
    self.owners[ped] = self.owners[ped] or { entities = {}, effects = {} }
    return self.owners[ped]
end

function Props:effect(entity, definition, valid, owner)
    if not definition or not definition.dict or not definition.name then return end
    if not self.pool:wait('particle', definition.dict, valid) then return end
    if definition.delay then
        script.yield(definition.delay); if not valid() then return end
    end
    local pos, rot = definition.pos or zero, definition.rot or zero
    GRAPHICS.USE_PARTICLE_FX_ASSET(definition.dict)
    local handle
    if ENTITY.IS_ENTITY_A_PED(entity) then
        handle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(definition.name, entity,
            pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, definition.bone or 0, definition.scale or 1, false, false, false, 0,
            0, 0, 255)
    else
        handle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(definition.name, entity,
            pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, definition.scale or 1, false, false, false, 0, 0, 0, 255)
    end
    assert(handle ~= 0, 'Action particle effect creation failed')
    local list = self:owner(owner or entity).effects
    list[#list + 1] = { handle = handle, dict = definition.dict, entity = entity }
end

function Props:spawn(owner, definition, is_ped, valid, position, dynamic)
    local model = definition.model
    local entry = self.pool:create(is_ped and 'ped' or 'object', model, position or Vector3.new(0, 0, 0), 0, valid,
        dynamic, network.is_session_started())
    if not entry then return end
    local handle = entry.handle
    self:owner(owner).entities[#self:owner(owner).entities + 1] = entry
    if is_ped then
        PED.SET_PED_CONFIG_FLAG(handle, 179, true); PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true)
        PED.SET_PED_KEEP_TASK(handle, false); TASK.TASK_STAND_STILL(handle, -1)
    end
    if entry.model % 4294967296 == 2767137151 or entry.model % 4294967296 == 976772591 then
        self.emitters:party(owner,
            true)
    end
    return entry
end

function Props:attach(ped, list, is_ped, valid)
    for _, definition in ipairs(list or {}) do
        if not valid() then return end
        local entry = self:spawn(ped, definition, is_ped, valid)
        if not entry then return end
        local handle = entry.handle
        if definition.parentBone ~= -1 then
            local bone = PED.GET_PED_BONE_INDEX(ped, definition.parentBone or 0)
            local pos, rot = definition.pos or zero, definition.rot or zero
            ENTITY.ATTACH_ENTITY_TO_ENTITY(handle, ped, bone, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, false, false,
                false, false, 2, true, 1)
        else
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 0.7, 0)
            local found, ground = self.ctx.game.ground_z(pos)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(handle, pos.x, pos.y, found and ground or pos.z, false, false, false)
            ENTITY.SET_ENTITY_HEADING(handle, ENTITY.GET_ENTITY_HEADING(ped))
            PHYSICS.ACTIVATE_PHYSICS(handle); OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(handle)
            ENTITY.SET_CAN_CLIMB_ON_ENTITY(handle, false)
        end
        if is_ped and definition.dict then
            if not self.pool:wait('animation', definition.dict, valid) then return end
            TASK.TASK_PLAY_ANIM(handle, definition.dict, definition.name, 4, -4, -1, 1, 1, false, false, false)
        end
        if definition.ptfx and not self.ctx.settings:get('features.yim_actions.disable_ptfx') then
            self:effect(handle,
                definition.ptfx, valid, ped)
        end
    end
end

function Props:speech(ped, definition, now)
    local owner = self.owners[ped]
    if not owner or not definition or not definition.speechName or now < (owner.next_speech or 0) then return end
    for _, entry in ipairs(owner.entities) do
        if entry.kind == 'ped' and self.pool:exists(entry) and not AUDIO.IS_AMBIENT_SPEECH_PLAYING(entry.handle) then
            AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(entry.handle, definition.speechName, definition.voiceName,
                definition.speechParam or 'SPEECH_PARAMS_FORCE', false)
            break
        end
    end
    owner.next_speech = now + 2500
end

function Props:torch(ped)
    local owner = self.owners[ped]; local entry = owner and owner.entities[1]
    if not entry or entry.model ~= 211760048 or not self.pool:exists(entry) then return end
    local pos, fwd = entry.entity:get_position(), ENTITY.GET_ENTITY_FORWARD_VECTOR(entry.handle)
    GRAPHICS.DRAW_SPOT_LIGHT(pos.x, pos.y, pos.z - 0.2, -fwd.x, -fwd.y, -fwd.z, 226, 130, 78, 50, 8, 1, 10, 1)
end

function Props:clear_effects(ped)
    local owner = self.owners[ped]
    if not owner then return end
    for _, fx in ipairs(owner.effects) do
        GRAPHICS.STOP_PARTICLE_FX_LOOPED(fx.handle, false); GRAPHICS.REMOVE_PARTICLE_FX(fx.handle, false)
    end
    owner.effects = {}
end

function Props:clear_props(ped)
    local owner = self.owners[ped]
    if not owner then return end
    for _, entry in ipairs(owner.entities) do self.pool:delete(entry.handle) end
    owner.entities = {}; self.emitters:party(ped, false)
end

function Props:clear(ped)
    self:clear_effects(ped); self:clear_props(ped); self.owners[ped] = nil
end

function Props:clear_all()
    for ped in pairs(self.owners) do self:clear(ped) end
    self.pool:clear(); self.emitters:clear()
end

return Props
