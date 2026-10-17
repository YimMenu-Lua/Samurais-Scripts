-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView       = require("includes.classes.gta.CStructView")
local NetCatalogBaseItem = require("includes.classes.gta.NetCatalogBaseItem")


--------------------------------------
-- Class: NetCatalogNode
--------------------------------------
---@class NetCatalogNode : CStructBase<NetCatalogNode>
---@field m_key_hash pointer<uint32_t>
---@field m_item pointer_ref<NetCatalogBaseItem>
---@field m_next pointer_ref<NetCatalogNode>
---@overload fun(ptr: pointer): NetCatalogNode
local NetCatalogNode = CStructView("NetCatalogNode", 0x18)

---@param ptr pointer
---@return NetCatalogNode
function NetCatalogNode.new(ptr)
	return MakeInstance({
		m_ptr      = ptr,
		m_key_hash = ptr,
		m_item     = ptr:add(0x08),
		m_next     = ptr:add(0x10),
	}, NetCatalogNode)
end

---@return NetCatalogBaseItem?
function NetCatalogNode:GetItem()
	if (not self:IsValid()) then return nil end
	local ptr = self.m_item:deref()
	if (ptr:is_null()) then return nil end
	return NetCatalogBaseItem(ptr)
end

---@return NetCatalogNode?
function NetCatalogNode:GetNext()
	if (not self:IsValid()) then return nil end
	local ptr = self.m_next:deref()
	if (ptr:is_null()) then return nil end
	return NetCatalogNode(ptr)
end

return NetCatalogNode
