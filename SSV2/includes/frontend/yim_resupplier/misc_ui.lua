-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Pair                     = require("includes.classes.Pair")
local YRV3                     = require("includes.features.online.yim_resupplier.YimResupplierV3")
local maxSellMissionButtonSize = vec2:new(80, 30)
local cooldownBtnSize          = vec2:new(120, 40)
local COL_WARN_YELLOW <const>  = Color(240, 190, 2, 255)
local CooldownData <const>     = {
	Pair("YRV3_CLUB_WORK_CB", "mc_work_cd"),
	Pair("YRV3_HANGAR_STEAL_CB", "hangar_cd"),
	Pair("YRV3_NC_MANAGMENT_CB", "nc_management_cd"),
	Pair("YRV3_NC_CHANCE_ENCOUNTER_CB", "nc_vip_mission_chance"),
	Pair("YRV3_SECURITY_WORK_CB", "security_missions_cd"),
	Pair("YRV3_IE_VEH_STEAL_CB", "ie_vehicle_steal_cd"),
	Pair("YRV3_IE_VEH_SELL_CB", "ie_vehicle_sell_cd"),
	Pair("YRV3_CEO_BUY_CB", "ceo_crate_buy_cd"),
	Pair("YRV3_CEO_SELL_CB", "ceo_crate_sell_cd"),
	Pair("YRV3_DAX_WORK_CB", "dax_work_cd"),
	Pair("YRV3_HACKER_DEN_CD_CB", "garment_rob_cd"),
}

local bulkCooldownButtonLabels = {
	[true]  = "YRV3_CB_UNCHECK_ALL",
	[false] = "YRV3_CB_CHECK_ALL",
}

---@param cfg dict<boolean>
---@return boolean
local function areAllCooldownsEnabled(cfg)
	for _, pair in ipairs(CooldownData) do
		if (not cfg[pair.second]) then
			return false
		end
	end
	return true
end

---@param value boolean
local function setAllCooldowns(value)
	local cfg = GVars.features.yrv3
	for _, pair in ipairs(CooldownData) do
		cfg[pair.second] = value
	end
	YRV3:ProcessAllCooldowns()
end

return function()
	ImGui.SeparatorText(_T("YRV3_COOLDOWNS_LABEL"))

	local config = GVars.features.yrv3
	for _, pair in ipairs(CooldownData) do
		local label, key = pair.first, pair.second
		---@diagnostic disable-next-line
		config[key] = GUI:CustomToggle(_T(label), config[key], {
			onClick = function()
				YRV3:ProcessCooldown(key)
			end
		})
		if (label == "YRV3_NC_CHANCE_ENCOUNTER_CB") then
			GUI:HelpMarker(_T("YRV3_NC_CHANCE_ENCOUNTER_TT"))
		end
	end

	ImGui.BeginDisabled()
	ImGui.Toggle(_F("%s [x]", _T("YRV3_PAYHPONE_HITS_CB")), false)
	ImGui.EndDisabled()
	if (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled)) then
		ImGui.SetTooltip(_T("YRV3_SEXY_SHINABI_NOTICE"))

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.TAB)) then
			local url = "https://github.com/YimMenu-Lua/PayphoneHits"
			ImGui.SetClipboardText(url)
			Notifier:ShowMessage("Business Manager", _T("GENERIC_URL_COPY_SUCCESS", url), true, 6)
		end
	end

	ImGui.Spacing()
	local allEnabled = areAllCooldownsEnabled(config)
	local cdBtnLabel = bulkCooldownButtonLabels[allEnabled]
	if (GUI:Button(_T(cdBtnLabel), { size = cooldownBtnSize })) then
		setAllCooldowns(not allEnabled)
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_SELL_MISSIONS_LABEL"))
	ImGui.TextWrapped(_T("YRV3_SELL_MISSIONS_TT"))

	for name, data in pairs(YRV3:GetSaleMissionTunables()) do
		local isFloat      = (data.type == "float")
		local get_func     = isFloat and tunables.get_float or tunables.get_int
		local set_func     = isFloat and tunables.set_float or tunables.set_int
		local desiredValue = isFloat and 0.0 or 1
		local style        = ImGui.GetStyle()
		local label        = _F("Easy %s Missions", name) -- I'm not even going to bother translating these
		local buttonWidth  = ImGui.CalcTextSize(label) + (style.FramePadding.x * 2)
		if (buttonWidth > maxSellMissionButtonSize.x) then
			maxSellMissionButtonSize.x = buttonWidth
		end

		if (GUI:Button(label, { size = maxSellMissionButtonSize })) then
			for _, tuneable_name in pairs(data.tuneables) do
				if (get_func(tuneable_name) ~= desiredValue) then
					set_func(tuneable_name, desiredValue)
				end
			end

			Notifier:ShowSuccess("Business Manager", _T("YRV3_SELL_MISSIONS_NOTIF", name))
		end

		ImGui.SameLineIfAvail(buttonWidth + style.ItemSpacing.x)
	end

	ImGui.Dummy(0, 0)
	ImGui.Spacing()
	GUI:Text(_T("YRV3_SELL_MISSIONS_NOTE"), { color = COL_WARN_YELLOW })
end
