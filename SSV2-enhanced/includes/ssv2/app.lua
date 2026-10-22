local Settings = require('includes.ssv2.core.settings')
local Clock = require('includes.ssv2.core.clock')
local State = require('includes.ssv2.core.state')
local Runtime = require('includes.ssv2.core.runtime')
local Input = require('includes.ssv2.core.input')
local Translator = require('includes.ssv2.core.translator')
local View = require('includes.ssv2.core.view')
local defaults = require('includes.ssv2.data.defaults')
local App = {}

local function migrate_prototype(settings, existing_profile)
    if existing_profile or not FileMgr.DoesFileExist('samurais_v2.cfg') then return end
    local raw = FileMgr.ReadFileContent('samurais_v2.cfg')
    settings:set('features.self.autoheal.enabled', raw:match('autoheal_enabled=1') ~= nil)
    settings:set('features.vehicle.horn_beams', raw:match('horn_beams_enabled=1') ~= nil)
    local speed = tonumber(raw:match('autoheal_regen_speed=(%d+)'))
    if speed then settings:set('features.self.autoheal.regen_speed', math.max(1, math.min(100, speed))) end
    settings:save()
end

function App.start()
    local profile_exists = FileMgr.DoesFileExist('ssv2/settings.json')
        or FileMgr.DoesFileExist('ssv2/settings.json.bak')
    local ctx = {
        clock = Clock.new(),
        state = State.new(),
        owned_entities = {},
        features = {},
        activity = require('includes.ssv2.core.activity').new()
    }
    ctx.build = require('includes.ssv2.core.build').new()
    ctx.script_data = require('includes.ssv2.core.script_data').new(ctx.build)
    ctx.settings = Settings.new(defaults)
    require('includes.ssv2.core.migration').autoload(ctx.settings, profile_exists)
    migrate_prototype(ctx.settings, profile_exists or ctx.settings.migrated_from ~= nil)
    ctx.runtime = Runtime.new(ctx.settings, ctx.state, ctx.build)
    ctx.particles = require('includes.ssv2.core.particles').new()
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() ctx.particles:stop_all() end
    ctx.input = Input.new(ctx.settings, ctx.runtime)
    ctx.translator = Translator.new(ctx.settings)
    ctx.game = require('includes.ssv2.core.game')
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() ctx.game.clear_lock_feedback(ctx) end
    ctx.vehicle_flags = require('includes.ssv2.core.vehicle_flags').new()
    ctx.preview = require('includes.ssv2.core.preview').new(ctx)
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() ctx.preview:clear() end
    ctx.theme = require('includes.ssv2.core.theme').new(ctx)
    ctx.notifier = require('includes.ssv2.core.notifier').new(ctx)
    ctx.runtime.notifier = ctx.notifier
    ctx.view = View.new(ctx)
    for _, path in ipairs({ 'self.autoheal', 'self.ragdoll', 'vehicle.miscellaneous', 'vehicle.high_beams',
        'vehicle.flappy_doors', 'vehicle.rgb_lights', 'self.magic_bullet', 'self.laser_sights',
        'self.katana', 'self.miscellaneous', 'self.abilities', 'world.miscellaneous', 'world.public_enemy',
        'vehicle.mines', 'vehicle.flares', 'vehicle.cobra_maneuver', 'world.carpool', 'world.hide_and_seek',
        'vehicle.nos', 'vehicle.drift', 'vehicle.iv_exit', 'vehicle.launch_control', 'vehicle.crashes',
        'vehicle.abs_lights', 'vehicle.paints', 'vehicle.drift_minigame', 'vehicle.manual_gearbox', 'vehicle.stancer',
        'vehicle.flag_editor', 'vehicle.aircraft', 'vehicle.flatbed', 'vehicle.speedometer', 'vehicle.engine_swaps',
        'online.stat_controller', 'online.casino', 'online.minigame_hack', 'online.solo_missions', 'online.cooldowns', 'online.businesses', 'online.heists', 'extra.yim_actions', 'extra.entity_forge', 'extra.billionaire_services' }) do
        local feature = require('includes.ssv2.features.' .. path)(ctx)
        feature.uses_vehicle_controller = feature.category == 'vehicle' and feature.id ~= 'flatbed' and
            feature.id ~= 'iv_exit'
        feature.requires_build = ({ nos = true, launch_control = true, crashes = true, abs_lights = true, manual_gearbox = true,
                stancer = true, flag_editor = true, aircraft = true, speedometer = true, engine_swaps = true, casino = true,
                minigame_hack = true, solo_missions = true, businesses = true, heists = true, billionaire_services = true })
            [feature.id] or false
        ctx.features[feature.id] = feature
        ctx.runtime:add(feature)
        ctx.view:add(feature)
    end
    local kill_enemies = require('includes.ssv2.features.world.kill_enemies')(ctx)
    ctx.view:add_action('world', 'WRLD_KILL_ALL', function() kill_enemies:run() end)
    local enemies_flee = require('includes.ssv2.features.world.enemies_flee')(ctx)
    ctx.view:add_action('world', 'WRLD_FLEE_ALL', function() enemies_flee:run() end)
    require('includes.ssv2.core.migration').auxiliary(ctx)
    ctx.console = require('includes.ssv2.core.console').new(ctx)
    ctx.quick_toggles = require('includes.ssv2.core.quick_toggles').new(ctx)
    ctx.entity_limits = { ped = 25, vehicle = 15, object = 35 }
    ctx.debug_view = require('includes.ssv2.core.debug_view').new(ctx)
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() ctx.debug_view:clear() end
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function()
        for handle, record in pairs(ctx.owned_entities) do
            if type(record) == 'table' and record.pool then
                record.pool:delete(handle)
            else
                if ENTITY.DOES_ENTITY_EXIST(handle) then Entity.new(handle):delete() end; ctx.owned_entities[handle] = nil
            end
        end
    end
    event.register_handler(menu_event.PlayerMgrInit, function() ctx.runtime:reset() end)
    event.register_handler(menu_event.PlayerMgrShutdown, function() ctx.runtime:reset() end)
    event.register_handler(menu_event.Unload, function() ctx.runtime:stop() end)
    local next_local_sync = 0
    ctx.runtime:loop('SS_BACKEND', function()
        ctx.online = network.is_session_started()
        if not ctx.fsl then ctx.fsl = not NETSHOPPING.NET_GAMESERVER_USE_SERVER_TRANSACTIONS() end
        if ctx.fsl and not ctx.settings:get('features.unsafe_feats_enabled') then
            ctx.settings:set(
            'features.unsafe_feats_enabled', true)
        end
        if util.time() >= next_local_sync then
            ctx.build:update()
            ctx.clock:sync_local()
            next_local_sync = util.time() + 1000
        end
        local preview_state = ctx.state:read()
        if preview_state then
            ctx.preview:update(preview_state, ctx.view.open and util.time() - (ctx.preview.touched or 0) < 600)
        else
            ctx.preview:clear()
        end
        ctx.debug_view:update(preview_state)
        ctx.translator:update()
    end, function()
        ctx.preview:clear(); ctx.debug_view:clear()
    end)
    ctx.runtime:loop('SS_KEYMGR', function()
        ctx.quick_toggles:update(); ctx.input:update()
    end)
    ctx.runtime:loop('SS_SERIALIZER', function()
        ctx.theme.store:update(); ctx.settings:update()
    end)
    ctx.runtime:loop('SS_CTRLS', function() ctx.input:suppress_game(ctx) end)
    local next_pool_cleanup = 0
    ctx.runtime:loop('SS_POOLMGR', function()
        if util.time() < next_pool_cleanup then return end
        next_pool_cleanup = util.time() + (ctx.settings:get('backend.debug_mode') and 500 or 2000)
        for handle, record in pairs(ctx.owned_entities) do
            if type(record) == 'table' and record.pool and (not record.pool:exists(record) or ENTITY.IS_ENTITY_DEAD(handle, false)) then
                record.pool:delete(handle)
            end
        end
    end)
    local vehicle_controller = ctx.runtime:loop('SS_VEHICLE_CONTROLLER',
        function() ctx.state:update_vehicle(ctx.runtime) end)
    local vehicle_generation = ctx.runtime.generation
    vehicle_controller.before_tick = function()
        if vehicle_generation ~= ctx.runtime.generation then
            ctx.state.vehicle_control = {}; vehicle_generation = ctx.runtime.generation
        end
    end
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() ctx.state.vehicle_control = {} end
    ctx.runtime:start()
    return ctx
end

return App
