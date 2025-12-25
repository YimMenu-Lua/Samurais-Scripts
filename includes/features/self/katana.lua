---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class Katana : FeatureBase
---@field private m_entity Self
---@field private m_is_active boolean
---@field private m_katana_handle handle
---@field private m_katana_model hash
local Katana      = setmetatable({}, FeatureBase)
Katana.__index    = Katana

---@param entity Self
---@return Katana
function Katana.new(entity)
	local self = FeatureBase.new(entity)
	return setmetatable(self, Katana)
end

function Katana:Init()
	self.m_is_active = false
	self.m_katana_handle = 0
	self.m_katana_model = 0xE2BA016F
end

function Katana:ShouldRun()
	return GVars.features.weapon.katana.enabled
end

function Katana:Cleanup()
	if (self.m_katana_handle == 0) then
		return
	end

	Game.DeleteEntity(self.m_katana_handle, Enums.eEntityType.Object)
	self.m_katana_handle = 0
	self.m_is_active = false
end

function Katana:Update()
	local playerHandle = Self:GetHandle()
	local model_to_replace <const> = GVars.features.weapon.katana.model
	if (not WEAPON.IS_PED_ARMED(playerHandle, 1)) then
		self:Cleanup()
		return
	end

	local wpn_hash = Self:GetCurrentWeaponHash()
	if (wpn_hash ~= model_to_replace) then
		self:Cleanup()
		return
	end

	local wpn_idx = Self:GetCurrentWeaponIndex()
	if (not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(wpn_idx, playerHandle)) then
		self:Cleanup()
		return
	end

	if (self.m_katana_handle == 0) then
		Await(Game.RequestModel, self.m_katana_model)
		self.m_katana_handle = Game.CreateObject(self.m_katana_model, vec3:zero(), true, false, true)
		if (not ENTITY.DOES_ENTITY_EXIST(self.m_katana_handle)) then
			self:Cleanup()
			return
		end

		ENTITY.SET_ENTITY_COLLISION(self.m_katana_handle, false, false)
		ENTITY.SET_ENTITY_ALPHA(wpn_idx, 0, false)
		ENTITY.SET_ENTITY_VISIBLE(wpn_idx, false, false)
	elseif (not self.m_is_active) then
		ENTITY.ATTACH_ENTITY_TO_ENTITY(
			self.m_katana_handle,
			wpn_idx,
			0,
			0.0,
			0.0,
			0.025,
			0.0,
			0.0,
			0.0,
			false,
			false,
			false,
			false,
			2,
			true,
			0
		)

		self.m_is_active = true
	end
end

return Katana
