local VIRTUAL_KEYCODES <const> = {
    { code = 0x08,    name = "BACKSPACE", },
    { code = 0x09,    name = "TAB", },
    { code = 0x0C,    name = "CLEAR", },
    { code = 0x0D,    name = "ENTER", },
    { code = 0x10,    name = "SHIFT", },
    { code = 0x11,    name = "CTRL", },
    { code = 0x12,    name = "ALT", },
    { code = 0x13,    name = "PAUSE", },
    { code = 0x14,    name = "CAPS_LOCK", },
    { code = 0x1B,    name = "ESC", },
    { code = 0x20,    name = "SPACEBAR", },
    { code = 0x21,    name = "PAGE_UP", },
    { code = 0x22,    name = "PAGE_DOWN", },
    { code = 0x23,    name = "END", },
    { code = 0x24,    name = "HOME", },
    { code = 0x25,    name = "LEFT_ARROW", },
    { code = 0x26,    name = "UP_ARROW", },
    { code = 0x27,    name = "RIGHT_ARROW", },
    { code = 0x28,    name = "DOWN_ARROW", },
    { code = 0x29,    name = "SELECT", },
    { code = 0x2A,    name = "PRINT", },
    { code = 0x2B,    name = "EXECUTE", },
    { code = 0x2C,    name = "PRINT_SCREEN", },
    { code = 0x2D,    name = "INSERT", },
    { code = 0x2E,    name = "DEL", },
    { code = 0x2F,    name = "HELP", },
    { code = 0x30,    name = "0", },
    { code = 0x31,    name = "1", },
    { code = 0x32,    name = "2", },
    { code = 0x33,    name = "3", },
    { code = 0x34,    name = "4", },
    { code = 0x35,    name = "5", },
    { code = 0x36,    name = "6", },
    { code = 0x37,    name = "7", },
    { code = 0x38,    name = "8", },
    { code = 0x39,    name = "9", },
    { code = 0x41,    name = "A", },
    { code = 0x42,    name = "B", },
    { code = 0x43,    name = "C", },
    { code = 0x44,    name = "D", },
    { code = 0x45,    name = "E", },
    { code = 0x46,    name = "F", },
    { code = 0x47,    name = "G", },
    { code = 0x48,    name = "H", },
    { code = 0x49,    name = "I", },
    { code = 0x4A,    name = "J", },
    { code = 0x4B,    name = "K", },
    { code = 0x4C,    name = "L", },
    { code = 0x4D,    name = "M", },
    { code = 0x4E,    name = "N", },
    { code = 0x4F,    name = "O", },
    { code = 0x50,    name = "P", },
    { code = 0x51,    name = "Q", },
    { code = 0x52,    name = "R", },
    { code = 0x53,    name = "S", },
    { code = 0x54,    name = "T", },
    { code = 0x55,    name = "U", },
    { code = 0x56,    name = "V", },
    { code = 0x57,    name = "W", },
    { code = 0x58,    name = "X", },
    { code = 0x59,    name = "Y", },
    { code = 0x5A,    name = "Z", },
    { code = 0x5B,    name = "VK_LWIN", },
    { code = 0x5C,    name = "VK_RWIN", },
    { code = 0x5D,    name = "VK_APPS", },
    { code = 0x5F,    name = "Sleep", },
    { code = 0x60,    name = "Numpad0", },
    { code = 0x61,    name = "Numpad1", },
    { code = 0x62,    name = "Numpad2", },
    { code = 0x63,    name = "Numpad3", },
    { code = 0x64,    name = "Numpad4", },
    { code = 0x65,    name = "Numpad5", },
    { code = 0x66,    name = "Numpad6", },
    { code = 0x67,    name = "Numpad7", },
    { code = 0x68,    name = "Numpad8", },
    { code = 0x69,    name = "Numpad9", },
    { code = 0x6A,    name = "VK_MULTIPLY", },
    { code = 0x6B,    name = "VK_ADD", },
    { code = 0x6C,    name = "VK_SEPARATOR", },
    { code = 0x6D,    name = "VK_SUBTRACT", },
    { code = 0x6E,    name = "VK_DECIMAL", },
    { code = 0x6F,    name = "VK_DIVIDE", },
    { code = 0x70,    name = "F1", },
    { code = 0x71,    name = "F2", },
    { code = 0x72,    name = "F3", },
    { code = 0x73,    name = "F4", },
    { code = 0x74,    name = "F5", },
    { code = 0x75,    name = "F6", },
    { code = 0x76,    name = "F7", },
    { code = 0x77,    name = "F8", },
    { code = 0x78,    name = "F9", },
    { code = 0x79,    name = "F10", },
    { code = 0x7A,    name = "F11", },
    { code = 0x7B,    name = "F12", },
    { code = 0x7C,    name = "F13", },
    { code = 0x7D,    name = "F14", },
    { code = 0x7E,    name = "F15", },
    { code = 0x7F,    name = "F16", },
    { code = 0x80,    name = "F17", },
    { code = 0x81,    name = "F18", },
    { code = 0x82,    name = "F19", },
    { code = 0x83,    name = "F20", },
    { code = 0x84,    name = "F21", },
    { code = 0x85,    name = "F22", },
    { code = 0x86,    name = "F23", },
    { code = 0x87,    name = "F24", },
    { code = 0x90,    name = "NUM_LOCK", },
    { code = 0x91,    name = "SCROLL_LOCK", },
    { code = 0xA0,    name = "L_SHIFT", },
    { code = 0xA1,    name = "R_SHIFT", },
    { code = 0xA2,    name = "L_CONTROL", },
    { code = 0xA3,    name = "R_CONTROL", },
    { code = 0xA4,    name = "L_ALT", },
    { code = 0xA5,    name = "R_ALT", },
    { code = 0xA6,    name = "VK_BROWSER_BACK", },
    { code = 0xA7,    name = "VK_BROWSER_FORWARD", },
    { code = 0xA8,    name = "VK_BROWSER_REFRESH", },
    { code = 0xA9,    name = "VK_BROWSER_STOP", },
    { code = 0xAA,    name = "VK_BROWSER_SEARCH", },
    { code = 0xAB,    name = "VK_BROWSER_FAVORITES", },
    { code = 0xAC,    name = "VK_BROWSER_HOME" },
    { code = 0xAD,    name = "VK_VOLUME_MUTE", },
    { code = 0xAE,    name = "VK_VOLUME_DOWN", },
    { code = 0xAF,    name = "VK_VOLUME_UP", },
    { code = 0xB0,    name = "VK_MEDIA_NEXT_TRACK", },
    { code = 0xB1,    name = "VK_MEDIA_PREV_TRACK", },
    { code = 0xB2,    name = "VK_MEDIA_STOP", },
    { code = 0xB3,    name = "VK_MEDIA_PLAY_PAUSE", },
    { code = 0xB4,    name = "VK_LAUNCH_MAIL", },
    { code = 0xB5,    name = "VK_LAUNCH_MEDIA_SELECT", },
    { code = 0xB6,    name = "VK_LAUNCH_APP1", },
    { code = 0xB7,    name = "VK_LAUNCH_APP2", },
    { code = 0xBA,    name = "VK_OEM_1", },
    { code = 0xBB,    name = "VK_OEM_PLUS", },
    { code = 0xBC,    name = "VK_OEM_COMMA", },
    { code = 0xBD,    name = "VK_OEM_MINUS", },
    { code = 0xBE,    name = "VK_OEM_PERIOD", },
    { code = 0xBF,    name = "VK_OEM_2", },
    { code = 0xC0,    name = "VK_OEM_3", },
    { code = 0xDB,    name = "VK_OEM_4", },
    { code = 0xDC,    name = "VK_OEM_5", },
    { code = 0xDD,    name = "VK_OEM_6", },
    { code = 0xDE,    name = "VK_OEM_7", },
    { code = 0xDF,    name = "VK_OEM_8", },
    { code = 0xE1,    name = "VK_OEM_SPEC_1", },
    { code = 0xE2,    name = "VK_OEM_102", },
    { code = 0xE3,    name = "VK_OEM_SPEC_2", },
    { code = 0xE4,    name = "VK_OEM_SPEC_3", },
    { code = 0xE5,    name = "VK_PROCESSKEY", },
    { code = 0xE6,    name = "VK_OEM_SPEC_4", },
    { code = 0xE7,    name = "VK_PACKET", },
    { code = 0xE9,    name = "VK_OEM_SPEC_5", },
    { code = 0xF0,    name = "VK_OEM_SPEC_6", },
    { code = 0xF1,    name = "VK_OEM_SPEC_7", },
    { code = 0xF2,    name = "VK_OEM_SPEC_8", },
    { code = 0xF3,    name = "VK_OEM_SPEC_9", },
    { code = 0xF4,    name = "VK_OEM_SPEC_10", },
    { code = 0xF5,    name = "VK_OEM_SPEC_11", },
    { code = 0xF6,    name = "VK_ATTN", },
    { code = 0xF7,    name = "VK_CRSEL", },
    { code = 0xF8,    name = "VK_EXSEL", },
    { code = 0xF9,    name = "VK_EREOF", },
    { code = 0xFA,    name = "VK_PLAY", },
    { code = 0xFB,    name = "VK_ZOOM", },
    { code = 0xFD,    name = "VK_PA1", },
    { code = 0xFE,    name = "VK_OEM_CLEAR", },
    { code = 0x10020, name = "MOUSE4", },
    { code = 0x20040, name = "MOUSE5", },
}

local WM_KEYDOWN     <const> = 0x0100
local WM_KEYUP       <const> = 0x0101
local WM_LBUTTONDOWN <const> = 0x0201
local WM_LBUTTONUP   <const> = 0x0202
local WM_MBUTTONDOWN <const> = 0x0207
local WM_MBUTTONUP   <const> = 0x0208
local WM_MOUSEWHEEL  <const> = 0x020A
local WM_RBUTTONDOWN <const> = 0x0204
local WM_RBUTTONUP   <const> = 0x0205
local WM_SYSKEYDOWN  <const> = 0x0104
local WM_SYSKEYUP    <const> = 0x0105
local WM_XBUTTONDOWN <const> = 0x020B
local WM_XBUTTONUP   <const> = 0x020C


---@class Key
---@field code integer https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
---@field name string The key name
---@field callback function
Key = {}
Key.__index = Key

---@param code integer
---@param name string
function Key:New(code, name)
    local instance = setmetatable({}, Key)
    instance.code = code
    instance.name = name
    instance.pressed = false
    instance.just_pressed = false
    instance.callback = nil
    return instance
end

---@param keydown boolean
---@param keyup boolean
function Key:UpdateState(keydown, keyup)
    self.just_pressed = keyup
    self.pressed = keydown
    if self.just_pressed then
        script.run_in_fiber(function()
            self.just_pressed = false
        end)
    end
end

---@class KeyManager
KeyManager = {}
KeyManager.__index = KeyManager
KeyManager.keys = {}

function KeyManager:Init()
    local instance = setmetatable({}, KeyManager)
    for _, k in ipairs(VIRTUAL_KEYCODES) do
        table.insert(instance.keys, Key:New(k.code, k.name))
    end

    return instance
end

---@param code integer
---@return Key | nil
function KeyManager:GetKeyByCode(code)
    for _, key in ipairs(self.keys) do
        if key.code == code then
            return key
        end
    end
end

---@param name string
---@return Key | nil
function KeyManager:GetKeyByName(name)
    for _, key in ipairs(self.keys) do
        if key.name == name then
            return key
        end
    end
end

---@param key integer | string
---@return boolean
function KeyManager:IsKeyPressed(key)
    local retKey

    if type(key) == "number" then
        retKey = self:GetKeyByCode(key)
    elseif type(key) == "string" then
        retKey = self:GetKeyByName(key)
    end

    return retKey and retKey.pressed or false
end

---@param key integer | string
---@return boolean
function KeyManager:IsKeyJustPressed(key)
    local retKey

    if type(key) == "number" then
        retKey = self:GetKeyByCode(key)
    elseif type(key) == "string" then
        retKey = self:GetKeyByName(key)
    end

    return retKey and retKey.just_pressed or false
end

---@return boolean, integer | nil, string | nil
function KeyManager:IsAnyKeyPressed()
    for _, key in ipairs(self.keys) do
        if key.pressed then
            return true, key.code, key.name
        end
    end
    return false, nil, nil
end

---@param msg integer
---@param wParam integer
function KeyManager:HandleEvent(msg, wParam)
    local key = self:GetKeyByCode(wParam)

    if not key then
        return
    end

    if (msg == WM_KEYDOWN or msg == WM_SYSKEYDOWN or msg == WM_XBUTTONDOWN) then
        key:UpdateState(true, false)
    elseif (msg == WM_KEYUP or msg == WM_SYSKEYUP or msg == WM_XBUTTONUP) then
        key:UpdateState(false, true)
    end
end

---@param key integer | string
---@param callback function
---@param onKeyDown? boolean Set to true to loop the callback on key down. Ignore or set to false to execute once on key up only.
function KeyManager:RegisterKeybind(key, callback, onKeyDown)
    for _, k in ipairs(self.keys) do
        if (key == k.name or key == k.code) then
            if k.callback and k.callback ~= callback then
                gui.show_warning(
                    "Hotkey Manager",
                    ("[%s] was already assigned to a different function!"):format(k.name)
                )
                log.warning(
                    ("[WARNING] (Hotkey Manager): [%s] was already assigned to a different function!"):format(k.name)
                )
            end

            k.callback = callback
            k.on_hold = onKeyDown or false
        end
    end
end

---@param oldKey integer | string
---@param newKey table
function KeyManager:UpdateKeybind(oldKey, newKey)
    for _, v in ipairs(self.keys) do
        if (oldKey == v.name) or (oldKey == v.code) then
            v.code = newKey.code
            v.name = newKey.name
            break
        end
    end
end

---@param key integer | string
function KeyManager:RemoveKeybind(key)
    for _, v in ipairs(self.keys) do
        if (key == v.name) or (key == v.code) then
            v.callback = nil
            v.on_hold = false
            break
        end
    end
end

function KeyManager:HandleCallbacks()
    for _, k in ipairs(self.keys) do
        if k.callback then
            if not k.on_hold then
                if k.just_pressed then
                    k.callback()
                end
            else
                if (k.pressed and not k.just_pressed) then
                    k.callback()
                end
            end
        end
    end
end


local KeyMgr = KeyManager:Init()
event.register_handler(menu_event.Wndproc, function(_, msg, wParam, _)
    if msg == WM_XBUTTONDOWN or msg == WM_XBUTTONUP then
        -- the value for secondary mouse buttons is different between keydown and keyup events
        local xButton = (wParam >> 16)
        if xButton == 1 then
            wParam = 0x10020
        elseif xButton == 2 then
            wParam = 0x20040
        end
    end

    KeyManager:HandleEvent(msg, wParam)
end)

-- script.register_looped("SS_KEYMANAGER", function()
--     KeyMgr:HandleCallbacks()
-- end)

return KeyMgr
