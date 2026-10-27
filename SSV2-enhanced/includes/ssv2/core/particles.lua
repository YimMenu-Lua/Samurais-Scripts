local Assets = require('includes.ssv2.core.assets')
local Particles = {}
Particles.__index = Particles
function Particles.new() return setmetatable({ assets = Assets.new(), groups = {}, references = {} }, Particles) end

function Particles:start(entity, dict, name, bones, scale, position, rotation)
    assert(ENTITY.DOES_ENTITY_EXIST(entity), 'Particle owner no longer exists')
    if not self.assets:particle(dict) then return nil end
    if type(bones) ~= 'table' then bones = { bones } end
    local group = { dict = dict, handles = {} }
    self.groups[group] = true
    self.references[dict] = (self.references[dict] or 0) + 1
    local ok, err = pcall(function()
        for _, bone in ipairs(bones) do
            local right = type(bone) == 'string' and (bone:find('_rf', 1, true) or bone:find('_rr', 1, true))
            local index = type(bone) == 'string' and ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, bone) or bone
            if index ~= -1 then
                GRAPHICS.USE_PARTICLE_FX_ASSET(dict)
                local handle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(name, entity,
                    right and -position.x or position.x, position.y, position.z, rotation.x, rotation.y, rotation.z,
                    index, scale, false, false, false, 0, 0, 0, 255)
                assert(handle ~= 0, 'Particle effect creation failed: ' .. name)
                group.handles[#group.handles + 1] = handle
            end
        end
    end)
    if not ok then
        self:stop(group); error(err)
    end
    return group
end

function Particles:stop(group)
    if not group or not self.groups[group] then return end
    for _, handle in ipairs(group.handles) do
        GRAPHICS.STOP_PARTICLE_FX_LOOPED(handle, false)
        GRAPHICS.REMOVE_PARTICLE_FX(handle, false)
    end
    self.groups[group] = nil
    self.references[group.dict] = self.references[group.dict] - 1
    if self.references[group.dict] == 0 then
        STREAMING.REMOVE_NAMED_PTFX_ASSET(group.dict); self.references[group.dict] = nil
    end
end

function Particles:burst(entity, dict, name, bones, scale, position, rotation)
    assert(ENTITY.DOES_ENTITY_EXIST(entity), 'Particle owner no longer exists')
    if not self.assets:particle(dict) then return false end
    if type(bones) ~= 'table' then bones = { bones } end
    for _, bone in ipairs(bones) do
        local index = type(bone) == 'string' and ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, bone) or bone
        if index ~= -1 then
            GRAPHICS.USE_PARTICLE_FX_ASSET(dict)
            assert(GRAPHICS.START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(name, entity,
                    position.x, position.y, position.z, rotation.x, rotation.y, rotation.z, index, scale, false, false,
                    false),
                'Particle burst creation failed: ' .. name)
        end
    end
    return true
end

function Particles:stop_all()
    for group in pairs(self.groups) do self:stop(group) end
    self.assets:reset()
end

return Particles
