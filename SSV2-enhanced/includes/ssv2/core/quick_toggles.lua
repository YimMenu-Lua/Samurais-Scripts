local Quick = {}; Quick.__index = Quick
local function identifier(path)
    return 'quick_' .. path:gsub('.', function(char) return string.format('%02x', char:byte()) end)
end
function Quick.new(ctx) return setmetatable({ ctx = ctx, registered = {} }, Quick) end

function Quick:update()
    local definitions = self.ctx.settings:get('quick_toggle_keybinds') or {}
    for path, id in pairs(self.registered) do
        if not definitions[path] then
            for i = #self.ctx.input.bindings, 1, -1 do
                if self.ctx.input.bindings[i].id == id then
                    table.remove(
                        self.ctx.input.bindings, i)
                end
            end
            self.registered[path] = nil
        end
    end
    for path, definition in pairs(definitions) do
        if type(definition) == 'table' then
            local id = identifier(path)
            if not self.registered[path] then
                self.registered[path] = id; self.ctx.settings:set('keybinds.' .. id, definition)
                self.ctx.input:bind(id, function()
                    local value = self.ctx.settings:get(path)
                    assert(type(value) == 'boolean', 'Quick toggles require a boolean setting')
                    self.ctx.settings:set(path, not value)
                end)
                self.ctx.input.bindings[#self.ctx.input.bindings].label = path
            else
                if self.ctx.settings:get('keybinds.' .. id) == nil then
                    self.ctx.settings:set('keybinds.' .. id,
                        definition)
                end
                for _, field in ipairs({ 'keyboard', 'controller', 'keyboard_modifier', 'controller_modifier' }) do
                    local current = self.ctx.settings:get('keybinds.' .. id .. '.' .. field)
                    if current ~= nil then definition[field] = current end
                end
            end
        end
    end
end

function Quick:add(path)
    assert(type(self.ctx.settings:get(path)) == 'boolean', 'Select a boolean setting path')
    local definitions = {}; for key, value in pairs(self.ctx.settings:get('quick_toggle_keybinds') or {}) do
        definitions[key] =
            value
    end
    assert(not definitions[path], 'This quick toggle already exists')
    definitions[path] = { keyboard = 0, controller = 0, keyboard_modifier = 0, controller_modifier = 0 }
    self.ctx.settings:set('quick_toggle_keybinds', definitions); self:update()
end

function Quick:remove(path)
    local definitions = {}; for key, value in pairs(self.ctx.settings:get('quick_toggle_keybinds') or {}) do
        if key ~= path then
            definitions[key] =
                value
        end
    end
    self.ctx.settings:set('quick_toggle_keybinds', definitions); self:update()
end

return Quick
