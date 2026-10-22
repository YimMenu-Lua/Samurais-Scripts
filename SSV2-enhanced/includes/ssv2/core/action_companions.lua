local Pool = require('includes.ssv2.core.entity_pool')
local Group = require('includes.ssv2.core.group')
local Companions = {}; Companions.__index = Companions
local combat = { 1, 2, 3, 4, 5, 13, 20, 21, 22, 27, 28, 31, 34, 38, 41, 42, 46, 50, 54, 55, 58, 61, 68, 71 }
local config = { 118, 141, 179, 188, 193, 208, 261, 268, 286, 294, 301, 364, 398, 401, 443 }
function Companions.new(ctx, actions)
    return setmetatable({ ctx = ctx, actions = actions, pool = Pool.new(ctx), group = Group.new(ctx), members = {} },
        Companions)
end

function Companions:spawn(model, name, godmode, armed, valid)
    local ped = PLAYER.PLAYER_PED_ID()
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, math.random(-5, 5), math.random(2, 5), 0)
    local entry = self.pool:create('ped', model, pos, ENTITY.GET_ENTITY_HEADING(ped) - 180, valid, nil,
        network.is_session_started())
    if not entry then return end
    entry.name = name ~= '' and name or tostring(model); entry.godmode, entry.armed = godmode or false, armed or false
    local handle = entry.handle
    self.group:add(handle)
    local group = PED.GET_PED_GROUP_INDEX(ped)
    PED.SET_PED_AS_GROUP_MEMBER(handle, group); PED.SET_PED_NEVER_LEAVES_GROUP(handle, true)
    PED.SET_PED_CAN_TELEPORT_TO_GROUP_LEADER(handle, group, true); PED.SET_PED_CONFIG_FLAG(handle, 167, false)
    PED.SET_PED_FLEE_ATTRIBUTES(handle, 32768, false); ENTITY.SET_ENTITY_INVINCIBLE(handle, entry.godmode, false)
    for _, flag in ipairs(config) do PED.SET_PED_CONFIG_FLAG(handle, flag, true) end
    for i = 0, 17 do PED.SET_RAGDOLL_BLOCKING_FLAGS(handle, i) end
    if entry.armed then
        WEAPON.GIVE_WEAPON_TO_PED(handle, 350597077, 9999, false, true)
        PED.SET_PED_FIRING_PATTERN(handle, 0xC6EE6B4C); PED.SET_PED_COMBAT_ABILITY(handle, 2)
        PED.SET_PED_CAN_BE_TARGETTED(handle, false)
        for _, attribute in ipairs(combat) do PED.SET_PED_COMBAT_ATTRIBUTES(handle, attribute, true) end
    end
    entry.blip = HUD.ADD_BLIP_FOR_ENTITY(handle)
    HUD.SET_BLIP_SCALE(entry.blip, 0.8); HUD.SET_BLIP_AS_FRIENDLY(entry.blip, true)
    HUD.SHOW_HEADING_INDICATOR_ON_BLIP(entry.blip, true)
    HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME('STRING'); HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME('YimActions Companion')
    HUD.END_TEXT_COMMAND_SET_BLIP_NAME(entry.blip)
    self.members[#self.members + 1] = entry
    return entry
end

function Companions:remove(entry)
    self.actions:stop(entry.handle)
    if self.pool:exists(entry) then PED.REMOVE_PED_FROM_GROUP(entry.handle) end
    if entry.blip then
        local output = memory.allocate(4)
        assert(output and output:get_address() ~= 0, 'Cannot allocate blip handle')
        local ok, err = pcall(function()
            output:set_int(entry.blip); HUD.REMOVE_BLIP(output)
        end)
        memory.free(output); if not ok then error(err) end
    end
    self.pool:delete(entry.handle)
    for i = #self.members, 1, -1 do if self.members[i] == entry then table.remove(self.members, i) end end
end

function Companions:update()
    for i = #self.members, 1, -1 do
        local entry = self.members[i]
        if not self.pool:exists(entry) or ENTITY.IS_ENTITY_DEAD(entry.handle, false) then
            self:remove(entry)
        else
            local alpha = PED.IS_PED_IN_ANY_VEHICLE(entry.handle, true) and 0 or 255
            if alpha ~= entry.alpha then
                HUD.SET_BLIP_ALPHA(entry.blip, alpha); entry.alpha = alpha
            end
        end
    end
end

function Companions:bring(valid)
    local state = self.ctx.state:read(); if not state then return end
    for i, entry in ipairs(self.members) do
        if valid and not valid() then return end
        self.actions:stop(entry.handle)
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, i, (state.on_foot and 1 or 6.9) + i - 1,
            0)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entry.handle, pos.x, pos.y, pos.z, false, false, false)
        script.yield(200)
    end
end

function Companions:clear()
    for i = #self.members, 1, -1 do self:remove(self.members[i]) end
    self.pool:clear()
end

return Companions
