local Pool = require('includes.ssv2.core.entity_pool')
local Preview = {}; Preview.__index = Preview
function Preview.new(ctx)
    return setmetatable({ ctx = ctx, pool = Pool.new(ctx), serial = 0, failed_models = {} },
        Preview)
end

function Preview:request(model, kind)
    if self.failed_models[model] then return end
    self.touched = util.time()
    if self.model ~= model or self.kind ~= kind then
        self.serial = self.serial + 1; self.model, self.kind, self.requested = model, kind, util.time()
    end
end

function Preview:update(state, visible)
    if not visible then
        self:clear(); return
    end
    if self.model and (not self.current or self.current.model ~= self.model) and util.time() - self.requested >= 200 and not self.pending then
        local serial, generation, model, kind = self.serial, self.ctx.runtime.generation, self.model, self.kind
        self.pending = true
        self.ctx.runtime:run('entity_preview', function()
            local function valid()
                return self.ctx.runtime.running and self.ctx.runtime.generation == generation and
                    self.serial == serial
            end
            local ok, err = pcall(function()
                if self.current then
                    self.pool:delete(self.current.handle); self.current = nil
                end
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 1, 5, 0)
                local found, height = self.ctx.game.ground_z(pos, true)
                pos.z = (found and height or pos.z) + 1
                local entry = self.pool:create(kind, model, pos, ENTITY.GET_ENTITY_HEADING(state.handle), valid, false,
                    false)
                if not entry then return end
                ENTITY.SET_ENTITY_ALPHA(entry.handle, 150, false); ENTITY.SET_ENTITY_INVINCIBLE(entry.handle, true)
                ENTITY.FREEZE_ENTITY_POSITION(entry.handle, true); ENTITY.SET_ENTITY_COLLISION(entry.handle, false, false)
                if kind == 'ped' then
                    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entry.handle, true); TASK
                        .TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entry.handle, true)
                end
                if kind == 'vehicle' then VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(entry.handle, 5) end
                if network.is_session_started() and not self.ctx.game.control(entry.handle, 250, valid) then
                    self.pool:delete(entry.handle); return
                end
                self.current = entry
            end)
            self.pending = false
            if not ok and self.serial == serial then
                self.failed_models[model] = true; self.model = nil
                log.warn('[PreviewService]: Failed to load/create model (' .. tostring(model) .. '): ' .. tostring(err))
            end
        end)
    end
    if self.current and self.pool:exists(self.current) then
        local handle = self.current.handle
        ENTITY.SET_ENTITY_HEADING(handle, (ENTITY.GET_ENTITY_HEADING(handle) - 0.3) % 360)
        if ENTITY.GET_ENTITY_SPEED(state.handle) > 0.1 then
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 1, 5, 0)
            local found, height = self.ctx.game.ground_z(pos)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(handle, pos.x, pos.y, (found and height or pos.z) + 1, false, false, false)
        end
        if self.current.kind == 'vehicle' and not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(handle) then
            VEHICLE
                .SET_VEHICLE_ON_GROUND_PROPERLY(handle, 5)
        end
    end
end

function Preview:clear()
    if self.model or self.current or self.pending then self.serial = self.serial + 1 end
    self.model = nil; self.current = nil; self.pool:clear()
end

return Preview
