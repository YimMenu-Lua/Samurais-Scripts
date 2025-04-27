---@diagnostic disable: undefined-global, lowercase-global

DriftMinigame = {
    isDrifting = false,
    crashed = false,
    points = 0,
    multiplier = 1,
    extraPoints = 0,
    driftTime = 0,
    straightCounter = 0,
    streakText = "",
    extraText = "",
    personalBest = driftPB or CFG:ReadItem("driftPB"),
    lastCrash = 0,
    extraTextTimeout = 0,
    textSizeY = 0.7
}

function DriftMinigame:ResetStreak()
    self.textSizeY = 0.7
    if self.crashed then
        self.extraPoints = 0
        self.extraText = ""
        Sleep(2000)
    end

    self.streakText = "Streak Lost!"

    Sleep(3000)
    self.points = 0
    self.multiplier = 1
    self.isDrifting = false
    self.streakText = ""
    self.crashed = false
end

function DriftMinigame:PlayIncrementSound()
    if driftScoreSound then
        UI.WidgetSound("Nav")
    end
end

function DriftMinigame:Update()
    if not (Self.IsDriving() and Self.Vehicle.IsCar and driftMinigame and not self.crashed) then
        self:ResetStreak()
        self.driftTime = 0
        return
    end

    local veh = Self.Vehicle.Current
    local speedVec = ENTITY.GET_ENTITY_SPEED_VECTOR(veh, true)
    local speed = ENTITY.GET_ENTITY_SPEED(veh)
    local height = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(veh)
    local localCrashText = ""

    self.crashed, localCrashText = Game.Vehicle.HasCrashed()

    if Self.Vehicle.IsDrifting then
        self.textSizeY = 0.7
        self.isDrifting = true
        self.streakText = string.format("Drift   x%d", self.multiplier)
        self.points = self.points + (1 * self.multiplier)
        self.straightCounter = 0
        self:PlayIncrementSound()
    end

    if math.abs(speedVec.x) > 11 then
        self.streakText = string.format("Big Angle!   x%d", self.multiplier)
        self.points = self.points + (5 * self.multiplier)
    end

    if math.abs(speedVec.x) > 14 then
        self.streakText = string.format("SICK ANGLE!   x%d", self.multiplier)
        self.points = self.points + (10 * self.multiplier)
    end

    if math.abs(speedVec.x) < 2 and not VEHICLE.IS_VEHICLE_STOPPED(veh) then
        self.straightCounter = self.straightCounter + 1
    else
        self.straightCounter = 0
    end

    if self.straightCounter == 0 and self.isDrifting then
        self.driftTime = self.driftTime + 1
    else
        self.driftTime = 0
    end

    if self.driftTime >= 10 and self.driftTime < 30 then
        self.multiplier = 1
    elseif self.driftTime >= 30 and self.driftTime < 60 then
        self.multiplier = 2
    elseif self.driftTime >= 60 and self.driftTime < 120 then
        self.multiplier = 5
    elseif self.driftTime >= 120 then
        self.multiplier = 10
    end

    if speed > 5 and not self.crashed then
        if height > 1 and height < 5 then
            self.extraPoints = self.extraPoints + 1
            self.points = self.points + self.extraPoints
            self.extraText = string.format("Air  +%d pts", self.extraPoints)
        elseif height >= 5 then
            self.extraPoints = self.extraPoints + 5
            self.points = self.points + self.extraPoints
            self.extraText = string.format("Big Air!  +%d pts", self.extraPoints)
        end

        if localCrashText ~= "" then
            self.extraPoints = self.extraPoints + 1
            self.extraText = string.format("%s  +%d", localCrashText, self.extraPoints)
            self.extraTextTimeout = MISC.GET_GAME_TIMER() + 3000
        end
    end

    if self.crashed then
        self.textSizeY = 0.7
        self.streakText = localCrashText
        self:ResetStreak()
    elseif self.straightCounter > 100 or VEHICLE.IS_VEHICLE_STOPPED(veh) then
        local timer = Timer.new(5000)

        while not timer:isDone() do
            if not Self.IsDriving() then
                self:ResetStreak()
                return
            end

            if Self.Vehicle.IsDrifting or ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(veh) then
                timer:reset(3000)
                return
            end

            local pulse = 0.67 + 0.03 * math.sin(MISC.GET_GAME_TIMER() / 120)
            self.textSizeY = pulse
            Sleep(16)
        end

        self.streakText = "Banked Points: "

        if not Game.IsOnline() and self.points > 100 then
            BankDriftPoints_SP(Lua_fn.Round((self.points / 10), 0))
        end

        if self.points > self.personalBest then
            self.personalBest = self.points
            driftPB = self.points
            CFG:SaveItem("driftPB", self.points)
            YimToast:ShowSuccess(
                "Samurai's Scripts",
                "Drift Minigame: New personal best achieved!"
            )
        end

        Sleep(3000)
        self.streakText = ""
        self.points = 0
        self.extraPoints = 0
        self.multiplier = 1
        self.isDrifting = false
    end
end

function DriftMinigame:Draw()
    if not Self.IsDriving() or not self.isDrifting then
        return
    end

    if self.points > 0 then
        local driftText = not self.crashed and string.format("%s\n+%s pts", self.streakText, Lua_fn.SeparateInt(self.points)) or self.streakText
        local col = Col(255, 192, 0, 200)

        Game.DrawText(
            vec2:new(0.5, 0.03),
            driftText,
            col,
            vec2:new(1, self.textSizeY),
            7,
            true
        )

        if ((self.extraText ~= "") and (MISC.GET_GAME_TIMER() < self.extraTextTimeout)) then
            Game.DrawText(
                vec2:new(0.5, 0.12),
                self.extraText,
                col,
                vec2:new(1, 0.4),
                7,
                true
            )
        end
    end
end
