local Group = {}; Group.__index = Group
function Group.new(ctx) return setmetatable({ ctx = ctx }, Group) end

function Group:add(handle)
    local hash = util.joaat('WOMPUS_SPECIAL')
    if not self.hash then
        if PED.DOES_RELATIONSHIP_GROUP_EXIST(hash) then
            self.hash = hash
        else
            local output = memory.allocate(4)
            assert(output and output:get_address() ~= 0, 'Cannot allocate relationship group output')
            local ok, result = pcall(function()
                PED.ADD_RELATIONSHIP_GROUP('WOMPUS_SPECIAL', output); return output:get_int()
            end)
            memory.free(output); if not ok then error(result) end
            self.hash = result
        end
    end
    local player = PED.GET_PED_RELATIONSHIP_GROUP_HASH(PLAYER.PLAYER_PED_ID())
    PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.hash, player)
    PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, player, self.hash)
    PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.hash, self.hash)
    PED.SET_PED_RELATIONSHIP_GROUP_HASH(handle, self.hash)
    ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(handle, false, self.hash)
end

return Group
