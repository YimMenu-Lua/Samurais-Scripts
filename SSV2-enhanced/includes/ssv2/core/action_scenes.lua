local Pool = require('includes.ssv2.core.entity_pool')
local Scenes = {}; Scenes.__index = Scenes
function Scenes.new(ctx) return setmetatable({ ctx = ctx, pool = Pool.new(ctx) }, Scenes) end

function Scenes:play(definition, valid)
    self:clear()
    local ped = PLAYER.PLAYER_PED_ID()
    local off = definition.origin.pos_offset or { x = 0, y = 0, z = 0 }
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, off.x, off.y, off.z)
    local heading = ENTITY.GET_ENTITY_HEADING(ped)
    local function create(model)
        local hash = type(model) == 'string' and util.joaat(model) or model
        if STREAMING.IS_MODEL_A_PED(hash) and hash % 4294967296 == ENTITY.GET_ENTITY_MODEL(ped) % 4294967296 then
            return
                ped
        end
        local kind = STREAMING.IS_MODEL_A_PED(hash) and 'ped' or STREAMING.IS_MODEL_A_VEHICLE(hash) and 'vehicle' or
            'object'
        local entry = self.pool:create(kind, hash, Vector3.new(pos.x, pos.y, pos.z - 50), heading, valid, true,
            kind == 'object')
        return entry and entry.handle
    end
    local origin = definition.origin.isPlayer and ped or create(definition.origin.model)
    if not origin or not valid() then
        self:clear(); return false
    end
    if ENTITY.IS_ENTITY_A_PED(origin) then
        local found, height = self.ctx.game.ground_z(pos)
        if found then pos.z = height end
    end
    if origin ~= ped then ENTITY.SET_ENTITY_COORDS_NO_OFFSET(origin, pos.x, pos.y, pos.z, false, false, false) end
    local participants = {}
    for _, item in ipairs(definition.participants) do
        local handle = item.isPlayer and ped or create(item.model)
        if not handle or not valid() then
            self:clear(); return false
        end
        participants[#participants + 1] = { handle = handle, name = item.animName }
    end
    if not self.pool:wait('animation', definition.animDict, valid) then
        self:clear(); return false
    end
    local rot = ENTITY.GET_ENTITY_ROTATION(origin, 2)
    local params = definition.params or {}; local net = network.is_session_started()
    local scene
    if net then
        scene = NETWORK.NETWORK_CREATE_SYNCHRONISED_SCENE(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2,
            params.holdLastFrame or false, params.looped or false, 1, params.startPhase or 0, params.animSpeed or 1)
    else
        scene = PED.CREATE_SYNCHRONIZED_SCENE(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2)
        PED.SET_SYNCHRONIZED_SCENE_HOLD_LAST_FRAME(scene, params.holdLastFrame or false)
        PED.SET_SYNCHRONIZED_SCENE_LOOPED(scene, params.looped or false)
    end
    self.current = {
        handle = scene,
        networked = net,
        dict = definition.animDict,
        participants = participants,
        local_handle =
            scene
    }
    for _, item in ipairs(participants) do
        if not valid() then
            self:clear(); return false
        end
        if ENTITY.IS_ENTITY_A_PED(item.handle) then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(item.handle)
            if item.handle ~= ped then
                if net then
                    self.ctx.game.control(item.handle, 300, valid)
                    if not valid() then
                        self:clear(); return false
                    end
                end
                local offset = net and 1 or 0
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(item.handle, pos.x + offset, pos.y + offset, pos.z + offset, false,
                    false, false)
            end
            if net then
                NETWORK.NETWORK_ADD_PED_TO_SYNCHRONISED_SCENE(item.handle, scene, definition.animDict, item.name, 4, -4,
                    -1, 1, 8, 0)
            else
                TASK.TASK_SYNCHRONIZED_SCENE(item.handle, scene, definition.animDict, item.name, 4, -4, 0, 0, 0x447A0000,
                    0)
            end
        elseif net then
            NETWORK.NETWORK_ADD_ENTITY_TO_SYNCHRONISED_SCENE(item.handle, scene, definition.animDict, item.name, 4, -4, 0)
        else
            self.pool:delete(item.handle)
            self.ctx.notifier:warn("Samurai's Scripts",
                'Some props from this scene have been removed because they are online-only.', 5)
        end
        if net then script.yield(0) end
    end
    if net then
        NETWORK.NETWORK_START_SYNCHRONISED_SCENE(scene)
        script.yield(10)
        if not valid() then
            self:clear(); return false
        end
        self.current.local_handle = NETWORK.NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID(scene)
    end
    assert(self:running(), 'Synchronized scene did not start')
    return true
end

function Scenes:running()
    return self.current and PED.IS_SYNCHRONIZED_SCENE_RUNNING(self.current.local_handle) or false
end

function Scenes:clear()
    local scene = self.current
    if scene then
        if scene.networked then NETWORK.NETWORK_STOP_SYNCHRONISED_SCENE(scene.handle) end
        for _, item in ipairs(scene.participants) do
            if ENTITY.DOES_ENTITY_EXIST(item.handle) and ENTITY.IS_ENTITY_A_PED(item.handle) then
                TASK.CLEAR_PED_TASKS(
                    item.handle)
            end
        end
        STREAMING.REMOVE_ANIM_DICT(scene.dict)
    end
    self.current = nil; self.pool:clear()
end

return Scenes
