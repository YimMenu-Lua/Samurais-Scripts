local sCooldownButtonLabel, bCooldownParam
local hangarSupplies    = 0
local hangarTotalValue  = 0
local bunkerTotalValue  = 0
local acidLabTotalValue = 0
local acidLabOwned      = false
local ownsWarehouse     = false
local ownsBikerBusiness = false
local yrv3_state        = {
	disabled = false,
	reason = "Something went wrong! Please contact a developer."
}

local tabNames <const>  = {
	"CEO",
	"Hangar",
	"Bunker",
	"Acid Lab",
	"Biker Business",
	"Safes",
	"Misc",
	"Settings"
}

local selectedTabName   = tabNames[1]

local fmbg              = GetScriptGlobalOrLocal("freemode_business_global")
if (not fmbg) then
	yrv3_state.disabled = true
	yrv3_state.reason = "Failed to read freemode global. Please contact a developer."
	return
end

local FreemodeGlobal = ScriptGlobal(fmbg)

local function CalcTotalBusinessIncome()
	return math.sum(
		YRV3.m_biker_value_sum,
		YRV3.m_ceo_value_sum,
		YRV3.m_safe_cash_sum,
		hangarTotalValue,
		bunkerTotalValue,
		acidLabTotalValue
	)
end

local function GetAllCDCheckboxes()
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
local function SetAllCDCheckboxes(value)
	GVars.features.yrv3.mc_work_cd = value
	GVars.features.yrv3.hangar_cd = value
	GVars.features.yrv3.nc_management_cd = value
	GVars.features.yrv3.nc_vip_mission_chance = value
	GVars.features.yrv3.security_missions_cd = value
	GVars.features.yrv3.ie_vehicle_steal_cd = value
	GVars.features.yrv3.ie_vehicle_sell_cd = value
	GVars.features.yrv3.ceo_crate_buy_cd = value
	GVars.features.yrv3.ceo_crate_sell_cd = value
	GVars.features.yrv3.dax_work_cd = value
	GVars.features.yrv3.garment_rob_cd = value
	GVars.features.yrv3.cfr_cd = value

	YRV3:SetAllCooldownStatesDirty(true)
end

local function drawCEOwarehouses()
	if (not YRV3:DoesPlayerOwnAnyWarehouse()) then
		ImGui.Text("You don't own any CEO warehouses.")
		return
	end

	YRV3.m_ceo_value_sum = 0
	for i, wh in ipairs(YRV3.m_warehouse_data) do
		local slot = i - 1
		wh.isOwned = stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(slot)) > 0

		if wh.isOwned then
			ownsWarehouse = true

			if (not YRV3.m_warehouse_data[i].wasChecked) then
				YRV3:PopulateCEOwarehouseSlot(i)
			else
				wh.totalSupplies = stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(slot))
				wh.totalValue = YRV3:GetCEOCratesValue(wh.totalSupplies or 0)
				YRV3.m_ceo_value_sum = YRV3.m_ceo_value_sum + wh.totalValue

				if (wh.name and wh.size and wh.max) then
					ImGui.PushID(i)
					ImGui.SeparatorText(tostring(wh.name))
					ImGui.BulletText("Cargo Held:")
					ImGui.SameLine()
					ImGui.Dummy(20, 1)
					ImGui.SameLine()

					ImGui.ProgressBar(
						(wh.totalSupplies / wh.max),
						240,
						30,
						_F(
							"%d Crates (%d%%)",
							wh.totalSupplies,
							(math.floor(wh.totalSupplies / wh.max) * 100)
						)
					)
					GUI:Tooltip(_F("%s: %d / %d", wh.name, wh.totalSupplies, wh.max))

					ImGui.SameLine()
					ImGui.Text(string.formatmoney(wh.totalValue))

					if (wh.pos) then
						if GUI:Button(_F("Teleport##%d", i)) then
							YRV3:Teleport(wh.pos)
						end
					end

					ImGui.SameLine()
					ImGui.BeginDisabled(wh.totalSupplies >= wh.max)
					ImGui.BeginDisabled(wh.autoFill)
					if GUI:Button(_F("%s##wh%d", _T("GET_RANDOM_CRATES"), i)) then
						stats.set_bool_masked(
							"MPX_FIXERPSTAT_BOOL1",
							true,
							i + 11
						)
					end
					ImGui.EndDisabled()
					ImGui.SameLine()
					YRV3.m_warehouse_data[i].autoFill, _ = GUI:Checkbox(_F("Auto##wh%d", i),
						YRV3.m_warehouse_data[i].autoFill)
					ImGui.EndDisabled()
					ImGui.PopID()
				end
			end
		end
	end

	if (ownsWarehouse) then
		ImGui.Dummy(1, 5)
		ImGui.SeparatorText("MISC")
		ImGui.Spacing()
		local bCond = (not script.is_active("gb_contraband_buy") and not script.is_active("fm_content_cargo"))
		ImGui.BeginDisabled(bCond)
		if (GUI:Button("Finish Cargo Source Mission")) then
			YRV3:FinishCEOCargoSourceMission()
		end
		ImGui.EndDisabled()

		if (bCond) then
			GUI:Tooltip("Start a source mission then press this button to finish it.")
		end

		ImGui.BulletText("Total Value: " .. string.formatmoney(YRV3.m_ceo_value_sum))
	end
end

local function drawHangar()
	local hangar_index = stats.get_int("MPX_HANGAR_OWNED")
	local hangarOwned = hangar_index ~= 0

	if (not hangarOwned) then
		ImGui.Text("You don't own a hangar.")
		return
	end

	local hangar_name = YRV3.t_Hangars[hangar_index].name
	local hangar_pos = YRV3.t_Hangars[hangar_index].coords

	ImGui.SeparatorText(hangar_name)
	hangarSupplies = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
	hangarTotalValue = hangarSupplies * 30000

	ImGui.BulletText("Supplies:")
	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(hangarSupplies / 50),
		240,
		30
	)

	if (hangarSupplies < 50) then
		ImGui.SameLine()

		ImGui.BeginDisabled(YRV3.m_hangar_loop)
		if GUI:Button(_F("%s##hangar", _T("GET_RANDOM_CRATES"))) then
			script.run_in_fiber(function()
				stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
			end)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()
		YRV3.m_hangar_loop, _ = GUI:Checkbox("Auto##hangar", YRV3.m_hangar_loop)
	end

	ImGui.BulletText("Stock:")
	ImGui.SameLine()
	ImGui.Dummy(33, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(hangarSupplies / 50),
		240,
		30,
		_F("%d Crates (%d%%)", hangarSupplies, math.floor(hangarSupplies / 0.5))
	)

	ImGui.SameLine()
	ImGui.Text(_F("Value: %s", string.formatmoney(hangarTotalValue)))
	ImGui.Spacing()
	ImGui.SeparatorText(_T "QUICK_TP_TXT")
	if GUI:Button(_T "TP_HANGAR") then
		YRV3:Teleport(hangar_pos, true)
	end
end

local function drawBunker()
	local bunker_index = stats.get_int("MPX_PROP_FAC_SLOT5")
	local bunkerOwned = bunker_index ~= 0

	if (not bunkerOwned) then
		ImGui.Text("You don't own a bunker.")
		return
	end

	ImGui.SeparatorText(YRV3.t_Bunkers[bunker_index].name)

	local bunkerUpdgrade1  = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
	local bunkerUpdgrade2  = stats.get_int("MPX_BUNKER_STAFF") == 1
	local bunkerOffset1    = 0
	local bunkerOffset2    = 0
	local bunkerEqLabelCol = "white"
	local bunkerStLabelCol = "white"

	if (bunkerUpdgrade1) then
		bunkerOffset1 = tunables.get_int("GR_MANU_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
		bunkerEqLabelCol = "green"
	else
		bunkerOffset1 = 0
		bunkerEqLabelCol = "red"
	end

	if (bunkerUpdgrade2) then
		bunkerOffset2 = tunables.get_int("GR_MANU_PRODUCT_VALUE_STAFF_UPGRADE")
		bunkerStLabelCol = "green"
	else
		bunkerOffset2 = 0
		bunkerStLabelCol = "red"
	end

	local bunkerSupplies = stats.get_int("MPX_MATTOTALFORFACTORY5")
	local bunkerStock = stats.get_int("MPX_PRODTOTALFORFACTORY5")
	bunkerTotalValue = (tunables.get_int("GR_MANU_PRODUCT_VALUE") + bunkerOffset1 + bunkerOffset2) * bunkerStock

	ImGui.BulletText("Equipment Upgrade: ")
	ImGui.SameLine()
	GUI:TextColored(bunkerUpdgrade1 and "Active" or "Inactive", Color(bunkerEqLabelCol))

	ImGui.SameLine()
	ImGui.BulletText("Staff Upgrade: ")
	ImGui.SameLine()
	GUI:TextColored(bunkerUpdgrade2 and "Active" or "Inactive", Color(bunkerStLabelCol))

	ImGui.Spacing()
	ImGui.BulletText("Supplies:")
	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()
	ImGui.ProgressBar((bunkerSupplies / 100), 240, 30)

	ImGui.SameLine()
	ImGui.BeginDisabled(bunkerSupplies >= 100)
	if (GUI:Button(" Fill Supplies ##bunker")) then
		FreemodeGlobal:At(5):At(1):WriteInt(1)
	end
	ImGui.EndDisabled()

	ImGui.BulletText("Stock:")
	ImGui.SameLine()
	ImGui.Dummy(33, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(bunkerStock / 100),
		240,
		30,
		_F("%d Crates (%d%%)", bunkerStock, bunkerStock)
	)

	ImGui.SameLine()
	ImGui.Text("Value:")
	ImGui.SameLine()
	ImGui.Text(
		_F(
			"¤ Blaine County: %s\n¤ Los Santos:      %s",
			string.formatmoney(bunkerTotalValue),
			string.formatmoney(math.floor(bunkerTotalValue * 1.5))
		)
	)

	ImGui.Spacing()
	ImGui.SeparatorText(_T "QUICK_TP_TXT")

	if (GUI:Button(_T "TP_BUNKER")) then
		YRV3:Teleport(YRV3.t_Bunkers[bunker_index].coords, true)
	end
end

local function drawAcidLab()
	acidLabOwned = stats.get_int("MPX_XM22_LAB_OWNED") ~= 0
	if (not acidLabOwned) then
		ImGui.Text("You don't own an acid lab.")
		return
	end

	ImGui.SeparatorText("Acid Lab")
	local acidUpdgrade = (stats.get_int("MPX_AWD_CALLME") >= 10)
		and (stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1)

	local acidUpgradeLabelCol = "white"
	local acidOffset = 0

	if (acidUpdgrade) then
		acidUpgradeLabelCol = "green"
		acidOffset = tunables.get_int("BIKER_ACID_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
	else
		acidUpgradeLabelCol = "red"
		acidOffset = 0
	end

	local acidSupplies = stats.get_int("MPX_MATTOTALFORFACTORY6")
	local acidStock = stats.get_int("MPX_PRODTOTALFORFACTORY6")
	acidLabTotalValue = tunables.get_int("BIKER_ACID_PRODUCT_VALUE") + acidOffset * acidStock

	ImGui.BulletText("Lab Upgrade: ")
	ImGui.SameLine()
	GUI:TextColored(acidUpdgrade and "Active" or "Inactive", Color(acidUpgradeLabelCol))
	ImGui.BulletText("Supplies:")
	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()
	ImGui.ProgressBar((acidSupplies / 100), 240, 30)

	ImGui.SameLine()
	ImGui.BeginDisabled(acidSupplies >= 100)
	if (GUI:Button(_F(" %s ##acid", _T "SUPPLIES_FILL"))) then
		FreemodeGlobal:At(6):At(1):WriteInt(1)
	end
	ImGui.EndDisabled()

	ImGui.BulletText("Stock:")
	ImGui.SameLine()
	ImGui.Dummy(33, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(acidStock / 160),
		240,
		30,
		_F(
			"%d Sheets (%d%%)",
			acidStock,
			math.floor(acidStock / 16 * 10)
		)
	)

	ImGui.SameLine()
	ImGui.Text(("Value: %s"):format(string.formatmoney(acidLabTotalValue)))

	ImGui.Spacing()
	ImGui.SeparatorText(_T "QUICK_TP_TXT")

	if (GUI:Button("Teleport To The Freakshop")) then
		YRV3:Teleport(848)
	end
end

local function drawBikerBusiness()
	if (not YRV3:DoesPlayerOwnAnyBikerBusiness()) then
		ImGui.Text("You don't own any biker businesses.")
		return
	end

	YRV3.m_biker_value_sum = 0

	for i, data in ipairs(YRV3.m_biker_data) do
		local slot = i - 1
		local business = YRV3.m_biker_data[i]
		data.isOwned = stats.get_int(("MPX_PROP_FAC_SLOT%d"):format(slot)) ~= 0

		if (data.isOwned) then
			ownsBikerBusiness = true

			if (not business.wasChecked) then
				YRV3:PopulateBikerBusinessSlot(i)
			elseif (business.name and business.value_tunable) then
				ImGui.PushID(i)
				ImGui.SeparatorText(business.name)

				data.totalSupplies = stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
				data.totalStock = stats.get_int(_F("MPX_PRODTOTALFORFACTORY%d", slot))
				data.totalValue = tunables.get_int(business.value_tunable) * data.totalStock
				YRV3.m_biker_value_sum = YRV3.m_biker_value_sum + data.totalValue

				ImGui.BulletText("Supplies:")
				ImGui.SameLine()
				ImGui.Dummy(10, 1)
				ImGui.SameLine()
				ImGui.ProgressBar(data.totalSupplies / 100, 240, 30)

				ImGui.SameLine()
				ImGui.BeginDisabled(data.totalSupplies >= 100)
				if (GUI:Button(_F(" %s ##%d", _T("SUPPLIES_FILL"), i))) then
					FreemodeGlobal:At(slot):At(1):WriteInt(1)
				end
				ImGui.EndDisabled()

				ImGui.SameLine()
				if (GUI:Button(_F("Teleport##%d", i))) then
					if (not business.blip) then
						return
					end

					YRV3:Teleport(business.blip)
				end

				ImGui.BulletText("Stock:")
				ImGui.SameLine()
				ImGui.Dummy(33, 1)
				ImGui.SameLine()

				ImGui.ProgressBar(
					(data.totalStock / business.unit_max),
					240,
					30,
					_F("%d%%", math.floor(data.totalStock * (100 / business.unit_max)))
				)

				ImGui.BulletText(_F("Sell Value:\tBlaine County: %s | Los Santos: %s",
					string.formatmoney(data.totalValue),
					string.formatmoney(math.floor(data.totalValue * 1.5))
				)
				)
				ImGui.PopID()
			end
		else
			ImGui.Text("You don't own this business.")
		end
	end

	if (ownsBikerBusiness) then
		ImGui.Separator()
		ImGui.Spacing()
		ImGui.BulletText(
			_F("Approximate Total MC Business Value: %s", string.formatmoney(YRV3.m_biker_value_sum))
		)
		GUI:Tooltip("Prices may be higher depending on your business upgrades.")
	end
end

local function drawBusinessSafes()
	YRV3.m_safe_cash_sum = 0

	for name, data in pairs(YRV3.m_safe_cash_data) do
		ImGui.PushID(name)

		if data.isOwned() then
			local cashValue = data.cashValue()
			YRV3.m_safe_cash_sum = YRV3.m_safe_cash_sum + cashValue

			ImGui.Spacing()
			ImGui.SeparatorText(name)

			if (IsInstance(data.popularity, "function")) then
				local popValue = data.popularity()
				ImGui.BulletText("Popularity: ")
				ImGui.SameLine()
				ImGui.Dummy(18, 1)
				ImGui.SameLine()
				ImGui.ProgressBar(popValue / 1e3, 240, 30, _F("%d%%", math.floor(popValue / 10)))

				if (popValue < 1e3) then
					ImGui.SameLine()

					if GUI:Button(("Max Popularity##"):format(name)) then
						data.maxPop()
						Toast:ShowSuccess("Samurai's Scripts", "Nightclub popularity increased.")
					end
				end
			end

			ImGui.BulletText("Safe: ")
			ImGui.SameLine()
			ImGui.Dummy(60, 1)
			ImGui.SameLine()

			ImGui.ProgressBar(cashValue / data.max_cash, 240, 30, string.formatmoney(cashValue))
			ImGui.SameLine()
			if (GUI:Button(_F("Teleport##%s", name))) then
				YRV3:Teleport(data.blip)
			end
		end
		ImGui.PopID()
	end

	ImGui.Separator()
	ImGui.Spacing()
	ImGui.BulletText(_F("Total Cash In All Safes: %s", string.formatmoney(YRV3.m_safe_cash_sum)))
end

local cooldownsGrid = GridRenderer.new(1)
cooldownsGrid:AddCheckbox("MC Club Work", "features.yrv3.mc_work_cd", {
	persistent = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("mc_work_cd", true)
	end
})

cooldownsGrid:AddCheckbox("Hangar Crate Steal", "features.yrv3.hangar_cd", {
	persistent = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("hangar_cd", true)
	end
})

cooldownsGrid:AddCheckbox("Nightclub Management", "features.yrv3.nc_management_cd",
	{
		persistent = true,
		onClick = function()
			YRV3:SetCooldownStateDirty("nc_management_cd", true)
		end
	})

cooldownsGrid:AddCheckbox("Always Troublemaker", "features.yrv3.nc_vip_mission_chance", {
	persistent = true,
	tooltip = "Always spawns the troublemaker nightclub missions and disables the knocked out VIP missions.",
	onClick = function()
		YRV3:SetCooldownStateDirty("nc_vip_mission_chance", true)
	end
})

cooldownsGrid:AddCheckbox("CEO Crate Buy", "features.yrv3.ceo_crate_buy_cd", {
	persistent = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ceo_crate_buy_cd", true)
	end
})

cooldownsGrid:AddCheckbox("CEO Crate Sell", "features.yrv3.ceo_crate_sell_cd", {
	persistent = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ceo_crate_sell_cd", true)
	end
})

cooldownsGrid:AddCheckbox("Security Missions", "features.yrv3.security_missions_cd",
	{
		persistent = true,
		onClick = function()
			YRV3:SetCooldownStateDirty("security_missions_cd", true)
		end
	})

cooldownsGrid:AddCheckbox("Dax Work Cooldown", "features.yrv3.dax_work_cd", {
	persistent = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("dax_work_cd", true)
	end
})

cooldownsGrid:AddCheckbox("Garment Factory Files", "features.yrv3.garment_rob_cd",
	{
		persistent = true,
		onClick = function()
			YRV3:SetCooldownStateDirty("garment_rob_cd", true)
		end
	})

cooldownsGrid:AddCheckbox("Chicken Factory Raid", "features.yrv3.cfr_cd", {
	persistent = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("cfr_cd", true)
	end
})

cooldownsGrid:AddCheckbox("I/E Vehicle Sourcing", "features.yrv3.ie_vehicle_steal_cd",
	{
		persistent = true,
		onClick = function()
			YRV3:SetCooldownStateDirty("ie_vehicle_steal_cd", true)
		end
	})

cooldownsGrid:AddCheckbox("I/E Vehicle Selling", "features.yrv3.ie_vehicle_sell_cd",
	{
		persistent = true,
		onClick = function()
			YRV3:SetCooldownStateDirty("ie_vehicle_sell_cd", true)
		end
	})

local function drawMisc()
	ImGui.SeparatorText("Cooldowns")

	cooldownsGrid:Draw()

	ImGui.BeginDisabled()
	ImGui.Checkbox("Payphone Hits [x]", false)
	ImGui.EndDisabled()
	if (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and KeyManager:IsKeyJustPressed(eVirtualKeyCodes.TAB)) then
		local url = "https://github.com/YimMenu-Lua/PayphoneHits"
		Toast:ShowMessage("YRV3", _F("URL '%s' copied to clipboard.", url), true, 6)
		ImGui.SetClipboardText(url)
	end
	GUI:Tooltip("Use ShinyWasabi's Payphone Hits script instead. Press [TAB] to copy the GitHub link.")

	ImGui.Dummy(1, 5)
	if (GetAllCDCheckboxes()) then
		sCooldownButtonLabel, bCooldownParam = "Uncheck All", false
	else
		sCooldownButtonLabel, bCooldownParam = "Check All", true
	end

	if (GUI:Button(sCooldownButtonLabel or "", { size = vec2:new(120, 40) })) then
		SetAllCDCheckboxes(bCooldownParam)
	end

	ImGui.Spacing()
	ImGui.SeparatorText("Sell Missions")

	ImGui.Spacing()
	ImGui.TextWrapped(
		"These options will not be saved. Each button disables the most tedious sell missions for that business.")

	ImGui.Spacing()
	GUI:TextColored(
		"[NOTE]: If you plan on selling more than once for the same business, please switch sessions after finishing the first sale to reset the missions, otherwise a sesond one will more than likely fail to start.",
		Color("yellow")
	)

	for name, data in pairs(YRV3.t_ShittyMissions) do
		local isFloat      = (data.type == "float")
		local get_func     = isFloat and tunables.get_float or tunables.get_int
		local set_func     = isFloat and tunables.set_float or tunables.set_int
		local desiredValue = isFloat and 0.0 or 1
		local style        = ImGui.GetStyle()
		local label        = _F("Easy %s Sell Missions", name)
		local buttonWidth  = ImGui.CalcTextSize(label) + style.FramePadding.x

		if (GUI:Button(label)) then
			for _, index in pairs(data.tuneable) do
				if get_func(index) ~= desiredValue then
					set_func(index, desiredValue)
				end
			end

			Toast:ShowSuccess("Samurai's Scripts", _F("Disabled the most annoying %s sell missions.", name:lower())
			)
		end

		ImGui.SameLine()
		if (ImGui.GetContentRegionAvail() <= (buttonWidth + style.ItemSpacing.x)) then
			ImGui.NewLine()
		end
	end
end

local function drawSettings()
	ImGui.SeparatorText("Auto Sell")
	ImGui.TextWrapped("Note: Only these businesses are supported:")
	ImGui.BulletText("Bunker")
	ImGui.BulletText("Hangar (Air only)")
	ImGui.BulletText("CEO Warehouses")
	ImGui.BulletText("MC Businesses")
	ImGui.BulletText("Acid Lab")
	ImGui.Spacing()
	ImGui.Text(_F("Currently Selling: %s", YRV3.m_sell_script_disp_name))
	ImGui.BeginDisabled(YRV3.m_has_triggered_autosell)
	GVars.features.yrv3.autosell, _ = GUI:Checkbox("Auto-Sell", GVars.features.yrv3.autosell)
	ImGui.EndDisabled()
	GUI:Tooltip(
		"Automatically finishes a sale mission 20 seconds after it starts. Doesn't require you to interact with anything other than starting the mission."
	)

	if (script.is_active("fm_content_smuggler_sell")) then
		GUI:TextColored("Land sales are currently not supported.", Color("red"))
	else
		ImGui.BeginDisabled(GVars.features.yrv3.autosell or YRV3.m_has_triggered_autosell or
			not YRV3.m_sell_script_running)
		if (GUI:Button("Manually Finish Sale")) then
			YRV3.m_has_triggered_autosell = true
			YRV3:FinishSale()
			script.run_in_fiber(function()
				repeat
					yield()
				until not YRV3.m_sell_script_running
				YRV3.m_has_triggered_autosell = false
			end)
		end
		ImGui.EndDisabled()
	end

	ImGui.SeparatorText("Auto Fill Cargo")
	ImGui.Text("Global Auto-Fill delay:")
	GVars.features.yrv3.autofill_delay, _ = ImGui.SliderFloat("##autofilldelay", GVars.features.yrv3.autofill_delay, 100,
		5000, "%.0f ms")
	ImGui.SameLine()
	ImGui.Text(_F("%.1fs", GVars.features.yrv3.autofill_delay / 1000))
end

local tabCallbacks <const> = {
	[tabNames[1]] = drawCEOwarehouses,
	[tabNames[2]] = drawHangar,
	[tabNames[3]] = drawBunker,
	[tabNames[4]] = drawAcidLab,
	[tabNames[5]] = drawBikerBusiness,
	[tabNames[6]] = drawBusinessSafes,
	[tabNames[7]] = drawMisc,
	[tabNames[8]] = drawSettings,
}

local function YRV3UI()
	if (yrv3_state.disabled) then
		ImGui.Text(yrv3_state.reason)
		return
	end

	if (not YRV3:CanAccess()) then
		ImGui.Text(_T("OFFLINE_OR_OUTDATED"))
		return
	end

	if ImGui.BeginChild("yrv3_header", 0, 100, false, ImGuiWindowFlags.AlwaysUseWindowPadding) then
		local textWidth = ImGui.CalcTextSize("Master Control Terminal") + ImGui.GetStyle().FramePadding.x + 10
		local regionWidth = ImGui.GetWindowWidth()
		ImGui.SetCursorPosX((regionWidth - textWidth) / 2)

		if (GUI:Button("Master Control Terminal")) then
			YRV3:MCT()
		end

		ImGui.Spacing()
		ImGui.SetWindowFontScale(0.85)
		ImGui.BulletText("Approximate Income From All Businesses: ")
		GUI:Tooltip("Cycle through all tabs to update the total amount.")

		ImGui.SameLine()

		GUI:TextColored(string.formatmoney(CalcTotalBusinessIncome()), Color("#85BB65"))
		GUI:Tooltip("Cycle through all tabs to update the total amount.")
		ImGui.SetWindowFontScale(1)
		ImGui.EndChild()
	end

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	if ImGui.BeginChild("##yrv3_tabbar", 0, 40, false, ImGuiWindowFlags.NoScrollbar) then
		ImGui.BeginTabBar("##BusinessManager")
		for i = 1, #tabNames do
			local name = tabNames[i]
			if (ImGui.BeginTabItem(name)) then
				selectedTabName = name
				ImGui.EndTabItem()
			end
		end
		ImGui.EndChild()
	end
	ImGui.EndTabBar()

	ImGui.SetNextWindowBgAlpha(0)
	if (ImGui.BeginChild("main", 0, GVars.ui.window_size.y - 240, true)) then
		for name, callback in pairs(tabCallbacks) do
			if (name == selectedTabName and type(callback) == "function") then
				callback()
			end
		end
		ImGui.EndChild()
	end
end

GUI:RegisterNewTab(eTabID.TAB_ONLINE, "YRV3", YRV3UI)
