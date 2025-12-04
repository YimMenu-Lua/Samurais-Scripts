PatternScanner = require("includes.services.PatternScanner"):init()


-- ### A place to store pointers globally.
--
-- You can add new indexes to this global table from any other file
--
-- as long as it's loaded before `GPointers:Init()` is called *(bottom of init.lua)*.
--
-- **NOTE:** Please make sure no modules/files try to use a pointer before the scan is complete.
--
-- You can call `PointerScanner:IsDone()` to double check.
---@class GPointers
---@field GameState pointer<byte>
---@field GameTime pointer<uint32_t>
GPointers = {
    Init = function()
        PatternScanner:Scan()
    end,
    Retry = function()
        PatternScanner:RetryScan()
    end
}

PatternScanner:Add("ScriptGlobals", "48 8D 15 ? ? ? ? 4C 8B C0 E8 ? ? ? ? 48 85 FF 48 89 1D", function(ptr)
    GPointers.ScriptGlobals = ptr:add(0x3):rip()
end)

-- PatternScanner:Add("CWheelOffset", "3B B7 ? ? ? ? 7D 0D", function(ptr)
--     if ptr:is_null() then
--         GPointers.CWheelOffset = 0
--         return
--     end

--     GPointers.CWheelOffset = ptr:get_disp32(0x2) -- cmp esi, [rdi+0000C38h] (b3586.0)
-- end)

PatternScanner:Add("GameVersion", "8B C3 33 D2 C6 44 24 20", function(ptr)
    if ptr:is_null() then
        GPointers.GameVersion = { _build = "nil", _online = "nil" }
        return
    end

    local pGameBuild = ptr:add(0x24):rip()
    local pOnlineVersion = pGameBuild:add(0x20)
    GPointers.GameVersion = {
        _build  = pGameBuild:get_string(),
        _online = pOnlineVersion:get_string()
    }
end)

PatternScanner:Add("GameState", "83 3D ? ? ? ? ? 75 17 8B 43 20 25", function(ptr)
    if ptr:is_null() then
        GPointers.GameState = ptr
        return
    end

    GPointers.GameState = ptr:add(0x2):rip():add(0x1)
end)

PatternScanner:Add("GameTime", "8B 05 ? ? ? ? 89 ? 48 8D 4D C8", function(ptr)
    if ptr:is_null() then
        GPointers.GameTime = ptr
        return
    end

    GPointers.GameTime = ptr:add(0x2):rip()
end)

PatternScanner:Add("ScreenResolution", "66 0F 6E 0D ? ? ? ? 0F B7 3D", function(ptr)
    if ptr:is_null() then
        GPointers.ScreenResolution = vec2:zero()
        return
    end

    GPointers.ScreenResolution = vec2:new(
        ptr:sub(0x4):rip():get_word(),
        ptr:add(0x4):rip():get_word()
    )
end)
