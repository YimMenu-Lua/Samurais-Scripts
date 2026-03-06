-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: phFragInst
--------------------------------------
---@class phFragInst
---@field protected m_ptr pointer
---@field public m_cache_entry pointer
---@field public m_num_bones number
---@field public m_skeleton pointer
---@field public m_obj_matrices pointer<fMatrix44[]> `rage::fMatrix44`
---@field public m_global_matrices pointer<fMatrix44[]> `rage::fMatrix44`
---@overload fun(addr: pointer): phFragInst
local phFragInst = {}
phFragInst.__index = phFragInst
phFragInst.__type = "phFragInst"
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(phFragInst, {
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

---@param ptr pointer
---@return phFragInst|nil
function phFragInst.new(ptr)
	if (not ptr or ptr:is_null()) then
		return
	end

	local cache = ptr:add(0x68):deref()
	if (not cache or cache:is_null()) then
		return
	end

	local skel = cache:add(0x178):deref() -- CSkeleton*
	if (not skel or skel:is_null()) then
		return
	end

	local numBones      = skel:add(0x20):get_int() or 0
	local matricesPtr   = skel:add(0x10):deref()
	local g_matricesPtr = skel:add(0x18):deref()

	return setmetatable({
		m_ptr             = ptr,
		m_cache_entry     = cache,
		m_skeleton        = skel,
		m_num_bones       = numBones or 0,
		m_obj_matrices    = matricesPtr,
		m_global_matrices = g_matricesPtr,
		---@diagnostic disable-next-line: param-type-mismatch
	}, phFragInst)
end

---@return pointer
function phFragInst:GetMatrixPtr(bone_index)
	if (not self.m_obj_matrices or self.m_num_bones == 0 or bone_index < 0) then
		return nullptr
	end

	return self.m_obj_matrices:add(bone_index * 0x40)
end

---@return pointer
function phFragInst:GetGlobalMatrixPtr(bone_index)
	if (not self.m_global_matrices or self.m_num_bones == 0 or bone_index < 0) then
		return nullptr
	end

	return self.m_global_matrices:add(bone_index * 0x40)
end

return phFragInst
