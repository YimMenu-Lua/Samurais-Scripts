-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local sCooldownButtonLabel, bCooldownParam
local maxSellMissionButtonSize = vec2:new(80, 30)

local function getAllCDCheckboxes()
	return GVars.features.yrv3.mc_work_cd
		and GVars.features.yrv3.hangar_cd
		and GVars.features.yrv3.nc_management_cd
		and GVars.features.yrv3.nc_vip_mission_chance
		and GVars.features.yrv3.security_missions_cd
		and GVars.features.yrv3.ie_vehicle_steal_cd
		and GVars.features.yrv3.ie_vehicle_sell_cd
		and GVars.features.yrv3.ceo_crate_buy_cd
		and GVars.features.yrv3.ceo_crate_sell_cd
		and GVars.features.yrv3.dax_work_cd
		and GVars.features.yrv3.garment_rob_cd
		and GVars.features.yrv3.cfr_cd -- chicken factory raid
end

---@param value boolean
local function setAllCDCheckboxes(value)
	GVars.features.yrv3.mc_work_cd            = value
	GVars.features.yrv3.hangar_cd             = value
	GVars.features.yrv3.nc_management_cd      = value
	GVars.features.yrv3.nc_vip_mission_chance = value
	GVars.features.yrv3.security_missions_cd  = value
	GVars.features.yrv3.ie_vehicle_steal_cd   = value
	GVars.features.yrv3.ie_vehicle_sell_cd    = value
	GVars.features.yrv3.ceo_crate_buy_cd      = value
	GVars.features.yrv3.ceo_crate_sell_cd     = value
	GVars.features.yrv3.dax_work_cd           = value
	GVars.features.yrv3.garment_rob_cd        = value
	GVars.features.yrv3.cfr_cd                = value

	YRV3:SetAllCooldownStatesDirty(true)
end

local cooldownsGrid = GridRenderer.new(1)
cooldownsGrid:AddCheckbox("YRV3_CEO_BUY_CB", "features.yrv3.ceo_crate_buy_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ceo_crate_buy_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_CEO_SELL_CB", "features.yrv3.ceo_crate_sell_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ceo_crate_sell_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_CLUB_WORK_CB", "features.yrv3.mc_work_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("mc_work_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_HANGAR_STEAL_CB", "features.yrv3.hangar_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("hangar_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_NC_MANAGMENT_CB", "features.yrv3.nc_management_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("nc_management_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_NC_CHANCE_ENCOUNTER_CB", "features.yrv3.nc_vip_mission_chance", {
	persistent = true,
	isTranslatorLabel = true,
	tooltip = "YRV3_NC_CHANCE_ENCOUNTER_TT",
	onClick = function()
		YRV3:SetCooldownStateDirty("nc_vip_mission_chance", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_HACKER_DEN_CD_CB", "features.yrv3.garment_rob_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("garment_rob_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_CFR_CD_CB", "features.yrv3.cfr_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("cfr_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_DAX_WORK_CB", "features.yrv3.dax_work_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("dax_work_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_IE_VEH_STEAL_CB", "features.yrv3.ie_vehicle_steal_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ie_vehicle_steal_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_IE_VEH_SELL_CB", "features.yrv3.ie_vehicle_sell_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ie_vehicle_sell_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_SECURITY_WORK_CB", "features.yrv3.security_missions_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("security_missions_cd", true)
	end
})

return function()
	ImGui.SeparatorText(_T("YRV3_COOLDOWNS_LABEL"))

	cooldownsGrid:Draw()

	ImGui.Spacing()
	ImGui.BeginDisabled()
	ImGui.Toggle(_F("%s [x]", _T("YRV3_PAYHPONE_HITS_CB")), false)
	ImGui.EndDisabled()
	if (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and KeyManager:IsKeyJustPressed(eVirtualKeyCodes.TAB)) then
		local url = "https://github.com/YimMenu-Lua/PayphoneHits"
		Notifier:ShowMessage("YRV3", _F(_T("GENERIC_URL_COPY_SUCCESS"), url), true, 6)
		ImGui.SetClipboardText(url)
	end
	GUI:Tooltip(_T("YRV3_SEXY_SHINABI_NOTICE"))

	ImGui.Dummy(1, 5)
	if (getAllCDCheckboxes()) then
		sCooldownButtonLabel, bCooldownParam = "YRV3_CB_UNCHECK_ALL", false
	else
		sCooldownButtonLabel, bCooldownParam = "YRV3_CB_CHECK_ALL", true
	end

	if (GUI:Button(_T(sCooldownButtonLabel), { size = vec2:new(120, 40) })) then
		setAllCDCheckboxes(bCooldownParam)
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_SELL_MISSIONS_LABEL"))

	ImGui.Spacing()
	ImGui.TextWrapped(_T("YRV3_SELL_MISSIONS_TT"))

	ImGui.Spacing()
	GUI:Text(_T("YRV3_SELL_MISSIONS_NOTE"), Color("yellow"))

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
			for _, index in pairs(data.tuneable) do
				if get_func(index) ~= desiredValue then
					set_func(index, desiredValue)
				end
			end

			Notifier:ShowSuccess("YRV3", _F(_T("YRV3_SELL_MISSIONS_NOTIF"), name:lower()))
		end

		ImGui.SameLine()
		if (ImGui.GetContentRegionAvail() <= (buttonWidth + style.ItemSpacing.x)) then
			ImGui.NewLine()
		end
	end
end
