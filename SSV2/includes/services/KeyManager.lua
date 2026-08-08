-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: lowercase-global

local Set     = require("includes.classes.Set")
local Keybind = require("includes.structs.Keybind")


--#region defs

---@enum eControlType
eControlType                    = {
	KEYBOARD   = 0x0,
	CONTROLLER = 0x1
}

---@enum eVirtualKeyCodes
eVirtualKeyCodes                = { -- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
	DIGIT_0                = 0x30,
	DIGIT_1                = 0x31,
	DIGIT_2                = 0x32,
	DIGIT_3                = 0x33,
	DIGIT_4                = 0x34,
	DIGIT_5                = 0x35,
	DIGIT_6                = 0x36,
	DIGIT_7                = 0x37,
	DIGIT_8                = 0x38,
	DIGIT_9                = 0x39,
	A                      = 0x41,
	ADD                    = 0x6B,

	-- This is disabled because KeyManager never sees the KEYUP event after alt-tabbing so this key gets stuck on KEYDOWN until you press and release it again.
	-- Since this is a feature keybinding system not a raw input debugger, having it in the first place is counter-intuitive because it's a modifier key
	-- often used for window focus switching and it's reserved by the game as the default character switch key. Imagine assigning it to a "suicide" command then alt-tabbing
	-- during a heist or mission. Now that is simply stupid.
	-- ALT                    = 0x12,

	APPS                   = 0x5D,
	B                      = 0x42,
	BACKSPACE              = 0x8,
	C                      = 0x43,
	CAPSLOCK               = 0x14,
	CLEAR                  = 0xC,
	CTRL                   = 0x11,
	D                      = 0x44,
	DECIMAL                = 0x6E,
	DEL                    = 0x2E,
	DIVIDE                 = 0x6F,
	DOWN                   = 0x28,
	E                      = 0x45,
	END                    = 0x23,
	ENTER                  = 0xD,
	ESC                    = 0x1B,
	EXECUTE                = 0x2B,
	F                      = 0x46,
	F1                     = 0x70,
	F10                    = 0x79,
	F11                    = 0x7A,
	F12                    = 0x7B,
	F13                    = 0x7C,
	F14                    = 0x7D,
	F15                    = 0x7E,
	F16                    = 0x7F,
	F17                    = 0x80,
	F18                    = 0x81,
	F19                    = 0x82,
	F2                     = 0x71,
	F20                    = 0x83,
	F21                    = 0x84,
	F22                    = 0x85,
	F23                    = 0x86,
	F24                    = 0x87,
	F3                     = 0x72,
	F4                     = 0x73,
	F5                     = 0x74,
	F6                     = 0x75,
	F7                     = 0x76,
	F8                     = 0x77,
	F9                     = 0x78,
	G                      = 0x47,
	H                      = 0x48,
	HELP                   = 0x2F,
	HOME                   = 0x24,
	I                      = 0x49,
	INSERT                 = 0x2D,
	J                      = 0x4A,
	K                      = 0x4B,
	L                      = 0x4C,
	LALT                   = 0xA4,
	LCONTROL               = 0xA2,
	LEFT                   = 0x25,
	LSHIFT                 = 0xA0,
	LWIN                   = 0x5B,
	M                      = 0x4D,
	MOUSE4                 = 0x10020,
	MOUSE5                 = 0x20040,
	MULTIPLY               = 0x6A,
	N                      = 0x4E,
	NUMLOCK                = 0x90,
	NUMPAD0                = 0x60,
	NUMPAD1                = 0x61,
	NUMPAD2                = 0x62,
	NUMPAD3                = 0x63,
	NUMPAD4                = 0x64,
	NUMPAD5                = 0x65,
	NUMPAD6                = 0x66,
	NUMPAD7                = 0x67,
	NUMPAD8                = 0x68,
	NUMPAD9                = 0x69,
	O                      = 0x4F,
	P                      = 0x50,
	PAGEDOWN               = 0x22,
	PAGEUP                 = 0x21,
	PAUSE                  = 0x13,
	PRINT                  = 0x2A,
	PRINTSCREEN            = 0x2C,
	Q                      = 0x51,
	R                      = 0x52,
	RALT                   = 0xA5,
	RCONTROL               = 0xA3,
	RIGHT                  = 0x27,
	RSHIFT                 = 0xA1,
	RWIN                   = 0x5C,
	S                      = 0x53,
	SCROLLLOCK             = 0x91,
	SELECT                 = 0x29,
	SEPARATOR              = 0x6C,
	SHIFT                  = 0x10,
	SPACEBAR               = 0x20,
	SUBTRACT               = 0x6D,
	Sleep                  = 0x5F,
	T                      = 0x54,
	TAB                    = 0x9,
	U                      = 0x55,
	UP                     = 0x26,
	V                      = 0x56,
	VK_ATTN                = 0xF6,
	VK_BROWSER_BACK        = 0xA6,
	VK_BROWSER_FAVORITES   = 0xAB,
	VK_BROWSER_FORWARD     = 0xA7,
	VK_BROWSER_HOME        = 0xAC,
	VK_BROWSER_REFRESH     = 0xA8,
	VK_BROWSER_SEARCH      = 0xAA,
	VK_BROWSER_STOP        = 0xA9,
	VK_CRSEL               = 0xF7,
	VK_EREOF               = 0xF9,
	VK_EXSEL               = 0xF8,
	VK_LBUTTON             = 0x1,
	VK_RBUTTON             = 0x2,
	VK_LAUNCH_APP1         = 0xB6,
	VK_LAUNCH_APP2         = 0xB7,
	VK_LAUNCH_MAIL         = 0xB4,
	VK_LAUNCH_MEDIA_SELECT = 0xB5,
	VK_MEDIA_NEXT_TRACK    = 0xB0,
	VK_MEDIA_PLAY_PAUSE    = 0xB3,
	VK_MEDIA_PREV_TRACK    = 0xB1,
	VK_MEDIA_STOP          = 0xB2,
	VK_OEM_1               = 0xBA,
	VK_OEM_102             = 0xE2,
	VK_OEM_2               = 0xBF,
	VK_OEM_3               = 0xC0,
	VK_OEM_4               = 0xDB,
	VK_OEM_5               = 0xDC,
	VK_OEM_6               = 0xDD,
	VK_OEM_7               = 0xDE,
	VK_OEM_8               = 0xDF,
	VK_OEM_CLEAR           = 0xFE,
	VK_OEM_COMMA           = 0xBC,
	VK_OEM_MINUS           = 0xBD,
	VK_OEM_PERIOD          = 0xBE,
	VK_OEM_PLUS            = 0xBB,
	VK_OEM_SPEC_1          = 0xE1,
	VK_OEM_SPEC_10         = 0xF4,
	VK_OEM_SPEC_11         = 0xF5,
	VK_OEM_SPEC_2          = 0xE3,
	VK_OEM_SPEC_3          = 0xE4,
	VK_OEM_SPEC_4          = 0xE6,
	VK_OEM_SPEC_5          = 0xE9,
	VK_OEM_SPEC_6          = 0xF0,
	VK_OEM_SPEC_7          = 0xF1,
	VK_OEM_SPEC_8          = 0xF2,
	VK_OEM_SPEC_9          = 0xF3,
	VK_PA1                 = 0xFD,
	VK_PACKET              = 0xE7,
	VK_PLAY                = 0xFA,
	VK_PROCESSKEY          = 0xE5,
	VK_VOLUME_DOWN         = 0xAE,
	VK_VOLUME_MUTE         = 0xAD,
	VK_VOLUME_UP           = 0xAF,
	VK_ZOOM                = 0xFB,
	W                      = 0x57,
	X                      = 0x58,
	Y                      = 0x59,
	Z                      = 0x5A,
}

local WM_KEYDOWN <const>        = 0x0100
local WM_KEYUP <const>          = 0x0101
local WM_LBUTTONDOWN <const>    = 0x0201
local WM_LBUTTONUP <const>      = 0x0202
local WM_MBUTTONDOWN <const>    = 0x0207
local WM_MBUTTONUP <const>      = 0x0208
local WM_MOUSEWHEEL <const>     = 0x020A -- TODO
local WM_RBUTTONDOWN <const>    = 0x0204
local WM_RBUTTONUP <const>      = 0x0205
local WM_SYSKEYDOWN <const>     = 0x0104
local WM_SYSKEYUP <const>       = 0x0105
local WM_XBUTTONDOWN <const>    = 0x020B
local WM_XBUTTONUP <const>      = 0x020C

local KeyDownMessageSet <const> = Set(
	WM_KEYDOWN,
	WM_LBUTTONDOWN,
	WM_MBUTTONDOWN,
	WM_RBUTTONDOWN,
	WM_SYSKEYDOWN,
	WM_XBUTTONDOWN
)

local KeyUpMessageSet <const>   = Set(
	WM_KEYUP,
	WM_LBUTTONUP,
	WM_MBUTTONUP,
	WM_RBUTTONUP,
	WM_SYSKEYUP,
	WM_XBUTTONUP
)

--#endregion


--#region Key

-- I got tired of juggling keyboard and controller keys.
--
-- For controller, we have to have a table with the PAD key
--
-- and its name because I'm not adding another giant map to
--
-- resolve gamepad keys. Keyboard keys can be simple (VK key or string)
--
-- and our [Key](lua://Key) object stores both the name and the code
--
-- so this generic key is yet another duct-taped abstraction to unify both
--
-- into a simple and serialization-friendly object.

-- Class representing a generic key.
---@class GenericKey
---@field name string
---@field code integer

--------------------------------------
-- Class: Key
--------------------------------------
---@ignore
---@class VirtualKey: GenericKey
---@field public code integer https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
---@field public name string The key name
---@field private m_pressed boolean
---@field private m_just_pressed boolean
---@field private m_just_released boolean
---@field private m_prev_pressed boolean
local VirtualKey <const> = {}
VirtualKey.__index       = VirtualKey

---@param code integer
---@param name string
function VirtualKey.new(code, name)
	return setmetatable({
		code            = code,
		name            = name,
		m_pressed       = false,
		m_prev_pressed  = false,
		m_just_pressed  = false,
		m_just_released = false,
	}, VirtualKey)
end

---@param state boolean
function VirtualKey:UpdateState(state)
	if (state and self.m_pressed) then
		return
	end

	self.m_pressed = state
end

function VirtualKey:BeginFrame()
	self.m_just_pressed  = self.m_pressed and not self.m_prev_pressed
	self.m_just_released = not self.m_pressed and self.m_prev_pressed
	self.m_prev_pressed  = self.m_pressed
end

function VirtualKey:EndFrame() end -- redundant

--#endregion


--#region KeyManager

--------------------------------------
-- Class: KeyManager
--------------------------------------
---@class KeyManager : Callable<KeyManager>
---@field private m_virtual_keys VirtualKey[]
---@field private m_vk_map_by_code table<eVirtualKeyCodes, VirtualKey>
---@field private m_vk_map_by_name table<string, VirtualKey>
---@field private m_registered_keybinds table<string, Keybind>
---@field private m_initialized boolean
---@overload fun(): KeyManager
local KeyManager = Callable("KeyManager")

function KeyManager:init()
	if (self.m_initialized) then return self end
	if (_G.KeyManager) then return _G.KeyManager end

	self.m_virtual_keys        = {}
	self.m_vk_map_by_code      = {}
	self.m_vk_map_by_name      = {}
	self.m_registered_keybinds = {}

	for name, code in pairs(eVirtualKeyCodes) do
		local key = VirtualKey.new(code, name)
		table.insert(self.m_virtual_keys, key)
		self.m_vk_map_by_code[code] = key
		self.m_vk_map_by_name[name] = key
	end

	event.register_handler(menu_event.Wndproc, function(_, msg, wParam, _)
		self:EventHandler(_, msg, wParam, _)
	end)

	ThreadManager:RegisterLooped("SS_KEYMGR", function()
		self:BeginFrame()
		self:HandleCallbacks()
		self:EndFrame()
	end)

	self.m_initialized = true
	_G.KeyManager      = self
	return self
end

---@private
function KeyManager:BeginFrame()
	for _, key in ipairs(self.m_virtual_keys) do
		key:BeginFrame()
	end
end

---@private
function KeyManager:EndFrame() end -- redundant

---@private
---@param msg integer
---@param wParam integer
function KeyManager:OnEvent(msg, wParam)
	local key = self:GetKeyByCode(wParam)
	if (not key) then return end

	if (KeyDownMessageSet:Contains(msg)) then
		key:UpdateState(true)
	elseif (KeyUpMessageSet:Contains(msg)) then
		key:UpdateState(false)
	end
end

---@private
function KeyManager:HandleCallbacks()
	for _, key in pairs(self.m_registered_keybinds) do
		key:OnTick()
	end
end

---@private
function KeyManager:EventHandler(_, msg, wParam, _)
	if (msg == WM_XBUTTONDOWN or msg == WM_XBUTTONUP) then
		-- the value for secondary mouse buttons is different between keydown and keyup events
		local xButton = (wParam >> 16)
		if (xButton == 1) then
			wParam = 0x10020
		elseif (xButton == 2) then
			wParam = 0x20040
		end
	end

	if (msg == WM_LBUTTONUP) then
		wParam = 0x1
	elseif (msg == WM_RBUTTONUP) then
		wParam = 0x2
	end
	self:OnEvent(msg, wParam)
end

---@param code eVirtualKeyCodes
---@return VirtualKey?
function KeyManager:GetKeyByCode(code)
	if (not code) then
		return
	end

	return self.m_vk_map_by_code[code]
end

---@param name string
---@return VirtualKey?
function KeyManager:GetKeyByName(name)
	if (not name) then
		return
	end

	return self.m_vk_map_by_name[name:upper()]
end

---@param key eVirtualKeyCodes|string
function KeyManager:GetVirtualKey(key)
	if (type(key) == "number") then
		return self:GetKeyByCode(key)
	elseif (type(key) == "string") then
		return self:GetKeyByName(key)
	end
end

---@return eControlType
function KeyManager:GetCurrentControlType()
	return PAD.IS_USING_KEYBOARD_AND_MOUSE(0) and eControlType.KEYBOARD or eControlType.CONTROLLER
end

---@diagnostic disable: invisible

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyPressed(key)
	local _key = self:GetVirtualKey(key)
	return _key and _key.m_pressed or false
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyJustPressed(key)
	local _key = self:GetVirtualKey(key)
	return _key and _key.m_just_pressed or false
end

---@return boolean, eVirtualKeyCodes? keyCode, string? keyName
function KeyManager:IsAnyKeyPressed()
	for _, key in ipairs(self.m_virtual_keys) do
		if (key.m_pressed) then
			return true, key.code, key.name
		end
	end
	return false
end

---@return boolean, eVirtualKeyCodes? keyCode, string? keyName
function KeyManager:IsAnyKeyJustPressed()
	for _, key in ipairs(self.m_virtual_keys) do
		if (key.m_just_pressed) then
			return true, key.code, key.name
		end
	end
	return false
end

---@return boolean, eVirtualKeyCodes? keyCode, string? keyName
function KeyManager:IsAnyKeyJustReleased()
	for _, key in ipairs(self.m_virtual_keys) do
		if (key.m_just_released) then
			return true, key.code, key.name
		end
	end
	return false
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyReleased(key)
	return not self:IsKeyPressed(key)
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyJustReleased(key)
	local _key = self:GetVirtualKey(key)
	return _key and _key.m_just_released or false
end

---@diagnostic enable: invisible

---@param restoreOnFail boolean Automatically reset to default if assertion fails
---@param keyPath string Keybind path as registered in the [Config](lua://Config) table. Example: `"keyboard_keybinds.nos"`
---@param default? Keybind
---@return boolean
function KeyManager:AssertKeybind(restoreOnFail, keyPath, default)
	local default_cfg = Serializer:GetDefaultConfig()
	default           = default or table.get_nested_value(default_cfg, keyPath) ---@type Keybind?

	if (not default) then
		log.ferror("[KeyManager]: Assertion failed for keybind at '%s': No default value!", keyPath)
		return false
	end

	local runtime = table.get_nested_value(GVars, keyPath) ---@type Keybind?
	local success = (runtime and not runtime:IsDummy()) or false

	if (not success and restoreOnFail) then
		table.set_nested_value(GVars, keyPath, default)
		Backend:debug("Restored keybind at %s", keyPath)
	end

	return success
end

---@param gvar_key string
---@return eControlType, Keybind?
function KeyManager:GetKeybind(gvar_key)
	return self:GetCurrentControlType(), GVars.keybinds[gvar_key]
end

---@param keybindName string
---@return boolean
function KeyManager:IsKeybindPressed(keybindName)
	if (Backend:AreControlsDisabled()) then
		return false
	end

	local _, keybind = self:GetKeybind(keybindName)
	if (not keybind) then
		return false
	end

	return keybind:IsPressed()
end

---@param keybindName string
---@return boolean
function KeyManager:IsKeybindJustPressed(keybindName)
	if (Backend:AreControlsDisabled()) then
		return false
	end

	local _, keybind = self:GetKeybind(keybindName)
	if (not keybind) then
		return false
	end

	return keybind:IsJustPressed()
end

---@param keybindName string
---@return boolean
function KeyManager:IsKeybindJustReleased(keybindName)
	if (Backend:AreControlsDisabled()) then
		return false
	end

	local _, keybind = self:GetKeybind(keybindName)
	if (not keybind) then
		return false
	end

	return keybind:IsJustReleased()
end

---@param keybindName string
---@return boolean
function KeyManager:IsKeybindReleased(keybindName)
	return not self:IsKeybindPressed(keybindName)
end

---@param keybind Keybind
---@param callback? function
function KeyManager:RegisterKeybind(keybind, callback)
	if (Keybind.IsRawTable(keybind)) then
		Backend:debug("Ignored junk keybind %s", table.serialize(keybind))
		return
	end

	if (type(callback) == "function") then
		keybind:SetCallback(callback)
	end

	self.m_registered_keybinds[keybind:GetName()] = keybind
end

---@param name string
---@param keyCode eVirtualKeyCodes
---@param isController boolean
---@param kwargs? KeybindKeywordArgs
---@return Keybind?
function KeyManager:RegisterKeybindByCode(name, keyCode, isController, kwargs)
	local keyName = isController and Game.GetControllerKeyByCode(keyCode) or (self:GetKeyByCode(keyCode) or {}).name
	if (not keyName) then return end

	local bind    = { key = { name = keyName, code = keyCode } } ---@type Keybinding
	local keybind = Keybind:new(name, {
		keyboard_binding   = isController and nil or bind,
		controller_binding = isController and bind or nil,
	}, kwargs)


	self.m_registered_keybinds[name] = keybind
	return keybind
end

---@param name string
---@param keyName string
---@param isController boolean
---@param kwargs? KeybindKeywordArgs
---@return Keybind?
function KeyManager:RegisterKeybindByName(name, keyName, isController, kwargs)
	local keyCode = isController and Game.GetControllerKeyByName(keyName) or (self:GetKeyByName(keyName) or {}).code
	if (not keyCode) then return end

	local bind    = { key = { name = keyName, code = keyCode } } ---@type Keybinding
	local keybind = Keybind:new(name, {
		keyboard_binding   = isController and nil or bind,
		controller_binding = isController and bind or nil,
	}, kwargs)


	self.m_registered_keybinds[name] = keybind
	return keybind
end

-- Updates a runtime keybind.
---@param name string
---@param newKey GenericKey|VirtualKey
---@param isController boolean
---@param callback function?
function KeyManager:UpdateKeybind(name, newKey, isController, callback)
	local registered = self.m_registered_keybinds[name]
	if (not registered) then
		return
	end

	if (isController) then
		registered:SetKeyboardBinding(newKey)
	else
		registered:SetControllerBinding(newKey)
	end

	if (type(callback) == "function") then
		registered:SetCallback(callback)
	end
end

-- Removes a runtime keybind.
---@param name string
function KeyManager:RemoveKeybind(name)
	self.m_registered_keybinds[name] = nil
end

--#endregion

return KeyManager()
