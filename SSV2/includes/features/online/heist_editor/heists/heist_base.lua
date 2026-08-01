-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL                = require("includes.services.SGSL")
local boostTunableInit    = SGSL:Get(SGSL.data.heist_boosts_global_start):AsGlobal()
local tpLabelWidths       = {}
local confirmBtnSize      = vec2:new(0, 40)
local boolColors          = {
	[true]  = vec4:new(0.0, 0.96, 0.04, 1.0),
	[false] = vec4:new(0.96, 0.0, 0.02, 1.0),
}
local is_activity_session = NETWORK.NETWORK_IS_ACTIVITY_SESSION


---@class BasicProperty
---@field public name string
---@field public coords vec3


---@class HeistCtorData
---@field name string
---@field script_name string
---@field requires_property boolean
---@field property? BasicProperty
---@field boost_bit? integer
---@field payout_tunable? IManagedTuneable
---@field managed_values? array<IManagedValueCtorData>
---@field gui_callback? fun(self: Heist): nil
---@field custom_header_cb? fun(self: Heist): nil
---@field property_fail_msg? string


---@class Heist
---@field private m_has_error boolean -- don't nuke the whole heist editor tab if one heist ui crashes
---@field private m_traceback? string
---@field protected m_name string
---@field protected m_gui_callback fun(self: Heist): nil
---@field protected m_custom_header_callback? fun(self: Heist): nil
---@field protected m_is_property_required boolean
---@field protected m_property? BasicProperty
---@field protected m_property_fail_msg? string
---@field protected m_boost_bit? integer
---@field protected m_player_cuts? Int4
---@field protected m_payout_tunable? IManagedTuneable
---@field protected m_managed_values? dict<IManagedValueCtorData>
---@field protected m_script_name? string
---@field protected m_is_active boolean
---@field protected Update? fun(self: Heist): nil -- Optional code that will be executed in a background thread.
---@field protected DrawWhenActive? fun(self: Heist): nil -- Optional ImGui code to draw when the heist is active.
---@field private m_dummy_confirm_timer? Timer
---@field public SetPlayerCuts? fun(self: Heist): nil
---@field public Reset? fun(self: Heist): nil
---@field public InstantFinish? fun(self: Heist): nil -- Will probably never implement this anywhere since HeistEditor will have an instant-finish button that will work for most if not all heists (same as the existing 'Skip Objective' button). pros? zero repeated code and much less script global/local maintenance. cons? will not work for all heists.
local Heist   = {}
Heist.__index = Heist

---@param args HeistCtorData
---@return Heist
function Heist.new(args)
	return setmetatable({
		m_name                   = args.name,
		m_script_name            = args.script_name,
		m_property               = args.property,
		m_boost_bit              = args.boost_bit,
		m_payout_tunable         = args.payout_tunable,
		m_managed_values         = args.managed_values,
		m_is_property_required   = args.requires_property,
		m_gui_callback           = args.gui_callback,
		m_custom_header_callback = args.custom_header_cb,
		m_property_fail_msg      = args.property_fail_msg,
		m_has_error              = false,
		m_is_active              = false,
	}, Heist)
end

---@virtual
---@protected
function Heist:Init() end

---@virtual
---@protected
function Heist:Setup() end

---@public
---@return string
function Heist:GetName()
	return _T(self.m_name or "GENERIC_UNKNOWN")
end

---@return Int4?
function Heist:GetPlayerCuts()
	return self.m_player_cuts
end

---@private
---@nodiscard
---@return boolean
function Heist:IsRunning()
	local scr_name = self.m_script_name
	if (not scr_name) then
		return false
	end

	return script.is_active(scr_name) and is_activity_session()
end

---@public
---@nodiscard
---@return boolean
function Heist:IsActive()
	return self.m_is_active
end

--```c
--BOOL func_13005(int iParam0)
---```
---@protected
---@nodiscard
---@param bitPos? integer
---@return boolean
function Heist:IsWeeklyBoostDisabledImpl(bitPos)
	if (boostTunableInit:ReadInt() ~= 0) then
		return true
	end

	bitPos = bitPos or self.m_boost_bit -- this is so that multi-stage heists can pass the appropriate bit (like doomsday)
	if (not bitPos) then
		return true
	end

	return boostTunableInit:At(bitPos, 1):ReadInt() ~= 0
end

---@nodiscard
---@return boolean
function Heist:CanBeBoosted()
	return type(self.m_boost_bit) == "number"
end

---@return boolean
function Heist:IsBoosted()
	local bitPos = self.m_boost_bit
	if (type(bitPos) ~= "number") then
		return false
	end

	if (self:IsWeeklyBoostDisabledImpl()) then
		return false
	end

	-- return !IS_BIT_SET(func_26276(14313, -1), iParam0);
	return stats.get_bit("MPX_WEEKLY_BOOST_BS", bitPos) == 0 -- the stat value is saved to Global_1912667[player_id /*318*/].f_316 as well;
end

---@nodiscard
---@return boolean
function Heist:RequiresProperty()
	return self.m_is_property_required
end

---@return BasicProperty?
function Heist:GetProperty()
	return self.m_property
end

---@param controller IManagedValueController
function Heist:RegisterManagedValues(controller)
	local data = self.m_managed_values
	if (not data) then
		return
	end

	for k, v in pairs(data) do
		if (not controller:Append(k, v)) then
			log.fwarning("[%s]: Failed to register managed values!", self.m_name)
		end
	end
end

function Heist:OnTick()
	if (not self.m_is_active and self:IsRunning()) then
		self.m_is_active = true
	end

	if (self.m_is_active and not self:IsRunning()) then
		self.m_is_active = false
		self:Init()
		sleep(3000)
	end
end

--#region ImGui
-- Normally we separate game logic from UI. This is the only exception.

---@private
function Heist:DrawHeader()
	local customCallbakc = self.m_custom_header_callback
	if (customCallbakc) then
		customCallbakc(self)
		return
	end

	local property = self.m_property
	if (self.m_is_property_required and not property) then
		local msg = _T(self.m_property_fail_msg or "YH_REQUIRED_PROPERTY_ERR")
		ImGui.Text(msg)
		return
	end

	if (not property) then return end
	ImGui.SetWindowFontScale(1.16)
	ImGui.TextCentered(_T("YH_GENERIC_PROPERTY"))
	ImGui.SetWindowFontScale(0.88)
	ImGui.TextCentered(_T(property.name))
	ImGui.SetWindowFontScale(1.0)

	local coords = property.coords
	if (not coords) then return end

	local style          = ImGui.GetStyle()
	local tp_label       = _T("GENERIC_TELEPORT")
	local wp_label       = _T("GENERIC_SET_WAYPOINT")
	local lang_idx       = GVars.backend.language_index
	local tp_label_width = tpLabelWidths[lang_idx]
	if (not tp_label_width) then
		tp_label_width = ImGui.CalcTextSize(tp_label)
			+ ImGui.CalcTextSize(wp_label)
			+ style.ItemSpacing.x
			+ (style.FramePadding.x * 4); tpLabelWidths[lang_idx] = tp_label_width
	end

	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - tp_label_width) * 0.5)

	if (GUI:Button(tp_label)) then
		LocalPlayer:Teleport(coords)
	end

	ImGui.SameLine()
	if (GUI:Button(wp_label)) then
		Game.SetWaypointCoords(coords)
	end
end

function Heist:Draw()
	local callback = self.m_gui_callback
	if (not callback) then
		return
	end

	if (self.m_has_error and self.m_traceback) then
		ImGui.PushTextWrapPos()
		ImGui.TextColored(0.5, 0.4, 0.0, 1.0, "An error has occured! Please contact a developer.")
		ImGui.Indent()
		ImGui.TextColored(1.0, 0.0, 0.0, 1.0, _F("Traceback: %s", self.m_traceback))
		ImGui.Unindent()
		ImGui.PopTextWrapPos()
		return
	end

	local requiresProp = self.m_is_property_required
	local topBarHeight = GUI:GetMaxTopBarHeight()
	local headerHeight = requiresProp and 130.0 or 0.0
	local footerHeight = 195.0
	local middleHeight = GVars.ui.window_size.y - topBarHeight - headerHeight - footerHeight
	local isActive     = self.m_is_active

	ImGui.BeginDisabled(isActive)
	if (requiresProp) then
		ImGui.SetNextWindowBgAlpha(0.45)
		ImGui.BeginChildEx("##heist_header", vec2:new(0, headerHeight), ImGuiChildFlags.Borders)
		self:DrawHeader()
		ImGui.EndChild()
	end
	ImGui.EndDisabled() -- isActive

	ImGui.SetNextWindowBgAlpha(0.40)
	ImGui.BeginChildEx("##heist_scroll", vec2:new(0, middleHeight), ImGuiChildFlags.AlwaysUseWindowPadding)
	if (self:CanBeBoosted()) then
		ImGui.SetWindowFontScale(0.7)
		ImGui.BulletText(_T("YH_BOOST_STATUS"))
		ImGui.SameLine()
		local isBoosted  = self:IsBoosted()
		local boostText  = _T(isBoosted and "GENERIC_ACTIVE" or "GENERIC_INACTIVE")
		local boostColor = boolColors[isBoosted]
		ImGui.TextColored(boostColor.x, boostColor.y, boostColor.z, boostColor.w, boostText)
		ImGui.SetWindowFontScale(1.0)
	end

	local isOnDummyTimeout = self.m_dummy_confirm_timer and not self.m_dummy_confirm_timer:IsDone() or false
	if (isOnDummyTimeout) then
		ImGui.Dummy(0, 15)
		ImGui.SetWindowFontScale(1.15)
		ImGui.Text(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL")))
		ImGui.SetWindowFontScale(1.0)
		ImGui.EndChild()
	else
		ImGui.BeginDisabled(isActive)
		local ok, err = pcall(callback, self)
		ImGui.EndDisabled() -- isActive

		local drawWhenActive = self.DrawWhenActive
		if (drawWhenActive) then
			ImGui.BeginDisabled(not isActive)
			ok, err = pcall(drawWhenActive, self)
			ImGui.EndDisabled() -- !isActive
		end
		ImGui.EndChild()

		if (not ok) then ---@cast err string?
			local msg = (err or "Unknown error.")
			self.m_has_error, self.m_traceback = true, msg
			log.warning(msg)
			return
		end
	end

	ImGui.Separator()
	ImGui.BeginDisabled(isOnDummyTimeout or isActive)
	local confirmLabel    = _T("GENERIC_CONFIRM")
	local confirmLblWidth = ImGui.CalcTextSize(confirmLabel) + 40
	if (confirmLblWidth > confirmBtnSize.x) then
		confirmBtnSize.x = confirmLblWidth
	end

	if (GUI:Button(confirmLabel, { size = confirmBtnSize })) then
		self.m_dummy_confirm_timer = self.m_dummy_confirm_timer or Timer(1200)
		self.m_dummy_confirm_timer:Reset()
		ThreadManager:Run(function()
			self:Setup()
		end)
	end

	local reset = self.Reset
	if (reset) then
		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_RESET"), { size = confirmBtnSize })) then
			self.m_dummy_confirm_timer = self.m_dummy_confirm_timer or Timer(1200)
			self.m_dummy_confirm_timer:Reset()
			ThreadManager:Run(function()
				reset(self)
			end)
		end
	end
	ImGui.EndDisabled() -- isOnDummyTimeout || isActive
end

--#endregion ImGui

return Heist
