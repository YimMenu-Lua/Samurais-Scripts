-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


require("includes.lib.callable")

local joaat                             = _G.joaat
local REF_COUNT                         = 0
local IS_CONTROL_PRESSED                = PAD.IS_CONTROL_PRESSED
local IS_CONTROL_JUST_PRESSED           = PAD.IS_CONTROL_JUST_PRESSED
local IS_CONTROL_JUST_RELEASED          = PAD.IS_CONTROL_JUST_RELEASED
local IS_DISABLED_CONTROL_PRESSED       = PAD.IS_DISABLED_CONTROL_PRESSED
local IS_DISABLED_CONTROL_JUST_PRESSED  = PAD.IS_DISABLED_CONTROL_JUST_PRESSED
local IS_DISABLED_CONTROL_JUST_RELEASED = PAD.IS_DISABLED_CONTROL_JUST_RELEASED
local IS_USING_KEYBOARD_AND_MOUSE       = PAD.IS_USING_KEYBOARD_AND_MOUSE

local function isUsingKeyboard()
	return IS_USING_KEYBOARD_AND_MOUSE(0)
end

---@return boolean
local function isPadControlPressed(code)
	return IS_CONTROL_PRESSED(0, code) or IS_DISABLED_CONTROL_PRESSED(0, code)
end

---@return boolean
local function isPadControlJustPressed(code)
	return IS_CONTROL_JUST_PRESSED(0, code) or IS_DISABLED_CONTROL_JUST_PRESSED(0, code)
end

---@return boolean
local function isPadControlJustReleased(code)
	return IS_CONTROL_JUST_RELEASED(0, code) or IS_DISABLED_CONTROL_JUST_RELEASED(0, code)
end

---@nodiscard
---@param code integer
---@param is_controller boolean
---@return boolean
local function isGenericKeyPressed(code, is_controller)
	if (is_controller) then
		return isPadControlPressed(code)
	end

	return KeyManager:IsKeyPressed(code)
end

---@nodiscard
---@param code integer
---@param is_controller boolean
---@return boolean
local function isGenericKeyJustPressed(code, is_controller)
	if (is_controller) then
		return isPadControlJustPressed(code)
	end

	return KeyManager:IsKeyJustPressed(code)
end

---@nodiscard
---@param code integer
---@param is_controller boolean
---@return boolean
local function isGenericKeyJustReleased(code, is_controller)
	if (is_controller) then
		return isPadControlJustReleased(code)
	end

	return KeyManager:IsKeyJustReleased(code)
end


---@class Keybinding
---@field public key GenericKey
---@field public modifier GenericKey?

---@class KeybindMeta
---@field name string
---@field keyboard_binding Keybinding
---@field controller_binding Keybinding
---@field is_exclusive boolean
---@field repeat_on_hold boolean
---@field allow_unbind boolean

---@class KeybindKeywordArgs
---@field callback function?
---@field repeat_on_hold boolean?
---@field is_exclusive boolean?
---@field allow_unbind boolean?
---@field no_gamepad boolean?

---@return GenericKey
local function newGenericKey()
	return { name = "Unbound", code = 0 }
end

---@return Keybinding
local function newUnBoundKey()
	return { key = newGenericKey(), }
end


---@class Keybind : Callable<Keybind>
---@field private m_name string this is usually the toggle or feature or whatever's name
---@field private m_keyboard_binding Keybinding
---@field private m_controller_binding Keybinding
---@field private m_callback function
---@field private m_is_exclusive boolean
---@field private m_repeat_on_hold boolean
---@field private m_allow_unbind boolean
---@field private m_no_gamepad boolean
---@field private m_uid joaat_t
local Keybind   = {}
Keybind.__index = Keybind

---@param name string
---@param keys { keyboard_binding: Keybinding?, controller_binding: Keybinding? }
---@param kwargs? KeybindKeywordArgs
---@return Keybind
function Keybind:new(name, keys, kwargs)
	if (not name) then
		print(keys)
		print(kwargs)
	end
	REF_COUNT        = REF_COUNT + 1
	kwargs           = kwargs or {}
	local no_gamepad = kwargs.no_gamepad or false
	local keyboard   = keys.keyboard_binding
	local controller = keys.controller_binding
	if (not keyboard and not controller and not no_gamepad) then
		Backend:debug("[Keybind]: Attempt to create a keybind with no keys. Falling back to dummies.")
	end
	keyboard           = keyboard or newUnBoundKey()
	controller         = controller or newUnBoundKey()

	local allow_unbind = kwargs.allow_unbind
	if (allow_unbind == nil) then
		allow_unbind = true
	end

	return setmetatable({
		m_name               = name,
		m_keyboard_binding   = keyboard,
		m_controller_binding = controller,
		m_callback           = kwargs.callback,
		m_is_exclusive       = kwargs.is_exclusive or false,
		m_repeat_on_hold     = kwargs.repeat_on_hold or false,
		m_no_gamepad         = no_gamepad,
		m_allow_unbind       = allow_unbind,
		m_uid                = joaat(name .. REF_COUNT)
	}, Keybind)
end

---@param name string
function Keybind.MakeDummy(name)
	return Keybind:new(name, {
		keyboard_binding   = newUnBoundKey(),
		controller_binding = newUnBoundKey()
	})
end

---@param keybind Keybind
---@return boolean
function Keybind.IsRawTable(keybind)
	return getmetatable(keybind) == nil and type(keybind.new) ~= "function"
end

---@return boolean
function Keybind:IsDummy()
	local keyboard   = self.m_keyboard_binding
	local controller = self.m_controller_binding
	return keyboard.key.code == 0
		and controller.key.code == 0
		and keyboard.key.name == "Unbound"
		and controller.key.name == "Unbound"
end

---@return boolean
function Keybind:IgnoresGamepad()
	return self.m_no_gamepad
end

---@return string
function Keybind:GetName()
	return self.m_name
end

---@return joaat_t
function Keybind:GetID()
	return self.m_uid
end

---@private
---@return boolean isKeyboard, Keybinding
function Keybind:GetBindingImpl()
	if (isUsingKeyboard()) then
		return false, self.m_keyboard_binding
	end

	return true, self.m_controller_binding
end

---@return string
function Keybind:GetCurrentKeyName()
	local _, binding = self:GetBindingImpl()
	local keyName = binding.key.name
	local mod = binding.modifier
	if (not mod) then
		return keyName
	end

	if (mod.code == 0) then
		return keyName
	end

	return _F("%s + %s", mod.name, keyName)
end

---@return integer
function Keybind:GetCurrentKeyCode()
	local _, binding = self:GetBindingImpl()
	return binding.key.code
end

---@return Keybinding
function Keybind:GetKeyboardBinding()
	return self.m_keyboard_binding
end

---@return Keybinding
function Keybind:GetControllerBinding()
	return self.m_controller_binding
end

---@return integer
function Keybind:GetKeyboardModifierKeyCode()
	local mod = self.m_keyboard_binding.modifier
	return mod and mod.code or 0
end

---@return integer
function Keybind:GetControllerModifierKeyCode()
	local mod = self.m_controller_binding.modifier
	return mod and mod.code or 0
end

---@param newKey GenericKey
function Keybind:SetKeyboardBinding(newKey)
	-- this is because newKey can be a reference to a VirtualKey object and we don't want to copy the whole thing
	self.m_keyboard_binding.key = { name = newKey.name, code = newKey.code }
end

---@param newKey GenericKey
function Keybind:SetControllerBinding(newKey)
	self.m_controller_binding.key = { name = newKey.name, code = newKey.code }
end

---@param newKey GenericKey
function Keybind:SetKeyboardModifier(newKey)
	self.m_keyboard_binding.modifier = { name = newKey.name, code = newKey.code }
end

---@param newKey GenericKey
function Keybind:SetControllerModifier(newKey)
	self.m_controller_binding.modifier = { name = newKey.name, code = newKey.code }
end

---@param other Keybind
function Keybind:SetKeysFrom(other)
	self.m_keyboard_binding   = table.copy(other.m_keyboard_binding)
	self.m_controller_binding = table.copy(other.m_controller_binding)
end

function Keybind:ClearKeyboardBinding()
	self.m_keyboard_binding = newUnBoundKey()
end

function Keybind:ClearControllerBinding()
	self.m_controller_binding = newUnBoundKey()
end

function Keybind:Unbind()
	self:ClearKeyboardBinding()
	self:ClearControllerBinding()
end

---@return boolean
function Keybind:IsJustReleased()
	local is_controller, binding = self:GetBindingImpl()
	local code = binding.key.code
	if (code == 0) then
		return false
	end

	local mod = binding.modifier
	if (mod and mod.code ~= 0 and not isGenericKeyPressed(mod.code, is_controller)) then
		return false
	end

	return isGenericKeyJustReleased(code, is_controller)
end

---@return boolean
function Keybind:IsPressed()
	local is_controller, binding = self:GetBindingImpl()
	local code = binding.key.code
	if (code == 0) then
		return false
	end

	local mod = binding.modifier
	if (mod and mod.code ~= 0 and not isGenericKeyPressed(mod.code, is_controller)) then
		return false
	end

	return isGenericKeyPressed(code, is_controller)
end

---@return boolean
function Keybind:IsJustPressed()
	local is_controller, binding = self:GetBindingImpl()
	local code = binding.key.code
	if (code == 0) then
		return false
	end

	local mod = binding.modifier
	if (mod and mod.code ~= 0 and not isGenericKeyPressed(mod.code, is_controller)) then
		return false
	end

	return isGenericKeyJustPressed(code, is_controller)
end

---@return boolean
function Keybind:IsReleased()
	return not self:IsPressed()
end

---@return boolean
function Keybind:AllowsUnbinding()
	return self.m_allow_unbind
end

---@nodiscard
---@param other Keybind
---@return boolean
function Keybind:ConflictsWith(other)
	if not (self.m_is_exclusive or other.m_is_exclusive) then
		return false
	end

	local this_kb_bind  = self.m_keyboard_binding
	local this_ct_bind  = self.m_controller_binding
	local other_kb_bind = other.m_keyboard_binding
	local other_ct_bind = other.m_controller_binding

	local this_kb_code  = this_kb_bind.key.code
	local this_ct_code  = this_ct_bind.key.code
	local other_kb_code = other_kb_bind.key.code
	local other_ct_code = other_ct_bind.key.code
	if ((this_kb_code == 0 and this_ct_code == 0) or (this_kb_code ~= other_kb_code and this_ct_code ~= other_ct_code)) then
		return false
	end

	local this_kb_mod  = this_kb_bind.modifier.code
	local this_ct_mod  = this_ct_bind.modifier.code
	local other_kb_mod = other_kb_bind.modifier.code
	local other_ct_mod = other_ct_bind.modifier.code
	if ((this_kb_mod == 0 and this_ct_mod == 0) or (this_kb_mod ~= other_kb_mod and this_ct_mod ~= other_ct_mod)) then
		return false
	end

	return true
end

---@param func function
function Keybind:SetCallback(func)
	self.m_callback = func
end

-- Must be called in [KeyManager](lua://KeyManager.HandleCallbacks).
function Keybind:OnTick()
	if (self:IsDummy()) then
		return
	end

	local callback = self.m_callback
	if (not callback) then
		return
	end

	local cond = self.m_repeat_on_hold and self.IsPressed or self.IsJustReleased
	if (cond(self)) then
		callback()
	end
end

---@return KeybindMeta
function Keybind:serialize()
	return {
		name               = self.m_name,
		keyboard_binding   = table.copy(self.m_keyboard_binding),
		controller_binding = table.copy(self.m_controller_binding),
		is_exclusive       = self.m_is_exclusive or false,
		repeat_on_hold     = self.m_repeat_on_hold or false,
		allow_unbind       = self.m_allow_unbind or false,
		__type             = "Keybind"
	}
end

---@param data KeybindMeta
function Keybind.deserialize(data)
	return Keybind:new(data.name,
		{
			keyboard_binding   = data.keyboard_binding,
			controller_binding = data.controller_binding
		},
		{
			is_exclusive   = data.is_exclusive or false,
			repeat_on_hold = data.repeat_on_hold or false,
			allow_unbind   = data.allow_unbind or false
		})
end

---@param other Keybind
function Keybind:__eq(other)
	if (self.m_name ~= other.m_name) then
		return false
	end

	local this_kb_bind  = self.m_keyboard_binding
	local this_ct_bind  = self.m_controller_binding
	local other_kb_bind = other.m_keyboard_binding
	local other_ct_bind = other.m_controller_binding
	local this_kb_code  = this_kb_bind.key.code
	local this_ct_code  = this_ct_bind.key.code
	local other_kb_code = other_kb_bind.key.code
	local other_ct_code = other_ct_bind.key.code

	local this_kb_mod   = self:GetKeyboardModifierKeyCode()
	local this_ct_mod   = self:GetControllerModifierKeyCode()
	local other_kb_mod  = other:GetKeyboardModifierKeyCode()
	local other_ct_mod  = other:GetControllerModifierKeyCode()

	return this_kb_code == other_kb_code
		and this_ct_code == other_ct_code
		and this_kb_mod == other_kb_mod
		and this_ct_mod == other_ct_mod
end

return Keybind
