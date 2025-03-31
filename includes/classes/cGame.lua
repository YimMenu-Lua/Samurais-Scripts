---@diagnostic disable: param-type-mismatch

---@class Game
Game = {}
Game.__index = Game
Game.Version = Memory.GetGameVersion()
Game.ScreenResolution = Memory.GetScreenResolution()

Game.GetLanguage = function()
    local lang_iso, lang_name
    local lang = LOCALIZATION.GET_CURRENT_LANGUAGE()
    for _, l in ipairs(t_languageCodes) do
        if lang == l.id then
            lang_iso  = l.iso
            lang_name = l.name
            break
        else
            lang_iso  = "en-US"
            lang_name = "English"
        end
    end
    if lang_iso == "es-MX" then
        lang_iso = "es-ES"
    end
    return lang_iso, lang_name
end

Game.GetKeyPressed = function()
    local btn, gpad
    for _, v in ipairs(t_GamepadControls) do
        if PAD.IS_CONTROL_JUST_PRESSED(0, v.ctrl) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, v.ctrl) then
            btn, gpad = v.ctrl, v.gpad
        end
    end
    if not PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
        return btn, gpad
    else
        return nil, nil
    end
end

Game.IsOnline = function()
    return network.is_session_started() and not script.is_active("maintransition")
end

---@param text string
---@param type integer
Game.BusySpinnerOn = function(text, type)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(type)
end

Game.BusySpinnerOff = function()
    HUD.BUSYSPINNER_OFF()
end

---@param text string
Game.ShowButtonPrompt = function(text)
    if not HUD.IS_HELP_MESSAGE_ON_SCREEN() then
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_HELP("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
        HUD.END_TEXT_COMMAND_DISPLAY_HELP(0, false, true, -1)
    end
end

---@param posX float
---@param posY float
---@param width float
---@param height float
---@param fgCol table
---@param bgCol table
---@param value number
Game.DrawBar = function(posX, posY, width, height, fgCol, bgCol, value)
    local bgPaddingX = 0.005
    local bgPaddingY = 0.01
    -- background
    GRAPHICS.DRAW_RECT(posX, posY, width + bgPaddingX, height + bgPaddingY, bgCol.r, bgCol.g, bgCol.b, bgCol.a, false)

    -- foreground
    GRAPHICS.DRAW_RECT(posX - width * 0.5 + value * width * 0.5, posY, width * value, height, fgCol.r, fgCol.g, fgCol.b,
        fgCol.a, false)
end

---@param posX float
---@param PosY float
---@param text string
---@param col table
---@param scale vec2 | table
---@param font number
Game.DrawText = function(posX, PosY, text, col, scale, font)
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("TWOSTRINGS")
    HUD.SET_TEXT_COLOUR(col.r, col.g, col.b, col.a)
    HUD.SET_TEXT_SCALE(scale.x, scale.y)
    HUD.SET_TEXT_OUTLINE()
    HUD.SET_TEXT_FONT(font)
    HUD.SET_TEXT_CENTRE(true)
    HUD.SET_TEXT_DROP_SHADOW()
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(posX, PosY, 0)
end

---@param entity integer
Game.AddBlipForEntity = function(entity)
    HUD.ADD_BLIP_FOR_ENTITY(entity)
end

-- Full list of blip icon IDs: https://wiki.rage.mp/index.php?title=Blips
---@param blip integer
---@param icon integer
Game.SetBlipIcon = function(blip, icon)
    HUD.SET_BLIP_SPRITE(blip, icon)
end

-- Sets a custom name for a blip. Custom names appear on the pause menu and the world map.
---@param blip integer
---@param name string
Game.SetBlipName = function(blip, name)
    HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
    HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
end

---@param model integer
Game.RequestModel = function(model)
    if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_IN_CDIMAGE(model) then
        while not STREAMING.HAS_MODEL_LOADED(model) do
            STREAMING.REQUEST_MODEL(model)
            coroutine.yield()
        end
        return STREAMING.HAS_MODEL_LOADED(model)
    end

    return false
end

---@param dict string
Game.RequestNamedPtfxAsset = function(dict)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict) do
        STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)
        coroutine.yield()
    end

    return STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict)
end

---@param dict string
Game.RequestAnimDict = function(dict)
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        coroutine.yield()
    end
    return STREAMING.HAS_ANIM_DICT_LOADED(dict)
end

---@param dict string
Game.RequestTextureDict = function(dict)
    while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict) do
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(dict, false)
        coroutine.yield()
    end
    return GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict)
end

---@param weapon integer
Game.RequestWeaponAsset = function(weapon)
    while not WEAPON.HAS_WEAPON_ASSET_LOADED(weapon) do
        WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0)
        coroutine.yield()
    end
    return WEAPON.HAS_WEAPON_ASSET_LOADED(weapon)
end

---@param scr string
Game.RequestScript = function(scr)
    while not SCRIPT.HAS_SCRIPT_LOADED(scr) do
        SCRIPT.REQUEST_SCRIPT(scr)
        coroutine.yield()
    end
    return SCRIPT.HAS_SCRIPT_LOADED(scr)
end

---@param entity integer
---@param isAlive boolean
Game.GetCoords = function(entity, isAlive)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, isAlive)
    return vec3:new(coords.x, coords.y, coords.z)
end

---@param entity integer
Game.GetHeading = function(entity)
    return ENTITY.GET_ENTITY_HEADING(entity)
end

---@param entity integer
Game.GetForwardX = function(entity)
    return ENTITY.GET_ENTITY_FORWARD_X(entity)
end

---@param entity integer
Game.GetForwardY = function(entity)
    return ENTITY.GET_ENTITY_FORWARD_Y(entity)
end

---@param entity integer
Game.GetForwardVector = function(entity)
    local fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)
    return vec3:new(fwdVec.x, fwdVec.y, fwdVec.z)
end

---@param ped integer
---@param boneID integer
Game.GetPedBoneIndex = function(ped, boneID)
    return PED.GET_PED_BONE_INDEX(ped, boneID)
end

---@param ped integer
---@param boneID integer
Game.GetPedBoneCoords = function(ped, boneID)
    return PED.GET_PED_BONE_COORDS(ped, boneID, 0, 0, 0)
end

---@param entity integer
---@param boneName string
Game.GetEntityBoneIndexByName = function(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, boneName)
end

---@param entity integer
---@param boneName string
Game.GetWorldPosFromEntityBone = function(entity, boneName)
    local boneIndex = Game.GetEntityBoneIndexByName(entity, boneName)
    return ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(entity, boneIndex)
end

---@param entity integer
---@param boneName string
Game.GetEntityBonePos = function(entity, boneName)
    local boneIndex = Game.GetEntityBoneIndexByName(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_POSTION(entity, boneIndex)
end

---@param entity integer
---@param boneName string
Game.GetEntityBoneRot = function(entity, boneName)
    local boneIndex = Game.GetEntityBoneIndexByName(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_ROTATION(entity, boneIndex)
end

---@param entity integer
Game.GetEntityBoneCount = function(entity)
    return ENTITY.GET_ENTITY_BONE_COUNT(entity)
end

---Returns the entity localPlayer is aiming at.
Game.GetEntityPlayerIsFreeAimingAt = function()
    local Entity = 0
    if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
        _, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), Entity)
    end
    return Entity
end

---Gets the hash from an entity handle.
---@param entity integer
Game.GetEntityModel = function(entity)
    return ENTITY.GET_ENTITY_MODEL(entity)
end

---@param model integer
Game.GetModelDimensions = function(model)
    if STREAMING.IS_MODEL_VALID(model) then
        local vmin = memory.allocate(0xC)
        local vmax = memory.allocate(0xC)
        local retVecMin, retVecMax = MISC.GET_MODEL_DIMENSIONS(model, vmin, vmax)
        memory.free(vmin)
        memory.free(vmax)
        return retVecMin, retVecMax
    end

    return vec3:new(0, 0, 0), vec3:new(0, 0, 0)
end

---Returns a number for the vehicle seat the provided ped
---
---is sitting in (-1 driver, 0 front passenger, etc...).
---@param ped integer
Game.GetPedVehicleSeat = function(ped)
    if PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) then
        ---@type integer
        local pedSeat
        local vehicle  = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        local maxSeats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
        for i = -1, maxSeats do
            if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
                local sittingPed = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, true)
                if sittingPed == ped then
                    pedSeat = i
                    break
                end
            end
        end
        return pedSeat
    end
end

-- Returns a handle for the closest vehicle to a provided entity or coordinates.
--
-- Param `excludeEntity` is not necessary but can be used to ignore a specific vehicle
--
-- using its entity handle .
---@param closeTo integer | vec3
---@param range integer
---@param excludeEntity? integer
Game.GetClosestVehicle = function(closeTo, range, excludeEntity)
    local thisPos = type(closeTo) == "number" and ENTITY.GET_ENTITY_COORDS(closeTo, false) or closeTo
    if VEHICLE.IS_ANY_VEHICLE_NEAR_POINT(thisPos.x, thisPos.y, thisPos.z, range) then
        local veh_handles = entities.get_all_vehicles_as_handles()

        for i = 0, #veh_handles do
            if excludeEntity and veh_handles[i] == excludeEntity then
                i = i + 1
            end
            local vehPos = ENTITY.GET_ENTITY_COORDS(veh_handles[i], true)
            local vDist2 = SYSTEM.VDIST2(thisPos.x, thisPos.y, thisPos.z, vehPos.x, vehPos.y, vehPos.z)
            if vDist2 <= range and math.floor(VEHICLE.GET_VEHICLE_BODY_HEALTH(veh_handles[i])) > 0 then
                return veh_handles[i]
            end
        end
    end

    return 0
end

-- Returns a handle for the closest human ped to a provided entity or coordinates.
--
-- Does not return your own ped.
---@param closeTo integer | vec3
---@param range integer
---@param aliveOnly boolean
Game.GetClosestPed = function(closeTo, range, aliveOnly)
    local thisPos = type(closeTo) == 'number' and ENTITY.GET_ENTITY_COORDS(closeTo, false) or closeTo

    if PED.IS_ANY_PED_NEAR_POINT(thisPos.x, thisPos.y, thisPos.z, range) then
        for _, ped in ipairs(entities.get_all_peds_as_handles()) do
            if PED.IS_PED_HUMAN(ped) and (ped ~= Self.GetPedID()) then
                local pedPos = ENTITY.GET_ENTITY_COORDS(ped, true)
                local vDist2 = SYSTEM.VDIST2(thisPos.x, thisPos.y, thisPos.z, pedPos.x, pedPos.y, pedPos.z)
                if vDist2 <= range then
                    if aliveOnly then
                        if not ENTITY.IS_ENTITY_DEAD(ped, false) then
                            return ped
                        end
                    else
                        return ped
                    end
                end
            end
        end
    end

    return 0
end

-- Temporary workaround to fix auto-pilot's "fly to objective" option.
Game.FindObjectiveBlip = function()
    for _, v in ipairs(t_ObjectiveBlipIDs) do
        if HUD.DOES_BLIP_EXIST(HUD.GET_FIRST_BLIP_INFO_ID(v)) then
            return true, HUD.GET_BLIP_INFO_ID_COORD(HUD.GET_FIRST_BLIP_INFO_ID(v))
        else
            local i_stdBlip      = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_STANDARD_BLIP_ENUM_ID())
            local vec_blipCoords = HUD.GET_BLIP_INFO_ID_COORD(i_stdBlip)

            if vec_blipCoords ~= vec3:new(0, 0, 0) then
                return true, vec_blipCoords
            end
        end
    end

    return false
end

---@param area vec3
---@param radius number
---@param isFree boolean
Game.DoesHumanScenarioExistInArea = function(area, radius, isFree)
    for _, v in ipairs(t_PedScenarios) do
        if TASK.DOES_SCENARIO_OF_TYPE_EXIST_IN_AREA(
            area.x,
            area.y,
            area.z,
            v.scenario,
            radius,
            isFree
        ) then
            return true, v.name
        end
    end

    return false
end

-- Starts a Line Of Sight world probe shape test.
---@param src vec3
---@param dest vec3
---@param traceFlags integer
Game.RayCast = function(src, dest, traceFlags, entityToExclude)
    local rayHandle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
        src.x,
        src.y,
        src.z,
        dest.x,
        dest.y,
        dest.z,
        traceFlags,
        entityToExclude,
        7
    )

    local endCoords = memory.allocate(0xC)
    local surfaceNormal = memory.allocate(0xC)
    local entityHit = 0
    local _, hit, retEntityHit, retEndCoords = 0, false, 0, vec3:new(0, 0, 0)
    _, hit, retEndCoords, _, retEntityHit = SHAPETEST.GET_SHAPE_TEST_RESULT(
        rayHandle,
        hit,
        endCoords,
        surfaceNormal,
        entityHit
    )

    memory.free(endCoords)
    memory.free(surfaceNormal)
    return hit, retEndCoords, retEntityHit
end

---@class Game.World
Game.World = {}
Game.World.__index = Game.World

---@param toggle boolean
Game.World.ExtendBounds = function(toggle)
    if toggle then
        PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(-42069420.0, -42069420.0, -42069420.0)
        PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(42069420.0, 42069420.0, 42069420.0)
    else
        PLAYER.RESET_WORLD_BOUNDARY_FOR_PLAYER()
    end
end

---@param toggle boolean
Game.World.DisableOceanWaves = function(toggle)
    MISC.WATER_OVERRIDE_SET_STRENGTH(toggle and 1.0 or -1)
end

-- Draws a green chevron down element on top of an entity in the game world.
---@param entity integer
Game.World.MarkSelectedEntity = function(entity)
    script.run_in_fiber(function()
        if not ENTITY.IS_ENTITY_ATTACHED(entity) then
            local entity_hash  = ENTITY.GET_ENTITY_MODEL(entity)
            local entity_pos   = ENTITY.GET_ENTITY_COORDS(entity, false)
            local min, max     = Game.GetModelDimensions(entity_hash)
            local entityHeight = max.z - min.z
            GRAPHICS.DRAW_MARKER(
                2,
                entity_pos.x,
                entity_pos.y,
                entity_pos.z + (entityHeight + 0.4),
                0,
                0,
                0,
                0,
                180,
                0,
                0.3,
                0.3,
                0.3,
                0,
                255,
                0,
                100,
                true,
                true,
                1,
                false,
                0,
                0,
                false
            )
        end
    end)
end
