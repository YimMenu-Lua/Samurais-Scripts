---@enum eHandlingEditorTypes
Enums.eHandlingEditorTypes = {
	TYPE_HF  = 0, -- handling flag
	TYPE_AF  = 1, -- advanced flag
	TYPE_MIF = 2, -- model info flag
}

---@class HandlingObject
---@field m_flag eVehicleHandlingFlags | eVehicleAdvancedFlags | eVehicleModelInfoFlags
---@field m_type eHandlingEditorTypes
---@field m_default boolean
---@field m_was_edited boolean
---@field m_predicate? Predicate<HandlingObject, PlayerVehicle>
---@field m_on_enable? Callback
---@field m_on_disable? Callback
local HandlingObject = {}
HandlingObject.__index = HandlingObject

---@param flag eVehicleHandlingFlags | eVehicleAdvancedFlags | eVehicleModelInfoFlags
---@param flagType eHandlingEditorTypes
---@param predicate? Predicate<HandlingObject, PlayerVehicle>
function HandlingObject.new(flag, flagType, predicate)
	return setmetatable({
		m_flag = flag,
		m_type = flagType,
		m_predicate = predicate
	}, HandlingObject)
end

---@class HandlingEditor
---@field private m_pv PlayerVehicle
---@field private m_handling_objects table<string, HandlingObject>
---@field private m_initialized boolean
local HandlingEditor = {}
HandlingEditor.__index = HandlingEditor

---@param pv PlayerVehicle
function HandlingEditor:init(pv)
	if (self.m_initialized) then
		log.warning("[HandlingEditor]: Attempt to re-initialize. Only one instance is allowed.")
		return self
	end

	self.m_pv = pv
	self.m_handling_objects = {}
	self.m_initialized = true

	return self
end

---@param gvarKey string
---@param flag eVehicleHandlingFlags | eVehicleAdvancedFlags | eVehicleModelInfoFlags
---@param flagType eHandlingEditorTypes
---@param predicate? Predicate
---@param onEnable? Callback
---@param onDisable? Callback
function HandlingEditor:PushFlag(gvarKey, flag, flagType, predicate, onEnable, onDisable)
	if (self.m_handling_objects[gvarKey]) then
		return
	end

	local obj = HandlingObject.new(flag, flagType, predicate)

	if (self.m_pv and self.m_pv:IsValid()) then
		obj.m_default = self:GetFlagDefault(obj)
	end

	obj.m_on_enable = onEnable
	obj.m_on_disable = onDisable
	self.m_handling_objects[gvarKey] = obj
end

---@param obj HandlingObject
---@return boolean
function HandlingEditor:GetFlagDefault(obj)
	return Switch(obj.m_type) {
		[Enums.eHandlingEditorTypes.TYPE_HF] = self.m_pv:GetHandlingFlag(obj.m_flag),
		[Enums.eHandlingEditorTypes.TYPE_AF] = self.m_pv:GetAdvancedFlag(obj.m_flag),
		[Enums.eHandlingEditorTypes.TYPE_MIF] = self.m_pv:GetModelInfoFlag(obj.m_flag),
		default = false
	}
end

---@param gvarKey string
---@return HandlingObject?
function HandlingEditor:GetFlagObject(gvarKey)
	return self.m_handling_objects[gvarKey]
end

---@param obj HandlingObject
---@param toggle boolean
---@param reset? boolean
function HandlingEditor:SetFlag(obj, toggle, reset)
	if (not self.m_pv or not self.m_pv:IsValid()) then
		return
	end

	assert(type(toggle) == "boolean", "Attempt to write garbage data to vehicle memory.")

	if (obj.m_default == nil) then
		obj.m_default = self:GetFlagDefault(obj)
	end

	if (toggle ~= obj.m_default and obj.m_was_edited) then
		return
	end

	local set_func
	if (obj.m_type == Enums.eHandlingEditorTypes.TYPE_HF) then
		set_func = Vehicle.SetHandlingFlag
	elseif (obj.m_type == Enums.eHandlingEditorTypes.TYPE_AF) then
		set_func = Vehicle.SetAdvancedFlag
	elseif (obj.m_type == Enums.eHandlingEditorTypes.TYPE_MIF) then
		set_func = Vehicle.SetModelInfoFlag
	end

	if (not set_func) then
		return
	end

	set_func(self.m_pv, obj.m_flag, toggle)
	local callback = toggle and obj.m_on_enable or obj.m_on_disable
	if (type(callback) == "function") then
		callback()
	end

	if (reset) then
		obj.m_was_edited = false
		return
	end

	obj.m_was_edited = true
end

---@param obj HandlingObject
function HandlingEditor:ResetFlag(obj)
	if ((type(obj.m_predicate) == "function") and not obj:m_predicate(self.m_pv)) then
		return
	end

	if (not obj.m_was_edited or obj.m_default == nil) then
		return
	end

	obj.m_was_edited = false
	self:SetFlag(obj, obj.m_default, true)
	if (type(obj.m_on_disable) == "function") then
		obj.m_on_disable()
	end
end

function HandlingEditor:Apply()
	if (not self.m_pv or not self.m_pv:IsValid()) then
		return
	end

	for key, obj in pairs(self.m_handling_objects) do
		if ((type(obj.m_predicate) == "function") and not obj:m_predicate(self.m_pv)) then
			goto continue
		end

		if (obj.m_default == nil) then
			obj.m_default = self:GetFlagDefault(obj)
		end

		local checkboxState = table.get_nested_key(GVars, key)
		-- explicit eval becayse these can be nil or garbage
		-- we only act on checkbox enabled and default is off because checkboxes don't represent actual flag state in memory
		-- this prevents disabling default enabled flags on init when a checkbox was never set in the first place
		if (checkboxState == true and obj.m_default == false) then
			self:SetFlag(obj, true)
		end

		::continue::
	end
end

function HandlingEditor:Reset()
	if (not self.m_pv or not self.m_pv:IsValid()) then
		return
	end

	for _, obj in pairs(self.m_handling_objects) do
		self:ResetFlag(obj)
	end
end

return HandlingEditor
