local Blips = {}; Blips.__index = Blips
function Blips.new() return setmetatable({ owned = {} }, Blips) end

function Blips:add(entity, name, sprite, scale, heading)
    local handle = HUD.ADD_BLIP_FOR_ENTITY(entity)
    assert(handle ~= 0, 'Blip creation failed')
    HUD.SET_BLIP_SCALE(handle, scale or 1); HUD.SET_BLIP_AS_FRIENDLY(handle, true); HUD.SHOW_HEADING_INDICATOR_ON_BLIP(
        handle, heading ~= false)
    if sprite then HUD.SET_BLIP_SPRITE(handle, sprite) end
    HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME('STRING'); HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name); HUD
        .END_TEXT_COMMAND_SET_BLIP_NAME(handle)
    self.owned[handle] = { entity = entity, alpha = 255 }; return handle
end

function Blips:visible(handle, visible)
    local entry = self.owned[handle]; if not entry then return end
    local alpha = visible and 255 or 0
    if alpha ~= entry.alpha then
        HUD.SET_BLIP_ALPHA(handle, alpha); entry.alpha = alpha
    end
end

function Blips:remove(handle)
    if not self.owned[handle] then return end
    local output = memory.allocate(4)
    assert(output and output:get_address() ~= 0, 'Cannot allocate blip output')
    local ok, err = pcall(function()
        output:set_int(handle); HUD.REMOVE_BLIP(output)
    end)
    memory.free(output); self.owned[handle] = nil
    if not ok then error(err) end
end

function Blips:clear() for handle in pairs(self.owned) do self:remove(handle) end end

return Blips
