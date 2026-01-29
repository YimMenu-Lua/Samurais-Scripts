-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-----------------------------------------------------
-- ForgeEntity Struct
-----------------------------------------------------
-- Represents an entity spawned with `EntityForge` (ped, vehicle, object).
---@class ForgeEntity
---@field m_handle integer
---@field m_name string
---@field m_model_hash integer
---@field m_type eEntityType
---@field m_properties table
---@field m_alpha number
---@field m_is_attached boolean
---@field m_is_forged boolean
---@field m_is_player boolean
---@field m_is_world_entity boolean
---@field m_parent table
---@field m_parent_bone number | string
---@field m_children ForgeEntity[]
---@field m_position vec3
---@field m_rotation vec3
---@field m_target_pos vec3?
---@field m_last_pos vec3?
---@field m_attach_pos vec3
---@field m_attach_rot vec3
---@overload fun(handle: handle, name: string, modelHash: hash, entityType: eEntityType, alpha: number, coords: vec3, rotation: vec3): ForgeEntity
local ForgeEntity = {}
ForgeEntity.__index = ForgeEntity
ForgeEntity.__type = "ForgeEntity"
---@diagnostic disable-next-line
setmetatable(ForgeEntity, {
	__call = function(_, ...)
		return ForgeEntity.new(...)
	end
})

---@param handle handle
---@param name string
---@param modelHash hash
---@param entityType eEntityType
---@param alpha? number
---@param coords vec3
---@param rotation vec3
---@return ForgeEntity
function ForgeEntity.new(handle, name, modelHash, entityType, alpha, coords, rotation)
	---@diagnostic disable-next-line: param-type-mismatch
	local instance = setmetatable({}, ForgeEntity)
	instance.m_handle = handle
	instance.m_name = name
	instance.m_model_hash = modelHash
	instance.m_type = entityType
	instance.m_properties = {}
	instance.m_alpha = alpha or 255
	instance.m_is_attached = false
	instance.m_is_player = handle == Self:GetHandle()
	instance.m_parent = {}
	instance.m_children = {}
	instance.m_position = coords
	instance.m_rotation = rotation
	return instance
end

---@return boolean
function ForgeEntity:IsParent()
	return self.m_children and next(self.m_children) ~= nil
end

function ForgeEntity:serialize()
	local childTables = {}
	for _, child in ipairs(self.m_children or {}) do
		table.insert(childTables, child:serialize())
	end

	return {
		name        = self.m_name,
		handle      = self.m_handle,
		modelHash   = self.m_model_hash,
		type        = self.m_type,
		alpha       = self.m_alpha,
		isAttached  = self.m_is_attached,
		isPlayer    = self.m_is_player,
		properties  = self.m_properties,
		parent_bone = self.m_parent_bone,
		attach_pos  = self.m_attach_pos and self.m_attach_pos:serialize() or vec3:zero():serialize(),
		attach_rot  = self.m_attach_rot and self.m_attach_rot:serialize() or vec3:zero():serialize(),
		isForged    = true,
		children    = childTables,
	}
end

---@param data table
---@return ForgeEntity
function ForgeEntity.deserialize(data)
	local instance         = ForgeEntity.new(
		0,
		data.name,
		data.modelHash,
		data.type,
		data.alpha or 255,
		data.coordinates or vec3:zero(),
		data.rotation or vec3:zero()
	)

	instance.m_properties  = data.properties or {}
	instance.m_attach_pos  = data.attach_pos and vec3.deserialize(data.attach_pos) or vec3:zero()
	instance.m_attach_rot  = data.attach_rot and vec3.deserialize(data.attach_rot) or vec3:zero()
	instance.m_parent_bone = data.parent_bone
	instance.m_is_player   = data.isPlayer
	instance.m_is_attached = data.isAttached
	instance.m_children    = data.children or {}
	instance.m_is_forged   = true

	return instance
end

-- if (Serializer and not Serializer.class_types["ForgeEntity"]) then
-- 	Serializer:RegisterNewType("ForgeEntity", ForgeEntity.serialize, ForgeEntity.deserialize)
-- end

return ForgeEntity
