-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CEntity           = require("includes.classes.gta.CEntity")
local CPedWeaponManager = require("includes.classes.gta.CPedWeaponManager")
local CPlayerInfo       = require("includes.classes.gta.CPlayerInfo")


---@class CPedIntelligence
---@class CPedInventory


--------------------------------------
-- Class: CPed
--------------------------------------
---@ignore
---@class CPed : CEntity
---@field protected m_ptr pointer
---@field m_ped_intelligence pointer<CPedIntelligence>
---@field m_ped_inventory pointer<CPedInventory>
---@field m_ped_weapon_mgr pointer_ref<CPedWeaponManager>
---@field m_player_info CPlayerInfo
---@field m_velocity pointer<vec3>
---@field m_ped_type pointer<uint32_t>
---@field m_ped_task_flag pointer<uint8_t>
---@field m_seatbelt pointer<uint8_t>
---@field m_armor pointer<float>
---@field m_cash pointer<uint16_t> // 0x1614
---@field private m_ped_weapon_mgr_inst CPedWeaponManager
---@overload fun(ped: handle): CPed
local CPed = Class("CPed", { parent = CEntity, symbolic_size = 0x161C, pointer_ctor = true })

---@param ped handle
---@return CPed
function CPed:init(ped)
	if (not Game.IsScriptHandle(ped) or not ENTITY.IS_ENTITY_A_PED(ped)) then
		error("Invalid entity!")
	end

	self:super().init(self, ped)
	local ptr = memory.handle_to_ptr(ped)
	return setmetatable({
		m_ptr              = ptr,
		m_ped_intelligence = ptr:add(0x10A0),
		m_ped_inventory    = ptr:add(0x10B0),
		m_ped_weapon_mgr   = ptr:add(0x10B8),
		m_velocity         = ptr:add(0x0300),
		m_ped_type         = ptr:add(0x1098),
		m_ped_task_flag    = ptr:add(0x144B),
		m_seatbelt         = ptr:add(0x143C),
		m_armor            = ptr:add(0x150C),
		m_cash             = ptr:add(0x1614),
		m_player_info      = CPlayerInfo(ptr:add(0x10A8):deref()),
		---@diagnostic disable-next-line: param-type-mismatch
	}, CPed)
end

---@return boolean
function CPed:CanRagdoll()
	return self:__safecall(false, function()
		return (self.m_ped_type:get_dword() & 0x20) ~= 0
	end)
end

---@return boolean
function CPed:HasSeatbelt()
	return self:__safecall(false, function()
		return (self.m_seatbelt:get_byte() & 0x3) ~= 0
	end)
end

---@return float
function CPed:GetSpeed()
	return self:__safecall(0.0, function()
		return self.m_velocity:get_vec3():mag()
	end)
end

---@return ePedType
function CPed:GetPedType()
	return self:__safecall(-1, function()
		return (self.m_ped_type:get_dword() << 11 >> 25)
	end)
end

---@return CPedWeaponManager?
function CPed:GetWeaponManager()
	return self:__safecall(nil, function()
		local ptr = self.m_ped_weapon_mgr:deref()
		if (ptr:is_null()) then
			self.m_ped_weapon_mgr_inst = nil
			return nil
		end

		local mgr = self.m_ped_weapon_mgr_inst
		---@diagnostic disable-next-line: invisible
		if (not mgr or not mgr:IsValid() or (mgr.m_ptr ~= ptr)) then
			self.m_ped_weapon_mgr_inst = CPedWeaponManager(ptr)
		end

		return self.m_ped_weapon_mgr_inst
	end)
end

return CPed
