local sCooldownButtonLabel, bCooldownParam
local SGSL                       = require("includes.services.SGSL")
local hangarSupplies             = 0
local hangarTotalValue           = 0
local bunkerTotalValue           = 0
local acidLabTotalValue          = 0
local ownsWarehouse              = false
local ownsBikerBusiness          = false
local maxSellMissionButtonSize   = vec2:new(80, 30)
local progressBarSize            = vec2:new(300, 25)
local moneyGreen                 = Color("#85BB65")

local yrv3_state                 = {
	disabled = false,
	reason   = _T("GENERIC_CONTACT_DEV")
}

local tabNames <const>           = {
	"CEO",
	"Hangar",
	"Bunker",
	"Acid Lab",
	"Biker Business",
	"Safes",
	"Money Fronts",
	"Misc",
	"Settings"
}

local money_fronts_order <const> = {
	"YRV3_CWASH_LABEL",
	"YRV3_WEED_SHOP_LABEL",
	"YRV3_HELITOURS_LABEL",
}

local selectedTabName            = tabNames[1]

local function CalcTotalBusinessIncome()
	return math.sum(
		YRV3.m_biker_value_sum,
		YRV3.m_ceo_value_sum,
		YRV3.m_safe_cash_sum,
		YRV3.m_cwash_cash_sum,
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
		ImGui.Text(_T("YRV3_CEO_NONE_OWNED"))
		return
	end

	YRV3.m_ceo_value_sum = 0
	for i, wh in ipairs(YRV3.m_warehouse_data) do
		local slot = i - 1
		wh.is_owned = stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(slot)) > 0

		if (not wh.is_owned) then
			goto continue
		end

		ownsWarehouse = true

		if (not YRV3.m_warehouse_data[i].was_checked) then
			YRV3:PopulateCEOwarehouseSlot(i)
		else
			wh.total_supplies    = stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(slot))
			wh.total_value       = YRV3:GetCEOCratesValue(wh.total_supplies or 0)
			YRV3.m_ceo_value_sum = YRV3.m_ceo_value_sum + wh.total_value

			if (wh.name and wh.size and wh.max) then
				ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
				ImGui.BeginChild(_F("wh##%d", i),
					0,
					180,
					false,
					ImGuiWindowFlags.NoScrollbar
					| ImGuiWindowFlags.AlwaysUseWindowPadding
				)
				ImGui.PushID(i)
				ImGui.SeparatorText(tostring(wh.name))
				ImGui.BulletText(_T("YRV3_CARGO_AMT"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
				ImGui.ProgressBar(
					(wh.total_supplies / wh.max),
					progressBarSize.x,
					progressBarSize.y,
					_F(
						"%d %s (%d%%)",
						wh.total_supplies,
						_T("YRV3_CRATES_LABEL"),
						(math.floor(wh.total_supplies / wh.max) * 100)
					)
				)
				ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
				GUI:Text(string.formatmoney(wh.total_value), { color = moneyGreen })
				ImGui.Spacing()

				if (wh.coords) then
					if GUI:Button(_F("%s##%d", _T("GENERIC_TELEPORT"), i)) then
						YRV3:Teleport(wh.coords)
					end
				end

				ImGui.SameLine()
				ImGui.BeginDisabled(wh.total_supplies >= wh.max)
				ImGui.BeginDisabled(wh.auto_fill_enabled)
				if GUI:Button(_F("%s##wh%d", _T("YRV3_RANDOM_CRATES"), i)) then
					stats.set_bool_masked(
						"MPX_FIXERPSTAT_BOOL1",
						true,
						i + 11
					)
				end
				ImGui.EndDisabled()
				ImGui.SameLine()
				YRV3.m_warehouse_data[i].auto_fill_enabled, _ = GUI:Checkbox(_F("%s##wh%d", _T("YRV3_AUTO_FILL"), i),
					YRV3.m_warehouse_data[i].auto_fill_enabled)
				ImGui.EndDisabled()
				ImGui.PopID()
				ImGui.EndChild()
				ImGui.PopStyleVar()
			end
		end
		::continue::
	end

	if (ownsWarehouse) then
		ImGui.Spacing()
		ImGui.BulletText(_F("%s: %s", _T("YRV3_VALUE_TOTAL"), string.formatmoney(YRV3.m_ceo_value_sum)))
		ImGui.Dummy(1, 5)
		ImGui.SeparatorText(_T("GENERIC_MISC"))
		ImGui.Spacing()
		local bCond = (not script.is_active("gb_contraband_buy") and not script.is_active("fm_content_cargo"))
		ImGui.BeginDisabled(bCond)
		if (GUI:Button(_T("YRV3_FINISH_SOURCE_MISSION"))) then
			YRV3:FinishCEOCargoSourceMission()
		end
		ImGui.EndDisabled()

		if (bCond) then
			GUI:Tooltip(_T("YRV3_FINISH_SOURCE_MISSION_TT"))
		end
	end
end

local function drawHangar()
	local hangar_index = stats.get_int("MPX_HANGAR_OWNED")
	local hangarOwned = hangar_index ~= 0

	if (not hangarOwned) then
		ImGui.Text(_T("YRV3_HANGAR_NOT_OWNED"))
		return
	end

	local hangar_name = YRV3.m_raw_data.Hangars[hangar_index].name
	local hangar_pos = YRV3.m_raw_data.Hangars[hangar_index].coords

	ImGui.SeparatorText(hangar_name)
	hangarSupplies = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
	hangarTotalValue = hangarSupplies * 30000

	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(
		(hangarSupplies / 50),
		progressBarSize.x,
		progressBarSize.y
	)

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(
		(hangarSupplies / 50),
		progressBarSize.x,
		progressBarSize.y,
		_F("%d %s (%d%%)", hangarSupplies, _T("YRV3_CRATES_LABEL"), math.floor(hangarSupplies / 0.5))
	)

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(string.formatmoney(hangarTotalValue), { color = moneyGreen })
	ImGui.Spacing()

	if GUI:Button(_T("GENERIC_TELEPORT")) then
		YRV3:Teleport(hangar_pos, true)
	end

	ImGui.SameLine()
	local is_maxed = hangarSupplies == 50
	ImGui.BeginDisabled(YRV3.m_hangar_loop or is_maxed)
	if GUI:Button(_F("%s##hangar", _T("YRV3_RANDOM_CRATES"))) then
		script.run_in_fiber(function()
			stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
		end)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled(is_maxed)
	YRV3.m_hangar_loop, _ = GUI:Checkbox(_F("%s##hangar", _T("YRV3_AUTO_FILL")), YRV3.m_hangar_loop)
	ImGui.EndDisabled()
end

local function drawBunker()
	local bunker = YRV3.m_biker_ext_data.bunker
	if (not bunker.is_owned) then
		ImGui.Text(_T("YRV3_BUNKER_NOT_OWNED"))
		return
	end

	ImGui.SeparatorText(bunker.name)

	local bunkerUpdgrade1  = bunker.equipment_upgrade
	local bunkerUpdgrade2  = bunker.staff_upgrade
	local bunkerOffset1    = bunker.value_offset_1
	local bunkerOffset2    = bunker.value_offset_2
	local bunkerEqLabelCol = bunkerUpdgrade1 and "green" or "red"
	local bunkerStLabelCol = bunkerUpdgrade2 and "green" or "red"
	local bunkerSupplies   = stats.get_int("MPX_MATTOTALFORFACTORY5")
	local bunkerStock      = stats.get_int("MPX_PRODTOTALFORFACTORY5")
	bunkerTotalValue       = (tunables.get_int("GR_MANU_PRODUCT_VALUE") + bunkerOffset1 + bunkerOffset2) * bunkerStock

	ImGui.BulletText(_T("YRV3_EQUIP_UPGDRADE"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(bunkerUpdgrade1 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), { color = Color(bunkerEqLabelCol) })

	ImGui.BulletText(_T("YRV3_STAFF_UPGDRADE"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(bunkerUpdgrade2 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), { color = Color(bunkerStLabelCol) })

	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar((bunkerSupplies / 100), progressBarSize.x, progressBarSize.y)

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(
		(bunkerStock / bunker.unit_max),
		progressBarSize.x,
		progressBarSize.y,
		_F("%d %s (%d%%)", bunkerStock, _T("YRV3_CRATES_LABEL"), bunkerStock)
	)

	ImGui.BulletText(_F(
		"%s\tBlaine County: %s | Los Santos: %s",
		_T("YRV3_VALUE_TOTAL"),
		string.formatmoney(bunkerTotalValue),
		string.formatmoney(math.floor(bunkerTotalValue * 1.5))
	))
	ImGui.Spacing()

	if (GUI:Button(_T("GENERIC_TELEPORT"))) then
		YRV3:Teleport(bunker.coords, true)
	end

	ImGui.SameLine()
	ImGui.BeginDisabled(bunkerSupplies >= 100)
	if (GUI:Button(_F(" %s ##bunker", _T("YRV3_FILL_SUPPLIES")))) then
		YRV3:FillBikerBusiness(5)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled(bunkerStock == bunker.unit_max or bunkerSupplies < 5 or bunker.fast_prod_enabled)
	if (GUI:Button(_F(" %s ##bunker", _T("YRV3_TRIGGER_PROD")), { repeatable = true })) then
		YRV3:TriggerBBProduction(5)
	end
	ImGui.EndDisabled()
	GUI:HelpMarker(_T("YRV3_TRIGGER_PROD_TT"))

	ImGui.SameLine()
	ImGui.BeginDisabled(bunkerStock == bunker.unit_max)
	bunker.fast_prod_enabled, _ = GUI:Checkbox(_T("YRV3_AUTO_PROD"), bunker.fast_prod_enabled)
	ImGui.EndDisabled()
end

local function drawAcidLab()
	local acidLab = YRV3.m_biker_ext_data.acid_lab
	if (not acidLab.is_owned) then
		ImGui.Text(_T("YRV3_LSD_LAB_NOT_OWNED"))
		return
	end

	local acidUpdgrade        = acidLab.equipment_upgrade
	local acidOffset          = acidLab.value_offset_1
	local acidUpgradeLabelCol = acidUpdgrade and "green" or "red"
	local acidSupplies        = stats.get_int("MPX_MATTOTALFORFACTORY6")
	local acidStock           = stats.get_int("MPX_PRODTOTALFORFACTORY6")
	acidLabTotalValue         = tunables.get_int("BIKER_ACID_PRODUCT_VALUE") + acidOffset * acidStock

	ImGui.BulletText(_T("YRV3_EQUIP_UPGDRADE"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(acidUpdgrade and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), { color = Color(acidUpgradeLabelCol) })
	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar((acidSupplies / 100), progressBarSize.x, progressBarSize.y)

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(
		(acidStock / acidLab.unit_max),
		progressBarSize.x,
		progressBarSize.y,
		_F(
			"%d %s (%d%%)",
			acidStock,
			_T("YRV3_CRATES_LABEL"),
			math.floor(acidStock / acidLab.unit_max)
		)
	)

	ImGui.Text(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(string.formatmoney(acidLabTotalValue), { color = moneyGreen })

	ImGui.Spacing()
	if (GUI:Button(_T("GENERIC_TELEPORT"))) then
		YRV3:Teleport(acidLab.blip)
	end

	ImGui.SameLine()
	ImGui.BeginDisabled(acidSupplies >= 100)
	if (GUI:Button(_F(" %s ##acid", _T("YRV3_FILL_SUPPLIES")))) then
		YRV3:FillBikerBusiness(6)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled(acidStock == acidLab.unit_max or acidSupplies < 20)
	if (GUI:Button(_F(" %s ##bunker", _T("YRV3_TRIGGER_PROD")), { repeatable = true })) then
		YRV3:TriggerBBProduction(6)
	end
	ImGui.EndDisabled()
	GUI:HelpMarker(_T("YRV3_TRIGGER_PROD_TT"))

	ImGui.SameLine()
	ImGui.BeginDisabled(acidStock == acidLab.unit_max)
	acidLab.fast_prod_enabled, _ = GUI:Checkbox(_T("YRV3_AUTO_PROD"), acidLab.fast_prod_enabled)
	ImGui.EndDisabled()
end

local function drawBikerBusiness()
	if (not YRV3:DoesPlayerOwnAnyBikerBusiness()) then
		ImGui.Text(_T("YRV3_MC_NONE_OWNED"))
		return
	end

	YRV3.m_biker_value_sum = 0

	for i, data in ipairs(YRV3.m_biker_data) do
		local slot = i - 1
		local business = YRV3.m_biker_data[i]
		data.is_owned = stats.get_int(_F("MPX_PROP_FAC_SLOT%d", slot)) ~= 0

		if (not data.is_owned) then
			goto continue
		end

		ownsBikerBusiness = true

		if (not business.was_checked) then
			YRV3:PopulateBikerBusinessSlot(i)
		elseif (business.name and business.value_tunable) then
			data.total_supplies    = stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
			data.total_stock       = stats.get_int(_F("MPX_PRODTOTALFORFACTORY%d", slot))
			data.total_value       = tunables.get_int(business.value_tunable) * data.total_stock
			YRV3.m_biker_value_sum = YRV3.m_biker_value_sum + data.total_value

			ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
			ImGui.BeginChild(_F("mc##%d", i),
				0,
				220,
				false,
				ImGuiWindowFlags.NoScrollbar
				| ImGuiWindowFlags.AlwaysUseWindowPadding
			)
			ImGui.PushID(i)
			ImGui.SeparatorText(business.name)
			ImGui.Spacing()

			ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
			ImGui.SameLine()
			ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
			ImGui.ProgressBar(data.total_supplies / 100, progressBarSize.x, progressBarSize.y)

			ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
			ImGui.SameLine()
			ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
			ImGui.ProgressBar(
				(data.total_stock / business.unit_max),
				progressBarSize.x,
				progressBarSize.y,
				_F("%d%%", math.floor(data.total_stock * (100 / business.unit_max)))
			)

			ImGui.BulletText(_F("%s:\tBlaine County: %s | Los Santos: %s",
				_T("YRV3_VALUE_TOTAL"),
				string.formatmoney(data.total_value),
				string.formatmoney(math.floor(data.total_value * 1.5))
			))

			ImGui.Spacing()
			if (GUI:Button(_F("%s##%d", _T("GENERIC_TELEPORT"), i))) then
				if (not business.coords) then
					return
				end

				YRV3:Teleport(business.coords)
			end

			ImGui.SameLine()
			ImGui.BeginDisabled(data.total_supplies >= 100)
			if (GUI:Button(_F(" %s ##%d", _T("YRV3_SUPPLIES_FILL"), i))) then
				YRV3:FillBikerBusiness(slot)
			end
			ImGui.EndDisabled()

			ImGui.SameLine()
			ImGui.BeginDisabled(data.total_stock == data.unit_max or data.total_supplies < 20 or data.fast_prod_enabled)
			if (GUI:Button(_F(" %s ##bunker", _T("YRV3_TRIGGER_PROD")), { repeatable = true })) then
				YRV3:TriggerBBProduction(slot)
			end
			ImGui.EndDisabled()
			GUI:HelpMarker(_T("YRV3_TRIGGER_PROD_TT"))

			ImGui.SameLine()
			ImGui.BeginDisabled(data.total_stock == data.unit_max)
			data.fast_prod_enabled, _ = GUI:Checkbox(_T("YRV3_AUTO_PROD"), data.fast_prod_enabled)
			ImGui.EndDisabled()

			ImGui.PopID()
			ImGui.EndChild()
			ImGui.PopStyleVar()
		end
		::continue::
	end

	if (ownsBikerBusiness) then
		ImGui.Separator()
		ImGui.Spacing()
		ImGui.BulletText(_T("YRV3_INCOME_APPROX_MC"))
		ImGui.SameLine()
		GUI:Text(string.formatmoney(YRV3.m_biker_value_sum), { color = moneyGreen })
		GUI:Tooltip(_T("YRV3_PRICE_NOTICE"))
	end
end

local function drawBusinessSafes()
	YRV3.m_safe_cash_sum = 0

	for name, data in pairs(YRV3.m_safe_cash_data) do
		if (not data.is_owned()) then
			goto continue
		end

		local hasSpecial = type(data.get_special_val) == "function"
		ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
		ImGui.BeginChild(name,
			0,
			hasSpecial and 200 or 160,
			false,
			ImGuiWindowFlags.NoScrollbar
			| ImGuiWindowFlags.AlwaysUseWindowPadding
		)
		ImGui.PushID(name)
		local cashValue      = data.cash_value()
		local popValue       = hasSpecial and data.get_special_val() or 0
		YRV3.m_safe_cash_sum = YRV3.m_safe_cash_sum + cashValue

		ImGui.SeparatorText(name)
		ImGui.Spacing()

		if (hasSpecial) then
			ImGui.BulletText(_F("%s: ", _T("YRV3_POPULARITY")))
			ImGui.SameLine()
			ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
			ImGui.ProgressBar(popValue / 1e3,
				progressBarSize.x,
				progressBarSize.y,
				_F("%d%%", math.floor(popValue / 10))
			)
		end

		ImGui.BulletText(_F("%s: ", _T("GENERIC_SAFE")))
		ImGui.SameLine()
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
		ImGui.ProgressBar(cashValue / data.max_cash,
			progressBarSize.x,
			progressBarSize.y,
			string.formatmoney(cashValue)
		)

		ImGui.Spacing()

		if (GUI:Button(_F("%s##%s", _T("GENERIC_TELEPORT"), name))) then
			YRV3:Teleport(data.blip)
		end

		if (hasSpecial) then
			ImGui.SameLine()
			ImGui.BeginDisabled(popValue >= 1e3)
			if GUI:Button(_F("%s %s##", _T("GENERIC_MAX"), _T("YRV3_POPULARITY"), name)) then
				data.set_special_val()
				Notifier:ShowSuccess("Samurai's Scripts", _T("YRV3_POPULARITY_NOTIF"))
			end
			ImGui.EndDisabled()
		end

		ImGui.PopID()
		ImGui.EndChild()
		ImGui.PopStyleVar()

		::continue::
	end

	ImGui.Separator()
	ImGui.Spacing()
	ImGui.BulletText(_T("YRV3_SAFECASH_TOTAL"))
	ImGui.SameLine()
	GUI:Text(string.formatmoney(YRV3.m_safe_cash_sum), { color = moneyGreen })
end

local function drawMoneyFronts()
	if (not YRV3.m_money_fronts_data["YRV3_CWASH_LABEL"].is_owned()) then
		ImGui.Text(_T("YRV3_CWASH_NOT_OWNED"))
		return
	end

	YRV3.m_cwash_cash_sum = 0
	for i = 1, #money_fronts_order do
		local label = money_fronts_order[i]
		local data = YRV3.m_money_fronts_data[label]

		if (not data.is_owned()) then
			goto continue
		end

		local region_width, _ = ImGui.GetContentRegionAvail()
		ImGui.PushID(label)
		ImGui.SeparatorText(_T(label))
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			Self:Teleport(data.coords, false)
		end

		if (data.cash_value) then
			local cw_dirty_cash = data.dirty_cash()
			local cw_clean_cash = data.duffel_total() - cw_dirty_cash
			local cw_safe_cash = data.cash_value()
			local dirty_cash_text = string.formatmoney(cw_dirty_cash)
			local clean_cash_text = string.formatmoney(cw_clean_cash)
			local cw_cash_text = _F("%s %s | %s %s",
				_T("YRV3_CWASH_CASH_DIRTY"),
				dirty_cash_text,
				_T("YRV3_CWASH_CASH_CLEAN"),
				clean_cash_text
			)
			local duffel_cash_text_width = ImGui.CalcTextSize(cw_cash_text)
			ImGui.BulletText(_T("YRV3_CWASH_WORK_EARNINGS"))
			ImGui.SameLine()
			ImGui.SetCursorPosX(region_width - duffel_cash_text_width)
			ImGui.Text(cw_cash_text)
			ImGui.Spacing()
			ImGui.BulletText(_T("GENERIC_SAFE"))
			ImGui.SameLine()
			ImGui.SetCursorPosX(region_width - 240)
			ImGui.ProgressBar(cw_safe_cash / (data.max_cash or 1), 240, 32, string.formatmoney(cw_safe_cash))
			YRV3.m_cwash_cash_sum = YRV3.m_cwash_cash_sum + cw_clean_cash + cw_safe_cash
		end

		local heat = data.get_special_val()
		local heatcol = math.max(0, heat / 100)
		local clearButtonLabel = _T("GENERIC_CLEAR")
		local clearButtonWidth, _ = ImGui.CalcTextSize(clearButtonLabel)
		local style = ImGui.GetStyle()
		ImGui.BulletText(_T("YRV3_CWASH_HEAT"))
		ImGui.SameLine()
		ImGui.SetCursorPosX(region_width - clearButtonWidth - 240 - (style.ItemSpacing.x * 2))
		ImGui.BeginDisabled(heat == 0)
		if (GUI:Button(_T("GENERIC_CLEAR"))) then
			data.set_special_val()
		end
		ImGui.EndDisabled()
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram, heatcol, 1 - heatcol, 0, 1)
		ImGui.ProgressBar(heat / (data.max_heat or 100), 240, 32, _F("%d%%", heat))
		ImGui.PopStyleColor()

		local cb1_val = table.get_nested_key(GVars, data.gvar_key_1)
		cb1_val, data.cb1_clicked = GUI:Checkbox(_T("YRV3_CWASH_LEGAL_WORK_CD"), cb1_val)
		if (data.cb1_clicked) then
			data.on_cb1_click(YRV3, cb1_val)
		end

		local cb2_val = table.get_nested_key(GVars, data.gvar_key_2)
		cb2_val, data.cb2_clicked = GUI:Checkbox(_T("YRV3_CWASH_ILLEGAL_WORK_CD"), cb2_val)
		if (data.cb2_clicked) then
			data.on_cb2_click(YRV3, cb2_val)
		end

		ImGui.PopID()
		ImGui.Spacing()

		::continue::
	end
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

local function drawMisc()
	ImGui.SeparatorText(_T("YRV3_COOLDOWNS_LABEL"))

	cooldownsGrid:Draw()

	ImGui.BeginDisabled()
	ImGui.Checkbox(_F("%s [x]", _T("YRV3_PAYHPONE_HITS_CB")), false)
	ImGui.EndDisabled()
	if (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and KeyManager:IsKeyJustPressed(eVirtualKeyCodes.TAB)) then
		local url = "https://github.com/YimMenu-Lua/PayphoneHits"
		Notifier:ShowMessage("YRV3", _F(_T("GENERIC_URL_COPY_SUCCESS"), url), true, 6)
		ImGui.SetClipboardText(url)
	end
	GUI:Tooltip(_T("YRV3_SEXY_SHINABI_NOTICE"))

	ImGui.Dummy(1, 5)
	if (GetAllCDCheckboxes()) then
		sCooldownButtonLabel, bCooldownParam = "YRV3_CB_UNCHECK_ALL", false
	else
		sCooldownButtonLabel, bCooldownParam = "YRV3_CB_CHECK_ALL", true
	end

	if (GUI:Button(_T(sCooldownButtonLabel), { size = vec2:new(120, 40) })) then
		SetAllCDCheckboxes(bCooldownParam)
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_SELL_MISSIONS_LABEL"))

	ImGui.Spacing()
	ImGui.TextWrapped(_T("YRV3_SELL_MISSIONS_TT"))

	ImGui.Spacing()
	GUI:Text(_T("YRV3_SELL_MISSIONS_NOTE"), Color("yellow"))

	for name, data in pairs(YRV3.m_raw_data.SellMissionTunables) do
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

			Notifier:ShowSuccess("Samurai's Scripts", _F(_T("YRV3_SELL_MISSIONS_NOTIF"), name:lower()))
		end

		ImGui.SameLine()
		if (ImGui.GetContentRegionAvail() <= (buttonWidth + style.ItemSpacing.x)) then
			ImGui.NewLine()
		end
	end
end

local function drawSettings()
	ImGui.SeparatorText(_T("YRV3_AUTO_SELL"))
	ImGui.TextWrapped(_T("YRV3_AUTO_SELL_SUPPORT_NOTICE"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_BUNKER_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_HANGAR_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_CEO_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_BIKER_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_LSD_LAB_LABEL"))
	ImGui.Spacing()
	ImGui.BeginDisabled(YRV3.m_has_triggered_autosell)
	GVars.features.yrv3.autosell, _ = GUI:Checkbox(_T("YRV3_AUTO_SELL"), GVars.features.yrv3.autosell)
	ImGui.EndDisabled()
	GUI:Tooltip(_T("YRV3_AUTOSELL_TT"))

	if (script.is_active("fm_content_smuggler_sell")) then
		GUI:Text(_T("YRV3_HANGAR_LAND_ERR"), Color("red"))
	else
		ImGui.BeginDisabled(GVars.features.yrv3.autosell or YRV3.m_has_triggered_autosell or
			not YRV3.m_sell_script_running)
		if (GUI:Button(_T("YRV3_AUTO_SELL_MANUAL"))) then
			YRV3.m_has_triggered_autosell = true
			YRV3:FinishSale()
			ThreadManager:Run(function()
				repeat
					yield()
				until not YRV3.m_sell_script_running
				YRV3.m_has_triggered_autosell = false
			end)
		end
		ImGui.EndDisabled()
	end

	ImGui.Text(_F(_T("YRV3_AUTOSELL_CURRENT"), YRV3.m_sell_script_disp_name))

	ImGui.SeparatorText(_T("YRV3_AUTO_FILL"))
	ImGui.Text(_T("YRV3_AUTO_FILL_DELAY"))
	ImGui.SetNextItemWidth(280)
	GVars.features.yrv3.autofill_delay, _ = ImGui.SliderFloat("##autofilldelay",
		GVars.features.yrv3.autofill_delay,
		100,
		5000,
		"%.0f ms"
	)
	ImGui.SameLine()
	ImGui.Text(_F("%.1f %s", GVars.features.yrv3.autofill_delay / 1000, _T("GENERIC_SECONDS_LABEL")))
end

local tabCallbacks <const> = {
	[tabNames[1]] = drawCEOwarehouses,
	[tabNames[2]] = drawHangar,
	[tabNames[3]] = drawBunker,
	[tabNames[4]] = drawAcidLab,
	[tabNames[5]] = drawBikerBusiness,
	[tabNames[6]] = drawBusinessSafes,
	[tabNames[7]] = drawMoneyFronts,
	[tabNames[8]] = drawMisc,
	[tabNames[9]] = drawSettings,
}

local function YRV3UI()
	if (yrv3_state.disabled) then
		ImGui.Text(yrv3_state.reason)
		return
	end

	if (not YRV3:CanAccess()) then
		ImGui.Text(_T("GENERIC_OFFLINE_OR_OUTDATED"))
		return
	end

	progressBarSize.x = math.max(progressBarSize.x, GVars.ui.window_size.x * 0.4)

	if ImGui.BeginChild("##yrv3_header", 0, 100, true, ImGuiWindowFlags.AlwaysUseWindowPadding) then
		local title = _T("YRV3_MCT_TITLE")
		local textWidth = ImGui.CalcTextSize(title) + ImGui.GetStyle().FramePadding.x + 10
		local regionWidth = ImGui.GetWindowWidth()
		ImGui.SetCursorPosX((regionWidth - textWidth) / 2)

		if (GUI:Button(title)) then
			if (YRV3.m_sell_script_running) then
				Notifier:ShowMessage("YRV3", _T("YRV3_MCT_UNAVAIL"))
			else
				YRV3:MCT()
				GUI:Close()
			end
		end

		ImGui.Spacing()
		ImGui.SetWindowFontScale(0.9)
		local tooltip = _T("YRV3_INCOME_APPROX_ALL_TT")
		ImGui.BulletText(_T("YRV3_INCOME_APPROX_ALL"))
		GUI:Tooltip(tooltip)
		ImGui.SameLine()
		GUI:Text(string.formatmoney(CalcTotalBusinessIncome()), { color = moneyGreen })
		GUI:Tooltip(tooltip)
		ImGui.SetWindowFontScale(1)
		ImGui.EndChild()
	end

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	if (ImGui.BeginChild("##yrv3_wrapped_tb", 0, 40, false, ImGuiWindowFlags.NoScrollbar)) then
		if (ImGui.BeginTabBar("##yrv3_tb")) then
			for i = 1, #tabNames do
				local name = tabNames[i]
				if (ImGui.BeginTabItem(name)) then
					selectedTabName = name
					ImGui.EndTabItem()
				end
			end
			ImGui.EndTabBar()
		end
		ImGui.EndChild()
	end

	ImGui.SetCursorPosY(ImGui.GetCursorPosY() - ImGui.GetStyle().ItemSpacing.y - 10)
	ImGui.SetNextWindowBgAlpha(0.75)
	if (ImGui.BeginChild("##yrv3_main", 0, GVars.ui.window_size.y - GUI:GetMaxTopBarHeight() - 100, false, ImGuiWindowFlags.AlwaysUseWindowPadding)) then
		for name, callback in pairs(tabCallbacks) do
			if (name == selectedTabName and type(callback) == "function") then
				callback()
			end
		end
		ImGui.EndChild()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YimResupplierV3", YRV3UI)
