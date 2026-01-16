---@class CWeaponFiringPatternAliases
---@field protected m_ptr pointer
---@field m_name_hash pointer<joaat_t> // 0x0
---@field m_aliases atArray<CFiringPatternAlias> // 0x8
---@overload fun(ptr: pointer): CWeaponFiringPatternAliases
local CWeaponFiringPatternAliases = {}
CWeaponFiringPatternAliases.__index = CWeaponFiringPatternAliases
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(CWeaponFiringPatternAliases, {
	__call = function(_, ...)
		return CWeaponFiringPatternAliases.new(...)
	end
})

---@param ptr pointer
---@return CWeaponFiringPatternAliases
function CWeaponFiringPatternAliases.new(ptr)
	return setmetatable({
		m_name_hash = ptr:add(0x0),
		m_aliases   = atArray(ptr:add(0x8))
		---@diagnostic disable-next-line: param-type-mismatch
	}, CWeaponFiringPatternAliases)
end

return CWeaponFiringPatternAliases
