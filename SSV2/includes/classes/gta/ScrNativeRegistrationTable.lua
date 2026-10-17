-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: ScrNativeRegistrationTable
--------------------------------------
---@class ScrNativeRegistrationTable : CStructBase<ScrNativeRegistrationTable>
---@overload fun(ptr: pointer): ScrNativeRegistrationTable
local ScrNativeRegistrationTable = CStructView("ScrNativeRegistrationTable", 0x800)

---@param ptr pointer
---@return ScrNativeRegistrationTable
function ScrNativeRegistrationTable.new(ptr)
	return MakeInstance({ m_ptr = ptr }, ScrNativeRegistrationTable)
end

---@param ptr pointer
---@param salt uint32_t
---@return uint64_t
local function decode_pair(ptr, salt)
	local key = (ptr:get_address() ~ salt) & 0xFFFFFFFF
	local lo  = (ptr:get_dword() ~ key) & 0xFFFFFFFF
	local hi  = (ptr:add(0x4):get_dword() ~ key) & 0xFFFFFFFF
	return (hi << 32) | lo
end

-- Resolve current-build hashes with integer arithmetic. Legacy dynamic_call
-- converts uint64_t arguments through double and cannot preserve these hashes.
---@param hash uint64_t
---@return pointer
function ScrNativeRegistrationTable:GetHandler(hash)
	assert(self:IsValid(), "Native registration table is null")
	assert(math.type(hash) == "integer", "Native hash must be a Lua integer")
	local node    = self.m_ptr:add((hash & 0xFF) * 0x8):deref()
	local visited = {}
	while (node:is_valid()) do
		local address = node:get_address()
		assert(not visited[address], "Cycle in native registration table")
		visited[address] = true
		local count_ptr = node:add(0x48)
		local count     = (count_ptr:get_dword() ~ count_ptr:add(0x4):get_dword()
			~ count_ptr:get_address()) & 0xFFFFFFFF
		assert(count <= 7, "Unsupported native registration layout")
		for index = 0, count - 1 do
			local entry = node:add(0x54 + index * 0x10)
			if (decode_pair(entry, entry:add(0x8):get_dword()) == hash) then
				return node:add(0x10 + index * 0x8):deref()
			end
		end
		node = memory.pointer:new(decode_pair(node, node:add(0x8):get_dword()))
	end
	return node
end

return ScrNativeRegistrationTable
