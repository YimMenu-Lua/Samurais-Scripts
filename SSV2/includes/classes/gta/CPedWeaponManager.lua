local CWeaponInfo = require("includes.classes.gta.CWeaponInfo")

---@class CPedWeaponManager
---@field protected m_ptr pointer
---@field public m_owner pointer<CPed>
---@field public m_selected_weapon_hash pointer<uint32_t>
---@field public m_weapon_info CWeaponInfo?
---@field public m_vehicle_weapon_info CWeaponInfo?
---@overload fun(ptr: pointer): CPedWeaponManager
local CPedWeaponManager = { m_ptr = nullptr }
CPedWeaponManager.__index = CPedWeaponManager
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(CPedWeaponManager, {
	__call = function(_, ...)
		return CPedWeaponManager.new(...)
	end
})

---@param ptr pointer
---@return CPedWeaponManager?
function CPedWeaponManager.new(ptr)
	if (not ptr or ptr:is_null()) then
		return
	end

	ptr = ptr:deref()
	return setmetatable({
		m_ptr                  = ptr,
		m_owner                = ptr:add(0x0010):deref(), -- CPed
		m_selected_weapon_hash = ptr:add(0x0018),
		m_weapon_info          = CWeaponInfo(ptr:add(0x0020):deref()),
		m_vehicle_weapon_info  = CWeaponInfo(ptr:add(0x0070):deref()),
		---@diagnostic disable-next-line: param-type-mismatch
	}, CPedWeaponManager)
end

---@return boolean
function CPedWeaponManager:IsValid()
	return self.m_ptr and self.m_ptr:is_valid()
end

---@return pointer
function CPedWeaponManager:GetPointer()
	return self.m_ptr
end

---@return uint64_t
function CPedWeaponManager:GetAddress()
	return self.m_ptr:get_address()
end

return CPedWeaponManager
