local Model = require('includes.ssv2.core.business_model')
local properties = require('includes.ssv2.data.mp_properties')
local definitions = require('includes.ssv2.data.business_definitions')
return function(ctx)
    local f = {
        id = 'businesses',
        category = 'online',
        scope = 'player',
        records = {},
        lookup = {},
        fronts = {},
        serial = 0,
        controls = {
            { kind = 'toggle', path = 'ui.show_businesses',                 label = 'YRV3 Business Manager' },
            { kind = 'toggle', path = 'features.unsafe_feats_enabled',      label = 'Enable original unsafe feature controls' },
            { kind = 'int',    path = 'features.yrv3.autofill_delay',       label = 'Warehouse sourcing delay',               min = 100, max = 5000 },
            { kind = 'toggle', path = 'features.yrv3.autosell',             label = 'Auto finish supported sales' },
            { kind = 'toggle', path = 'features.yrv3.nc_always_popular',    label = 'Keep nightclub popularity' },
            { kind = 'toggle', path = 'features.yrv3.sy_always_max_income', label = 'Keep salvage-yard income' },
        }
    }
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:poll()
        if not ctx.build.compatible then
            self.status, self.status_message = 'ERROR', 'GENERIC_OUTDATED'
        elseif self.failed then
            self.status, self.status_message = 'ERROR', self.error or 'GENERIC_UNKNOWN'
        elseif not network.is_session_started() then
            self.status, self.status_message = 'OFFLINE', 'GENERIC_UNAVAILABLE_SP'
        elseif scripts.is_active('maintransition') or STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS() then
            self.status, self.status_message = 'WAITING', 'YRV3_STATE_WAIT_TRANSITION'
        elseif NETWORK.NETWORK_IS_ACTIVITY_SESSION() then
            self.status, self.status_message = 'ERROR', 'YRV3_STATE_ERR_WRONG_SESSION'
        elseif self.reloading then
            self.status, self.status_message = 'RELOADING', 'GENERIC_WAIT_LABEL'
        elseif not ctx.script_data:global('mp_business_stuff') then
            self.status, self.status_message = 'LOADING', 'GENERIC_WAIT_LABEL'
        else
            self.status, self.status_message = 'RUNNING', ''
        end
    end

    function f:ready()
        return network.is_session_started() and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
            and ctx.script_data:global('mp_business_stuff') ~= nil
    end

    function f:label(key) return HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(key) end

    function f:add(record)
        record = Model.new(ctx, record)
        self.records[#self.records + 1] = record; self.lookup[record.key] = record; return record
    end

    function f:safe(key, metadata, name, coords)
        local record = { key = key, kind = 'safe', name = name, coords = coords, count_stat = metadata.cash_value_stat }
        for _, field in ipairs({ 'paytime_stat', 'capacity_tunable', 'upgrade_stat', 'upgrade_tunable', 'global_offset', 'room_hash', 'car_wash' }) do
            record[field] =
                metadata[field]
        end
        return self:add(record)
    end

    function f:warehouse(key, index, property, hangar)
        local ref = (hangar and properties.Hangars or properties.CEOWarehouses)[property]
        if not ref then return end
        return self:add({
            key = key,
            index = index,
            kind = hangar and 'hangar' or 'cargo',
            coords = ref.coords,
            name = self:label((hangar and 'MP_HANGAR_' or 'MP_WHOUSE_') .. (hangar and property or property - 1)),
            max = hangar and 50 or ref.max,
            vpu = hangar and 30000 or nil,
            count_stat = hangar and 'MPX_HANGAR_CONTRABAND_TOTAL' or 'MPX_CONTOTALFORWHOUSE' .. index
        })
    end

    function f:factory(index, property, bunker)
        local ref = (bunker and properties.Bunkers or properties.BikerBusinesses)[property]
        if not ref then return end
        local info = bunker and
            {
                max_units = 100,
                vpu = 'GR_MANU_PRODUCT_VALUE',
                mult_1 = 'GR_MANU_PRODUCT_VALUE_EQUIPMENT_UPGRADE',
                mult_2 =
                'GR_MANU_PRODUCT_VALUE_STAFF_UPGRADE'
            }
            or definitions.BikerTunables[ref.id]
        if not info then return end
        local equipment = stats.get_int(bunker and 'MPX_BUNKER_EQUIPMENT' or 'MPX_FACTORYUPGRADES' .. index) == 1
        local staff = stats.get_int(bunker and 'MPX_BUNKER_STAFF' or 'MPX_FACTORYUPGRADES' .. index .. '_1') == 1
        local name = bunker and self:label('MP_BUNKER_' .. (property < 28 and property - 20 or property - 19)) or
            self:label(ref.gxt)
        local normalized = not bunker and
            ({ [0] = 'BIKER_WH_5B', 'BIKER_WH_2B', 'BIKER_WH_4B', 'BIKER_WH_1B', 'BIKER_WH_3B' })[ref.id]
        return self:add({
            key = 'factory_' .. index,
            kind = 'factory',
            index = index,
            name = name,
            coords = ref.coords,
            max = info.max_units,
            normalized_name = normalized and self:label(normalized),
            vpu = tunables.get_int(info.vpu) + (equipment and tunables.get_int(info.mult_1) or 0) +
                (staff and tunables.get_int(info.mult_2) or 0),
            equipment = equipment,
            staff = staff,
            count_stat = 'MPX_PRODTOTALFORFACTORY' .. index,
            supply_stat = 'MPX_MATTOTALFORFACTORY' .. index,
            setup_stat = 'MPX_FACTORYSETUP' .. index
        })
    end

    function f:rebuild()
        self.serial = self.serial + 1; self.records = {}; self.lookup = {}; self.fronts = {}
        local hangar = stats.get_int('MPX_HANGAR_OWNED'); self:warehouse('hangar', -1, hangar, true)
        local office = stats.get_int('MPX_PROP_OFFICE') - 86
        if properties.Offices[office] then
            self.fronts.office = {
                index = office,
                name = self:label(properties.Offices[office].gxt),
                coords = properties.Offices[office].coords,
                custom = stats.get_string('MPX_GB_OFFICE_NAME') .. stats.get_string('MPX_GB_OFFICE_NAME2')
            }
            for index = 0, 4 do
                self:warehouse('cargo_' .. index, index, stats.get_int('MPX_PROP_WHOUSE_SLOT' .. index),
                    false)
            end
            local vehicle_warehouse = properties.VehicleWarehouses[stats.get_int('MPX_PROP_IE_WAREHOUSE') - 114]
            if vehicle_warehouse then
                self.fronts.vehicle_warehouse = {
                    name = self:label(vehicle_warehouse.gxt),
                    coords =
                        vehicle_warehouse.coords
                }
            end
        end
        local clubhouse = stats.get_int('MPX_PROP_CLUBHOUSE') - 90
        if properties.Clubhouses[clubhouse] then
            local ref = properties.Clubhouses[clubhouse]
            self.fronts.clubhouse = {
                index = clubhouse,
                name = self:label(ref.gxt),
                coords = ref.coords,
                custom = stats.get_string('MPX_MC_GANG_NAME') .. stats.get_string('MPX_MC_GANG_NAME2')
            }
            self:safe('clubhouse_safe', definitions.CashSafes.fronts.clubhouse, 'Clubhouse Duffle Bag', ref.coords)
            for index = 0, 4 do self:factory(index, stats.get_int('MPX_FACTORYSLOT' .. index), false) end
        end
        self:factory(5, stats.get_int('MPX_PROP_FAC_SLOT5'), true)
        if stats.get_int('MPX_XM22_LAB_OWNED') ~= 0 then
            local equipment = stats.get_int('MPX_AWD_CALLME') >=
                tunables.get_int('ACID_LAB_UPGRADE_EQUIPMENT_NUM_MISSIONS_UNLOCK')
                and stats.get_int('MPX_XM22_LAB_EQUIP_UPGRADED') == 1
            self:add({
                key = 'factory_6',
                kind = 'factory',
                index = 6,
                name = self:label('ACID_LAB_TITLE'),
                coords = Vector3.new(597.7751, -405.7288, 26.0292),
                max = 160,
                vpu = tunables.get_int('BIKER_ACID_PRODUCT_VALUE') +
                    (equipment and tunables.get_int('BIKER_ACID_PRODUCT_VALUE_EQUIPMENT_UPGRADE') or 0),
                equipment = equipment,
                count_stat = 'MPX_PRODTOTALFORFACTORY6',
                supply_stat = 'MPX_MATTOTALFORFACTORY6',
                setup_stat = 'MPX_FACTORYSETUP6'
            })
        end
        for index, metadata in ipairs(definitions.CashSafes.regular) do
            local owned = stats.get_int(metadata.property_stat)
            local ref = properties[metadata.property_key][owned]
            if ref then self:safe('safe_' .. index, metadata, self:label(ref.gxt), ref.coords) end
        end
        local nightclub = stats.get_int('MPX_NIGHTCLUB_OWNED')
        if properties.Nightclubs[nightclub] then
            local ref = properties.Nightclubs[nightclub]
            self.fronts.nightclub = {
                index = nightclub,
                name = self:label('MP_NCLU_' .. nightclub),
                coords = ref.coords,
                name_id = stats.get_int('MPX_PROP_NIGHTCLUB_NAME_ID'),
                custom = definitions.NightclubNames[stats.get_int('MPX_PROP_NIGHTCLUB_NAME_ID') + 1]
            }
            self:safe('nightclub_safe', definitions.CashSafes.fronts.nightclub, self.fronts.nightclub.custom, ref.coords)
            if stats.get_int('MPX_BUSINESSHUB_OWNED') == nightclub then
                local owned = { self.lookup.hangar ~= nil or self.lookup.cargo_0 ~= nil, self.lookup.factory_5 ~= nil }
                for _, record in ipairs(self.records) do if record.kind == 'cargo' then owned[1] = true end end
                for index = 0, 4 do owned[index + 3] = self.lookup['factory_' .. index] ~= nil end
                for index = 0, 6 do
                    if owned[index + 1] then
                        local definition = definitions.BusinessHubs[index + 1]
                        self:add({
                            key = 'hub_' .. index,
                            index = index,
                            kind = 'hub',
                            name = self:label('CLUB_STOCK' .. index),
                            max = tunables.get_int(definition.max_units_tunable),
                            vpu = tunables.get_int(definition.vpu_tunable),
                            count_stat = 'MPX_HUB_PROD_TOTAL_' .. index
                        })
                    end
                end
            end
        end
        local salvage = stats.get_int('MPX_SALVAGE_YARD_OWNED')
        if properties.SalvageYards[salvage] then
            local ref = properties.SalvageYards[salvage]
            self.fronts.salvage = { index = salvage, name = self:label(ref.gxt), coords = ref.coords }
            self:safe('salvage_safe', definitions.CashSafes.fronts.salvage_yard, self.fronts.salvage.name, ref.coords)
        end
        if stats.get_int('MPX_SB_CAR_WASH_OWNED') > 0 then
            local coords = Vector3.new(25.645266, -1412.290649, 29.362230)
            self.fronts.car_wash = { name = self:label('CELL_CWAS'), coords = coords }
            self:safe('car_wash_safe',
                {
                    cash_value_stat = 'MPX_CWASH_SAFE_CASH_VALUE',
                    paytime_stat = 'MPX_CWASH_PAY_TIME_LEFT',
                    capacity_tunable = 'TYCOON_CAR_WASH_SAFE_MAX_STORAGE_AMOUNT',
                    room_hash = 4269274169,
                    car_wash = true
                }, self.fronts.car_wash.name, coords)
            self:add({
                key = 'car_wash_duffle',
                name = 'Car Wash Duffle',
                kind = 'duffle',
                count_stat =
                'MPX_CAR_WASH_DUFFEL_VALUE',
                capacity_tunable = 564305888
            })
            for _, definition in ipairs({ { 'MPX_SB_CAR_WASH_OWNED', 'CELL_CWAS', 24924, coords },
                { 'MPX_SB_WEED_SHOP_OWNED',  'CELL_WSHOP', 24925, Vector3.new(-1162.051147, -1564.757202, 4.410227) },
                { 'MPX_SB_HELI_TOURS_OWNED', 'CELL_HELIT', 24926, Vector3.new(-753.524841, -1511.244751, 5.015130) } }) do
                if stats.get_int(definition[1]) > 0 then
                    self:add({
                        key = 'heat_' .. definition[3],
                        kind = 'heat',
                        name =
                            self:label(definition[2]),
                        heat = definition[3],
                        coords = definition[4]
                    })
                end
            end
        end
        self.next_snapshot = 0
    end

    function f:enter()
        self:rebuild(); self.actions = require('includes.ssv2.core.business_actions').new(ctx, self)
        self.extras = require('includes.ssv2.core.business_extras').new(ctx, self)
        self.view = self.view or require('includes.ssv2.core.business_view').new(ctx, self)
    end

    function f:cleanup()
        self.serial = self.serial + 1
        self.reloading = false
        if self.actions then self.actions:cleanup() end
        self.records = {}; self.lookup = {}; self.fronts = {}
    end

    function f:run(label, callback)
        local serial = self.serial
        ctx.runtime:run(label, function() if self.active and self.serial == serial then callback() end end)
    end

    function f:reload()
        if self.reloading or not self.active then return end
        self.reloading = true; self.total = 0
        local serial, generation = self.serial, ctx.runtime.generation
        ctx.runtime:run('reload businesses', function()
            script.yield(1500)
            if not self.active or self.serial ~= serial or ctx.runtime.generation ~= generation then return end
            self.actions:cleanup(); self:rebuild(); self.next_snapshot = 0; self.reloading = false
        end)
    end

    function f:fill_all()
        assert(ctx.settings:get('features.unsafe_feats_enabled'), 'Enable original unsafe feature controls first')
        for _, record in ipairs(self.records) do if record.kind == 'safe' then record:fill_safe() end end
    end

    function f:restock_all()
        for _, record in ipairs(self.records) do
            if record.kind == 'cargo' or record.kind == 'hangar' then
                record.auto = true
            elseif record.kind == 'factory' then
                record:restock()
            end
        end
    end

    function f:update(state)
        if self.reloading then return end
        local now = util.time()
        for _, record in ipairs(self.records) do record:update(state, now) end
        self.actions:update(state, now)
        self.extras:update(state, now)
        if now >= (self.next_snapshot or 0) then
            self.total = (self.extras.ie_income or 0) + (self.extras.salvage_income or 0)
            for _, record in ipairs(self.records) do
                self.total = self.total +
                    (record.snapshot and record.snapshot.value or 0)
            end
            self.next_snapshot = now + 1200
        end
    end

    function f:draw()
        if not ctx.settings:get('ui.show_businesses') then return end
        if self.failed and ImGui.Button('Retry Business Manager') then self.failed = false end
        if not self.active then
            local message = ctx.translator:text(self.status_message or 'GENERIC_WAIT_LABEL')
            if self.status == 'ERROR' then ImGui.TextColored(0.9, 0.1, 0.1, 1, message) else ImGui.Text(message) end
            return
        end
        self.view:draw()
    end

    return f
end
