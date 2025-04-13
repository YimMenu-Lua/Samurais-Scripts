---@diagnostic disable: param-type-mismatch

---@class Game
Game = {}
Game.__index = Game
Game.Version = Memory.GetGameVersion()
Game.ScreenResolution = Memory.GetScreenResolution()

---@return string, string
Game.GetLanguage = function()
    local lang_iso = "en-US"
    local lang_name = "English"
    local i_LangID = LOCALIZATION.GET_CURRENT_LANGUAGE()

    for _, _lang in ipairs(t_languageCodes) do
        if i_LangID == _lang.id then
            lang_iso = _lang.iso
            lang_name = _lang.name
            break
        end
    end

    if lang_iso == "es-MX" then
        lang_iso = "es-ES"
    end

    return lang_iso, lang_name
end

---@return integer | nil, string | nil
Game.GetKeyPressed = function()
    if PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
        return nil, nil
    end

    for _, v in ipairs(t_GamepadControls) do
        if PAD.IS_CONTROL_JUST_PRESSED(0, v.ctrl) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, v.ctrl) then
            return v.ctrl, v.gpad
        end
    end
end

---@return boolean
Game.IsOnline = function()
    return network.is_session_started() and not script.is_active("maintransition")
end

---@param value integer
---@return boolean
Game.IsScriptHandle = function(value)
    if not value or type(value) ~= "number" then
        return false
    end

    return ENTITY.DOES_ENTITY_EXIST(value)
end

---@param value integer | string
---@return boolean
Game.IsModelHash = function(value)
    if type(value) == "string" then
        value = joaat(value)
    end

    return type(value) == "number" and value >= 0xFFFF and STREAMING.IS_MODEL_VALID(value)
end

---@param input integer | string
---@return integer
Game.EnsureModelHash = function(input)
    if not input then
        return 0
    end

    if Game.IsModelHash(input) then
        if type(input) == "string" then
            return joaat(input)
        else
            return input
        end
    end

    if Game.IsScriptHandle(input) then
        return Game.GetEntityModel(input)
    end

    return 0
end

---@param entity integer
Game.DeleteEntity = function(entity)
    script.run_in_fiber(function(del)
        if not entity or entity == self.get_ped() then
            return
        end

        ENTITY.DELETE_ENTITY(entity)
        del:sleep(100)

        if ENTITY.DOES_ENTITY_EXIST(entity) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, true, true)
            ENTITY.DELETE_ENTITY(entity)
        end

        del:sleep(100)
        if ENTITY.DOES_ENTITY_EXIST(entity) then
            YimToast:ShowError(
                "Samurai's Scripts",
                ("Failed to delete entity: [%d]"):format(entity)
            )
        end
    end)
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

---@param position vec2
---@param width float
---@param height float
---@param fgCol Color | table
---@param bgCol Color | table
---@param value number
Game.DrawBar = function(position, width, height, fgCol, bgCol, value)
    local bgPaddingX = 0.005
    local bgPaddingY = 0.01
    local fg = {}
    local bg = {}

    if type(fgCol) == "table" and fgCol.r then
        fg = fgCol
    else
        fg.r, fg.g, fg.b, fg.a = fgCol:AsRGBA()
    end

    if type(bgCol) == "table" and bgCol.r then
        bg = bgCol
    else
        bg.r, bg.g, bg.b, bg.a = bgCol:AsRGBA()
    end

    -- background
    GRAPHICS.DRAW_RECT(
        position.x,
        position.y,
        width + bgPaddingX,
        height + bgPaddingY,
        bg.r,
        bg.g,
        bg.b,
        bg.a,
        false
    )

    -- foreground
    GRAPHICS.DRAW_RECT(
        position.x - width * 0.5 + value * width * 0.5,
        position.y, width * value,
        height,
        fg.r,
        fg.g,
        fg.b,
        fg.a,
        false
    )
end

---@param position vec2
---@param text string
---@param color Color | table
---@param scale vec2 | table
---@param font number
---@param center? boolean
Game.DrawText = function(position, text, color, scale, font, center)
    local col = {}

    if type(color) == "table" and color.r then
        col = color
    else
        col.r, col.g, col.b, col.a = color:AsRGBA()
    end

    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
    HUD.SET_TEXT_COLOUR(col.r, col.g, col.b, col.a)
    HUD.SET_TEXT_SCALE(scale.x, scale.y)
    HUD.SET_TEXT_OUTLINE()
    HUD.SET_TEXT_FONT(font)
    if center then
        HUD.SET_TEXT_CENTRE(true)
    else
        HUD.SET_TEXT_JUSTIFICATION(1)
    end
    HUD.SET_TEXT_DROP_SHADOW()
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(position.x, position.y, 0)
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

---@param i_entity integer
---@param v_coords vec3
---@param b_xAxis? boolean
---@param b_yAxis? boolean
---@param b_zAxis? boolean
---@param b_clearArea? boolean
Game.SetEntityCoords = function(i_entity, v_coords, b_xAxis, b_yAxis, b_zAxis, b_clearArea)
    script.run_in_fiber(function()
        ENTITY.SET_ENTITY_COORDS(
            i_entity,
            v_coords.x,
            v_coords.y,
            v_coords.z,
            b_xAxis or false,
            b_yAxis or false,
            b_zAxis or false,
            b_clearArea or false
        )
    end)
end

---@param i_entity integer
---@param v_coords vec3
---@param b_xAxis? boolean
---@param b_yAxis? boolean
---@param b_zAxis? boolean
Game.SetEntityCoordsNoOffset = function(i_entity, v_coords, b_xAxis, b_yAxis, b_zAxis)
    script.run_in_fiber(function()
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
            i_entity,
            v_coords.x,
            v_coords.y,
            v_coords.z,
            b_xAxis or false,
            b_yAxis or false,
            b_zAxis or false
        )
    end)
end

---@param model integer
---@return boolean
Game.RequestModel = function(model)
    if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_IN_CDIMAGE(model) then
        STREAMING.REQUEST_MODEL(model)

        while not STREAMING.HAS_MODEL_LOADED(model) do
            STREAMING.REQUEST_MODEL(model)
            coroutine.yield()
        end

        return STREAMING.HAS_MODEL_LOADED(model)
    end

    return false
end

---@param dict string
---@return boolean
Game.RequestNamedPtfxAsset = function(dict)
    STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)

    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict) do
        STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)
        coroutine.yield()
    end

    return STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict)
end

---@param dict string
---@return boolean
Game.RequestAnimDict = function(dict)
    STREAMING.REQUEST_ANIM_DICT(dict)

    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        coroutine.yield()
    end

    return STREAMING.HAS_ANIM_DICT_LOADED(dict)
end

---@param dict string
---@return boolean
Game.RequestTextureDict = function(dict)
    GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(dict, false)

    while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict) do
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(dict, false)
        coroutine.yield()
    end

    return GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict)
end

---@param weapon integer
---@return boolean
Game.RequestWeaponAsset = function(weapon)
    WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0)

    while not WEAPON.HAS_WEAPON_ASSET_LOADED(weapon) do
        WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0)
        coroutine.yield()
    end

    return WEAPON.HAS_WEAPON_ASSET_LOADED(weapon)
end

---@param scr string
---@return boolean
Game.RequestScript = function(scr)
    SCRIPT.REQUEST_SCRIPT(scr)

    while not SCRIPT.HAS_SCRIPT_LOADED(scr) do
        SCRIPT.REQUEST_SCRIPT(scr)
        coroutine.yield()
    end

    return SCRIPT.HAS_SCRIPT_LOADED(scr)
end

---@param entity integer
---@param isAlive boolean
---@return vec3
Game.GetEntityCoords = function(entity, isAlive)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, isAlive)

    return vec3:new(coords.x, coords.y, coords.z)
end

---@param entity integer
---@param order? integer
---@return vec3
Game.GetEntityRotation = function(entity, order)
   local v_Rot = ENTITY.GET_ENTITY_ROTATION(entity, order or 2)

   return vec3:new(v_Rot.x, v_Rot.y, v_Rot.z)
end

---@param entity integer
---@return number
Game.GetHeading = function(entity)
    return ENTITY.GET_ENTITY_HEADING(entity)
end

---@param entity integer
---@return number
Game.GetForwardX = function(entity)
    return ENTITY.GET_ENTITY_FORWARD_X(entity)
end

---@param entity integer
---@return number
Game.GetForwardY = function(entity)
    return ENTITY.GET_ENTITY_FORWARD_Y(entity)
end

---@param entity integer
---@return vec3
Game.GetForwardVector = function(entity)
    local fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)

    return vec3:new(fwdVec.x, fwdVec.y, fwdVec.z)
end

---@param ped integer
---@param boneID integer
---@return integer
Game.GetPedBoneIndex = function(ped, boneID)
    return PED.GET_PED_BONE_INDEX(ped, boneID)
end

---@param ped integer
---@param boneID integer
---@return vec3
Game.GetPedBoneCoords = function(ped, boneID)
    local boneCoords = PED.GET_PED_BONE_COORDS(ped, boneID, 0, 0, 0)

    return vec3:new(boneCoords.x, boneCoords.y, boneCoords.z)
end

---@param entity integer
---@param boneName string
---@return integer
Game.GetEntityBoneIndexByName = function(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, boneName)
end

---@param entity integer
---@param boneName string
---@return vec3
Game.GetWorldPositionOfEntityBone = function(entity, boneName)
    local boneIndex = Game.GetEntityBoneIndexByName(entity, boneName)
    local bonePos = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(entity, boneIndex)

    return vec3:new(bonePos.x, bonePos.y, bonePos.z)
end

---@param entity integer
---@param boneName string
---@return vec3
Game.GetEntityBonePos = function(entity, boneName)
    local boneIndex = Game.GetEntityBoneIndexByName(entity, boneName)
    local bonePos = ENTITY.GET_ENTITY_BONE_POSTION(entity, boneIndex)

    return vec3:new(bonePos.x, bonePos.y, bonePos.z)
end

---@param entity integer
---@param boneName string
---@return vec3
Game.GetEntityBoneRot = function(entity, boneName)
    local boneIndex = Game.GetEntityBoneIndexByName(entity, boneName)
    local boneRot = ENTITY.GET_ENTITY_BONE_ROTATION(entity, boneIndex)

    return vec3:new(boneRot.x, boneRot.y, boneRot.z)
end

---@param entity integer
---@return integer
Game.GetEntityBoneCount = function(entity)
    return ENTITY.GET_ENTITY_BONE_COUNT(entity)
end

-- Returns the entity localPlayer is aiming at.
---@param player integer
---@return integer | nil
Game.GetEntityPlayerIsFreeAimingAt = function(player)
    local bIsAiming, Entity = false, 0

    if PLAYER.IS_PLAYER_FREE_AIMING(player) then
        bIsAiming, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(self.get_id(), Entity)
    end

    return bIsAiming and Entity or nil
end

---@param entity integer
---@return integer
Game.GetEntityModel = function(entity)
    return ENTITY.GET_ENTITY_MODEL(entity)
end

---@param entity integer
---@return integer
Game.GetEntityType = function(entity)
    return ENTITY.GET_ENTITY_TYPE(entity)
end

---@param model integer
---@return vec3, vec3
Game.GetModelDimensions = function(model)
    if STREAMING.IS_MODEL_VALID(model) then
        local vmin = memory.allocate(0xC)
        local vmax = memory.allocate(0xC)
        local retVecMin, retVecMax = MISC.GET_MODEL_DIMENSIONS(model, vmin, vmax)

        memory.free(vmin)
        memory.free(vmax)

        return retVecMin, retVecMax
    end

    return vec3:zero(), vec3:zero()
end

---Returns a number for the vehicle seat the provided ped
---
---is sitting in (-1 driver, 0 front passenger, etc...).
---@param ped integer
---@return integer | nil
Game.GetPedVehicleSeat = function(ped)
    if not PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) then
        return
    end

    local vehicle  = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    local maxSeats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))

    for i = -1, maxSeats do
        if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
            if VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, true) == ped then
                return i
            end
        end
    end
end

function Game.GetPedComponents(ped)
    local variations = {}

    for i = 0, 11 do
        local max_drawables = 0
        local drawable = PED.GET_PED_DRAWABLE_VARIATION(ped, i)
        local max_textures = PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(ped, i, drawable)
        local texture  = PED.GET_PED_TEXTURE_VARIATION(ped, i)
        local palette  = PED.GET_PED_PALETTE_VARIATION(ped, i)

        for _drawable = 0, 100 do
            local count = PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(ped, i, _drawable)
            if count > 0 then
                max_drawables = max_drawables + 1
            else
                break
            end
        end

        table.insert(variations, {
            component = i,
            max_drawables = max_drawables,
            max_textures = max_textures,
            drawable = drawable,
            texture = texture,
            palette = palette
        })
    end

    return variations
end

function Game.ApplyPedComponents(ped, components)
    for _, part in ipairs(components) do
        if PED.IS_PED_COMPONENT_VARIATION_VALID(
            ped,
            part.component,
            part.drawable,
            part.texture
        ) then
            PED.SET_PED_COMPONENT_VARIATION(
                ped,
                part.component,
                part.drawable,
                part.texture,
                part.palette
            )
        end
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
---@return integer
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
---@return integer
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
---@return boolean, vec3
Game.FindObjectiveBlip = function()
    for _, v in ipairs(t_ObjectiveBlipIDs) do
        if HUD.DOES_BLIP_EXIST(HUD.GET_FIRST_BLIP_INFO_ID(v)) then
            return true, HUD.GET_BLIP_INFO_ID_COORD(HUD.GET_FIRST_BLIP_INFO_ID(v))
        else
            local i_stdBlip = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_STANDARD_BLIP_ENUM_ID())
            local vec_blipCoords = HUD.GET_BLIP_INFO_ID_COORD(i_stdBlip)

            if vec_blipCoords ~= vec3:zero() then
                return true, vec_blipCoords
            end
        end
    end

    return false, vec3:zero()
end

---@param area vec3
---@param radius number
---@param isFree boolean
---@return boolean, string
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

    return false, ""
end

-- Starts a Line Of Sight world probe shape test.
---@param src vec3
---@param dest vec3
---@param traceFlags integer
---@return boolean, vec3, integer
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
    local _, hit, retEntityHit, retEndCoords = 0, false, 0, vec3:zero()
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
---@param offset? float
Game.World.MarkSelectedEntity = function(entity, offset)
    script.run_in_fiber(function()
        -- if not ENTITY.IS_ENTITY_ATTACHED(entity) then
            local entity_hash  = ENTITY.GET_ENTITY_MODEL(entity)
            local entity_pos   = ENTITY.GET_ENTITY_COORDS(entity, false)
            local min, max     = Game.GetModelDimensions(entity_hash)
            local entityHeight = max.z - min.z

            if not offset then
                offset = 0.4
            end

            GRAPHICS.DRAW_MARKER(
                2,
                entity_pos.x,
                entity_pos.y,
                entity_pos.z + entityHeight + offset,
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
        -- end
    end)
end
