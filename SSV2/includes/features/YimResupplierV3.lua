local SGSL = require("includes.services.SGSL")

local ScriptDisplayNames <const> = {
	["fm_content_smuggler_sell"] = "Hangar (Land. Not supported.)",
	["gb_smuggler"]              = "Hangar (Air)",
	["gb_contraband_sell"]       = "CEO",
	["gb_gunrunning"]            = "Bunker",
	["gb_biker_contraband_sell"] = "Biker Business",
	["fm_content_acid_lab_sell"] = "Acid Lab",
}

local ScriptsToTerminate <const> = {
	"appArcadeBusinessHub",
	"appsmuggler",
	"appbikerbusiness",
	"appbunkerbusiness",
	"appbusinesshub"
}

---@class YRV3
---@field m_total_sum number
---@field m_ceo_value_sum number
---@field m_biker_value_sum number
---@field m_safe_cash_sum number
---@field m_cwash_cash_sum number
---@field m_bhub_script_handle number
---@field m_hangar_loop boolean
---@field m_has_triggered_autosell boolean
---@field m_sell_script_running boolean
---@field m_sell_script_name string?
---@field m_sell_script_disp_name string
---@field m_script_display_names table<string, string>
---@field m_raw_data RawBusinessData
---@field m_warehouse_data array<SCWarehouse>
---@field m_biker_data array<BikerBusiness>
---@field m_biker_ext_data { bunker: BikerBusinessExt, acid_lab: BikerBusinessExt }
---@field m_safe_cash_data dict<BusinessSafe>
---@field m_money_fronts_data dict<MoneyFrontsBusiness>
---@field m_prod_trigger_global ScriptGlobal
---@field m_freemode_business_global ScriptGlobal
---@field private m_last_as_check_time number
---@field private m_cooldown_state_dirty boolean
---@field private m_data_initialized boolean
---@field protected m_thread Thread?
---@field protected m_initialized boolean
local YRV3 = { m_raw_data = require("includes.data.yrv3_data") }
YRV3.__index = YRV3

---@return YRV3
function YRV3:init()
	if (self.m_initialized) then
		return self
	end

	self.m_total_sum                = 0
	self.m_ceo_value_sum            = 0
	self.m_biker_value_sum          = 0
	self.m_safe_cash_sum            = 0
	self.m_cwash_cash_sum           = 0
	self.m_bhub_script_handle       = 0
	self.m_last_as_check_time       = 0
	self.m_hangar_loop              = false
	self.m_has_triggered_autosell   = false
	self.m_sell_script_running      = false
	self.m_data_initialized         = false
	self.m_cooldown_state_dirty     = true
	self.m_sell_script_name         = nil
	self.m_sell_script_disp_name    = "None"
	self.m_warehouse_data           = self.m_raw_data.SC_Default
	self.m_biker_data               = self.m_raw_data.BB_Default
	self.m_biker_ext_data           = self.m_raw_data.BBEXT_Default
	self.m_safe_cash_data           = self.m_raw_data.BS_Default
	self.m_money_fronts_data        = self.m_raw_data.MF_Default
	self.m_script_display_names     = ScriptDisplayNames
	self.m_prod_trigger_global      = SGSL:Get(SGSL.data.biker_trigger_production_global):AsGlobal()
	self.m_freemode_business_global = SGSL:Get(SGSL.data.freemode_business_global):AsGlobal()

	self.m_thread                   = ThreadManager:RegisterLooped("SS_YRV3", function()
		self:Main()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		self:Reset()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
		self:Reset()
	end)

	return self
end

function YRV3:Reset()
	self.m_ceo_value_sum        = 0
	self.m_biker_value_sum      = 0
	self.m_safe_cash_sum        = 0
	self.m_cwash_cash_sum       = 0
	self.m_warehouse_data       = self.m_raw_data.SC_Default
	self.m_biker_data           = self.m_raw_data.BB_Default
	self.m_biker_ext_data       = self.m_raw_data.BBEXT_Default
	self.m_safe_cash_data       = self.m_raw_data.BS_Default
	self.m_money_fronts_data    = self.m_raw_data.MF_Default
	self.m_data_initialized     = false
	self.m_cooldown_state_dirty = true
end

function YRV3:CanAccess()
	return Backend:IsUpToDate()
		and Game.IsOnline()
		and not Backend:IsMockEnv()
		and not script.is_active("maintransition")
		and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
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

---@param index integer
function YRV3:PopulateBikerBusinessSlot(index)
	ThreadManager:Run(function()
		if (self.m_biker_data[index].was_checked) then
			return
		end

		local property_index = (stats.get_int(_F("MPX_FACTORYSLOT%d", index - 1)))
		local ref            = self.m_raw_data.BikerBusinesses[property_index]
		if (not ref) then
			return
		end

		self.m_biker_data[index] = {
			was_checked       = true,
			is_owned          = true,
			fast_prod_enabled = false,
			fast_prod_running = false,
			name              = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(ref.gxt),
			id                = ref.id,
			unit_max          = ref.unit_max,
			value_tunable     = ref.val_tunable,
			coords            = ref.coords,
		}
	end)
end

function YRV3:PopulateBikerExtData()
	ThreadManager:Run(function()
		if (not self.m_biker_ext_data.bunker.was_checked) then
			local idx                             = stats.get_int("MPX_PROP_FAC_SLOT5")
			local ref                             = self.m_raw_data.Bunkers[idx]
			local gxt_idx                         = (idx < 28) and idx - 20 or idx - 19
			local has_eq_upgrade                  = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
			local has_staff_upgrade               = stats.get_int("MPX_BUNKER_STAFF") == 1

			self.m_biker_ext_data.bunker.is_owned = idx ~= 0
			self.m_biker_ext_data.bunker.name     = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_BUNKER_%d",
				gxt_idx))
			self.m_biker_ext_data.bunker.coords   = ref and ref.coords or vec3:zero()

			if (has_eq_upgrade) then
				self.m_biker_ext_data.bunker.equipment_upgrade = true
				self.m_biker_ext_data.bunker.value_offset_1 = tunables.get_int("GR_MANU_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
			end

			if (has_staff_upgrade) then
				self.m_biker_ext_data.bunker.staff_upgrade  = true
				self.m_biker_ext_data.bunker.value_offset_2 = tunables.get_int("GR_MANU_PRODUCT_VALUE_STAFF_UPGRADE")
			end

			self.m_biker_ext_data.bunker.was_checked = true
		end

		if (not self.m_biker_ext_data.acid_lab.was_checked) then
			self.m_biker_ext_data.acid_lab.name        = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION("MP_BWH_ACID")
			self.m_biker_ext_data.acid_lab.is_owned    = stats.get_int("MPX_XM22_LAB_OWNED") ~= 0
			self.m_biker_ext_data.acid_lab.was_checked = true
			local has_eq_upgrade                       = (stats.get_int("MPX_AWD_CALLME") >= 10)
				and (stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1)

			if (has_eq_upgrade) then
				self.m_biker_ext_data.acid_lab.equipment_upgrade = true
				self.m_biker_ext_data.acid_lab.value_offset_1 = tunables.get_int(
					"BIKER_ACID_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
			end
		end
	end)
end

function YRV3:PopulateCEOwarehouseSlot(index)
	if self.m_warehouse_data[index].was_checked then
		return
	end

	ThreadManager:Run(function()
		local property_index = (stats.get_int(_F("MPX_PROP_WHOUSE_SLOT%d", index - 1)))
		local ref            = self.m_raw_data.CEOWarehouses[property_index]
		if (not ref) then
			return
		end

		self.m_warehouse_data[index] = {
			was_checked       = true,
			is_owned          = true,
			auto_fill_enabled = false,
			name              = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_WHOUSE_%d", property_index - 1)),
			size              = ref.size,
			max               = ref.max,
			coords            = ref.coords,
		}
	end)
end

function YRV3:InitializeData()
	if (self.m_data_initialized or not Game.IsOnline()) then
		return
	end

	for i, v in ipairs(self.m_warehouse_data) do
		if (not v.was_checked or not v.max) then
			self:PopulateCEOwarehouseSlot(i)
			sleep(100)
		end
	end

	for i, v in ipairs(self.m_biker_data) do
		if (not v.was_checked or not v.unit_max) then
			self:PopulateBikerBusinessSlot(i)
			sleep(100)
		end
	end

	for i, v in ipairs(self.m_raw_data.Hangars) do
		v.name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_HANGAR_%d", i))
	end

	-- for i, v in ipairs(self.m_raw_data.Nightclubs) do
	-- 	v.name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_NCLU_%d", i))
	-- end


	self:PopulateBikerExtData()
	self.m_data_initialized = true
end

---@param index integer
---@return integer
function YRV3:GetBBProdTime(index)
	local g_obj      = SGSL:Get(SGSL.data.biker_trigger_production_global)
	local pid_size   = g_obj:GetOffset(1)
	local offset_2   = g_obj:GetOffset(2)
	local offset_3   = g_obj:GetOffset(3)
	local index_size = g_obj:GetOffset(4)
	return self.m_prod_trigger_global
		:At(Self:GetPlayerID(), pid_size)
		:At(offset_2)
		:At(offset_3)
		:At(index, index_size)
		:At(9)
		:ReadInt()
end

---@param index integer
function YRV3:TriggerBBProduction(index)
	local g_obj      = SGSL:Get(SGSL.data.biker_trigger_production_global)
	local pid_size   = g_obj:GetOffset(1)
	local offset_2   = g_obj:GetOffset(2)
	local offset_3   = g_obj:GetOffset(3)
	local index_size = g_obj:GetOffset(4)
	self.m_prod_trigger_global
		:At(Self:GetPlayerID(), pid_size)
		:At(offset_2)
		:At(offset_3)
		:At(index, index_size)
		:At(9)
		:WriteInt(100)
end

function YRV3:BBAutoProduce(slot)
	---@type BikerBusiness|BikerBusinessExt
	local data = Switch(slot) {
		[5]     = self.m_biker_ext_data.bunker,
		[6]     = self.m_biker_ext_data.acid_lab,
		default = self.m_biker_data[slot + 1]
	}

	if (not data) then
		error("no data!")
		return
	end

	if (data.fast_prod_running) then
		return
	end

	local function getSupplies()
		return stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
	end

	local function getStock()
		return stats.get_int(_F("MPX_PRODTOTALFORFACTORY%d", slot))
	end

	ThreadManager:Run(function()
		data.fast_prod_running = true

		if (not data.was_checked) then
			if (slot < 5) then
				self:PopulateBikerBusinessSlot(slot)
			else
				self:PopulateBikerExtData()
			end

			sleep(500)
		end

		if (not data.is_owned) then
			data.fast_prod_enabled = false
			data.fast_prod_running = false
			return
		end

		while (data.fast_prod_enabled and getStock() < data.unit_max) do
			if (getSupplies() <= 25) then
				self:FillBikerBusiness(slot)
				sleep(250)
			end

			self:TriggerBBProduction(slot)
			yield()
		end

		data.fast_prod_enabled = false
		data.fast_prod_running = false
	end)
end

---@param crates number
function YRV3:GetCEOCratesValue(crates)
	if (not crates or crates <= 0) then
		return 0
	end

	if (crates == 1) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1") -- EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1
	end

	if (crates == 2) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD2") * 2 -- +1
	end

	if (crates == 3) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD3") * 3 -- +1
	end

	if (crates == 4 or crates == 5) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD4") * crates -- +1
	end

	if (crates >= 6 and crates <= 9) then
		return (tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD4") + math.floor((crates - 4) / 2)) * crates -- +0
	end

	if (crates >= 10 and crates <= 110) then
		return (tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD7") + math.floor((crates - 10) / 5)) * crates -- +3
	end

	if (crates == 111) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD21") * 111 -- + 14
	end

	return 0
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

function YRV3:WarehouseAutofill()
	if (not self:CanAccess()) then
		return
	end

	for i, v in ipairs(self.m_warehouse_data) do
		if (not v.auto_fill_enabled) then
			goto continue
		end

		if (not v.was_checked or not v.name or not v.max) then
			self:PopulateCEOwarehouseSlot(i)
			sleep(500)
		end

		if (stats.get_int(_F("MPX_CONTOTALFORWHOUSE%d", i - 1))) == v.max then
			GUI:PlaySound(GUI.Sounds.Error)
			Notifier:ShowWarning("YRV3", _F("Warehouse N°%d is already full! Option has been disabled.", i))
			v.auto_fill_enabled = false
			goto continue
		end

		ThreadManager:Run(function()
			while ((stats.get_int(_F("MPX_CONTOTALFORWHOUSE%d", i - 1))) < v.max) do
				if (not v.auto_fill_enabled) then
					break
				end

				stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, i + 11)
				sleep(GVars.features.yrv3.autofill_delay or 100)
			end

			v.auto_fill_enabled = false
		end)

		::continue::
	end

	sleep(1000)
end

function YRV3:HangarAutofill()
	if (not self:CanAccess()) then
		return
	end

	if (not self.m_hangar_loop) then
		return
	end

	if (stats.get_int("MPX_HANGAR_OWNED") == 0) then
		Notifier:ShowWarning(
			"YRV3",
			"You don't seem to own a hangar. Option has been disabled.",
			false,
			3
		)

		self.m_hangar_loop = false
		return
	end

	if stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") == 50 then
		Notifier:ShowWarning("YRV3", "Your Hangar is already full! Option has been disabled.")
		self.m_hangar_loop = false
		return
	end

	ThreadManager:Run(function()
		while stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") < 50 do
			if (not self.m_hangar_loop) then
				break
			end

			stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
			sleep(GVars.features.yrv3.autofill_delay or 100)
		end

		self.m_hangar_loop = false
	end)
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

	ThreadManager:Run(function(s)
		if (not self.m_warehouse_data[index].was_checked) then
			self:PopulateCEOwarehouseSlot(index)
			s:sleep(250)
		end

		if (not self.m_warehouse_data[index].is_owned) then
			Notifier:ShowError(
				"YRV3",
				_F("No warehouse found in slot %d!", index),
				false
			)
			return
		end

		self.m_warehouse_data[index].auto_fill_enabled = not self.m_warehouse_data[index].auto_fill_enabled
		Notifier:ShowMessage(
			"YRV3",
			_F("CEO Warehouse %d auto-fill %s.",
				index,
				self.m_warehouse_data[index].auto_fill_enabled
				and "Enabled"
				or "Disabled"
			),
			false,
			2
		)
	end)
end

function YRV3:FillBikerBusiness(index)
	self.m_freemode_business_global:At(index):At(1):WriteInt(1)
end

function YRV3:FillAll()
	if (not self:CanAccess()) then
		return
	end

	ThreadManager:Run(function()
		if (stats.get_int("MPX_HANGAR_OWNED") ~= 0 and not self.m_hangar_loop) then
			self.m_hangar_loop = true
			sleep(math.random(100, 300))
		end

		for i, v in ipairs(self.m_warehouse_data) do
			if (not v.was_checked or not v.max) then
				self:PopulateCEOwarehouseSlot(i)
				sleep(100)
			end
		end

		for _, v in ipairs(self.m_warehouse_data) do
			if (v.is_owned) then
				v.auto_fill_enabled = true
			end
		end

		if (stats.get_int("MPX_PROP_FAC_SLOT5") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY5") < 100) then
			self:FillBikerBusiness(5)
			sleep(math.random(100, 300))
		end

		if (stats.get_int("MPX_XM22_LAB_OWNED") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY6") < 100) then
			self:FillBikerBusiness(6)
			sleep(math.random(100, 300))
		end

		for i, v in ipairs(self.m_biker_data) do
			if (not v.was_checked or not v.unit_max) then
				self:PopulateBikerBusinessSlot(i)
				sleep(100)
			end
		end

		for i, v in ipairs(self.m_biker_data) do
			local slot = i - 1
			local supplies = stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
			if (v.is_owned and v.unit_max and supplies < 100) then
				self:FillBikerBusiness(slot)
				sleep(math.random(200, 666))
			end
		end
	end)
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
			if not (NETWORK.NETWORK_GET_HOST_OF_THIS_SCRIPT() == Self:GetPlayerID()) then
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

function YRV3:GetRunningSellScriptDisplayName()
	if (not self.m_sell_script_running or not self.m_sell_script_name) then
		return "None"
	end

	return self.m_script_display_names[self.m_sell_script_name] or "None"
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
function YRV3:SetupAutosell()
	if (Time.now() < self.m_last_as_check_time) then
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
	end

	self.m_last_as_check_time = Time.now() + 1
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

	local BusinessHubGlobal1 = SGSL:Get(SGSL.data.business_hub_global_1):AsGlobal()
	local BusinessHubGlobal2 = SGSL:Get(SGSL.data.business_hub_global_2):AsGlobal()
	ThreadManager:Run(function()
		if (BusinessHubGlobal1:ReadInt() ~= 0) then
			BusinessHubGlobal1:WriteInt(0)
		end

		TaskWait(Game.RequestScript, "appArcadeBusinessHub")
		GUI:PlaySound(GUI.Sounds.Button)
		self.m_bhub_script_handle = SYSTEM.START_NEW_SCRIPT("appArcadeBusinessHub", 1424) -- STACK_SIZE_DEFAULT
		SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appArcadeBusinessHub")
		sleep(100)
		gui.toggle(false)

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

function YRV3:BBAutoProduceHandler()
	for i, v in ipairs(self.m_biker_data) do
		if (v.fast_prod_enabled and not v.fast_prod_running) then
			self:BBAutoProduce(i)
		end
	end

	for _, ext in pairs(self.m_biker_ext_data) do
		if (ext.fast_prod_enabled and not ext.fast_prod_running) then
			self:BBAutoProduce(ext.index)
		end
	end
end

function YRV3:AutoFillHandler()
	self:HangarAutofill()
	self:WarehouseAutofill()
end

function YRV3:Main()
	if (not Backend:IsUpToDate() and self.m_thread and self.m_thread:IsRunning()) then
		self.m_thread:Stop()
		return
	end

	if (not self:CanAccess()) then
		yield()
		return
	end

	self:InitializeData()
	self:AutoSellHandler()
	self:AutoFillHandler()
	self:BBAutoProduceHandler()
	self:CooldownHandler()
end

return YRV3
