-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView    = require("includes.classes.gta.CStructView")
local NetCatalogNode = require("includes.classes.gta.NetCatalogNode")


--------------------------------------
-- Class: NetCatalog
--------------------------------------
---@class NetCatalog : CStructBase<NetCatalog>
---@field m_bucket_array pointer_ref
---@field m_bucket_count pointer<uint16_t>
---@field m_catalog_crc pointer<uint32_t>
---@field m_catalog_file_crc pointer<uint32_t>
---@field m_catalog_version pointer<uint32_t>
---@field m_catalog_latest_version pointer<uint32_t>
---@overload fun(ptr: pointer): NetCatalog
local NetCatalog = CStructView("NetCatalog", 0x60)

---@param ptr pointer
---@return NetCatalog
function NetCatalog.new(ptr)
	return MakeInstance({
		m_ptr                    = ptr,
		m_bucket_array           = ptr:add(0x30),
		m_bucket_count           = ptr:add(0x38),
		m_catalog_crc            = ptr:add(0x50),
		m_catalog_file_crc       = ptr:add(0x54),
		m_catalog_version        = ptr:add(0x58),
		m_catalog_latest_version = ptr:add(0x5C),
	}, NetCatalog)
end

---@return uint16_t
function NetCatalog:GetBucketCount()
	return self:__safecall(0, function() return self.m_bucket_count:get_word() end)
end

-- Bucket indices match C++: 0..count-1.
---@param index integer
---@return NetCatalogNode?
function NetCatalog:GetBucket(index)
	local count = self:GetBucketCount()
	assert(math.type(index) == "integer" and index >= 0 and index < count, "Catalog bucket index out of bounds")
	local buckets = self.m_bucket_array:deref()
	assert(buckets:is_valid(), "Catalog bucket array is null")
	local ptr = buckets:add(index * 0x8):deref()
	if (ptr:is_null()) then return nil end
	return NetCatalogNode(ptr)
end

---@return fun(): integer?, NetCatalogNode?
function NetCatalog:Iter()
	local bucket, current, visited, done = -1, nil, {}, false
	return function()
		if (done) then return nil end
		if (current) then current = current:GetNext() end
		while (not current) do
			bucket = bucket + 1
			if (bucket >= self:GetBucketCount()) then
				done = true
				return nil
			end
			current = self:GetBucket(bucket)
			visited = {}
		end
		local address = current:GetAddress()
		assert(not visited[address], "Cycle in catalog bucket")
		visited[address] = true
		return bucket, current
	end
end

return NetCatalog
