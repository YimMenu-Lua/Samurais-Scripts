-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eWindowAnimType
Enums.eWindowAnimType = {
	CUSTOM = 0,
	MOVE   = 1,
	RESIZE = 2,
	FADE   = 3,
	APPEAR = 4
}

---@class WindowMoveAnimParams
---@field init_pos vec2
---@field end_pos vec2
---@field duration seconds
---@field window_label? string
---@field callback? fun(instance: WindowAnimation, t: float)
---@field ease_func? fun(t: float): float

---@class WindowResizeAnimParams
---@field init_size vec2
---@field end_size vec2
---@field duration seconds
---@field window_label? string
---@field callback? fun(instance: WindowAnimation, t: float)
---@field ease_func? fun(t: float): float

---@class WindowFadeAnimParams
---@field init_alpha float
---@field end_alpha float
---@field duration seconds
---@field window_label? string
---@field callback? fun(instance: WindowAnimation, t: float)
---@field ease_func? fun(t: float): float

---@class WindowAppearAnimParams
---@field init_size vec2
---@field end_size vec2
---@field init_alpha float
---@field end_alpha float
---@field duration seconds
---@field window_label? string
---@field callback? fun(instance: WindowAnimation, t: float)
---@field ease_func? fun(t: float): float

---@param start_vector vec2
---@param end_vector vec2
---@param delta float
---@param ease_func? fun(t: float): float
---@return vec2
local function vector_lerp(start_vector, end_vector, delta, ease_func)
	ease_func = ease_func or math.ease_in_out_quad
	return start_vector:lerp(end_vector, ease_func(delta))
end

---@type table<eWindowAnimType, fun(instance: WindowAnimation, t: float)>
local base_callbacks <const> = {
	[Enums.eWindowAnimType.MOVE] = function(instance, t)
		if (not instance.m_end_pos) then
			instance.m_is_active = false
			return
		end

		if (t >= 1.0) then
			instance.m_is_active = false
			ImGui.SetNextWindowPos(instance.m_end_pos.x, instance.m_end_pos.y, ImGuiCond.Always)
			return
		end

		instance.m_init_pos = instance.m_init_pos or vec2:zero()
		local target        = vector_lerp(instance.m_init_pos, instance.m_end_pos, t, instance.m_ease_fn)
		ImGui.SetNextWindowPos(target.x, target.y, ImGuiCond.Always)
	end,
	[Enums.eWindowAnimType.RESIZE] = function(instance, t)
		if (not instance.m_end_size) then
			instance.m_is_active = false
			return
		end

		if (t >= 1.0) then
			instance.m_is_active = false
			ImGui.SetNextWindowSize(instance.m_end_size.x, instance.m_end_size.y, ImGuiCond.Once)
			return
		end

		instance.m_init_size = instance.m_init_size or vec2:zero()
		local target         = vector_lerp(instance.m_init_size, instance.m_end_size, t, instance.m_ease_fn)
		ImGui.SetNextWindowSize(target.x, target.y, ImGuiCond.Once)
	end,
	[Enums.eWindowAnimType.FADE] = function(instance, t)
		instance.m_init_alpha = instance.m_init_alpha or 0.0
		instance.m_end_alpha  = instance.m_end_alpha or 1.0

		if (t >= 1.0) then
			instance.m_is_active = false
			ImGui.SetNextWindowBgAlpha(instance.m_end_alpha)
			return
		end

		local ease_func = instance.m_ease_fn or math.ease_in_out_quad
		local delta     = ease_func(t)
		local target    = math.lerp(instance.m_init_alpha, instance.m_end_alpha, delta)
		ImGui.SetNextWindowBgAlpha(target)
	end,
	[Enums.eWindowAnimType.APPEAR] = function(instance, t)
		if (not instance.m_end_size) then
			instance.m_is_active = false
			return
		end

		instance.m_init_alpha = instance.m_init_alpha or 0.0
		instance.m_end_alpha  = instance.m_end_alpha or 1.0

		if (t >= 1.0) then
			instance.m_is_active = false
			ImGui.SetNextWindowBgAlpha(instance.m_end_alpha)
			ImGui.SetNextWindowSize(instance.m_end_size.x, instance.m_end_size.y, ImGuiCond.Once)
			return
		end

		local ease_func    = instance.m_ease_fn or math.ease_in_out_quad
		local target_alpha = math.lerp(instance.m_init_alpha, instance.m_end_alpha, ease_func(t))
		local target_size  = vector_lerp(instance.m_init_size, instance.m_end_size, t, ease_func)
		ImGui.SetNextWindowBgAlpha(target_alpha)
		ImGui.SetNextWindowSize(target_size.x, target_size.y, ImGuiCond.Once)
	end
}

--------------------------------------
-- WindowAnimation Struct
--------------------------------------
---@class WindowAnimation : Callable<WindowAnimation>
---@field private m_type eWindowAnimType
---@field private m_callback fun(self: WindowAnimation, t: float)
---@field public m_duration seconds Total animation time
---@field public m_start_time seconds
---@field public m_is_active boolean
---@field public m_label? string
---@field public m_init_pos? vec2
---@field public m_end_pos? vec2
---@field public m_init_size? vec2
---@field public m_end_size? vec2
---@field public m_init_alpha? float
---@field public m_end_alpha? float
---@overload fun() : WindowAnimation
local WindowAnimation = Callable("WindowAnimation", {
	ctor = function(t, ...) return t:new(...) end
})

---@return WindowAnimation
function WindowAnimation:new()
	return setmetatable({
		m_is_active  = false,
		m_duration   = 1.0,
		m_start_time = 0,
	}, self)
end

---@return boolean
function WindowAnimation:IsActive()
	return self.m_is_active
end

---@param kwArgs { init_pos?: vec2, end_pos?: vec2, init_size?: vec2, end_size?: vec2, init_alpha?: float, end_alpha: float, duration: seconds, window_label?: string, callback?: fun(instance: WindowAnimation), ease_func?: fun(t: float): float }
---@overload fun(self, anim_type: 0, kwArgs: { callback: fun(instance: WindowAnimation, t: float), duration: seconds, window_label?: string })
---@overload fun(self, anim_type: 1, kwArgs: WindowMoveAnimParams)
---@overload fun(self, anim_type: 2, kwArgs: WindowResizeAnimParams)
---@overload fun(self, anim_type: 3, kwArgs: WindowFadeAnimParams)
---@overload fun(self, anim_type: 4, kwArgs: WindowAppearAnimParams)
function WindowAnimation:Setup(anim_type, kwArgs)
	self.m_type       = anim_type
	self.m_label      = self.m_label or kwArgs.window_label
	self.m_start_time = Time.Now()
	self.m_duration   = kwArgs.duration or 1.0
	self.m_ease_fn    = kwArgs.ease_func or math.ease_in_out_quad
	self.m_init_pos   = kwArgs.init_pos
	self.m_end_pos    = kwArgs.end_pos
	self.m_init_size  = kwArgs.init_size
	self.m_end_size   = kwArgs.end_size
	self.m_init_alpha = kwArgs.init_alpha
	self.m_end_alpha  = kwArgs.end_alpha

	local callback    = kwArgs.callback or base_callbacks[anim_type]
	self.m_callback   = callback
	self.m_is_active  = callback ~= nil
end

function WindowAnimation:OnFrame()
	if (not self.m_is_active) then
		return
	end

	local callback = self.m_callback
	if (not callback) then
		self.m_is_active = false
		return
	end

	local t = (Time.Now() - self.m_start_time) / self.m_duration ---@type float
	if (not pcall(callback, self, t)) then
		self.m_is_active = false
		return
	end
end

return WindowAnimation
