local ie = require('includes.ssv2.data.imp_exp_vehicles')
local salvage = require('includes.ssv2.data.sv23_data')
local geometry = require('includes.ssv2.core.geometry')
local tow_models = {}
for hash, name in pairs(require('includes.ssv2.data.vehicle_hashmap')) do
    if name == 'towtruck' or name == 'towtruck2' or name == 'towtruck3' or name == 'towtruck4' then tow_models[hash] = true end
end
local Extras = {}; Extras.__index = Extras
local clutter = { 'cash', 'Swag_Silver', 'Swag_Pills', 'Swag_Med', 'Swag_JewelWatch', 'Swag_Ivory', 'Swag_Guns',
    'Swag_Gems',
    'Swag_Furcoats', 'Swag_electronic', 'Swag_DrugStatue', 'Swag_DrugBags', 'Swag_Counterfeit', 'Swag_Booze_cigs',
    'Swag_Art' }
function Extras.new(ctx, manager)
    return setmetatable({
        ctx = ctx,
        manager = manager,
        names = {},
        storage = {},
        earnings = {},
        next_snapshot = 0,
        money = require('includes.ssv2.core.money').new(ctx),
        transfer_amount = 10000,
        clutter = {},
        rename_text = '',
        front_selection = 0,
        selected_earnings = 1,
        earnings_value = 0
    }, Extras)
end

function Extras:boss_action(kind)
    local snapshot = self.boss or {}
    if kind == -1 then
        if snapshot.type == -1 then return end
    else
        assert(kind == 0 or kind == 1, 'Invalid boss type')
        assert(not snapshot.associate, 'Leave your current organization first')
        if snapshot.type ~= -1 then return end
        assert(kind ~= 1 or self.manager.fronts.clubhouse, 'A clubhouse is required to register as MC president')
    end
    assert(scripts.is_active('freemode'), 'Freemode script is not running')
    local pattern = kind == -1 and '2D 01 03 00 00 38 00 56 ? ? 25 5B' or '2D 03 14 00 00 72'
    local pointer = ScriptPointer.new('ssv2_boss_' .. kind, pattern):scan('freemode')
    assert(pointer and pointer:get_address() ~= 0, 'Boss registration function was not found')
    local call = ScriptFunction.new('freemode', pointer)
    if kind == -1 then call:call('b=n', true) else call:call('bii=n', true, kind, 208508824) end
end

function Extras:rename(kind, name)
    local front = assert(self.manager.fronts[kind], 'Business is not owned')
    if kind == 'nightclub' then
        local index = tonumber(name); assert(index and index >= 0 and index <= 8, 'Invalid nightclub name')
        local data = self.ctx.script_data
        local field = data:global('mp_business_stuff',
            { { PLAYER.PLAYER_ID(), data:offset('mp_business_stuff', 1) }, data:offset('mp_business_stuff', 2), 364, 1 })
        local value = bit.band(field:get_int(), bit.bnot(bit.bor(1, 0xFF000000)))
        field:set_int(bit.bor(value, bit.lshift(1, index == 8 and 0 or index + 24)))
        stats.set_int('MPX_PROP_NIGHTCLUB_NAME_ID', index)
        front.name_id = index
        front.custom = require('includes.ssv2.data.business_definitions').NightclubNames[index + 1]
    else
        assert(scripts.is_active('freemode'), 'Freemode script is not running')
        local suffix = kind == 'office' and '2D' or '31'
        local pointer = ScriptPointer.new('ssv2_' .. kind .. '_rename',
            '2D 02 14 00 00 38 01 56 ? ? 38 00 2C 05 ? ? 06 56 ? ? 26 ' .. suffix):scan('freemode')
        assert(pointer and pointer:get_address() ~= 0, 'Business rename function was not found')
        if not name:find('%S') then name = self.manager:label(kind == 'office' and 'GB_REST_ACC' or 'GB_REST_ACCM') end
        ScriptFunction.new('freemode', pointer):call('sb=n', name, true)
        front.custom = name
    end
end

function Extras:transfer(source, destination)
    local first, second = self.manager.lookup[source], self.manager.lookup[destination]
    assert(first and second and first.kind == 'hub' and second.kind == 'hub' and first ~= second,
        'Choose two distinct hubs')
    local from, to = first:technician(), second:technician()
    if from < 0 then return false end
    first:assign(-1); second:assign(-1); second:assign(from)
    if to >= 0 then first:assign(to) end
    return true
end

function Extras:remove_clutter(state)
    local office = self.manager.fronts.office
    if not office or self.ctx.game.outside(state.handle) then return end
    local interior = INTERIOR.GET_INTERIOR_FROM_ENTITY(state.handle)
    if interior == 0 then return end
    local prefixes = { 'ex_sm_13_', 'ex_sm_15_', 'ex_dt1_02_', 'ex_dt1_11_' }
    local variants = { 'office_01a', 'office_01b', 'office_01c', 'office_02a', 'office_02b', 'office_02c', 'office_03a',
        'office_03b', 'office_03c' }
    local variant = variants[stats.get_int('MPX_PROP_OFFICE_VAR')]
    if not variant or not STREAMING.IS_IPL_ACTIVE(prefixes[office.index] .. variant) then return end
    local changed = false
    local function disable(name)
        if INTERIOR.IS_INTERIOR_ENTITY_SET_ACTIVE(interior, name) then
            INTERIOR.DEACTIVATE_INTERIOR_ENTITY_SET(interior, name); changed = true
        end
    end
    for _, name in ipairs(clutter) do
        if self.ctx.settings:get('features.yrv3.office_clutter.items.' .. name) then
            if name == 'cash' then
                for i = 1, 24 do disable(string.format('Cash_Set_%02d', i)) end
            else
                disable(name); disable(name .. '2'); disable(name .. '3')
            end
        end
    end
    if changed then INTERIOR.REFRESH_INTERIOR(interior) end
end

function Extras:finish_import()
    if not scripts.is_active('gb_vehicle_export') then return end
    local data = self.ctx.script_data
    assert(data:host('gb_vehicle_export'), 'Local player must host the vehicle source mission')
    data:write_local('ie_objective_local', 2, { data:offset('ie_objective_local', 1) + 1 })
    data:write_local('ie_objective_local', 13, { data:offset('ie_objective_local', 1) })
    data:write_local('ie_objective_local', 420972882, { data:value('ie_bitset_1') })
    data:write_local('ie_objective_local', 420972882, { data:value('ie_steal_bitset'), data:offset('ie_steal_bitset', 1) })
end

function Extras:salvage_action(action)
    assert(self.manager.fronts.salvage, 'Salvage yard is not owned')
    if action == 'skip' then
        local info = assert(salvage.robbery_types[stats.get_int('MPX_SALV23_VEH_ROB') + 1], 'No selected robbery')
        stats.set_int('MPX_SALV23_FM_PROG', info.fm_prog); stats.set_int('MPX_SALV23_SCOPE_BS', info.scope_bs); stats
            .set_int('MPX_SALV23_DISRUPT', info.disrupt)
    elseif action == 'double' then
        stats.set_int('MPX_SALV23_SALE_VAL', math.min(2147483647, stats.get_int('MPX_SALV23_SALE_VAL') * 2))
    elseif action == 'weekly' then
        self.manager.actions:lease('salvage_week',
            {
                kind = 'tunable',
                type = 'int',
                t = 'SALV23_VEH_ROBBERY_WEEK_ID',
                v = stats.get_int('MPX_SALV23_WEEK_SYNC') +
                    1
            }, true)
    elseif action == 'weekly_reset' then
        self.manager.actions:lease('salvage_week', {}, false)
    elseif action == 'income' then
        stats.set_packed_int(51051, 100)
    elseif action == 'keep' then
        stats.set_bool('MPX_SALV23_CAN_KEEP', not stats.get_bool('MPX_SALV23_CAN_KEEP'))
    end
end

function Extras:tow_target()
    local ctx, manager = self.ctx, self.manager
    if self.towing then return end
    self.towing = true
    local serial, generation = manager.serial, ctx.runtime.generation
    local ok, err = pcall(function()
        assert(scripts.is_active('fm_content_tow_truck_work') and ctx.script_data:host('fm_content_tow_truck_work'),
            'Host a tow-truck mission first')
        local state = ctx.state:read(); assert(state and state.driving, 'Enter your tow truck')
        local truck = state.vehicle_handle
        local model = state.vehicle:get_model() % 4294967296
        assert(tow_models[model], 'Current vehicle is not a tow truck')
        local target_position = assert(ctx.game.objective(), 'No tow objective was found')
        local target = ctx.game.closest_vehicle(target_position, 1, truck, true, 0)
        assert(target ~= 0, 'No target vehicle was found')
        local function valid()
            local current = ctx.state:read()
            return ctx.runtime.running and ctx.runtime.generation == generation and manager.serial == serial and
                manager.active
                and current and current.vehicle_handle == truck and scripts.is_active('fm_content_tow_truck_work')
        end
        assert(ctx.game.control(target, 350, valid), 'Unable to control the tow target')
        local position = state.ped:get_position()
        if geometry.distance(position, target_position) >= 100 then
            PED.SET_PED_COORDS_KEEP_VEHICLE(state.handle, target_position.x, target_position.y, target_position.z)
            script.yield(0); if not valid() then return end
            PED.SET_PED_COORDS_KEEP_VEHICLE(state.handle, position.x, position.y, position.z)
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(truck, 5)
        end
        VEHICLE.SET_VEHICLE_TOW_TRUCK_ARM_POSITION(truck, 0)
        script.yield(2000); if not valid() then return end
        local bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(truck, 'tow_mount_a')
        local point = ENTITY.GET_ENTITY_BONE_POSTION(truck, bone)
        local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(truck)
        local offset = Vector3.new(point.x - forward.x * 3.5, point.y - forward.y * 3.5, point.z)
        ENTITY.SET_ENTITY_HEADING(target, ENTITY.GET_ENTITY_HEADING(truck))
        ENTITY.SET_ENTITY_PROOFS(target, false, false, false, true, false, false, false, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(target, offset.x, offset.y, offset.z, false, false, false)
        while geometry.distance(ENTITY.GET_ENTITY_COORDS(target, false), offset) > 50 do
            script.yield(0); if not valid() then return end
        end
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(target, 5)
        if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(target, truck) then
            VEHICLE.ATTACH_VEHICLE_TO_TOW_TRUCK(truck, target, false, 0, 0, 0)
            script.yield(500); if not valid() then return end
        end
        VEHICLE.SET_VEHICLE_TOW_TRUCK_ARM_POSITION(truck, 1)
        local yard = manager.fronts.salvage.coords
        if geometry.distance(state.ped:get_position(), yard) > 10 then
            ctx.game.teleport(ctx, yard, true)
            script.yield(2000); if not valid() then return end
            if ctx.game.outside(state.handle) and not CAMERA.IS_SCREEN_FADING_OUT() and not CAMERA.IS_SCREEN_FADED_OUT()
                and not CAMERA.IS_SCREEN_FADING_IN() and not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(target, truck) then
                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(target, 5)
                VEHICLE._SET_ATTACHED_VEHICLE_TO_TOW_TRUCK_ARM(truck, target)
            end
        end
    end)
    self.towing = false; if not ok then error(err) end
end

function Extras:salvage_now(slot)
    assert(slot == 1 or slot == 2, 'Invalid salvage lift')
    if stats.get_int('MPX_MPSV_MODEL_SALVAGE_LIFT' .. slot) == 0 then return false end
    local name = 'MPX_SALVAGING_POSIX_LIFT' .. slot
    stats.set_int(name, stats.get_int(name) - (stats.get_int('MPX_SALVAGE_YARD_STAFF') == 1 and 2880 or 5760))
    return true
end

function Extras:update(state, now)
    self.money:update(now)
    if self.ctx.settings:get('features.yrv3.office_clutter.auto_disable') then self:remove_clutter(state) end
    if now < self.next_snapshot then return end
    local data, pid = self.ctx.script_data, PLAYER.PLAYER_ID()
    local boss = data:global('gpbd_fm_3', { { pid, data:offset('gpbd_fm_3', 1) }, 10 })
    local id = boss and boss:get_int() or -1
    self.boss = { type = id == pid and boss:at(433):get_int() or -1, associate = id >= 0 and id ~= pid }
    self.character_name = stats.get_string('MPX_CHAR_NAME'); self.net_worth = stats.get_int('MPPLY_TOTAL_EARNED')
    self.character_index = self.ctx.game.character_index()
    self.player_name = PLAYER.GET_PLAYER_NAME(pid)
    local client_bike = stats.get_int('MPX_MPSV_MODEL_BIKER_CLT')
    self.client_bike_name = client_bike ~= 0 and
        HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(client_bike)) or
        self.ctx.translator:text('GENERIC_NONE')
    self.storage = {}; self.range_counts = { 0, 0, 0 }; self.ie_income = 0
    for slot = 0, 39 do
        local entry = ie.base_data[stats.get_int('MPX_IE_WH_OWNED_VEHICLE_' .. slot)]
        if entry then
            local range = ie.range_data[entry.model] and ie.range_data[entry.model].range or 3
            local value = tunables.get_int(ie.base_value_tunables[range])
            self.storage[#self.storage + 1] = {
                slot = slot + 1,
                name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(entry.model)),
                plate = entry.plate,
                range = range,
                value = value
            }
            self.range_counts[range] = self.range_counts[range] + 1; self.ie_income = self.ie_income + value
        end
    end
    for _, name in ipairs({ 'MPX_LIFETIME_BUY_UNDERTAKEN', 'MPX_LIFETIME_BUY_COMPLETE', 'MPX_LIFETIME_SELL_UNDERTAKEN', 'MPX_LIFETIME_SELL_COMPLETE', 'MPX_LIFETIME_CONTRA_EARNINGS' }) do
        self.earnings[name] =
            stats.get_int(name)
    end
    if self.manager.fronts.salvage then
        local kind = stats.get_int('MPX_SALV23_VEH_ROB')
        self.salvage = {
            name = salvage.robbery_types[kind + 1] and salvage.robbery_types[kind + 1].name or 'None',
            value = stats.get_int('MPX_SALV23_SALE_VAL'),
            active = kind >= 0,
            preps_complete = bit.band(stats.get_int('MPX_SALV23_GEN_BS'), 1) ~= 0,
            model = stats.get_int('MPX_SALV23_VEH_MODEL'),
            keep = stats.get_bool('MPX_SALV23_CAN_KEEP'),
            income = stats.get_packed_int(51051),
            lifts = {},
            weekly = {}
        }
        self.salvage.vehicle_name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(
            self.salvage.model))
        self.salvage_income = 0; self.salvage.garage = {}
        for i = 1, 2 do
            self.salvage.lifts[i] = {
                model = stats.get_int('MPX_MPSV_MODEL_SALVAGE_LIFT' .. i),
                value = stats.get_int('MPX_MPSV_VALUE_SALVAGE_LIFT' .. i),
                due = stats.get_int('MPX_SALVAGING_POSIX_LIFT' .. i)
            }
        end
        for _, lift in ipairs(self.salvage.lifts) do
            lift.name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE
                .GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(lift.model))
        end
        for i = 0, 2 do
            self.salvage.weekly[i + 1] = {
                model = stats.get_int('MPX_MPSV_MODEL_SALVAGE_VEH' .. i),
                value = stats.get_int('MPX_SAL23_VALUE_VEH' .. i),
                status = stats.get_int('MPX_SALV23_VEHROB_STATUS' .. i)
            }
        end
        for _, lift in ipairs(self.salvage.lifts) do self.salvage_income = self.salvage_income + lift.value end
        for i = 1, 4 do
            local model = stats.get_int('MPX_MPSV_MODEL_SALVAGE_VEH' .. i)
            local value = stats.get_int('MPX_SAL23_VALUE_VEH' .. i)
            self.salvage.garage[i] = { name = salvage.vehicle_targets[model] or 'Empty', value = value }
            self.salvage_income = self.salvage_income + value
        end
    end
    if self.manager.fronts.nightclub then self.popularity = stats.get_int('MPX_CLUB_POPULARITY') end
    self.next_snapshot = now + 1200
end

return Extras
