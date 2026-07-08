-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.
--
-- Converted from Yimura's C++ GTA V Classes: https://github.com/Yimura/GTAV-Classes (forked here: https://github.com/Mr-X-GTA/GTAV-Classes-1)


local CStructView = require("includes.classes.gta.CStructView")


---@class IPV4
---@field private m_dword uint32_t
---@field private m_bytes UByte4
---@field private m_fmt string
---@overload fun(n: uint32_t): IPV4
local IPV4 <const> = Callable("IPV4", { ctor = function(t, n) return t:new(n) end })

---@param n uint32_t
---@return IPV4
function IPV4:new(n)
	local ubyte4 = {
		(n >> 24) & 0xFF,
		(n >> 16) & 0xFF,
		(n >> 8) & 0xFF,
		n & 0xFF
	}
	return setmetatable({
		m_dword = n,
		m_bytes = ubyte4,
		m_fmt   = table.concat(ubyte4, ".")
	}, self)
end

---@return uint32_t
function IPV4:GetU32()
	return self.m_dword
end

---@return uint8_t a, uint8_t b, uint8_t c, uint8_t d
function IPV4:Unpack()
	---@diagnostic disable-next-line: redundant-return-value
	return table.unpack(self.m_bytes)
end

---@return string
function IPV4:__tostring()
	return self.m_fmt
end

---@param right IPV4
---@return boolean
function IPV4:__eq(right)
	return self.m_dword == right.m_dword
end

--------------------------------------
-- Class: rlGamerInfo
--------------------------------------
---@class rlGamerInfo : CStructBase<rlGamerInfo>
---@field private m_peer_id pointer<uint64_t>
---@field private m_rockstar_id pointer<int64_t>
---@field private m_external_ip pointer<uint32_t>
---@field private m_external_port pointer<uint16_t>
---@field private m_internal_ip pointer<uint32_t>
---@field private m_internal_port pointer<uint16_t>
---@field private m_nat_type pointer<uint32_t>
---@field private m_player_name pointer<string> // 0x00DC
---@field private m_cached_extern_ipv4 IPV4
---@field private m_cached_intern_ipv4 IPV4
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

---@return int64_t
function rlGamerInfo:GetRockstarID()
	return self.m_rockstar_id:get_int()
end

---@return IPV4
function rlGamerInfo:GetExternalIP()
	if (not self.m_cached_extern_ipv4) then
		self.m_cached_extern_ipv4 = IPV4(self.m_external_ip:get_dword())
	end
	return self.m_cached_extern_ipv4
end

---@return IPV4
function rlGamerInfo:GetInternalIP()
	if (not self.m_cached_intern_ipv4) then
		self.m_cached_intern_ipv4 = IPV4(self.m_internal_ip:get_dword())
	end
	return self.m_cached_intern_ipv4
end

---@return string
function rlGamerInfo:GetPlayerName()
	return self.m_player_name:get_string()
end

return rlGamerInfo
