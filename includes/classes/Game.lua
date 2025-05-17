---@diagnostic disable: param-type-mismatch, undefined-global, lowercase-global

---@class Game
Game = {}
Game.__index = Game
Game.Version = Memory.GetGameVersion()
Game.ScreenResolution = Memory.GetScreenResolution()
Game.MaxEntities = {
    objects = 75,
    peds = 50,
    vehicles = 25,
}

---@return string, string
Game.GetLanguage = function()
    local lang_iso = "en-US"
    local lang_name = "English"
    local i_LangID = LOCALIZATION.GET_CURRENT_LANGUAGE()

    for _, _lang in ipairs(t_Locales) do
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

---@param handle integer
---@return boolean
Game.IsScriptHandle = function(handle)
    if not handle or type(handle) ~= "number" then
        return false
    end

    return ENTITY.DOES_ENTITY_EXIST(handle)
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

---@param category string
Game.CanCreateEntity = function(category)
    local currentCount = 0

    for _ in pairs(g_SpawnedEntities[category]) do
        currentCount = currentCount + 1
    end

    return currentCount < (Game.MaxEntities[category] or math.huge)
end

---@param i_ModelHash integer
---@param v_SpawnPos vec3
---@param i_Heading? integer
---@param b_Networked? boolean
---@param b_SriptHostPed? boolean
Game.CreatePed = function(i_ModelHash, v_SpawnPos, i_Heading, b_Networked, b_SriptHostPed)
    if not Game.CanCreateEntity("peds") then
        if not b_AutoCleanupEntities then
            YimToast:ShowError(
                "Samurai's Scripts",
                "Ped spawn limit reached! Consider enabling 'Auto Replace Entities' in the Settings tab if you want to automatically replace old entities when you reach the limit.",
                true,
                5
            )
            return 0
        end

        local oldest = table.remove(g_SpawnedEntities.peds, 1)
        Game.DeleteEntity(oldest, "peds")
    end

    if not Await(Game.RequestModel, i_ModelHash) then
        return 0
    end

    if (i_ModelHash == joaat("A_C_Boar_02"))
    and Self.IsOutside()
    and Self.IsOnFoot()
    and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
    and not g_WompusHasRisen
    then -- hehe boii
        local gameHour = CLOCK.GET_CLOCK_HOURS()
        local sysHour  = os.date("*t").hour

        if (gameHour >= 0 and gameHour < 4)
        and (sysHour >= 0 and sysHour < 4)
        and (math.random(1, 100) <= 3) then
            CompanionManager:FulfillTheProphecy()
            g_WompusHasRisen = true
            Sleep(100)
            return -1
        end
    end

    local i_Handle = PED.CREATE_PED(
        Game.GetPedTypeFromModel(i_ModelHash),
        i_ModelHash,
        v_SpawnPos.x,
        v_SpawnPos.y,
        v_SpawnPos.z,
        i_Heading or math.random(1, 180),
        b_Networked or false,
        b_SriptHostPed or false
    )

    g_SpawnedEntities.peds[i_Handle] = i_Handle
    return i_Handle
end

---@param i_ModelHash integer
---@param v_SpawnPos vec3
---@param i_Heading? integer
---@param b_Networked? boolean
---@param b_SriptHostVehicle? boolean
Game.CreateVehicle = function(i_ModelHash, v_SpawnPos, i_Heading, b_Networked, b_SriptHostVehicle)
    if not Game.CanCreateEntity("vehicles") then
        if not b_AutoCleanupEntities then
            YimToast:ShowError(
                "Samurai's Scripts",
                "Vehicle spawn limit reached! Consider enabling 'Auto Replace Entities' in the Settings tab if you want to automatically replace old entities when you reach the limit.",
                true,
                5
            )
            return 0
        end

        local oldest = table.remove(g_SpawnedEntities.vehicles, 1)
        Game.DeleteEntity(oldest, "vehicles")
    end

    Await(Game.RequestModel, i_ModelHash)
    local i_Handle = VEHICLE.CREATE_VEHICLE(
        i_ModelHash,
        v_SpawnPos.x,
        v_SpawnPos.y,
        v_SpawnPos.z,
        i_Heading or math.random(1, 180),
        b_Networked or false,
        b_SriptHostVehicle or false,
        false
    )

    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(i_Handle, 5.0)
    VEHICLE.SET_VEHICLE_IS_STOLEN(i_Handle, false)

    if Game.IsOnline() then
        DECORATOR.DECOR_SET_INT(i_Handle, "MPBitset", 0)
    end

    if i_Handle ~= 0 then
        g_SpawnedEntities.vehicles[i_Handle] = i_Handle
    end

    return i_Handle
end

---@param i_ModelHash integer
---@param v_SpawnPos vec3
---@param b_Networked? boolean
---@param b_SriptHostPed? boolean
---@param b_Dynamic? boolean
---@param bPlaceOnGround? boolean
---@param i_Heading? integer
Game.CreateObject = function(i_ModelHash, v_SpawnPos, b_Networked, b_SriptHostPed, b_Dynamic, bPlaceOnGround, i_Heading)
    if not Game.CanCreateEntity("objects") then
        if not b_AutoCleanupEntities then
            YimToast:ShowError(
                "Samurai's Scripts",
                "Object spawn limit reached! Consider enabling 'Auto Replace Entities' in the Settings tab if you want to automatically replace old entities when you reach the limit.",
                true,
                5
            )
            return 0
        end

        local oldest = table.remove(g_SpawnedEntities.objects, 1)
        Game.DeleteEntity(oldest, "objects")
    end

    Await(Game.RequestModel, i_ModelHash)
    local i_Handle = OBJECT.CREATE_OBJECT(
        i_ModelHash,
        v_SpawnPos.x,
        v_SpawnPos.y,
        v_SpawnPos.z,
        b_Networked or false,
        b_SriptHostPed or false,
        (b_Dynamic ~= nil) and b_Dynamic or true
    )

    if bPlaceOnGround then
        OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(i_Handle)
    end

    if i_Heading then
        ENTITY.SET_ENTITY_HEADING(i_Handle, i_Heading)
    end

    if i_Handle ~= 0 then
        g_SpawnedEntities.objects[i_Handle] = i_Handle
    end

    return i_Handle
end

Game.SafeRemovePedFromGroup = function(ped)
    local groupID = PED.GET_PED_GROUP_INDEX(Self.GetPedID())
    if PED.DOES_GROUP_EXIST(groupID) and PED.IS_PED_GROUP_MEMBER(ped, groupID) then
        PED.REMOVE_PED_FROM_GROUP(ped)
    end
end

---@param entity integer
---@param category string | number
Game.DeleteEntity = function(entity, category)
    script.run_in_fiber(function(del)
        if not entity or (entity == 0) or (entity == self.get_ped()) or not ENTITY.DOES_ENTITY_EXIST(entity) then
            return
        end

        if ENTITY.IS_ENTITY_A_PED(entity) then
            Game.SafeRemovePedFromGroup(entity)
        end

        ENTITY.DELETE_ENTITY(entity)
        del:sleep(50)

        if ENTITY.DOES_ENTITY_EXIST(entity) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, true, true)
            ENTITY.DELETE_ENTITY(entity)
            del:sleep(50)

            if ENTITY.DOES_ENTITY_EXIST(entity) and Game.IsOnline() then
                if entities.take_control_of(entity, 300) then
                    ENTITY.DELETE_ENTITY(entity)
                end
            end
            del:sleep(50)

            if ENTITY.DOES_ENTITY_EXIST(entity) then
                YimToast:ShowError(
                    "Samurai's Scripts",
                    ("Failed to delete entity: [%d]"):format(entity)
                )
                return
            end
        end

        if not category or (type(category) == "number" and (category <= 0 or category > 3)) then
            return
        end

        if g_SpawnedEntities[category] and g_SpawnedEntities[category][entity] then
            g_SpawnedEntities[category][entity] = nil
        end

        Game.RemoveBlip(entity)
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
---@param color Color
Game.DrawBoundingBox = function(entity, color)
    local r, g, b, a = color:AsRGBA()
    local model = ENTITY.GET_ENTITY_MODEL(entity)
    local min, max = Game.GetModelDimensions(model)

    local corners = SS.GetBoxCorners(entity, min, max)
    local connections = {
        {1,2}, {2,4}, {4,3}, {3,1},
        {5,6}, {6,8}, {8,7}, {7,5},
        {1,5}, {2,6}, {3,7}, {4,8},
    }

    for _, pair in ipairs(connections) do
        local v_CornerA = corners[pair[1]]
        local v_CornerB = corners[pair[2]]

        GRAPHICS.DRAW_LINE(
            v_CornerA.x,
            v_CornerA.y,
            v_CornerA.z,
            v_CornerB.x,
            v_CornerB.y,
            v_CornerB.z,
            r,
            g,
            b,
            a or 255
        )
    end
end

---@param entity integer
---@param scale? float
---@param isFriendly? boolean
---@param showHeading? boolean
---@param name? string
Game.AddBlipForEntity = function(entity, scale, isFriendly, showHeading, name)
    local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)

    if not blip or not HUD.DOES_BLIP_EXIST(blip) then
        return 0
    end

    HUD.SET_BLIP_SCALE(blip, scale or 1.0)
    HUD.SET_BLIP_AS_FRIENDLY(blip, isFriendly or false)
    HUD.SHOW_HEADING_INDICATOR_ON_BLIP(blip, showHeading or false)

    if name then
        Game.SetBlipName(blip, name)
    end

    g_CreatedBlips[entity] = {
        handle = blip,
        owner = entity,
        alpha = 255
    }

    return blip
end

-- Blip Sprites: https://wiki.rage.mp/index.php?title=Blips
---@param blip integer
---@param icon integer
Game.SetBlipSprite = function(blip, icon)
    if not blip or not HUD.DOES_BLIP_EXIST(blip) then
        return
    end

    HUD.SET_BLIP_SPRITE(blip, icon)
end

-- Sets a custom name for a blip. Custom names appear on the pause menu and the world map.
---@param blip integer
---@param name string
Game.SetBlipName = function(blip, name)
    if not blip or not HUD.DOES_BLIP_EXIST(blip) then
        return
    end

    HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
    HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
end

---@param handle integer
Game.RemoveBlip = function(handle)
    local blip = g_CreatedBlips[handle]
    if blip and HUD.DOES_BLIP_EXIST(blip.handle) then
        HUD.REMOVE_BLIP(blip.handle)
        g_CreatedBlips[handle] = nil
    end
end

---@param i_entity integer
---@param i_heading integer
Game.SetEntityHeading = function(i_entity, i_heading)
    if not Game.IsScriptHandle(i_entity) then
        return
    end

    ENTITY.SET_ENTITY_HEADING(i_entity, i_heading)
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
        return STREAMING.HAS_MODEL_LOADED(model)
    end
    return false
end

---@param dict string
---@return boolean
Game.RequestNamedPtfxAsset = function(dict)
    STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)
    return STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict)
end

---@param clipset string
---@return boolean
Game.RequestClipSet = function(clipset)
    STREAMING.REQUEST_CLIP_SET(clipset)
    return STREAMING.HAS_CLIP_SET_LOADED(clipset)
end

---@param dict string
---@return boolean
Game.RequestAnimDict = function(dict)
    STREAMING.REQUEST_ANIM_DICT(dict)
    return STREAMING.HAS_ANIM_DICT_LOADED(dict)
end

---@param dict string
---@return boolean
Game.RequestTextureDict = function(dict)
    GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(dict, false)
    return GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict)
end

---@param weapon integer
---@return boolean
Game.RequestWeaponAsset = function(weapon)
    WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0)
    return WEAPON.HAS_WEAPON_ASSET_LOADED(weapon)
end

---@param scr string
---@return boolean
Game.RequestScript = function(scr)
    SCRIPT.REQUEST_SCRIPT(scr)
    return SCRIPT.HAS_SCRIPT_LOADED(scr)
end

---@param entity integer
---@param isAlive boolean
---@return vec3
Game.GetEntityCoords = function(entity, isAlive)
    return vec3(ENTITY.GET_ENTITY_COORDS(entity, isAlive))
end

---@param entity integer
---@param order? integer
---@return vec3
Game.GetEntityRotation = function(entity, order)
   return vec3(ENTITY.GET_ENTITY_ROTATION(entity, order or 2))
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
    return vec3(ENTITY.GET_ENTITY_FORWARD_VECTOR(entity))
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
    return vec3(PED.GET_PED_BONE_COORDS(ped, boneID, 0, 0, 0))
end

---@param entity integer
---@param boneName string
---@return integer
Game.GetEntityBoneIndexByName = function(entity, boneName)
    return ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, boneName)
end

---@param entity integer
---@param bone number | string
---@return vec3
Game.GetWorldPositionOfEntityBone = function(entity, bone)
    local boneIndex

    if type(bone) == "string" then
        boneIndex = Game.GetEntityBoneIndexByName(entity, bone)
    else
        boneIndex = bone
    end

    return vec3(ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(entity, boneIndex))
end

---@param entity integer
---@param bone integer | string
---@return vec3
Game.GetEntityBonePos = function(entity, bone)
    local boneIndex = bone

    if type(bone) == "string" then
        boneIndex = Game.GetEntityBoneIndexByName(entity, bone)
    end

    return vec3(ENTITY.GET_ENTITY_BONE_POSTION(entity, boneIndex))
end

---@param entity integer
---@param bone integer | string
---@return vec3
Game.GetEntityBoneRot = function(entity, bone)
    local boneIndex = bone

    if type(bone) == "string" then
        boneIndex = Game.GetEntityBoneIndexByName(entity, bone)
    end

    return vec3(ENTITY.GET_ENTITY_BONE_ROTATION(entity, boneIndex))
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

---@param entity integer
---@return string
Game.GetEntityTypeString = function(entity)
    local iType = Game.GetEntityType(entity)

    if iType == 1 then
        return "Ped"
    elseif iType == 2 then
        return "Vehicle"
    elseif iType == 3 then
        return "Object"
    else
        return "Unknown"
    end
end

---@param entity integer
---@return string
Game.GetCategoryFromEntityType = function(entity)
    local sType = Game.GetEntityTypeString(entity)
    return sType:lower() .. "s"
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

---@param netID integer
Game.SyncNetworkID = function(netID)
    if not Game.IsOnline() or not NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netID) then
        return false
    end

    local timer = Timer.new(250)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
    while not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID) and not timer:isDone() do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
        yield()
    end

    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, true)
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID, true)

    return NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID)
end

Game.DesyncNetworkID = function(netID)
    if not Game.IsOnline() or not NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netID) then
        return
    end

    local timer = Timer.new(250)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
    while not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID) and timer:isDone() do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
        yield()
    end

    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, false)
    NETWORK.SET_NETWORK_ID_CAN_BE_REASSIGNED(netID, false)
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID, false)

    return NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID)
end

---@param i_EntityHandle integer
---@param s_PtfxDict string
---@param s_PtfxName string
---@param bone string | integer | table
---@param f_Scale integer
---@param v_Pos vec3
---@param v_Rot vec3
---@param color? Color
---@return table | nil
function Game.StartSyncedPtfxLoopedOnEntityBone(i_EntityHandle, s_PtfxDict, s_PtfxName, bone, f_Scale, v_Pos, v_Rot, color)
    if not i_EntityHandle or not ENTITY.DOES_ENTITY_EXIST(i_EntityHandle) then
        return
    end

    local effects = {}

    Await(Game.RequestNamedPtfxAsset, s_PtfxDict)
    local r, g, b, a = color and color:AsRGBA() or 0, 0, 0, 255
    local boneList = {}
    local isRightBone = false

    if Game.IsOnline() and (i_EntityHandle ~= Self.GetPedID()) and entities.take_control_of(i_EntityHandle, 300) then
        Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(i_EntityHandle))
    end

    if type(bone) == "table" then
        boneList = bone
    else
        boneList = { bone }
    end

    for _, v in ipairs(boneList) do
        local boneIndex = v

        if type(v) == "string" then
            isRightBone = (string.find(v, "_rf") ~= nil) or (string.find(v, "_rr") ~= nil)
            boneIndex = Game.GetEntityBoneIndexByName(i_EntityHandle, v)
        end

        if boneIndex ~= -1 then
            GRAPHICS.USE_PARTICLE_FX_ASSET(s_PtfxDict)
            local fxHandle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
                s_PtfxName,
                i_EntityHandle,
                isRightBone and -v_Pos.x or v_Pos.x,
                v_Pos.y,
                v_Pos.z,
                v_Rot.x,
                v_Rot.y,
                v_Rot.z,
                boneIndex,
                f_Scale,
                false,
                false,
                false,
                r,
                g,
                b,
                a
            )

            table.insert(effects, fxHandle)
            yield()
        end
    end

    return effects
end

---@param i_EntityHandle integer
---@param s_PtfxDict string
---@param s_PtfxName string
---@param bone string | integer | table
---@param v_Pos vec3
---@param v_Rot vec3
---@param f_Scale integer
Game.StartSyncedPtfxNonLoopedOnEntityBone = function(i_EntityHandle, s_PtfxDict, s_PtfxName, bone, v_Pos, v_Rot, f_Scale)
    if not i_EntityHandle or not ENTITY.DOES_ENTITY_EXIST(i_EntityHandle) then
        return
    end

    Await(Game.RequestNamedPtfxAsset, s_PtfxDict)

    local boneList = {}

    if Game.IsOnline() and (i_EntityHandle ~= Self.GetPedID()) and entities.take_control_of(i_EntityHandle, 500) then
        Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(i_EntityHandle))
    end

    if type(bone) == "table" then
        boneList = bone
    else
        boneList = { bone }
    end

    for _, v in ipairs(boneList) do
        local i_BoneIndex = v

        if type(v) == "string" then
            i_BoneIndex = Game.GetEntityBoneIndexByName(i_EntityHandle, v)
        end

        GRAPHICS.USE_PARTICLE_FX_ASSET(s_PtfxDict)
        GRAPHICS.START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
            s_PtfxName,
            i_EntityHandle,
            v_Pos.x,
            v_Pos.y,
            v_Pos.z,
            v_Rot.x,
            v_Rot.y,
            v_Rot.z,
            i_BoneIndex or 0,
            f_Scale,
            false,
            false,
            false
        )
    end
end


---@param fxHandles table
---@param dict? string
function Game.StopParticleEffects(fxHandles, dict)
    for _, fx in ipairs(fxHandles) do
        GRAPHICS.STOP_PARTICLE_FX_LOOPED(fx, false)
        GRAPHICS.REMOVE_PARTICLE_FX(fx, false)
    end

    if dict then
        STREAMING.REMOVE_NAMED_PTFX_ASSET(dict)
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
---@param closeTo integer|vec3
---@param range number
---@param excludeEntity? integer **Optional**: a specific vehicle to ignore.
---@param nonPlayerVehicle? boolean -- **Optional**: if true, ignores player vehicles
---@param maxSpeed? number  -- **Optional**: if set, skips vehicles faster than this speed (m/s)
---@return integer -- vehicle handle or 0
Game.GetClosestVehicle = function(closeTo, range, excludeEntity, nonPlayerVehicle, maxSpeed)
    local thisPos = type(closeTo) == "number" and Game.GetEntityCoords(closeTo, false) or closeTo
    local closestVeh = 0
    local closestDist = range * range

    if VEHICLE.IS_ANY_VEHICLE_NEAR_POINT(thisPos.x, thisPos.y, thisPos.z, range) then
        local veh_handles = entities.get_all_vehicles_as_handles()

        for _, veh in ipairs(veh_handles) do
            if veh ~= excludeEntity then
                local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, true)

                if not (nonPlayerVehicle and PED.IS_PED_A_PLAYER(driver)) then
                    local vehPos = Game.GetEntityCoords(veh, true)
                    local distance = thisPos:distance(vehPos)

                    if distance <= closestDist and math.floor(VEHICLE.GET_VEHICLE_BODY_HEALTH(veh)) > 0 then
                        if maxSpeed then
                            local vehSpeed = ENTITY.GET_ENTITY_SPEED(veh)
                            if vehSpeed <= maxSpeed then
                                closestVeh = veh
                                closestDist = distance
                            end
                        else
                            closestVeh = veh
                            closestDist = distance
                        end
                    end
                end
            end
        end
    end

    return closestVeh
end

-- Returns a handle for the closest human ped to a provided entity or coordinates.
---@param closeTo integer|vec3
---@param range integer
---@param aliveOnly boolean **Optional**: if true, ignores dead peds.
---@return integer
Game.GetClosestPed = function(closeTo, range, aliveOnly)
    local thisPos = type(closeTo) == 'number' and Game.GetEntityCoords(closeTo, false) or closeTo
    local closestDist = range * range

    if PED.IS_ANY_PED_NEAR_POINT(thisPos.x, thisPos.y, thisPos.z, range) then
        for _, ped in ipairs(entities.get_all_peds_as_handles()) do
            if PED.IS_PED_HUMAN(ped) and (ped ~= Self.GetPedID()) then
                local pedPos = Game.GetEntityCoords(ped, true)
                local distance = thisPos:distance(pedPos)

                if distance <= closestDist then
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
Game.GetObjectiveBlipCoords = function()
    for _, v in ipairs(eObjectiveBlips) do
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

---@return vec3|nil
Game.GetWaypointCoords = function()
    local waypoint = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())

    if HUD.DOES_BLIP_EXIST(waypoint) then
        return HUD.GET_BLIP_COORDS(waypoint)
    end
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
            return true, v.label
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
    end)
end

---@param modelName string
Game.GetPedHash = function(modelName)
    return t_PedLookup[modelName].hash -- not sure if this is faster than simply calling `joaat` on the model name.
end

---@param modelHash integer
Game.GetPedName = function(modelHash)
    return t_PedLookup[modelHash].name or string.format("0x%X", modelHash)
end

---@param model integer|string
Game.GetPedTypeFromModel = function(model)
    return t_PedLookup[model].ped_type or PED_TYPE._CIVMALE
end

---@param model integer|string
Game.GetPedGenderFromModel = function(model)
    return t_PedLookup[model].gender or "unknown"
end

---@param model integer|string
Game.IsPedModelHuman = function(model)
    return t_PedLookup[model].is_human
end

---@param coords vec3
---@param forwardVector vec3
---@param distance integer
Game.FindSpawnPointInDirection = function(coords, forwardVector, distance)
    local pVector = memory.allocate(0xC)

    local bFound, vSpawnPos = MISC.FIND_SPAWN_POINT_IN_DIRECTION(
        coords.x,
        coords.y,
        coords.z,
        forwardVector.x,
        forwardVector.y,
        forwardVector.z,
        distance,
        pVector
    )

    memory.free(pVector)
    return bFound and vSpawnPos or nil
end

---@param distance integer
Game.FindSpawnPointNearPlayer = function(distance)
    return Game.FindSpawnPointInDirection(
        Self.GetPos(),
        Self.GetForwardVector(),
        distance
    )
end

---@param coords vec3
---@param nodeType integer
---@return vec3, integer
Game.GetClosestVehicleNodeWithHeading = function(coords, nodeType)
    local outPos = memory.allocate(0xC)
    local outHeading = 0
    local retVec = vec3:zero()

    _, retVec, outHeading = PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(
        coords.x,
        coords.y,
        coords.z,
        outPos,
        outHeading,
        nodeType,
        3,
        0
    )

    memory.free(outPos)
    return retVec, outHeading
end

---@param entity integer | table
Game.FadeOutEntity = function(entity)
    if not Game.IsOnline() then
        return
    end

    if type(entity) == "number" then
        if ENTITY.DOES_ENTITY_EXIST(entity) then
            NETWORK.NETWORK_FADE_OUT_ENTITY(entity, false, true)
        end
    elseif type(entity) == "table" then
        for i = 1, #entity do
            if ENTITY.DOES_ENTITY_EXIST(entity[i]) then
                NETWORK.NETWORK_FADE_OUT_ENTITY(entity[i], false, true)
            end
        end
    end
end

---@param entity integer | table
Game.FadeInEntity = function(entity)
    if not Game.IsOnline() then
        return
    end

    if type(entity) == "number" then
        if ENTITY.DOES_ENTITY_EXIST(entity) then
            NETWORK.NETWORK_FADE_IN_ENTITY(entity, false, true)
        end
    elseif type(entity) == "table" then
        for i = 1, #entity do
            if ENTITY.DOES_ENTITY_EXIST(entity[i]) then
                NETWORK.NETWORK_FADE_IN_ENTITY(entity[i], false, true)
            end
        end
    end
end

---@class Game.Audio
---@field Emitters table Static Emitters.
---@field ActiveEmitters table A list of enabled emitters and the entities they are linked to.
Game.Audio = {}
Game.Audio.__index = Game.Audio
Game.Audio.ActiveEmitters = {}
Game.Audio.Emitters = {
    rave_1 = {
        name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_01_LEFT",
        default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
    },
    rave_2 = {
        name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_02_RIGHT",
        default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
    },
    rave_3 = {
        name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_03_REVERB",
        default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
    },
    rave_4 = {
        name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_04_REVERB",
        default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
    },
    muffled = {
        name = "SE_BA_DLC_CLUB_EXTERIOR",
        default_station = "RADIO_22_DLC_BATTLE_MIX1_CLUB"
    },
    muffled_2 = {
        name = "DLC_TUNER_MEET_BUILDING_MUSIC",
        default_station = "RADIO_07_DANCE_01"
    },
    muffled_3 = {
        name = "SE_DLC_BIKER_TEQUILALA_EXTERIOR_EMITTER",
        default_station = "HIDDEN_RADIO_04_PUNK"
    },
    radio_low = {
        name = "DLC_MPSUM2_AUTO_STORE_MUSIC",
        default_station = "RADIO_22_DLC_BATTLE_MIX1_RADIO"
    },
    radio_medium = {
        name = "SE_DLC_FIXER_INVESTIGATION_WAY_IN_MUSIC_01",
        default_station = "HIDDEN_RADIO_09_HIPHOP_OLD"
    },
    radio_high = {
        name = "SE_DLC_FIXER_DATA_LEAK_MANSION_SPEAKER_09",
        default_station = "RADIO_07_DANCE_01"
    },
    special = {
        name = "DLC_TUNER_MEET_BUILDING_ENGINES",
        default_station = ""
    },
    test = {
        name = "SE_DLC_BTL_YACHT_EXTERIOR_01",
        default_station = "HIDDEN_RADIO_07_DANCE_01"
    },
    test_2 = {
        name = "se_dlc_hei4_island_beach_party_music_new_03_reverb",
        default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
    },
}

---@param emitter table
---@param toggle boolean
---@param entity? integer
---@param station? string
function Game.Audio:ToggleEmitter(emitter, toggle, entity, station)
    script.run_in_fiber(function(s)
        if emitter and self.ActiveEmitters[emitter.name] then
            AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, self.ActiveEmitters[emitter.name].default_station)
            AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, false)
            self.ActiveEmitters[emitter.name] = nil
            s:sleep(250)
        end

        if not toggle then
            return
        end

        if not Game.IsOnline() then
            AUDIO.SET_AUDIO_FLAG("LoadMPData", true)
        end

        if type(emitter) == "string" then
            emitter = self.Emitters[emitter] or { name = emitter, default_station = station }
        end

        entity  = entity or Self.GetPedID()
        emitter = emitter or self.Emitters.rave_1
        station = station or emitter.default_station

        AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, true)
        AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, station)
        AUDIO.LINK_STATIC_EMITTER_TO_ENTITY(emitter.name, entity)

        self.ActiveEmitters[emitter.name] = {
            name = emitter.name,
            default_station = emitter.default_station,
            current_station = station,
            source = entity,
            coords = Game.GetEntityCoords(entity, false)
        }
    end)
end

---@param toggle boolean
---@param station? string
function Game.Audio:BlastRadio(toggle, station)
    Game.Audio:ToggleEmitter(
        self.Emitters.radio_high,
        toggle,
        Self.GetPedID(),
        station
    )
end

---@param toggle boolean
---@param entity? integer
function Game.Audio:PartyMode(toggle, entity)
    for i = 1, 4 do
        Game.Audio:ToggleEmitter(
            self.Emitters["rave_" .. i],
            toggle,
            entity,
            "RADIO_30_DLC_HEI4_MIX1_REVERB"
        )
    end
end

---@return boolean
function Game.Audio:AreAnyEmittersEnabled()
    return next(self.ActiveEmitters) ~= nil
end

function Game.Audio:StopAllEmitters()
    if self:AreAnyEmittersEnabled() then
        for _, emitter in pairs(self.ActiveEmitters) do
            AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, emitter.default_station)
            AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, false)
        end

        self.ActiveEmitters = {}
    end
end

---@param vehicle integer
---@param isLoud? boolean
function Game.Audio.PlayExhaustPop(vehicle, isLoud)
    if not vehicle or not ENTITY.DOES_ENTITY_EXIST(vehicle) then
        return
    end

    local soundName = isLoud and "SNIPER_FIRE" or "BOOT_POP"
    local soundRef = isLoud and "DLC_BIKER_RESUPPLY_MEET_CONTACT_SOUNDS" or "DLC_VW_BODY_DISPOSAL_SOUNDS"

    AUDIO.PLAY_SOUND_FROM_ENTITY(
        -1,
        soundName,
        vehicle,
        soundRef,
        true,
        0
    )
end
