-- Samurai's Scripts V2 port. GPL-3.0-or-later; see LICENSE.
local Json = require('includes.ssv2.vendor.json')()
local normalize = require('includes.ssv2.data.schema')
local Settings = {}
Settings.__index = Settings

local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function merge(value, defaults)
    if type(value) ~= 'table' then return copy(defaults) end
    for key, default in pairs(defaults) do
        if type(default) == 'table' then
            value[key] = merge(value[key], default)
        elseif type(value[key]) ~= type(default) then
            value[key] = default
        end
    end
    return value
end

function Settings.new(defaults, path)
    local self = setmetatable({
        path = path or 'ssv2/settings.json',
        defaults = copy(defaults),
        data = {},
        dirty = false,
        changed_at = 0,
        last_flush = util.time(),
        listeners = {}
    }, Settings)
    self:load()
    return self
end

function Settings:read(path)
    if not FileMgr.DoesFileExist(path) then return nil end
    local raw = FileMgr.ReadFileContent(path)
    if raw == '' then return nil end
    local ok, value = pcall(function() return Json:decode(raw) end)
    return ok and type(value) == 'table' and value or nil
end

function Settings:load()
    local value = self:read(self.path)
    if not value then
        value = self:read(self.path .. '.bak')
        if value then log.warn('Samurai: recovered settings from backup') end
    end
    self.data = merge(value or {}, self.defaults)
    self.persisted = value and copy(value) or nil
    self:normalize()
end

function Settings:normalize()
    self.data = merge(self.data, self.defaults)
    local function sanitize(node, prefix)
        for key, item in pairs(node) do
            local path = prefix == '' and tostring(key) or prefix .. '.' .. tostring(key)
            if type(item) == 'table' then
                sanitize(item, path)
            else
                node[key] = normalize(path, item)
            end
        end
    end
    sanitize(self.data, '')
end

function Settings:get(path)
    local value = self.data
    for key in path:gmatch('[^.]+') do
        if type(value) ~= 'table' then return nil end
        value = value[key]
    end
    return value
end

function Settings:set(path, value)
    assert(value ~= nil, 'Settings values must not be nil')
    value = normalize(path, value)
    local target, keys = self.data, {}
    for key in path:gmatch('[^.]+') do keys[#keys + 1] = key end
    assert(#keys > 0, 'Empty settings path')
    for i = 1, #keys - 1 do
        if type(target[keys[i]]) ~= 'table' then target[keys[i]] = {} end
        target = target[keys[i]]
    end
    local key = keys[#keys]
    if target[key] == value then return end
    target[key] = value
    self.dirty, self.changed_at = true, util.time()
    for _, callback in ipairs(self.listeners[path] or {}) do callback(value) end
end

function Settings:on_change(path, callback)
    self.listeners[path] = self.listeners[path] or {}
    self.listeners[path][#self.listeners[path] + 1] = callback
end

function Settings:save()
    if self.debug_disabled then return false end
    if not self.dirty then return true end
    local parent = self.path:match('^(.*)/[^/]+$')
    if parent then FileMgr.CreateDir(parent) end
    -- Back up the last successfully decoded/saved state, never a corrupt file.
    if self.persisted and not FileMgr.WriteFileContent(self.path .. '.bak',
            Json:encode_pretty(self.persisted), false) then
        log.warn('Samurai: settings backup failed; keeping current file')
        self.changed_at, self.last_error = util.time(), 'Settings backup failed'
        return false
    end
    local raw = Json:encode_pretty(self.data)
    if not FileMgr.WriteFileContent(self.path, raw, false) then
        log.warn('Samurai: settings write failed')
        self.changed_at, self.last_error = util.time(), 'Settings write failed'
        return false
    end
    if FileMgr.ReadFileContent(self.path) ~= raw then
        log.warn('Samurai: settings verification failed')
        self.changed_at, self.last_error = util.time(), 'Settings verification failed'
        return false
    end
    self.persisted, self.dirty = copy(self.data), false
    self.last_error = nil
    self.last_flush = util.time()
    return true
end

function Settings:update()
    if self.debug_disabled then return end
    if self.dirty and util.time() - self.changed_at >= 250 then self:save() end
end

return Settings
