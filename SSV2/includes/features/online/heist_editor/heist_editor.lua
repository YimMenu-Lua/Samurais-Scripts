-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local heistData               = require("includes.data.heist_editor_data")
local mpProperties            = require("includes.data.mp_properties")
local IManagedValueController = require("includes.services.IManagedValueController")

-- TODO: property resolution is repeated in several places. add a property manager service.
---@param prop_id integer
---@param data_key string
---@return GenericProperty?
local function get_generic_property(prop_id, data_key)
	if (prop_id == 0) then return end

	local entry = mpProperties[data_key]
	if (not entry) then return end

	local t = entry[prop_id]
	local gxt = t.gxt
	if (gxt) then
		Translator:TranslateGXT(gxt)
	end
	return { name = gxt or t.name or "GENERIC_UNKNOWN", coords = t.coords }
end

local HeistResolvers <const> = {
	{
		resolve_property = function()
			return get_generic_property(stats.get_int("MPX_DBASE_OWNED"), "Facilities")
		end,
		ctor = require("includes.features.online.heist_editor.heists.gang_ops").new
	},
	{
		resolve_property = function()
			return get_generic_property(stats.get_int("MPX_ARCADE_OWNED"), "Arcades")
		end,
		ctor = require("includes.features.online.heist_editor.heists.casino_heist").new
	},
	{
		resolve_property = function() return nil end, -- special case vehicle property. the constructor handles it instead
		ctor = require("includes.features.online.heist_editor.heists.cayo_perico").new
	},
	{
		resolve_property = function()
			for i = 1, 9 do
				local id = stats.get_int("MPX_MULTI_PROPERTY_" .. i)
				if (id ~= 0) then
					return get_generic_property(id, "Apartments")
				end
			end
			return nil
		end,
		ctor = require("includes.features.online.heist_editor.heists.og_heists").new
	},
	-- {
	-- 	resolve_property = function()
	-- 		for _, statname in ipairs(mansionStats) do
	-- 			local id = stats.get_int(statname)
	-- 			if (id ~= 0) then
	-- 				return get_generic_property(id, "Mansions")
	-- 			end
	-- 		end
	-- 		return nil
	-- 	end,
	-- },
	-- {
	-- 	resolve_property = function()
	-- 		return get_generic_property(stats.get_int("MPX_FIXER_HQ_OWNED"), "Agencies")
	-- 	end,
	-- },
	-- {
	-- 	resolve_property = function()
	-- 		return get_generic_property(stats.get_int("MPX_AUTO_SHOP_OWNED"), "AutoShops")
	-- 	end,
	-- },
	-- {
	-- 	resolve_property = function()
	-- 		if (stats.get_int("MPX_HACKER_DEN_OWNED") == 0) then
	-- 			return
	-- 		end
	-- 		return mpProperties.HackerDen[1]
	-- 	end,
	-- },
	-- {
	-- 	resolve_property = function()
	-- 		if (stats.get_int("MPX_AMCKENZIE_HANGAR_OWNED") == 0) then
	-- 			return
	-- 		end
	-- 		return mpProperties.FieldHangar[1]
	-- 	end,
	-- },
}

-- TODO: re-implement simple jobs
---@class Job


---@class HeistEditor
---@field private m_heists array<Heist>
---@field private m_jobs array<Job> -- TODO
---@field private m_managed_value_controller IManagedValueController
---@field private m_running_script ("fm_mission_controller"|"fm_mission_controller_2020"|"fm_mission_controller_v3")?
---@field private m_controller_last_tick TimePoint
---@field public SoloMissions SoloMissions
local HeistEditor   = { m_heists = {}, SoloMissions = require("includes.thirdparty.SoloMissions") }
HeistEditor.__index = HeistEditor

function HeistEditor:init()
	if (self.m_initialized) then
		return self
	end

	self.m_managed_value_controller = IManagedValueController.new()
	self.m_controller_last_tick     = TimePoint()

	if (Game.IsOnline()) then
		self:RebuildHeists()
		if (GVars.features.yim_heists.sixty_nine) then
			self:SetSetupCosts()
		end
	end

	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
		self:Reset()
	end)

	ThreadManager:RegisterLooped("SS_HEIST_EDITOR", function(s)
		self:OnTick(s)
	end)

	self.m_initialized = true
	return self
end

function HeistEditor:Reset()
	self.m_managed_value_controller:Clear()
	self:RebuildHeists()
end

---@return boolean
function HeistEditor:IsAnyScriptRunning()
	return self.m_running_script ~= nil
end

---@return array<Heist>
function HeistEditor:GetHeists()
	return self.m_heists
end

---@return ("fm_mission_controller"|"fm_mission_controller_2020"|"fm_mission_controller_v3")?
function HeistEditor:GetRunningScript()
	return self.m_running_script
end

---@param heist Heist
function HeistEditor:Append(heist)
	if (not heist) then return end

	heist:RegisterManagedValues(self.m_managed_value_controller)
	table.insert(self.m_heists, heist)
end

---@private
function HeistEditor:RebuildHeists()
	ThreadManager:Run(function()
		while (Game.IsInNetworkTransition()) do
			yield()
		end

		if (not network.is_session_started() or NETWORK.NETWORK_IS_ACTIVITY_SESSION()) then
			return
		end

		table.clear(self.m_heists)
		for _, v in ipairs(HeistResolvers) do
			local ctor = v.ctor ---@type (fun(GenericProperty?): Heist)?
			if (not ctor) then
				goto continue
			end

			self:Append(ctor(v.resolve_property()))
			::continue::
		end
	end)
end

---@private
function HeistEditor:SetSetupCosts()
	for _, t in ipairs(heistData.CostTunables) do
		if (not t:IsReady()) then
			t:SaveDefaultValue()
		end

		---@diagnostic disable-next-line
		t:Apply()
	end
end

---@private
function HeistEditor:ResetSetupCosts()
	for _, t in ipairs(heistData.CostTunables) do
		t:Reset()
	end
end

---@param v boolean
function HeistEditor:ToggleSetupCosts(v)
	if (v) then
		self:SetSetupCosts()
	else
		self:ResetSetupCosts()
	end
	Notifier:ShowMessage("HeistEditor", _T("GENERIC_SESSION_REFRESH_NOTIF"))
end

---@private
function HeistEditor:TickMVC()
	if (self.m_running_script ~= nil) then
		return
	end

	if (not self.m_controller_last_tick:HasElapsed(5000)) then
		return
	end

	self.m_managed_value_controller:OnCall()
	self.m_controller_last_tick:Reset()
end

---@param s script_util
function HeistEditor:OnTick(s)
	s:yield()

	if (not Game.IsOnline()) then
		return
	end


	local SoloMissions    = self.SoloMissions
	self.m_running_script = SoloMissions:GetRunningFmmcScript()
	SoloMissions:OnTick()
	self:TickMVC()

	for _, heist in ipairs(self.m_heists) do
		heist:OnTick()
		s:yield()
	end
end

return HeistEditor:init()
