-- Source definitions are maintained for this Enhanced build (includes/init.lua).
local Build = {}; Build.__index = Build
function Build.new()
    local self = setmetatable({ expected_online = '1.73', expected_build = '1158.16', next_check = 0 }, Build)
    self:update(); return self
end

function Build:update()
    if util.time() < self.next_check then return end
    self.online, self.build = util.get_game_version()
    self.compatible = self.online == self.expected_online and self.build == self.expected_build
    self.next_check = util.time() + 1000
end

function Build:require_supported()
    self:update()
    assert(self.compatible,
        'These game fields require Enhanced ' .. self.expected_build .. ' / online ' .. self.expected_online
        .. '; running ' .. tostring(self.build) .. ' / ' .. tostring(self.online))
end

return Build
