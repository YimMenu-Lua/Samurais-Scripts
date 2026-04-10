-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class RawPedData
---@field model_hash hash
---@field ped_type ePedType
---@field ped_gender ePedGender
---@field is_human boolean

---@class RawVehicleData
---@field model_hash hash
---@field display_name string
---@field manufacturer string
---@field class_id eVehicleClass
---@field class_name string

---@class RawWeaponData
---@field model_name string
---@field group string
---@field gxt string
---@field display_name string

---@generic T
---@class RawDataService
---@field private m_ped_data { name: "PedDictionary", dict: PedDictionary, normalized: array<Pair<string, RawPedData>>, normalizing: boolean }
---@field private m_vehicle_data { name: "VehicleDictionary", dict: VehicleDictionary, normalized: array<Pair<string, RawVehicleData>>, normalizing: boolean }
---@field private m_weapon_data { name: "WeaponDictionary", dict: WeaponDictionary, normalized: array<Pair<string, RawWeaponData>>, normalizing: boolean }
local RawDataService <const> = {
	m_ped_data     = {},
	m_vehicle_data = {},
	m_weapon_data  = {},
}
RawDataService.__index = RawDataService

---@public
---@return PedDictionary
function RawDataService:GetPeds()
	if (not self.m_ped_data.dict) then
		self.m_ped_data.dict = require("includes.data.peds")
	end

	return self.m_ped_data.dict
end

---@public
---@return VehicleDictionary
function RawDataService:GetVehicles()
	if (not self.m_vehicle_data) then
		self.m_vehicle_data = require("includes.data.vehicles")
	end

	return self.m_vehicle_data
end

---@public
---@return WeaponDictionary
function RawDataService:GetWeapons()
	if (not self.m_weapon_data) then
		self.m_weapon_data = require("includes.data.weapon_data")
	end

	return self.m_weapon_data
end

---@public
---@return array<Pair<string, RawPedData>>?
function RawDataService:GetNormalizedPeds()
	return self:GetNormalizedArray(self.m_ped_data, "includes.data.peds")
end

---@public
---@return array<Pair<string, RawVehicleData>>?
function RawDataService:GetNormalizedVehicles()
	return self:GetNormalizedArray(self.m_vehicle_data, "includes.data.vehicles")
end

-- TODO: refactor weapon data generator
-- ---@public
-- ---@return array<Pair<string, RawWeaponData>>?
-- function RawDataService:GetNormalizedWeapons()
-- 	return self:GetNormalizedArray(self.m_weapon_data, "includes.data.weapon_data")
-- end

---@parivate
---@generic T
---@param data { name: string, dict: table<string, T>, normalized: array<Pair<string, T>>, normalizing: boolean }
---@param path string
function RawDataService:GetNormalizedArray(data, path)
	if (data.normalized) then
		return data.normalized
	end

	if (not data.dict) then
		data.dict = require(path)
	end

	if (not data.normalizing) then
		self:NormalizeGenericDict(data)
	end

	return nil
end

-- Normalizes a dict into an array of pairs and sorts it by name.
---@private
---@generic T
---@param data { name: string, dict: table<string, T>, normalized: array<Pair<string, T>>, normalizing: boolean }
function RawDataService:NormalizeGenericDict(data)
	if (data.normalizing) then return end

	data.normalizing = true
	ThreadManager:Run(function()
		local names    = {}
		local outArray = {}
		local dict     = data.dict

		for k in pairs(dict) do
			table.insert(names, k)
			yield()
		end

		table.sort(names, function(a, b)
			return a < b
		end)

		for i, name in ipairs(names) do
			outArray[i] = Pair.new(name, dict[name])
			yield()
		end

		data.normalized  = outArray
		data.normalizing = false
	end)
end

return RawDataService
