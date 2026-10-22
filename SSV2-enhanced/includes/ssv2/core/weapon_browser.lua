-- Original weapon categories and selection behavior. GPL-3.0-or-later.
local Browser = {}; Browser.__index = Browser
local categories = { 'None', 'Melee', 'Pistols', 'SMGs', 'Shotguns', 'Assault Rifles', 'Machine Guns', 'Sniper Rifles',
    'Heavy Weapons', 'Throwables', 'Miscellaneous' }
local group_index = {
    GROUP_MELEE = 2,
    GROUP_PISTOL = 3,
    GROUP_SMG = 4,
    GROUP_SHOTGUN = 5,
    GROUP_RIFLE = 6,
    GROUP_MG = 7,
    GROUP_SNIPER = 8,
    GROUP_HEAVY = 9,
    GROUP_THROWN = 10,
    GROUP_PETROLCAN = 11,
    GROUP_STUNGUN = 11,
    GROUP_TRANQILIZER = 11
}
function Browser.supports(metadata) return group_index[metadata.group] ~= nil end

function Browser.new(ctx)
    return setmetatable({ ctx = ctx, category = 1, selected = 0, groups = {}, names = {} }, Browser)
end

function Browser:load()
    if self.loaded then return end
    for index = 2, #categories do self.groups[index] = {} end
    for hash, metadata in pairs(require('includes.ssv2.data.weapon_data')) do
        local index = group_index[metadata.group]
        if index and WEAPON.IS_WEAPON_VALID(hash) then
            self.groups[index][#self.groups[index] + 1] = hash
            local name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(metadata.gxt)
            self.names[hash] = name and name ~= '' and name or 'NULL'
        end
    end
    self.loaded = true
end

function Browser:draw()
    local width = (ImGui.GetContentRegionAvail() - ImGui.GetStyle().ItemSpacing.x) * 0.5
    ImGui.SetNextItemWidth(width)
    if ImGui.BeginCombo('##weaponCategories', categories[self.category]) then
        for index, name in ipairs(categories) do
            ImGui.Selectable(name, self.category == index)
            if ImGui.IsItemClicked(0) then
                self.category = index
                if self.groups[index] and self.groups[index][1] then self.selected = self.groups[index][1] end
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndCombo()
    end
    local list = self.groups[self.category]
    if list and #list > 0 then
        ImGui.SameLine(); ImGui.SetNextItemWidth(width)
        if ImGui.BeginCombo('##weaponlist', self.names[self.selected] or '') then
            for _, hash in ipairs(list) do
                ImGui.Selectable(self.names[hash], self.selected == hash)
                if ImGui.IsItemClicked(0) then
                    self.selected = hash; ImGui.SetItemDefaultFocus()
                end
            end
            ImGui.EndCombo()
        end
    end
    return self.selected
end

return Browser
