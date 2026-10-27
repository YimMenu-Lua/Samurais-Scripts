-- SSV2 asset-browser behavior expressed with V2 widgets. GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local Browser = {}; Browser.__index = Browser
local kinds = { 'object', 'ped', 'vehicle' }
local datasets = {}
local next_id = 0
local function enum_names(module, last, titlecase)
    local names = { 'None' }
    for name, index in pairs(require(module)) do
        if index <= last then
            names[index + 2] = titlecase and
                name:lower():gsub('_', ' '):gsub('(%a)([%w]*)', function(a, b) return a:upper() .. b end) or name
        end
    end
    return names
end
local ped_types = enum_names('includes.ssv2.data.ped_type', 29, false)
local classes = enum_names('includes.ssv2.data.vehicle_classes', 22, true)
local manufacturers = { 'None' }
for _, name in ipairs(require('includes.ssv2.data.vehicle_manufacturers')) do manufacturers[#manufacturers + 1] = name end
function Browser.new(ctx, opts)
    opts = opts or {}
    next_id = next_id + 1
    return setmetatable({
        ctx = ctx,
        uid = next_id,
        kind = opts.fixed_kind or 1,
        fixed_kind = opts.fixed_kind,
        query = '',
        gender = 0,
        ped_type = -1,
        vehicle_class = -1,
        manufacturer = '',
        manufacturer_index = 0,
        preview_enabled = false,
        humans_only = opts.humans_only or false,
        max_entries = opts.max_entries,
        states = {},
        gender_filter = opts.gender_filter ~= false,
        type_filter = opts.type_filter ~= false
    }, Browser)
end

function Browser:select_kind(kind)
    assert(kinds[kind + 1], 'Unknown model browser kind')
    if kind == self.kind then return end
    local fields = { 'query', 'gender', 'ped_type', 'vehicle_class', 'manufacturer', 'manufacturer_index',
        'preview_enabled', 'selected' }
    local old = {}
    for _, key in ipairs(fields) do old[key] = self[key] end
    self.states[self.kind] = old
    local saved = self.states[kind] or
        { query = '', gender = 0, ped_type = -1, vehicle_class = -1, manufacturer = '', manufacturer_index = 0, preview_enabled = false }
    for _, key in ipairs(fields) do self[key] = saved[key] end
    self.kind = kind
    if self.preview_hovered then
        local preview = self.ctx.preview; local serial = preview.serial
        self.ctx.runtime:run('switch asset browser preview',
            function() if preview.serial == serial then preview:clear() end end)
    end
    self.preview_hovered = false
end

function Browser:models(kind)
    if datasets[kind] then return datasets[kind] end
    local list = {}
    if kind == 'object' then
        for _, name in ipairs(require('includes.ssv2.data.objects')) do
            list[#list + 1] = {
                name = name,
                label = name,
                kind =
                    kind
            }
        end
    else
        for name, metadata in pairs(require('includes.ssv2.data.' .. (kind == 'ped' and 'peds' or 'vehicles'))) do
            list[#list + 1] = {
                name = name,
                label = kind == 'ped' and name or metadata.display_name,
                model = metadata
                    .model_hash,
                kind = kind,
                metadata = metadata
            }
        end
    end
    -- RawDataService normalizes dictionary order by model name, not displayed vehicle name.
    table.sort(list, function(a, b) return a.name < b.name end)
    for index, item in ipairs(list) do
        -- AssetBrowserBase falls back to the iterable index when its name getter returns nil.
        if not item.label then item.label = tostring(index) end
    end
    datasets[kind] = list; return list
end

function Browser:filtered(kind)
    local query = self.query:lower(); local list = {}
    for _, item in ipairs(self:models(kind)) do
        local meta = item.metadata or {}
        if item.label:lower():find(query, 1, true)
            and (kind ~= 'ped' or (not self.humans_only or meta.is_human)
                and (self.gender == 0 or meta.ped_gender == self.gender - 1)
                and (self.ped_type < 0 or meta.ped_type == self.ped_type))
            and (kind ~= 'vehicle' or (self.vehicle_class < 0 or meta.class_id == self.vehicle_class)
                and (self.manufacturer == '' or meta.manufacturer == self.manufacturer)) then
            list[#list + 1] = item
        end
    end
    return list
end

function Browser:combo(id, current, names, title, translate)
    local tr = self.ctx.translator
    ImGui.SetNextItemWidth(144)
    local preview = current == 0 and tr:text(title) or translate and tr:text(names[current + 1]) or names[current + 1]
    if ImGui.BeginCombo(id, preview) then
        for i, name in ipairs(names) do
            local label = i == 1 and tr:text('GENERIC_NONE') or translate and tr:text(name) or name
            ImGui.Selectable(label, current == i - 1)
            if ImGui.IsItemClicked() then
                current = i - 1; ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndCombo()
    end
    Widgets.tooltip(self.ctx, tr:text('GENERIC_LIST_FILTER'))
    return current
end

function Browser:draw_filters(kind)
    if kind == 'ped' then
        local genders = self.humans_only and { 'GENERIC_NONE', 'GENERIC_MALE', 'GENERIC_FEMALE' } or
            { 'GENERIC_NONE', 'GENERIC_MALE', 'GENERIC_FEMALE', 'GENERIC_UNKNOWN' }
        if self.gender_filter then
            self.gender = self:combo('##PedBrowserGendrFilter', self.gender, genders,
                'GENERIC_GENDER', true)
        end
        if self.type_filter then
            if self.gender_filter then Widgets.same_line_if_available(144) end
            self.ped_type = self:combo('##PedBrowserTypeFilter', self.ped_type + 1, ped_types, 'GENERIC_TYPE', false) - 1
        end
    elseif kind == 'vehicle' then
        self.manufacturer_index = self:combo('##VehicleBrowserMfrFilter', self.manufacturer_index, manufacturers,
            'GENERIC_MANUFACTURER', false)
        self.manufacturer = self.manufacturer_index == 0 and '' or manufacturers[self.manufacturer_index + 1]
        Widgets.same_line_if_available(144)
        self.vehicle_class = self:combo('##VehicleBrowserClassFilter', self.vehicle_class + 1, classes, 'GENERIC_CLASS',
            false) - 1
    end
end

function Browser:draw_list(preview, kind, region)
    self.regions = self.regions or {}
    if not self.regions[kind] then
        local w, h = ImGui.GetContentRegionAvail(); local r = region or { x = w, y = h }
        self.regions[kind] = { x = r.x == 0 and -1 or r.x, y = r.y == 0 and -1 or r.y }
    end
    region = self.regions[kind]
    local ctx = self.ctx
    if preview then
        self.preview_enabled = Widgets.toggle(ctx,
            ctx.translator:text('GENERIC_PREVIEW') .. '##model_browser_' .. self.uid, self.preview_enabled)
    end
    self:draw_filters(kind)
    self.query = Widgets.search(ctx, '##assetBrowserSearchbar', self.query, region.x)
    local list = self:filtered(kind)
    local maximum = self.max_entries or (kind == 'object' and 300 or 250)
    local hovered = false
    local clicked = false
    if ImGui.BeginListBox('##AssetBrowserList', region.x, region.y) then
        if maximum > 0 and #list >= maximum and self.query == '' then
            ImGui.TextColored(0.941, 0.745, 0.007, 1, '[ ! ]')
            Widgets.tooltip(ctx, ctx.translator:format('ASSET_BROWSER_TRUNC_TT', maximum))
            ImGui.Separator()
        end
        for index = 1, maximum > 0 and math.min(#list, maximum) or #list do
            local item = list[index]
            ImGui.Selectable(item.label, self.selected == item)
            if ImGui.IsItemClicked() then
                self.selected = item; clicked = true; ImGui.SetItemDefaultFocus()
            end
            if preview and self.preview_enabled and ImGui.IsItemHovered() then
                preview:request(item.model or util.joaat(item.name), item.kind); hovered = true
            end
        end
        ImGui.EndListBox()
    end
    if self.preview_hovered and not hovered and preview then
        local serial = preview.serial
        ctx.runtime:run('clear asset preview', function() if preview.serial == serial then preview:clear() end end)
    end
    self.preview_hovered = hovered
    return self.selected, clicked
end

function Browser:draw(preview, region)
    assert(self.ctx, 'The model browser requires the application context')
    ImGui.PushID(self.uid)
    if self.fixed_kind then
        local result, clicked = self:draw_list(preview, kinds[self.fixed_kind + 1], region)
        ImGui.PopID(); return result, clicked
    end
    if ImGui.BeginChild('##AssetBrowserTypes', 100, math.max(300, self.ctx.settings:get('ui.height') * 0.7), false) then
        for _, entry in ipairs({ { 'Peds', 1 }, { 'Vehicles', 2 }, { 'Objects', 0 } }) do
            if Widgets.navigation(self.ctx, '##model_kind_' .. entry[2], entry[1], self.kind == entry[2], 90, 32, false, true) then
                self:select_kind(entry[2])
            end
        end
    end
    ImGui.EndChild()
    ImGui.SameLine()
    local result, clicked
    if ImGui.BeginChild('##AssetBrowserModels', 0, math.max(300, self.ctx.settings:get('ui.height') * 0.7), true) then
        result, clicked =
            self:draw_list(preview, kinds[self.kind + 1], region)
    end
    ImGui.EndChild()
    ImGui.PopID()
    return result, clicked
end

return Browser
