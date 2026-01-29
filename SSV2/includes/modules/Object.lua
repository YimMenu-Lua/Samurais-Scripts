-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Object
--------------------------------------
-- **Global.**
--
-- **Parent:** `Entity`.
--
-- Class representing a GTA V object (Unfinished).
---@class Object : Entity
---@field private m_internal CEntity
---@field Resolve fun(self: Object) : CEntity
---@overload fun(handle: integer): Entity
Object = Class("Object", Entity)

---@return boolean
function Object:IsValid()
	return ENTITY.DOES_ENTITY_EXIST(self:GetHandle()) and ENTITY.IS_ENTITY_AN_OBJECT(self:GetHandle())
end

function Object:SetOnGroundProperly()
	if not self:IsValid() then
		return
	end

	OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(self:GetHandle())
end
