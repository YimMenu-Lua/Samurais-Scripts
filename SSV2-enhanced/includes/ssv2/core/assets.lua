-- Poll in a feature's game coroutine. The next update revalidates its owner.
local Assets = {}
Assets.__index = Assets
function Assets.new() return setmetatable({ pending = {} }, Assets) end

function Assets:poll(kind, name, loaded, request)
    local key = kind .. ':' .. tostring(name)
    if loaded(name) then
        self.pending[key] = nil; return true
    end
    local now = util.time()
    self.pending[key] = self.pending[key] or now
    if now - self.pending[key] > 1200 then error('Asset timeout: ' .. key) end
    request(name)
    if loaded(name) then
        self.pending[key] = nil; return true
    end
    return false
end

function Assets:model(hash)
    assert(STREAMING.IS_MODEL_VALID(hash) and STREAMING.IS_MODEL_IN_CDIMAGE(hash), 'Invalid model')
    return self:poll('model', hash, STREAMING.HAS_MODEL_LOADED, STREAMING.REQUEST_MODEL)
end

function Assets:animation(dict)
    return self:poll('animation', dict, STREAMING.HAS_ANIM_DICT_LOADED, STREAMING.REQUEST_ANIM_DICT)
end

function Assets:clipset(name)
    return self:poll('clipset', name, STREAMING.HAS_CLIP_SET_LOADED, STREAMING.REQUEST_CLIP_SET)
end

function Assets:weapon(hash)
    return self:poll('weapon', hash, WEAPON.HAS_WEAPON_ASSET_LOADED,
        function(value) WEAPON.REQUEST_WEAPON_ASSET(value, 31, 0) end)
end

function Assets:particle(dict)
    return self:poll('particle', dict, STREAMING.HAS_NAMED_PTFX_ASSET_LOADED, STREAMING.REQUEST_NAMED_PTFX_ASSET)
end

function Assets:reset() self.pending = {} end

return Assets
