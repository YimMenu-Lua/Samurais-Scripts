local Memory = require('includes.ssv2.core.vehicle_memory')
local Settings = require('includes.ssv2.core.settings')
local Json = require('includes.ssv2.vendor.json')()
local groups = {
    [0] = { name = 'advanced', label = 'VEH_FLAGS_ADVANCED', enum = require('includes.ssv2.data.vehicle_advanced_flags'), allowed = 1 },
    [1] = { name = 'handling', label = 'VEH_FLAGS_HANDLING', enum = require('includes.ssv2.data.vehicle_handling_flags'), allowed = 2049 },
    [2] = { name = 'model', label = 'VEH_FLAGS_MODEL', enum = require('includes.ssv2.data.vehicle_model_flags'), allowed = 1 },
    [3] = { name = 'model_info', label = 'VEH_FLAGS_MODEL_INFO', enum = require('includes.ssv2.data.vehicle_model_info_flags'), allowed = 1 },
}
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
local function validate(data)
    assert(type(data) == 'table' and type(data.name) == 'string' and data.name:find('%S'), 'Preset needs a name')
    assert(type(data.deltas) == 'table', 'Preset needs flag deltas')
    local out = copy(data); out.deltas = {}
    for category, flags in pairs(data.deltas) do
        local index = tonumber(category); local group = groups[index]
        assert(group and type(flags) == 'table', 'Invalid flag category')
        out.deltas[tostring(index)] = {}
        for name, value in pairs(flags) do
            assert(group.enum[name] ~= nil and type(value) == 'boolean', 'Invalid preset flag: ' .. tostring(name))
            out.deltas[tostring(index)][name] = value
        end
    end
    out.vehicle_bitset = tonumber(data.vehicle_bitset) or 1
    assert(out.vehicle_bitset == 1 or out.vehicle_bitset == 2048 or out.vehicle_bitset == 2049,
        'Preset must allow cars or bikes')
    out.auto_apply = data.auto_apply == true
    if data.callback_defs_filename ~= nil then
        assert(type(data.callback_defs_filename) == 'string',
            'Invalid callback module name')
    end
    return out
end
return function(ctx)
    local f = {
        id = 'flag_editor',
        category = 'vehicle',
        scope = 'vehicle',
        presets = {},
        lookup = {},
        reserved = {},
        active_presets = {},
        edits = {},
        cache = {},
        filter = 0,
        sort = 0,
        search = '',
        preset_filter = 0,
        preset_name = '',
        description = '',
        callback_module = '',
        allow_cars = true,
        allow_bikes = false,
        new_auto = false,
        controls = {
            { kind = 'toggle', path = 'ui.show_flags', label = 'VEH_FLAGS_EDITOR_TAB' },
        }
    }
    f.storage = Settings.new({ presets = {} }, 'ssv2/handling_editor.json')
    for _, data in ipairs(require('includes.ssv2.data.vehicle_flag_presets')) do
        local preset = validate(data); f.presets[#f.presets + 1] = preset; f.lookup[preset.name] = preset; f.reserved[preset.name] = true
    end
    local stored = f.storage:get('presets')
    if #stored == 0 and FileMgr.DoesFileExist('handling_editor.json') then
        stored = f.storage:read(
            'handling_editor.json') or {}
    end
    for _, data in ipairs(stored) do
        local ok, preset = pcall(validate, data)
        if ok then
            if f.reserved[preset.name] then
                f.lookup[preset.name].auto_apply = preset.auto_apply
            elseif not f.lookup[preset.name] then
                f.presets[#f.presets + 1] = preset; f.lookup[preset.name] = preset
            end
        else
            log.warn('Samurai: invalid saved handling preset: ' .. tostring(preset))
        end
    end
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() f.storage:save() end
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready(state) return state.car or state.bike end

    function f:allowed(mask) return self.vehicle_type and bit.band(mask, bit.lshift(1, self.vehicle_type)) ~= 0 end

    function f:save()
        local presets = copy(self.presets)
        for _, preset in ipairs(presets) do preset.previous_stance = nil end
        self.storage:set('presets', presets); return self.storage:save()
    end

    function f:import(data)
        local preset = validate(data)
        assert(not self.lookup[preset.name], 'A preset with this name already exists')
        self.presets[#self.presets + 1] = preset; self.lookup[preset.name] = preset; self:save()
        if self.active and preset.auto_apply then self:toggle(preset, true) end
        return preset
    end

    function f:remove(name)
        assert(not self.reserved[name], 'Built-in presets cannot be removed')
        local preset = self.lookup[name]; if not preset then return end
        if self.active_presets[name] then self:toggle(preset, false) end
        for index, item in ipairs(self.presets) do
            if item == preset then
                table.remove(self.presets, index); break
            end
        end
        self.lookup[name] = nil; self:save()
    end

    function f:callback(preset, enabled)
        local name, handle = preset.name, self.identity
        if name == 'VEH_KERS_BOOST' then
            VEHICLE.SET_VEHICLE_KERS_ALLOWED(handle, enabled)
        elseif name == 'VEH_JUMP' then
            VEHICLE.SET_USE_HIGHER_CAR_JUMP(handle, enabled)
        elseif name == 'VEH_RAMP' then
            if enabled or ENTITY.GET_ENTITY_MODEL(handle) % 4294967296 ~= 0xCEB28249 and ENTITY.GET_ENTITY_MODEL(handle) % 4294967296 ~= 0xED62BFA9 then
                VEHICLE.SET_ALLOW_RAMMING_SOOP_OR_RAMP(handle, enabled)
            end
            if enabled then VEHICLE.VEHICLE_SET_RAMP_AND_RAMMING_CARS_TAKE_DAMAGE(handle, false) end
        elseif name == 'VEH_ROCKET_BOOST' then
            if enabled then
                STREAMING.REQUEST_NAMED_PTFX_ASSET('VEH_IMPEXP_ROCKET')
            else
                STREAMING.REMOVE_NAMED_PTFX_ASSET('VEH_IMPEXP_ROCKET')
            end
        elseif name == 'VEH_OFFROAD_ABILITIES' then
            local stance = ctx.features.stancer
            if stance and stance.active then
                if enabled then
                    preset.previous_stance = copy(stance.deltas); stance:lock(name)
                    stance.deltas[1].m_susp_comp = 0.1207; stance.deltas[1].m_track_width = -0.047
                    stance.deltas[2].m_susp_comp = 0.1201; stance.deltas[2].m_track_width = -0.052
                else
                    if preset.previous_stance then stance.deltas = preset.previous_stance end
                    preset.previous_stance = nil; stance:unlock(name)
                end
                PHYSICS.ACTIVATE_PHYSICS(handle)
            end
        elseif preset.callback_defs_filename and preset.callback_defs_filename ~= '' then
            local definitions = require(preset.callback_defs_filename)
            assert(type(definitions) == 'table' and type(definitions[name]) == 'table', 'Invalid preset callback module')
            local callback = definitions[name][enabled and 'onEnable' or 'onDisable']
            if callback then
                assert(type(callback) == 'function', 'Invalid preset callback'); callback(preset, self, ctx)
            end
        end
    end

    function f:toggle(preset, enabled)
        if enabled == (self.active_presets[preset.name] ~= nil) then return end
        if not self.active or not self:allowed(preset.vehicle_bitset) then return false end
        if enabled then
            -- A lease is recorded before callbacks so a callback failure still cleans up its flags.
            self.active_presets[preset.name] = preset
            for category, flags in pairs(preset.deltas) do
                local group = groups[tonumber(category)]
                if self:allowed(group.allowed) then
                    for name, value in pairs(flags) do
                        ctx.vehicle_flags:set(preset, self.identity, group.name,
                            group.enum[name], value)
                    end
                end
            end
            self:callback(preset, true)
        else
            ctx.vehicle_flags:release(preset); self.active_presets[preset.name] = nil; self:callback(preset, false)
        end
        self.next_cache = 0; return true
    end

    function f:owned(category, name)
        local group = groups[category]; local index = group.enum[name]
        local field = Memory.flag_pointer(self.identity, group.name, index)
        if not field then return false end
        local entry = ctx.vehicle_flags.entries[tostring(field:get_address()) .. ':' .. index % 32]
        if entry then
            for owner in pairs(entry.owners) do if owner ~= self then return true end end
        end
        return false
    end

    function f:push(category, name, value)
        local group = assert(groups[category], 'Invalid flag category')
        assert(group.enum[name] ~= nil, 'Invalid flag name')
        if not self.active or not self:allowed(group.allowed) or self:owned(category, name) then return false end
        ctx.vehicle_flags:set(self, self.identity, group.name, group.enum[name], value)
        self.edits[tostring(category)] = self.edits[tostring(category)] or {}
        self.edits[tostring(category)][name] = value; self.next_cache = 0; return true
    end

    function f:make_preset(name, mask, description, auto_apply, module)
        return self:import({
            name = name,
            deltas = copy(self.edits),
            vehicle_bitset = mask,
            description = description,
            auto_apply = auto_apply,
            callback_defs_filename = module ~= '' and module or nil,
            is_user_generated = true
        })
    end

    function f:enter(state)
        self.vehicle_type = state.car and 0 or 11
        self.active_presets = {}; self.edits = {}; self.next_cache = 0
        for _, preset in ipairs(self.presets) do if preset.auto_apply then self:toggle(preset, true) end end
    end

    function f:cleanup()
        for _, preset in pairs(self.active_presets) do
            ctx.vehicle_flags:release(preset)
            if ENTITY.DOES_ENTITY_EXIST(self.identity) then
                local ok, err = pcall(function() self:callback(preset, false) end)
                if not ok then log.warn('Samurai preset cleanup: ' .. tostring(err)) end
            end
        end
        ctx.vehicle_flags:release(self); self.active_presets = {}; self.edits = {}; self.cache = {}
    end

    function f:update()
        self.storage:update()
        if util.time() < self.next_cache then return end
        for category = 0, 3 do
            local group = groups[category]; local cache = {}; local words = {}
            if self:allowed(group.allowed) then
                for name, index in pairs(group.enum) do
                    local field = Memory.flag_pointer(self.identity, group.name, index)
                    if field then words[math.floor(index / 32) + 1] = field:get_dword() % 4294967296 end
                    cache[#cache + 1] = {
                        name = name,
                        index = index,
                        value = field and bit.band(field:get_dword(), bit.lshift(1, index % 32)) ~= 0 or false,
                        owned = self:owned(category, name)
                    }
                end
            end
            self.cache[category] = cache
            self.raw_flags = self.raw_flags or {}; self.raw_flags[category] = category == 3 and words or words[1] or 0
        end
        self.next_cache = util.time() + 200
    end

    f.frontend = require('includes.ssv2.core.flag_view').new(ctx, f, groups)
    f.owns_controls = true
    function f:draw() self.frontend:draw() end

    return f
end
