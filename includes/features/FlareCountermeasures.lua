FlareCountermeasures = {
    active = false,
    shots = {},
    nextShotTime = 0,
}

function FlareCountermeasures:Deploy()
    if not Self.IsDriving() or not (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) then
        return
    end

    if self.active then
        return
    end

    local veh = Self.Vehicle.Current
    local firstDelay = 200

    self.active = true
    self.shots = {}
    self.nextShotTime = MISC.GET_GAME_TIMER() + firstDelay

    for _, bone in pairs(ePlaneBones) do
        local bone_idx = Game.GetEntityBoneIndexByName(veh, bone)

        if bone_idx ~= -1 then
            for i = 1, 2 do
                table.insert(self.shots, {
                    bone_idx = bone_idx,
                    offset = (i == 2) and vec3:new(-10, -10, -10) or vec3:zero()
                })
            end
        end
    end
end

function FlareCountermeasures:Update()
    if not self.active then
        return
    end

    local now = MISC.GET_GAME_TIMER()
    local veh = Self.GetVehicle()

    while now >= self.nextShotTime and #self.shots > 0 do
        local shot = table.remove(self.shots, 1)
        local distance = math.random(10, 50)
        local bone_pos = Game.GetEntityBonePos(veh, self.shots.bone_idx)
        local vehPos = Game.GetEntityCoords(veh, false)
        local backwardOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0.0, -1.0, 0.0)
        local rightOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 1.0, 0.0, 0.0)
        local upOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0.0, 0.0, 1.0)
        local spreadStrengthRight = (math.random() - 0.5) * 2
        local spreadStrengthUp = (math.random() - 0.5) * 2

        local backward = vec3:new(
            backwardOffset.x - vehPos.x,
            backwardOffset.y - vehPos.y,
            backwardOffset.z - vehPos.z
        ):normalize()

        local right = vec3:new(
            rightOffset.x - vehPos.x,
            rightOffset.y - vehPos.y,
            rightOffset.z - vehPos.z
        ):normalize()

        local up = vec3:new(
            upOffset.x - vehPos.x,
            upOffset.y - vehPos.y,
            upOffset.z - vehPos.z
        ):normalize()

        local direction = vec3:new(
            backward.x + (right.x * spreadStrengthRight) + (up.x * spreadStrengthUp),
            backward.y + (right.y * spreadStrengthRight) + (up.y * spreadStrengthUp),
            backward.z + (right.z * spreadStrengthRight) + (up.z * spreadStrengthUp)
        ):normalize()

        local end_pos = vec3:new(
            bone_pos.x + shot.offset.x + direction.x * distance,
            bone_pos.y + shot.offset.y + direction.y * distance,
            bone_pos.z + shot.offset.z + direction.z * distance
        )

        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
            bone_pos.x + shot.offset.x,
            bone_pos.y + shot.offset.y,
            bone_pos.z + shot.offset.z,
            end_pos.x,
            end_pos.y,
            end_pos.z,
            1.0,
            false,
            0x47757124,
            Self.GetPedID(),
            true,
            false,
            100.0
        )
        AUDIO.PLAY_SOUND_FRONTEND(-1, "HIT_OUT", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
        self.nextShotTime = self.nextShotTime + 200
    end

    if #self.shots == 0 then
        self.active = false
    end
end
