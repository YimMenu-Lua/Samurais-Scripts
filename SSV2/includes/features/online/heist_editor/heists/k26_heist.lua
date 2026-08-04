-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local sgi        = stats.get_int
local ssi        = stats.set_int
local ssb        = stats.set_bit
local scb        = stats.clear_bit
local sgb        = stats.get_bit
local tgi        = tunables.get_int
local tsi        = tunables.set_int
local Pair       = require("includes.classes.Pair")
local Heist      = require("includes.features.online.heist_editor.heists.heist_base")
local k26Data    = require("includes.data.heist_editor_data").K26Data
local SGSL       = require("includes.services.SGSL")
local drawFuncs  = require("includes.frontend.heist_editor.heists.k26_ui")
local eDataType  = Enums.eManagedValueDataType
local eValueType = Enums.eManagedValueType

---@class MansionProperty : BasicProperty
---@field has_art_room boolean


---@class KortzHeist : Heist
---@field private m_property? MansionProperty
---@field public m_current_target integer
---@field public m_weekly_cd_disabled boolean
---@field public GetProperty fun(self: KortzHeist): MansionProperty?
local KortzHeist   = setmetatable({}, Heist)
KortzHeist.__index = KortzHeist

---@param mansion MansionProperty
---@return KortzHeist
function KortzHeist.new(mansion)
	local base = Heist.new({
		name              = "DLCC_KORTZ",
		script_name       = "fm_mission_controller_v3",
		boost_bit         = 13,
		property          = mansion,
		requires_property = true,
		gui_callback      = drawFuncs.main_callback,
		custom_header_cb  = drawFuncs.header_callback,
		property_fail_msg = "K26_FLW_HLP4C",
		managed_values    = {
			["kortz_heist_cooldown"] = {
				get_state = function()
					return GVars.features.yim_heists.kortz_cd
				end,
				defs = {
					{ t = "MPX_K26_HEIST_COOLDOWN",      v = 0, obj_type = eValueType.STAT,     data_type = eDataType.INT },
					{ t = "MPX_K26_HEIST_COOLDOWN_HARD", v = 0, obj_type = eValueType.STAT,     data_type = eDataType.INT },
					{ t = 1182453353,                    v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				}
			}
		}
	})


	local instance = setmetatable(base, KortzHeist) ---@cast instance KortzHeist

	if (GVars.features.yim_heists.kortz_week_bypass) then
		instance:ToggleWeeklyCooldown(true, true)
	end

	instance:Init()
	return instance
end

---@protected
function KortzHeist:Init()
	self.m_current_target     = sgi("MPX_K26_HEIST_TARGET")
	self.m_weekly_cd_disabled = self:IsWeeklyCooldownDisabled()
end

---@return boolean
function KortzHeist:AreAllSecondariesUnlocked()
	for _, pair in ipairs(k26Data.secondary_objectives) do
		if (sgi(pair.first) ~= pair.second) then
			return false
		end
	end
	return true
end

---@private
---@return boolean
function KortzHeist:IsWeeklyCooldownDisabled()
	return tgi(1372139704) ~= sgi("MPX_K26_WEEK_ID")
end

---@param toggle boolean
---@param silent? boolean
function KortzHeist:ToggleWeeklyCooldown(toggle, silent)
	local week_id   = sgi("MPX_K26_WEEK_ID")
	local toggle_id = week_id + 1
	if (toggle_id > 6) then
		toggle_id = 0
	end

	tsi(1372139704, toggle and toggle_id or week_id)

	if (toggle and not silent) then
		Notifier:ShowSuccess(self:GetName(), _T("SY_CD_SKIP_SUCCESS"))
	end
end

function KortzHeist:SetCurrentTarget()
	local bit = self.m_current_target
	ssi("MPX_K26_HEIST_TARGET", bit)
	-- scb("MPX_K26_STOLENLAST_BS", bit) -- disabled until we look into whether its used for progression or cheat detection
end

function KortzHeist:UnlockSecondaries()
	for _, pair in ipairs(k26Data.secondary_objectives) do
		ssi(pair.first, pair.second)
	end
end

function KortzHeist:Setup()
	self:SetCurrentTarget()
	self:UnlockSecondaries()
end

function KortzHeist:Reset()
	for _, pair in ipairs(k26Data.secondary_objectives) do
		ssi(pair.first, 0)
	end
end

function KortzHeist:DrawWhenActive()
	ImGui.BeginDisabled(not script.is_active("fmmc_lasers"))
	if (GUI:Button(_T("YH_K26_DISABLE_LASERS"))) then
		ThreadManager:Run(function(s)
			scr_function.call_script_function("fmmc_lasers",
				"FMMC_LSR_END",
				"2D 01 03 00 00 38 00 51", "void", {
					{ "int", 3 }
				})
		end)
	end
	ImGui.EndDisabled()
end

return KortzHeist
