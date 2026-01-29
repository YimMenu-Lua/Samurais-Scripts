-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL                       = require("includes.services.SGSL")
local Warehouse                  = require("includes.modules.businesses.Warehouse")
local BikerBusiness              = require("includes.modules.businesses.BikerBusiness")
local Nightclub                  = require("includes.modules.businesses.Nightclub")

local ScriptDisplayNames <const> = {
	["fm_content_smuggler_sell"] = "Hangar (Land. Not supported.)",
	["gb_smuggler"]              = "Hangar (Air)",
	["gb_contraband_sell"]       = "CEO",
	["gb_gunrunning"]            = "Bunker",
	["gb_biker_contraband_sell"] = "Biker Business",
	["fm_content_acid_lab_sell"] = "Acid Lab",
}

local NightclubNames <const>     = {
	"Maisonette Los Santos",
	"Studio Los Santos",
	"GALAXY",
	"Gefangnis",
	"Omega",
	"Technologie",
	"Paradise",
	"The Palace",
	"Tony's Fun House",
}

local ScriptsToTerminate <const> = {
	"appArcadeBusinessHub",
	"appsmuggler",
	"appbikerbusiness",
	"appbunkerbusiness",
	"appbusinesshub"
}

---@enum eYRState
Enums.eYRState                   = {
	OFFLINE = 0x0,
	WAITING = 0x1,
	LOADING = 0x2,
	RUNNING = 0x3,
	ERROR   = 0x4
}

---@class YRV3Businesses
---@field warehouses Warehouse[]
---@field biker_businesses BikerBusiness[]
---@field safes dict<CashSafe>
---@field hangar? Warehouse
---@field bunker? BikerBusiness
---@field acid_lab? BikerBusiness
---@field nightclub? Nightclub
---@field money_fronts? dict<MoneyFrontsBusiness>

---@class YRV3
---@field private m_last_error string
---@field private m_total_sum number
---@field private m_bhub_script_handle number
---@field private m_has_triggered_autosell boolean
---@field private m_sell_script_running boolean
---@field private m_sell_script_name string?
---@field private m_sell_script_disp_name string
---@field private m_raw_data RawBusinessData
---@field private m_businesses YRV3Businesses
---@field private m_last_as_check_time milliseconds
---@field private m_last_income_check_time milliseconds
---@field private m_cooldown_state_dirty boolean
---@field private m_initial_data_done boolean
---@field private m_data_initialized boolean
---@field protected m_state eYRState
---@field protected m_thread Thread?
---@field protected m_initialized boolean
local YRV3                       = { m_raw_data = require("includes.data.yrv3_data") }
YRV3.__index                     = YRV3

---@return YRV3
function YRV3:init()
	if (self.m_initialized) then
		return self
	end

	self.m_total_sum              = 0
	self.m_bhub_script_handle     = 0
	self.m_last_as_check_time     = 0
	self.m_last_income_check_time = 0
	self.m_state                  = Enums.eYRState.OFFLINE
	self.m_has_triggered_autosell = false
	self.m_sell_script_running    = false
	self.m_initial_data_done      = false
	self.m_data_initialized       = false
	self.m_cooldown_state_dirty   = true
	self.m_sell_script_name       = nil
	self.m_sell_script_disp_name  = "None"
	self.m_last_error             = ""
	self.m_businesses             = {
		warehouses       = {},
		biker_businesses = {},
		safes            = self.m_raw_data.BS_Default,
		money_fronts     = self.m_raw_data.MF_Default,
	}


	self.m_thread = ThreadManager:RegisterLooped("SS_YRV3", function()
		self:OnTick()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		if (self.m_data_initialized) then
			self:Reset()
		end
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
		if (self.m_data_initialized) then
			self:Reset()
		end
	end)

	return self
end

function YRV3:Reset()
	self.m_total_sum              = 0
	self.m_last_as_check_time     = 0
	self.m_last_income_check_time = 0
	self.m_businesses             = {
		warehouses       = {},
		biker_businesses = {},
		safes            = self.m_raw_data.BS_Default,
		money_fronts     = self.m_raw_data.MF_Default,
	}
	self.m_has_triggered_autosell = false
	self.m_sell_script_running    = false
	self.m_initial_data_done      = false
	self.m_data_initialized       = false
	self.m_cooldown_state_dirty   = true
end

function YRV3:Reload()
	if (self.m_thread and self.m_thread:IsRunning()) then
		self.m_thread:Suspend()
	end

	self:Reset()

	if (self.m_thread and self.m_thread:IsSuspended()) then
		self.m_thread:Resume()
	end
end

---@return boolean
function YRV3:CanAccess()
	return Backend:IsUpToDate()
		and Game.IsOnline()
		and not Backend:IsMockEnv()
		and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
		and self.m_state ~= Enums.eYRState.ERROR
end

---@return boolean
function YRV3:IsDataInitialized()
	return self.m_data_initialized
end

---@param where integer|vec3
---@param keepVehicle? boolean
function YRV3:Teleport(where, keepVehicle)
	if not Self:IsOutside() then
		Notifier:ShowError("YRV3", "Please go outdside first!")
		return
	end

	Self:Teleport(where, keepVehicle)
end

---@return eYRState
function YRV3:GetState()
	return self.m_state
end

---@return string
function YRV3:GetLastError()
	if (not self.m_last_error:isempty() and self.m_last_error:gsub("_", ""):find("%l") == nil) then
		return _T(self.m_last_error)
	end

	return self.m_last_error
end

---@param msg string
function YRV3:SetLastError(msg)
	if (msg == self.m_last_error) then
		return
	end

	self.m_last_error = msg
end

---@return array<Warehouse>
function YRV3:GetSCWarehouses()
	return self.m_businesses.warehouses
end

---@return Warehouse?
function YRV3:GetHangar()
	return self.m_businesses.hangar
end

---@return array<BikerBusiness>
function YRV3:GetBikerBusinesses()
	return self.m_businesses.biker_businesses
end

---@return Nightclub
function YRV3:GetNightclub()
	return self.m_businesses.nightclub
end

---@return dict<CashSafe>
function YRV3:GetBusinessSafes()
	return self.m_businesses.safes
end

---@return dict<MoneyFrontsBusiness>
function YRV3:GetMoneyFrontsBusiness()
	return self.m_businesses.money_fronts
end

---@return BikerBusiness?
function YRV3:GetBunker()
	return self.m_businesses.bunker
end

---@return BikerBusiness?
function YRV3:GetAcidLab()
	return self.m_businesses.acid_lab
end

---@return table
function YRV3:GetSaleMissionTunables()
	return self.m_raw_data.SellMissionTunables
end

---@return integer
function YRV3:GetEstimatedIncome()
	return self.m_total_sum
end

---@return boolean
function YRV3:IsAnySaleInProgress()
	return self.m_sell_script_running
end

---@return boolean
function YRV3:HasTriggeredAutoSell()
	return self.m_has_triggered_autosell
end

---@param stat string
---@param slot integer
---@return boolean
function YRV3:DoesPlayerOwnPropertySlot(stat, slot)
	return stats.get_int(_F("%s%d", stat, slot)) ~= 0
end

---@return boolean
function YRV3:DoesPlayerOwnAnyWarehouse()
	for i = 0, 4 do
		if (self:DoesPlayerOwnPropertySlot("MPX_PROP_WHOUSE_SLOT", i)) then
			return true
		end
	end

	return false
end

---@return boolean
function YRV3:DoesPlayerOwnAnyBikerBusiness()
	for i = 0, 4 do
		if (self:DoesPlayerOwnPropertySlot("MPX_PROP_FAC_SLOT", i)) then
			return true
		end
	end

	return false
end

function YRV3:PopulateBikerBusinesses()
	for i = 0, 4 do
		local property_index = (stats.get_int(_F("MPX_FACTORYSLOT%d", i)))
		local ref = self.m_raw_data.BikerBusinesses[property_index]
		if (not ref) then
			goto continue
		end

		local ref2 = self.m_raw_data.BikerTunables[ref.id]
		if (not ref2) then
			goto continue
		end

		local has_eq_upgrade    = stats.get_int(_F("MPX_FACTORYUPGRADES%d", i)) == 1
		local has_staff_upgrade = stats.get_int(_F("MPX_FACTORYUPGRADES%d_1", i)) == 1
		local eq_upg_mult       = tunables.get_int(ref2.mult_1)
		local stf_upg_mult      = tunables.get_int(ref2.mult_2)
		table.insert(self.m_businesses.biker_businesses, BikerBusiness.new({
			id         = i,
			name       = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(ref.gxt),
			max_units  = ref2.max_units,
			vpu        = tunables.get_int(ref2.vpu),
			vpu_mult_1 = has_eq_upgrade and eq_upg_mult or 0,
			vpu_mult_2 = has_staff_upgrade and stf_upg_mult or 0,
			coords     = ref.coords,
		}))

		::continue::
	end

	if (not self.m_businesses.bunker) then
		local idx = stats.get_int("MPX_PROP_FAC_SLOT5")
		local ref = self.m_raw_data.Bunkers[idx]

		if (ref) then
			local gxt_idx            = (idx < 28) and idx - 20 or idx - 19
			local has_eq_upgrade     = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
			local has_staff_upgrade  = stats.get_int("MPX_BUNKER_STAFF") == 1
			local eq_upg_mult        = tunables.get_int("GR_MANU_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
			local stf_upg_mult       = tunables.get_int("GR_MANU_PRODUCT_VALUE_STAFF_UPGRADE")

			self.m_businesses.bunker = BikerBusiness.new({
				id         = 5,
				name       = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_BUNKER_%d", gxt_idx)),
				coords     = ref and ref.coords or vec3:zero(),
				vpu_mult_1 = has_eq_upgrade and eq_upg_mult or 0,
				vpu_mult_2 = has_staff_upgrade and stf_upg_mult or 0,
				vpu        = tunables.get_int("GR_MANU_PRODUCT_VALUE"),
				max_units  = 100,
			})
		end
	end

	if (not self.m_businesses.acid_lab and stats.get_int("MPX_XM22_LAB_OWNED") ~= 0) then
		local has_eq_upgrade       = (stats.get_int("MPX_AWD_CALLME") >= 10)
			and (stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1)
		local eq_upg_mult          = tunables.get_int("BIKER_ACID_PRODUCT_VALUE_EQUIPMENT_UPGRADE")

		self.m_businesses.acid_lab = BikerBusiness.new({
			id         = 6,
			name       = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION("MP_BWH_ACID"),
			vpu_mult_1 = has_eq_upgrade and eq_upg_mult or 0,
			vpu_mult_2 = 0,
			vpu        = tunables.get_int("BIKER_ACID_PRODUCT_VALUE"),
			max_units  = 160,
			blip       = 847,
		})
	end
end

function YRV3:PopulateWarehouses()
	for i = 0, 4 do
		local property_index = (stats.get_int(_F("MPX_PROP_WHOUSE_SLOT%d", i)))
		local ref            = self.m_raw_data.CEOWarehouses[property_index]
		if (not ref) then
			goto continue
		end

		table.insert(self.m_businesses.warehouses, Warehouse.new({
			id        = i,
			size      = ref.size,
			max_units = ref.max,
			name      = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_WHOUSE_%d", property_index - 1)),
			coords    = ref.coords,
		}, Enums.eWarehouseType.SPECIAL_CARGO))

		::continue::
	end

	if (self.m_businesses.hangar) then
		return
	end

	local property_index = stats.get_int("MPX_HANGAR_OWNED")
	local ref            = self.m_raw_data.Hangars[property_index]
	if (not ref) then
		return
	end

	self.m_businesses.hangar = Warehouse.new({
		id        = -1,
		name      = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_HANGAR_%d", property_index)),
		coords    = ref.coords,
		max_units = 50,
	}, Enums.eWarehouseType.HANGAR)
end

function YRV3:PopulateNightclub()
	if (self.m_businesses.nightclub) then
		return
	end

	ThreadManager:Run(function()
		local nc_index = stats.get_int("MPX_NIGHTCLUB_OWNED")
		local ref = self.m_raw_data.Nightclubs[nc_index]
		if (nc_index == 0 or not ref) then
			return
		end

		self.m_businesses.nightclub = Nightclub.new({
			id          = nc_index,
			name        = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_NCLU_%d", nc_index)),
			custom_name = NightclubNames[stats.get_int("MPX_PROP_NIGHTCLUB_NAME_ID") + 1],
			max_cash    = 25e4,
			coords      = ref.coords
		})

		while (not self.m_initial_data_done) do
			yield()
		end

		local owns_cargo = false

		if (self.m_businesses.hangar) then
			owns_cargo = true
		else
			for _, wh in ipairs(self.m_businesses.warehouses) do
				if (wh:IsValid()) then
					owns_cargo = true
					break
				end
			end
		end

		if (owns_cargo) then
			self.m_businesses.nightclub:SetupBusinessHub(0, self.m_raw_data.BusinessHubs)
		end

		if (self.m_businesses.bunker) then
			self.m_businesses.nightclub:SetupBusinessHub(1, self.m_raw_data.BusinessHubs)
		end

		for _, bb in ipairs(self.m_businesses.biker_businesses) do
			if (bb:IsValid()) then
				local index = bb:GetIndex()
				self.m_businesses.nightclub:SetupBusinessHub(index + 2, self.m_raw_data.BusinessHubs)
			end
		end

		self.m_data_initialized = true
		sleep(3000)

		if (GVars.features.yrv3.nc_always_popular) then
			self.m_businesses.nightclub:LockPopularityDecay()
		end
	end)
end

function YRV3:PreInit()
	if (self.m_initial_data_done or self.m_data_initialized) then
		return
	end

	ThreadManager:Run(function()
		self:PopulateBikerBusinesses()
		self:PopulateWarehouses()
		self.m_initial_data_done = true
	end)
end

function YRV3:InitializeData()
	if (self.m_data_initialized or not Game.IsOnline() or self.m_state == Enums.eYRState.LOADING) then
		return
	end

	self.m_state      = Enums.eYRState.LOADING
	self.m_last_error = "GENERIC_WAIT_LABEL"
	self:PreInit()
	self:PopulateNightclub()
end

function YRV3:WarehouseAutofill()
	if (not self:CanAccess()) then
		return
	end

	for _, wh in ipairs(self.m_businesses.warehouses) do
		wh:AutoFill()
	end
end

function YRV3:HangarAutofill()
	if (not self:CanAccess()) then
		return
	end

	local hangar = self.m_businesses.hangar
	if (hangar and hangar:IsValid()) then
		self.m_businesses.hangar:AutoFill()
	end
end

function YRV3:FinishSaleOnCommand()
	if (not self:CanAccess()) then
		return
	end

	if (GVars.features.yrv3.autosell) then
		Notifier:ShowWarning(
			"YRV3",
			"You aleady have 'Auto-Sell' enabled. No need to manually trigger it.",
			false,
			1.5
		)
		return
	end

	if (not self.m_sell_script_running) then
		Notifier:ShowWarning(
			"YRV3",
			"No supported sale script is currently running.",
			false,
			1.5
		)
		return
	end

	self:FinishSale()
end

---@param index number
function YRV3:WarehouseAutofillOnCommand(index)
	if (not self:CanAccess()) then
		return
	end

	local warehouse = self.m_businesses.warehouses[index]

	if (not warehouse or not warehouse:IsValid()) then
		Notifier:ShowError(
			"YRV3",
			_F("No warehouse found in slot %d!", index),
			false
		)
		return
	end

	if (warehouse:IsFull()) then
		return
	end

	warehouse.auto_fill = not warehouse.auto_fill
	Notifier:ShowMessage(
		"YRV3",
		_F("CEO Warehouse %d auto-fill %s.",
			index,
			warehouse.auto_fill
			and "Enabled"
			or "Disabled"
		),
		false,
		2
	)
end

function YRV3:FillAll()
	if (not self:CanAccess()) then
		return
	end

	for _, wh in ipairs(self.m_businesses.warehouses) do
		if (wh:IsValid()) then
			wh.auto_fill = true
		end
	end

	if (self.m_businesses.hangar and self.m_businesses.hangar:IsValid()) then
		self.m_businesses.hangar.auto_fill = true
		sleep(math.random(100, 300))
	end

	if (self.m_businesses.bunker and self.m_businesses.bunker:IsValid()) then
		self.m_businesses.bunker:ReStock()
		sleep(math.random(100, 300))
	end

	if (self.m_businesses.acid_lab and self.m_businesses.acid_lab:IsValid()) then
		self.m_businesses.acid_lab:ReStock()
		sleep(math.random(100, 300))
	end

	for _, bb in ipairs(self.m_businesses.biker_businesses) do
		if (bb:IsValid()) then
			bb:ReStock()
		end
		sleep(math.random(200, 666))
	end
end

---@return string
function YRV3:GetRunningSellScriptDisplayName()
	if (not self.m_sell_script_running or not self.m_sell_script_name) then
		return "None"
	end

	return ScriptDisplayNames[self.m_sell_script_name] or "None"
end

function YRV3:FinishSale()
	local sn = self.m_sell_script_name
	if (not sn or not self.m_raw_data.SellScripts[sn]) then
		return
	end

	self.m_has_triggered_autosell = true
	script.execute_as_script(sn, function()
		if not self.m_raw_data.SellScripts[sn].b then -- gb_*
			for _, data in pairs(self.m_raw_data.SellScripts[sn]) do
				locals.set_int(sn, data.l + data.o, data.v)
			end
		else -- fm_content_*
			if (NETWORK.NETWORK_GET_HOST_OF_THIS_SCRIPT() ~= Self:GetPlayerID()) then
				Notifier:ShowWarning(
					"YRV3",
					"Unable to finish sale mission. You are not host of this script."
				)
				return
			end

			local val = locals.get_int(sn, self.m_raw_data.SellScripts[sn].b + 1 + 0)
			if not Bit.is_set(val, 11) then
				val = Bit.set(val, 11)
				locals.set_int(sn, self.m_raw_data.SellScripts[sn].b + 1 + 0, val)
			end

			locals.set_int(sn, self.m_raw_data.SellScripts[sn].l + self.m_raw_data.SellScripts[sn].o, 3) -- 3=End reason.
		end
	end)
end

function YRV3:FinishCEOCargoSourceMission()
	if script.is_active("gb_contraband_buy") then
		script.execute_as_script("gb_contraband_buy", function()
			if (not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()) then
				Notifier:ShowError("YRV3", "You are not host of this script.")
				return
			end

			local buyLocal = SGSL:Get(SGSL.data.gb_contraband_buy_local_1):AsLocal()
			buyLocal:At(5):WriteInt(1) -- 1.71 b3568.0 -- case -1: return "INVALID - UNSET";
			buyLocal:At(191):WriteInt(6) -- 1.71 b3568.0 -- Local_623.f_191 = iParam0;
			buyLocal:At(192):WriteInt(4) -- 1.71 b3568.0 -- Local_623.f_192 = iParam0;
		end)
	elseif script.is_active("fm_content_cargo") then
		script.execute_as_script("fm_content_cargo", function()
			if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
				Notifier:ShowError("YRV3", "You are not host of this script.")
				return
			end

			local fmccLocal2       = SGSL:Get(SGSL.data.gb_contraband_buy_local_2):AsLocal():At(1):At(0) -- GENERIC_BITSET_I_WON -- 1.71 b3568.0: var uLocal_5973 = 4;
			local gbcb_obj         = SGSL:Get(SGSL.data.gb_contraband_buy_local_3)
			local fmccLocal3       = gbcb_obj:AsLocal()
			local fmccLocal3Offset = gbcb_obj:GetOffset(1)
			local bs               = fmccLocal2:ReadInt()

			if (not Bit.is_set(bs, 11)) then
				bs = Bit.set(bs, 11)
				fmccLocal2:WriteInt(bs)
			end

			fmccLocal3:At(fmccLocal3Offset):WriteInt(3) -- EndReason
		end)
	end
end

---@param key string
---@param state boolean
function YRV3:SetCooldownStateDirty(key, state)
	local data = self.m_raw_data.Cooldowns[key]
	if (not data) then
		return
	end

	data.dirty = state
end

---@param state boolean
function YRV3:SetAllCooldownStatesDirty(state)
	self.m_cooldown_state_dirty = state
end

function YRV3:CheckAllCooldowns()
	if (not self.m_cooldown_state_dirty) then
		return
	end

	for _, data in pairs(self.m_raw_data.Cooldowns) do
		local gvar = data.gstate()
		if (gvar and data.onEnable) then
			data.onEnable()
		elseif (not gvar and type(data.onDisable) == "function") then
			data.onDisable()
		end
		data.dirty = false
	end

	self.m_cooldown_state_dirty = false
end

function YRV3:CooldownHandler()
	if (self.m_cooldown_state_dirty) then
		self:CheckAllCooldowns()
		return
	end

	for _, data in pairs(self.m_raw_data.Cooldowns) do
		if (not data.dirty) then
			goto continue
		end

		local gvar = data.gstate()
		if (gvar and data.onEnable) then
			data.onEnable()
		elseif (not gvar and type(data.onDisable) == "function") then
			data.onDisable()
		end
		data.dirty = false

		::continue::
	end
end

local fadedOutTimer = Timer.new(1e4)
fadedOutTimer:pause()
function YRV3:SetupAutosell()
	if (Time.millis() - self.m_last_as_check_time < 1200) then
		return
	end

	for sn in pairs(self.m_raw_data.SellScripts) do
		if script.is_active(sn) then
			self.m_sell_script_name = sn
			self.m_sell_script_running = true
			self.m_sell_script_disp_name = self:GetRunningSellScriptDisplayName()
			break
		else
			self.m_sell_script_name = "None"
			self.m_sell_script_disp_name = "None"
			self.m_sell_script_running = false
		end
	end

	if (self.m_sell_script_running and self.m_bhub_script_handle ~= 0) then -- was triggered from the mct
		for _, scr in pairs(ScriptsToTerminate) do
			if (script.is_active(scr)) then
				PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
				sleep(200)
				PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
				break
			end
		end

		sleep(1000)

		if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
			fadedOutTimer:resume()
			while (not fadedOutTimer:is_done()) do
				if (not CAM.IS_SCREEN_FADED_OUT() or CAM.IS_SCREEN_FADING_IN()) then
					break
				end

				yield()
			end

			-- recheck
			if (CAM.IS_SCREEN_FADED_OUT() and not CAM.IS_SCREEN_FADING_IN()) then -- Step bro, I'm stuck!
				CAM.DO_SCREEN_FADE_IN(100)
			end
		end

		fadedOutTimer:reset()
		fadedOutTimer:pause()
	end

	self.m_last_as_check_time = Time.millis()
end

function YRV3:AutoSellHandler()
	self:SetupAutosell()

	if (GVars.features.yrv3.autosell
			and self.m_sell_script_running
			and not self.m_has_triggered_autosell
			and not CAM.IS_SCREEN_FADED_OUT()
		) then
		self.m_has_triggered_autosell = true
		Notifier:ShowMessage("YRV3", "Auto-Sell will start in 20 seconds.")
		sleep(2e4)

		while (AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()) do
			yield()
		end

		self:FinishSale()
	end

	while (self.m_has_triggered_autosell) do
		if (not script.is_active(self.m_sell_script_name)) then
			break
		end

		yield()
	end
	self.m_has_triggered_autosell = false
end

-- Master Control Terminal
function YRV3:MCT()
	if Self:IsBrowsingApps() then
		GUI:PlaySound(GUI.Sounds.Error)
		return
	end

	local BusinessHubGlobal1 = SGSL:Get(SGSL.data.arcade_bhub_global_1):AsGlobal()
	local BusinessHubGlobal2 = SGSL:Get(SGSL.data.arcade_bhub_global_2):AsGlobal()
	ThreadManager:Run(function()
		if (BusinessHubGlobal1:ReadInt() ~= 0) then
			BusinessHubGlobal1:WriteInt(0)
		end

		TaskWait(Game.RequestScript, "appArcadeBusinessHub")
		GUI:PlaySound(GUI.Sounds.Button)
		self.m_bhub_script_handle = SYSTEM.START_NEW_SCRIPT("appArcadeBusinessHub", 1424) -- STACK_SIZE_DEFAULT
		SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appArcadeBusinessHub")
		sleep(100)

		while (script.is_active("appArcadeBusinessHub")) do
			if (BusinessHubGlobal2:ReadInt() == -1) then
				BusinessHubGlobal2:WriteInt(0)
			end

			yield()
		end

		while (Self:IsBrowsingApps()) do
			yield()
		end

		BusinessHubGlobal1:WriteInt(0)
		self.m_bhub_script_handle = 0
	end)
end

function YRV3:AutoProduceHandler()
	for _, bb in ipairs(self.m_businesses.biker_businesses) do
		if (bb.fast_prod_enabled and not bb.fast_prod_running) then
			bb:LoopProduction()
		end
	end

	local bunker = self.m_businesses.bunker
	if (bunker and bunker:IsValid()) then
		if (bunker.fast_prod_enabled and not bunker.fast_prod_running) then
			bunker:LoopProduction()
		end
	end

	local acidlab = self.m_businesses.acid_lab
	if (acidlab and acidlab:IsValid()) then
		if (acidlab.fast_prod_enabled and not acidlab.fast_prod_running) then
			acidlab:LoopProduction()
		end
	end

	if (not self.m_businesses.nightclub) then
		return
	end

	local hubs = self.m_businesses.nightclub:GetBusinessHubs()
	if (not hubs) then
		return
	end

	for _, hub in ipairs(hubs) do
		if (hub.fast_prod_enabled and not hub.fast_prod_running) then
			hub:LoopProduction()
		end
	end
end

function YRV3:AutoFillHandler()
	self:HangarAutofill()
	self:WarehouseAutofill()
end

---@param business BusinessBase
local function getBusinessVal(business)
	if (not business or not business:IsValid()) then
		return 0
	end

	return business:GetEstimatedValue()
end

function YRV3:CalculateEstimatedIncome()
	if (not self.m_data_initialized or not GUI:IsOpen()) then -- has no purpose outside of UI
		return
	end

	if (Time.millis() - self.m_last_income_check_time < 500) then
		return
	end

	local businesses = self.m_businesses
	local warehouses = businesses.warehouses
	local biker      = businesses.biker_businesses

	self.m_total_sum = getBusinessVal(businesses.hangar)
		+ getBusinessVal(businesses.bunker)
		+ getBusinessVal(businesses.acid_lab)
		+ getBusinessVal(businesses.nightclub)

	for _, wh in ipairs(warehouses) do
		self.m_total_sum = self.m_total_sum + getBusinessVal(wh)
	end

	for _, bb in ipairs(biker) do
		self.m_total_sum = self.m_total_sum + getBusinessVal(bb)
	end

	for _, safe in pairs(businesses.safes) do
		if (safe.cash_value) then
			self.m_total_sum = self.m_total_sum + safe.cash_value()
		end
	end

	for _, mf in pairs(businesses.money_fronts) do
		if (mf.cash_value) then
			self.m_total_sum = self.m_total_sum + mf.cash_value()
		end
	end

	self.m_last_income_check_time = Time.millis()
end

function YRV3:OnTick()
	if (not Backend:IsUpToDate() and (self.m_thread and self.m_thread:IsRunning())) then
		self.m_state = Enums.eYRState.ERROR
		self:SetLastError("GENERIC_OUTDATED")
		self.m_thread:Stop()
		return
	end

	if (not self:CanAccess()) then
		self.m_state = Enums.eYRState.OFFLINE

		if (not network.is_session_started()) then
			self:SetLastError("GENERIC_UNAVAILABLE_SP")
		else
			if (script.is_active("maintransition")) then
				self.m_state = Enums.eYRState.WAITING
				self:SetLastError("YRV3_STATE_WAIT_TRANSITION")
			elseif (NETWORK.NETWORK_IS_ACTIVITY_SESSION()) then
				self.m_state = Enums.eYRState.ERROR
				self:SetLastError("YRV3_STATE_ERR_WRONG_SESSION")
			end
		end

		yield()
		return
	end

	self:InitializeData()

	if (not self.m_data_initialized) then
		yield()
		return
	end

	self.m_state = Enums.eYRState.RUNNING
	self:SetLastError("")

	self:AutoSellHandler()
	self:AutoFillHandler()
	self:AutoProduceHandler()
	self:CooldownHandler()
	self:CalculateEstimatedIncome()
end

return YRV3
