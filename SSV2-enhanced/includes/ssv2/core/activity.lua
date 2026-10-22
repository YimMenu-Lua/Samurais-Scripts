-- Animation/services register their actual activity here for shared input guards.
local Activity = {}
Activity.__index = Activity
function Activity.new() return setmetatable({ owners = {} }, Activity) end

function Activity:acquire(owner, state) self.owners[owner] = state end

function Activity:release(owner) self.owners[owner] = nil end

function Activity:has(state)
    for _, value in pairs(self.owners) do if value == state then return true end end
    return false
end

function Activity:busy() return next(self.owners) ~= nil end

return Activity
