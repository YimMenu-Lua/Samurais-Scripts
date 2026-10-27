local Codec = require('includes.ssv2.core.codec')
local Migration = {}
local function code(binding)
    if type(binding) == 'number' then return binding end
    if type(binding) == 'table' then return tonumber(binding.code) or tonumber(binding.key) or 0 end
    return 0
end
local function channel(value)
    value = tonumber(value) or 0
    return math.max(0, math.min(1, value > 1 and value / 255 or value))
end
function Migration.convert(value, path, seen)
    if type(value) ~= 'table' then return value end
    path = path or ''; seen = seen or {}
    assert(not seen[value], 'Cyclic profile data'); seen[value] = true
    local tag = tostring(value.__type or ''):lower()
    local result = {}
    if tag == 'keybind' or value.keyboard_binding or value.controller_binding then
        local keyboard, controller = value.keyboard_binding or {}, value.controller_binding or {}
        result = {
            keyboard = code(keyboard.key),
            keyboard_modifier = code(keyboard.modifier),
            controller = code(controller.key),
            controller_modifier = code(controller.modifier)
        }
        for _, field in ipairs({ 'name', 'no_gamepad', 'is_exclusive', 'repeat_on_hold', 'allow_unbind' }) do
            result[field] =
                value[field]
        end
    elseif tag == 'vec3' or tag == 'vec4' then
        if path:match('%.color$') or path:match('marker_color$') then
            result = { value.x or 0, value.y or 0, value.z or 0 }; if tag == 'vec4' then result[4] = value.w or 0 end
        else
            result = { x = value.x or 0, y = value.y or 0, z = value.z or 0 }; if tag == 'vec4' then
                result.w = value.w or
                    0
            end
        end
    elseif tag == 'vec2' then
        result = { x = value.x or 0, y = value.y or 0 }
    elseif tag == 'color' then
        local r, g, b, a = channel(value.r), channel(value.g), channel(value.b), channel(value.a == nil and 1 or value.a)
        if path:find('%.Colors%.') or path:match('SSAccent$') or path:match('SSGradient$') then
            result = { x = r, y = g, z = b, w = a }
        else
            result = { r, g, b, a }
        end
    else
        for key, item in pairs(value) do
            if key ~= '__schema_hash' and key ~= '__type' then
                result[key] = Migration.convert(item,
                    path == '' and tostring(key) or path .. '.' .. tostring(key), seen)
            end
        end
    end
    seen[value] = nil; return result
end

function Migration.profile(value)
    local result = Migration.convert(value)
    if result.quick_toggle_keybinds then
        local paths = require('includes.ssv2.data.control_paths')
        local labels = require('includes.ssv2.data.locales.en-US')
        local aliases = {}
        for key, path in pairs(paths) do
            aliases[key] = path; if labels[key] then aliases[labels[key]] = path end
        end
        local bindings = {}
        for key, binding in pairs(result.quick_toggle_keybinds) do bindings[aliases[key] or key] = binding end
        result.quick_toggle_keybinds = bindings
    end
    if result.ui and result.ui.window_size then
        result.ui.width, result.ui.height = result.ui.window_size.x, result.ui.window_size.y
        result.ui.window_size = nil
    end
    if result.ui and result.ui.window_pos then
        result.ui.position = result.ui.window_pos; result.ui.window_pos = nil
    end
    if result.features and result.features.vehicle then
        local vehicle = result.features.vehicle
        if vehicle.no_carjacking ~= nil and (not result.features.self or result.features.self.no_carjacking == nil) then
            result.features.self = result.features.self or {}; result.features.self.no_carjacking = vehicle
                .no_carjacking
        end
    end
    result.schema_version = 2
    return result
end

function Migration.read(path)
    if not FileMgr.DoesFileExist(path) then return nil end
    local ok, value = pcall(Codec.decode, FileMgr.ReadFileContent(path))
    return ok and type(value) == 'table' and value or nil
end

function Migration.import(settings, value)
    local profile = Migration.profile(value)
    for key, item in pairs(profile) do settings:set(tostring(key), item) end
    settings:normalize()
    return settings:save()
end

function Migration.autoload(settings, existing_profile)
    if existing_profile then return end
    for _, path in ipairs({ 'ssv2.json', 'ssv2.bak', 'samurais_scripts.json', 'samurais_scripts.bak' }) do
        local value = Migration.read(path)
        if value and (value.features or value.keybinds or value.backend) then
            assert(Migration.import(settings, value), 'Legacy profile could not be saved')
            settings.migrated_from = path; return
        end
    end
end

function Migration.store(store, path, root, convert)
    if FileMgr.DoesFileExist(store.path) or FileMgr.DoesFileExist(store.path .. '.bak') then return false end
    local value = Migration.read(path)
    if not value then return false end
    store:set(root, convert and convert(value) or Migration.convert(value))
    return store:save()
end

function Migration.auxiliary(ctx)
    local features = ctx.features
    local actions = features.yim_actions
    if actions and not FileMgr.DoesFileExist(actions.favorites.path) and not FileMgr.DoesFileExist(actions.favorites.path .. '.bak') then
        local value = Migration.read('saved_actions.json')
        if value then
            for _, kind in ipairs({ 'anims', 'scenarios', 'clipsets', 'scenes' }) do
                if type(value[kind]) == 'table' then
                    actions.favorites:set(kind, Migration.convert(value[kind]))
                end
            end
            actions.favorites:save()
        end
    end
    if actions then
        Migration.store(actions.commands, 'action_commands.json', 'aliases', function(value)
            local result = {}; local types = { [0] = 'anims', [1] = 'scenarios', [2] = 'scenes', [3] = 'clipsets' }
            for label, definition in pairs(value) do
                if type(definition) == 'table' and type(definition.command) == 'string' and types[definition.type] then
                    result[definition.command:lower()] = { kind = types[definition.type], label = label }
                end
            end
            return result
        end)
    end
    local forge = features.entity_forge
    if forge then
        Migration.store(forge.saved, 'forged_entities.json', 'creations')
        Migration.store(forge.favorites, 'forge_favorites.json', 'models', function(value)
            local result = {}; local types = { [1] = 'ped', [2] = 'vehicle', [3] = 'object' }
            for hash, definition in pairs(value) do
                if tonumber(hash) and type(definition) == 'table' and types[definition.entityType] then
                    result[tostring(tonumber(hash) % 4294967296)] = {
                        model = tonumber(hash),
                        kind = types
                            [definition.entityType],
                        name = definition.name or tostring(hash),
                        alpha = definition.alpha or 255
                    }
                end
            end
            return result
        end)
    end
    local billionaire = features.billionaire_services
    if billionaire then Migration.store(billionaire.store, 'escort_groups.json', 'groups') end
    local stats = features.stat_controller
    if stats then Migration.store(stats.store, 'mp_stats.json', 'definitions') end
    Migration.store(ctx.theme.store, 'ss_themes.json', 'themes')
end

return Migration
