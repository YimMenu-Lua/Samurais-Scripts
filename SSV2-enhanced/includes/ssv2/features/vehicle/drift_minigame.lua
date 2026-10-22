local Feature = require('includes.ssv2.core.feature')
local collided = require('includes.ssv2.core.collision')
local text = require('includes.ssv2.core.hud_text')
local multipliers = { { 1500, 1 }, { 3000, 2 }, { 6000, 5 }, { 12000, 10 } }
local sp_characters = { [225514697] = 0, [2602752943] = 1, [2608926626] = 2 }
return function(ctx)
    local root = 'features.vehicle.drift_minigame'
    local f = Feature.new(ctx, {
        id = 'drift_minigame',
        category = 'vehicle',
        scope = 'player',
        path = root .. '.enabled',
        points = 0,
        extra = 0,
        threshold = 0,
        multiplier = 1,
        straight = 0,
        playing = false,
        controls = { { kind = 'toggle', path = root .. '.enabled', label = 'VEH_DRIFT_MINIGAME',  tooltip = 'VEH_DRIFT_MINIGAME_TT' },
            { kind = 'toggle', path = root .. '.score_sound', label = 'VEH_DRIFT_MINIGAME_SOUND_OPT', tooltip = 'VEH_DRIFT_MINIGAME_SOUND_OPT_TT' } }
    })
    function f:ready(state) return state.car or self.playing or self.phase ~= nil end

    function f:cleanup()
        self.points, self.extra, self.threshold, self.multiplier, self.straight, self.playing = 0, 0, 0, 1, 0, false
        self.phase, self.extra_text, self.streak, self.extra_until = nil, nil, nil, nil
        self.has_crashed = false; self.vehicle = nil
    end

    function f:display(now)
        if self.points == 0 then return end
        local height = self.phase == 'banking' and 0.67 + 0.03 * math.sin(now / 120) or 0.7
        local points = tostring(math.floor(self.points)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
        local caption = (self.streak or '') .. (self.has_crashed and self.multiplier == 1 and '' or '\n+' .. points .. ' pts')
        text(0.5, 0.03, caption, height, { 255, 192, 0, 200 }, 7)
        if self.extra_text and now < (self.extra_until or 0) then
            text(0.5, 0.12, self.extra_text, 0.4, { 255, 192, 0, 200 },
                7)
        end
    end

    function f:bank(state, now)
        if not network.is_session_started() and self.points > 100 then
            local character = sp_characters[ENTITY.GET_ENTITY_MODEL(state.handle) % 4294967296]
            if character ~= nil then
                local name = 'SP' .. character .. '_TOTAL_CASH'
                local value = stats.get_int(name) + math.floor(self.points / 10)
                if value <= 2147483647 then stats.set_int(name, value) end
                AUDIO.PLAY_SOUND_FRONTEND(-1, 'LOCAL_PLYR_CASH_COUNTER_INCREASE', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS',
                    true)
            end
        end
        if self.points > ctx.settings:get(root .. '.player_best') then
            ctx.settings:set(root .. '.player_best', math.floor(self.points))
            ctx.notifier:success(ctx.translator:text('VEH_DRIFT_MINIGAME'),
                ctx.translator:text('VEH_DRIFT_MINIGAME_NEW_PB'))
        end
        self.streak = ctx.translator:text('VEH_DRIFT_MINIGAME_BANKED_PTS')
        self.phase, self.until_time = 'banked', now + 3000
    end

    function f:lose(now, force)
        self.extra = 0
        if self.multiplier > 1 and not force then
            for index = #multipliers, 2, -1 do
                if multipliers[index][2] == self.multiplier then
                    self.threshold, self.multiplier = multipliers[index - 1][1], multipliers[index - 1][2]; break
                end
            end
            self.extra_text, self.extra_until = ctx.translator:text('VEH_DRIFT_MINIGAME_PENALTY'), now + 3000
            self.phase, self.until_time = 'penalty', now + 250
        else
            self.streak = ctx.translator:text('VEH_DRIFT_MINIGAME_STREAK_LOST')
            self.phase, self.until_time = 'lost', now + 3000
        end
    end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        if state.car then
            if self.vehicle and self.vehicle ~= state.vehicle_handle then self:cleanup() end
            self.vehicle = state.vehicle_handle
        end
        if self.phase == 'lost' or self.phase == 'banked' or self.phase == 'penalty' then
            self:display(now)
            if now >= self.until_time then
                if self.phase == 'penalty' then self.phase = nil else self:cleanup() end
            end
            return
        end
        if self.playing and (not state.driving or state.vehicle:get_gear() < 1 or not state.alive) then
            self:lose(now, true); return
        end
        if not state.driving or not state.alive then return end
        local speed = ENTITY.GET_ENTITY_SPEED(state.vehicle_handle)
        local angle = math.abs(ENTITY.GET_ENTITY_SPEED_VECTOR(state.vehicle_handle, true).x)
        local drift = VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(state.vehicle_handle) and angle >= 6
        if self.phase == 'banking' then
            if collided(state.vehicle_handle) then
                self:lose(now, false)
            elseif drift then
                self.phase, self.straight = nil, 0
            elseif now >= self.until_time then
                self:bank(state, now)
            end
            self:display(now); return
        end
        if drift then
            self.playing, self.straight = true, 0
            if ctx.settings:get(root .. '.score_sound') then
                AUDIO.PLAY_SOUND_FRONTEND(-1, 'NAV_LEFT_RIGHT',
                    'HUD_FREEMODE_SOUNDSET', false)
            end
        elseif angle < 2 and speed > 0.1 then
            self.straight = self.straight + 1
        else
            self.straight = 0
        end
        if not self.playing then return end
        if self.straight == 0 then self.threshold = self.threshold + math.floor(speed / 10) end
        self.multiplier = 1
        for _, stage in ipairs(multipliers) do if self.threshold >= stage[1] then self.multiplier = stage[2] end end
        local angle_label = angle > 15 and 'VEH_DRIFT_MINIGAME_SICK_ANGLE' or angle > 12 and
            'VEH_DRIFT_MINIGAME_BIG_ANGLE' or 'VEH_DRIFT_MINIGAME_DRIFT_LABEL'
        self.streak = ctx.translator:text(angle_label) .. '   x' .. self.multiplier
        local hit, bonus = collided(state.vehicle_handle)
        self.has_crashed = hit
        if speed > 5 and not hit then
            local height = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(state.vehicle_handle)
            if height > 1 then
                bonus = ctx.translator:text(height >= 5 and 'VEH_DRIFT_MINIGAME_BIG_AIR' or 'VEH_DRIFT_MINIGAME_AIR')
            end
            if bonus ~= '' then
                self.extra = self.extra + (height >= 5 and 5 or 1)
                self.extra_text = bonus .. '  +' .. self.extra
                self.extra_until = now + 3000
            end
        end
        self.points = self.points + self.extra + (angle > 15 and 10 or angle > 12 and 5 or 1) * self.multiplier
        if hit then
            if self.multiplier < 2 then self.streak = bonus end; self:lose(now, false)
        elseif self.straight > 100 or speed <= 0.1 then
            self.phase, self.until_time = 'banking', now + 5000
        end
        self:display(now)
    end

    function f:draw()
        ImGui.Text(ctx.translator:text('VEH_DRIFT_MINIGAME_PB_LABEL') ..
            ': ' .. ctx.settings:get(root .. '.player_best'))
    end

    return f
end
