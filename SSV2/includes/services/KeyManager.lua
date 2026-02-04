-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: lowercase-global

--#region consts


---@enum eControlType
eControlType = {
	KEYBOARD   = 0x0,
	CONTROLLER = 0x1
}

---@enum eVirtualKeyCodes
eVirtualKeyCodes = { -- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
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
	ALT                    = 0x12,
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

local WM_KEYDOWN <const> = 0x0100
local WM_KEYUP <const> = 0x0101
local WM_LBUTTONDOWN <const> = 0x0201
local WM_LBUTTONUP <const> = 0x0202
local WM_MBUTTONDOWN <const> = 0x0207
local WM_MBUTTONUP <const> = 0x0208
local WM_MOUSEWHEEL <const> = 0x020A
local WM_RBUTTONDOWN <const> = 0x0204
local WM_RBUTTONUP <const> = 0x0205
local WM_SYSKEYDOWN <const> = 0x0104
local WM_SYSKEYUP <const> = 0x0105
local WM_XBUTTONDOWN <const> = 0x020B
local WM_XBUTTONUP <const> = 0x020C

--#endregion


--#region Key

--------------------------------------
-- Subclass: Key
--------------------------------------
---@ignore
---@class Key
---@field m_code integer https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
---@field m_name string The key name
---@field callback function
---@field m_repeat_on_hold boolean
---@field m_pressed boolean
---@field m_just_pressed boolean
---@field m_just_released boolean
---@field protected m_prev_pressed boolean
Key = {}
Key.__index = Key

---@param code integer
---@param name string
function Key.new(code, name)
	local instance            = setmetatable({}, Key)
	instance.m_code           = code
	instance.m_name           = name
	instance.m_pressed        = false
	instance.m_prev_pressed   = false
	instance.m_just_pressed   = false
	instance.m_just_released  = false
	instance.m_repeat_on_hold = false
	return instance
end

---@param state boolean
function Key:UpdateState(state)
	if (state and self.m_pressed) then
		return
	end

	self.m_pressed = state
end

function Key:BeginFrame()
	self.m_just_pressed  = self.m_pressed and not self.m_prev_pressed
	self.m_just_released = not self.m_pressed and self.m_prev_pressed
	self.m_prev_pressed  = self.m_pressed
end

function Key:EndFrame() end -- redundant

--#endregion


--#region KeyManager

--------------------------------------
-- Class: KeyManager
--------------------------------------
---@class KeyManager : ClassMeta<KeyManager>
---@field private m_keys Key[]
---@field private m_keymap_by_code table<eVirtualKeyCodes, Key>
---@field private m_keymap_by_name table<string, Key>
---@field private m_registered_keybinds table<eVirtualKeyCodes, Key>
---@field private BeginFrame function
---@field private EndFrame function
---@field private HandleCallbacks function
KeyManager = Class("KeyManager")
KeyManager.m_keys = {}
KeyManager.m_registered_keybinds = {}
KeyManager.m_keymap_by_code = {}
KeyManager.m_keymap_by_name = {}

function KeyManager:init()
	---@class KeyManager
	local instance = setmetatable({}, KeyManager)

	for name, code in pairs(eVirtualKeyCodes) do
		local key = Key.new(code, name)
		table.insert(instance.m_keys, key)
		instance.m_keymap_by_code[code] = key
		instance.m_keymap_by_name[name] = key
	end

	event.register_handler(menu_event.Wndproc, function(_, msg, wParam, _)
		instance:EventHandler(_, msg, wParam, _)
	end)

	ThreadManager:RegisterLooped("SS_KEYMGR", function()
		instance:BeginFrame()
		instance:HandleCallbacks()
		instance:EndFrame()
	end)

	return instance
end

-- still not perfectly in sync but much better than the duct taped approach of manually clearing just_pressed in a separate fiber 🤦‍♂️
function KeyManager:BeginFrame()
	for _, key in pairs(self.m_keys) do
		key:BeginFrame()
	end
end

function KeyManager:EndFrame() end -- redundant

---@param code eVirtualKeyCodes
---@return Key|nil
function KeyManager:GetKeyByCode(code)
	if (not code) then
		return
	end

	return self.m_keymap_by_code[code]
end

---@param name string
---@return Key|nil
function KeyManager:GetKeyByName(name)
	if (not name) then
		return
	end

	return self.m_keymap_by_name[name:upper()]
end

---@param key eVirtualKeyCodes|string
function KeyManager:GetKey(key)
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

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyPressed(key)
	if (Backend.disable_input) then
		return false
	end

	local _key = self:GetKey(key)
	return _key and _key.m_pressed or false
end

---@param key eVirtualKeyCodes|string
---@return boolean
function KeyManager:IsKeyJustPressed(key)
	local _key = self:GetKey(key)
	return _key and _key.m_just_pressed or false
end

---@return boolean, eVirtualKeyCodes|nil, string|nil
function KeyManager:IsAnyKeyPressed()
	for _, key in ipairs(self.m_keys) do
		if key.m_pressed then
			return true, key.m_code, key.m_name
		end
	end

	return false, nil, nil
end

---@param keybindName string
function KeyManager:IsKeybindPressed(keybindName)
	local control = self:GetCurrentControlType()
	if (control == eControlType.KEYBOARD) then
		local kbKeyStr = GVars.keyboard_keybinds[keybindName]
		return kbKeyStr and KeyManager:IsKeyPressed(kbKeyStr) or false
	end

	if (control == eControlType.CONTROLLER) then
		local gpad_t = GVars.gamepad_keybinds[keybindName]
		if (type(gpad_t) ~= "table" or not gpad_t.code or gpad_t.code == 0) then
			return false
		end

		return PAD.IS_CONTROL_PRESSED(0, gpad_t.code)
	end

	return false
end

---@param keybindName string
function KeyManager:IsKeybindJustPressed(keybindName)
	local control = self:GetCurrentControlType()
	if (control == eControlType.KEYBOARD) then
		local kbKeyStr = GVars.keyboard_keybinds[keybindName]
		return kbKeyStr and KeyManager:IsKeyJustPressed(kbKeyStr) or false
	end

	if (control == eControlType.CONTROLLER) then
		local gpad_t = GVars.gamepad_keybinds[keybindName]
		if (type(gpad_t) ~= "table" or not gpad_t.code or gpad_t.code == 0) then
			return false
		end

		return PAD.IS_CONTROL_JUST_PRESSED(0, gpad_t.code)
	end

	return false
end

---@param msg integer
---@param wParam integer
function KeyManager:OnEvent(msg, wParam)
	local key = self:GetKeyByCode(wParam)
	if (not key) then
		return
	end

	if (msg == WM_KEYDOWN or
			msg == WM_SYSKEYDOWN or
			msg == WM_XBUTTONDOWN or
			msg == WM_LBUTTONDOWN or
			msg == WM_RBUTTONDOWN
		) then
		key:UpdateState(true)
	elseif (msg == WM_KEYUP or
			msg == WM_SYSKEYUP or
			msg == WM_XBUTTONUP or
			msg == WM_LBUTTONUP or
			msg == WM_RBUTTONUP
		) then
		key:UpdateState(false)
	end
end

---@param key eVirtualKeyCodes | string
---@param callback function
---@param onKeyDown? boolean Set to true to loop the callback on key down. Ignore or set to false to execute once on key up only.
function KeyManager:RegisterKeybind(key, callback, onKeyDown)
	if (onKeyDown == nil) then
		onKeyDown = false
	end

	local __key = self:GetKey(key)
	if (not __key or not __key.m_code) then
		log.fwarning("[KeyManager]: Attempt to register a keybind to an unknown key %s", key)
		return
	end

	if (type(callback) ~= "function") then
		log.fwarning("[KeyManager]: Keybind registration for %s was rejected. No callback.", __key.m_name:upper())
	end

	if (self.m_registered_keybinds[__key.m_code]) then
		log.fwarning(
			"[KeyManager]: Key '%s' was already assigned to a different function! Did you mean to overwrite it?",
			__key.m_name:upper())
	end

	__key.callback = callback
	__key.m_repeat_on_hold = onKeyDown
	self.m_registered_keybinds[__key.m_code] = __key
end

---@param oldKey eVirtualKeyCodes | string
---@param newKey { id: eVirtualKeyCodes | string, newCallback: function }
function KeyManager:UpdateKeybind(oldKey, newKey)
	local k = self:GetKey(oldKey)
	if (not k or not k.m_code) then
		return
	end

	local registered = self.m_registered_keybinds[k.m_code]
	if (not registered) then
		return
	end

	local prev_func, on_key_down = registered.callback, registered.m_repeat_on_hold
	self:RemoveKeybind(oldKey)
	self:RegisterKeybind(newKey.id, prev_func, on_key_down)
end

---@param key eVirtualKeyCodes | string
function KeyManager:RemoveKeybind(key)
	local k = self:GetKey(key)
	if (not k or not k.m_code) then
		return
	end

	k.callback = nil
	k.m_repeat_on_hold = false
	self.m_registered_keybinds[k.m_code] = nil
end

function KeyManager:HandleCallbacks()
	for _, key in pairs(self.m_registered_keybinds) do
		if (not key.callback) then
			goto continue
		end

		if (not key.m_repeat_on_hold) then
			if (key.m_just_pressed) then
				key.callback()
			end
		else
			if (key.m_pressed) then
				key.callback()
			end
		end

		::continue::
	end
end

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

--#endregion

return KeyManager
