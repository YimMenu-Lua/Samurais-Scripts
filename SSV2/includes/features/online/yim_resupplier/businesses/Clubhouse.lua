-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront   = require("BusinessFront")
local Factory         = require("Factory")
local RawBusinessData = require("includes.data.yrv3_data")
local InteriorIDs     = require("includes.data.refs").InteriorIDs

-- Class representing a MC Clubhouse business.
---@class Clubhouse : BusinessFront
---@field private m_id integer
---@field private m_name string
---@field private m_custom_name string
---@field private m_safe CashSafe
---@field private m_subs Factory[]
---@field public GetSubBusinesses fun(self: Clubhouse): Factory[]
local Clubhouse       = setmetatable({}, BusinessFront)
Clubhouse.__index     = Clubhouse

---@param opts BusinessFrontOpts
---@return Clubhouse
function Clubhouse.new(opts)
	local base       = BusinessFront.new(opts)
	local instance   = setmetatable(base, Clubhouse) ---@cast instance Clubhouse
	local customName = stats.get_string("MPX_MC_GANG_NAME") .. stats.get_string("MPX_MC_GANG_NAME2")
	if (not string.isvalid(customName)) then
		customName = Game.GetLabelText("GB_REST_ACCM")
	end

	instance.m_custom_name = customName

	for i = 0, 4 do
		instance:AddSubBusiness(i)
	end

	return instance
end

---@return string
function Clubhouse:GetCustomName()
	return self.m_custom_name
end

---@return joaat_t
function Clubhouse:GetClientBikeModel()
	return stats.get_int("MPX_MPSV_MODEL_BIKER_CLT")
end

---@return string
function Clubhouse:GetClientBikeName()
	local model = self:GetClientBikeModel()
	if (not model or model == 0) then
		return _T("GENERIC_NONE")
	end

	return Game.GetVehicleDisplayName(model)
end

---@param index integer
function Clubhouse:AddSubBusiness(index)
	if (not math.is_inrange(index, 0, 4)) then
		return
	end

	local property_index = stats.get_int(_F("MPX_FACTORYSLOT%d", index))
	local ref = RawBusinessData.BikerBusinesses[property_index]
	if (not ref) then
		return
	end

	local ref2 = RawBusinessData.BikerTunables[ref.id]
	if (not ref2) then
		return
	end

	local has_eq_upgrade    = stats.get_int(_F("MPX_FACTORYUPGRADES%d", index)) == 1
	local has_staff_upgrade = stats.get_int(_F("MPX_FACTORYUPGRADES%d_1", index)) == 1
	local eq_upg_mult       = tunables.get_int(ref2.mult_1)
	local stf_upg_mult      = tunables.get_int(ref2.mult_2)
	local normalized_name   = Switch(ref.id) {
		[0]     = "BIKER_WH_5B",
		[1]     = "BIKER_WH_2B",
		[2]     = "BIKER_WH_4B",
		[3]     = "BIKER_WH_1B",
		[4]     = "BIKER_WH_3B",
		default = ""
	}

	table.insert(self.m_subs, Factory.new({
		id              = index,
		name            = Game.GetLabelText(ref.gxt),
		normalized_name = not normalized_name:isempty() and Game.GetLabelText(normalized_name) or nil,
		max_units       = ref2.max_units,
		vpu             = tunables.get_int(ref2.vpu),
		vpu_mult_1      = has_eq_upgrade and eq_upg_mult or 0,
		vpu_mult_2      = has_staff_upgrade and stf_upg_mult or 0,
		coords          = ref.coords,
	}))
end

---@param newName string
function Clubhouse:Rename(newName)
	newName = newName:trim()
	script.execute_as_script("freemode", function()
		if (not string.isvalid(newName)) then
			newName = Game.GetLabelText("GB_REST_ACCM")
		end

		local GPBD_FM_3 = self:GetGPBD3():At(10)
		local name1     = newName:sub(1, 10)
		local name2     = newName:sub(11, 32)
		local g_Name    = GPBD_FM_3:At(359)
		stats.set_string("MPX_MC_CLBHOSE_NAME", name1)
		stats.set_string("MPX_MC_CLBHOSE_NAME2", name2)
		stats.set_string("MPX_MC_GANG_NAME", name1)
		stats.set_string("MPX_MC_GANG_NAME2", name2)
		g_Name:WriteString(newName, 64)

		if (LocalPlayer:IsBoss()) then
			GPBD_FM_3:At(106):WriteString(newName, 64)
		end

		local clubInt = InteriorIDs.INTERIOR_ID_CLUBHOUSE
		if (LocalPlayer:GetInteriorID() == clubInt) then
			INTERIOR.REFRESH_INTERIOR(clubInt)
		end

		local current      = g_Name:ReadString()
		self.m_custom_name = current
		if (current ~= newName) then
			log.warning("Rename failed!")
		end
	end)
end

return Clubhouse.new
