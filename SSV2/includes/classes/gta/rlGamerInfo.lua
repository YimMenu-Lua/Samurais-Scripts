-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")

---@class IPAddress
---@field private m_decimal uint32_t
---@field private m_packed vec4
---@overload fun(n: uint32_t): IPAddress
local IPAddress <const> = {}
IPAddress.__index = IPAddress
---@diagnostic disable-next-line
setmetatable(IPAddress, {
	__call = function(t, ...)
		return t.new(...)
	end
})

---@param n uint32_t
---@return IPAddress
function IPAddress.new(n)
	local packed = vec4:zero()
	if (n ~= 0) then
		packed = vec4:new(
			math.floor(n / 16777216),
			math.floor(n / 65536) % 256,
			math.floor(n / 256) % 256,
			n % 256
		)
	end

	return setmetatable({
		m_decimal = n,
		m_packed  = packed
		---@diagnostic disable-next-line
	}, IPAddress)
end

---@return string
function IPAddress:__tostring()
	return _F("%d.%d.%d.%d",
		self.m_packed.x,
		self.m_packed.y,
		self.m_packed.z,
		self.m_packed.w
	)
end

--------------------------------------
-- Class: rlGamerInfo
--------------------------------------
---@class rlGamerInfo : CStructBase<rlGamerInfo>
---@field m_peer_id pointer<uint64_t>
---@field m_rockstar_id pointer<int64_t>
---@field m_external_ip pointer<uint32_t>
---@field m_external_port pointer<uint16_t>
---@field m_internal_ip pointer<uint32_t>
---@field m_internal_port pointer<uint16_t>
---@field m_nat_type pointer<uint32_t>
---@field m_player_name pointer<string> // 0x00DC
---@overload fun(ptr: pointer): rlGamerInfo
local rlGamerInfo = CStructView("rlGamerInfo", 0x0F90)

---@param ptr pointer
---@return rlGamerInfo
function rlGamerInfo.new(ptr)
	return setmetatable({
		m_ptr           = ptr,
		m_peer_id       = ptr:add(0x0008),
		m_rockstar_id   = ptr:add(0x0010),
		m_external_ip   = ptr:add(0x00A8),
		m_external_port = ptr:add(0x00AC),
		m_internal_ip   = ptr:add(0x00B0),
		m_internal_port = ptr:add(0x00B4),
		m_nat_type      = ptr:add(0x00B8),
		m_player_name   = ptr:add(0x00DC),
		---@diagnostic disable-next-line: param-type-mismatch
	}, rlGamerInfo)
end

---@return IPAddress
function rlGamerInfo:GetExternalIP()
	return IPAddress(self.m_external_ip:get_dword())
end

---@return IPAddress
function rlGamerInfo:GetInternalIP()
	return IPAddress(self.m_internal_ip:get_dword())
end

---@return string
function rlGamerInfo:GetPlayerName()
	return self.m_player_name:get_string()
end

return rlGamerInfo
