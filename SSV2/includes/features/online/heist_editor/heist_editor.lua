-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local heistData <const>       = require("includes.data.heist_editor_data")
local IManagedValueController = require("includes.services.IManagedValueController")
local GetRunningFmmcScript    = Game.GetRunningFmmcScript

-- TODO: re-implement simple jobs
---@class Job


---@class HeistEditor
---@field private m_heists array<Heist>
---@field private m_jobs array<Job> -- TODO
---@field private m_managed_value_controller IManagedValueController
---@field private m_running_script ("fm_mission_controller"|"fm_mission_controller_2020"|"fm_mission_controller_v3")?
---@field private m_controller_last_tick TimePoint
---@field private m_ready boolean
local HeistEditor   = { m_heists = {} }
HeistEditor.__index = HeistEditor

function HeistEditor:init()
	if (self.m_initialized) then
		return self
	end

	self.m_ready                    = false
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

---@return boolean
function HeistEditor:IsReady()
	return self.m_ready
end

function HeistEditor:Reload()
	self:Reset()
	ThreadManager:Run(function(s)
		self.m_ready = false
		sleep(1200)
		self.m_ready = true
	end)
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
	self.m_ready = false
	ThreadManager:Run(function()
		while (Game.IsInNetworkTransition()) do
			yield()
		end

		if (not network.is_session_started()) then
			return
		end

		table.clear(self.m_heists)
		for _, v in ipairs(heistData.HeistResolvers) do
			local get_ctor = v.get_ctor ---@type (fun(): (fun(GenericProperty?: GenericProperty): Heist)?)
			local ctor     = get_ctor and get_ctor() or nil
			if (ctor) then
				self:Append(ctor(v.resolve_property()))
			end
		end
		self.m_ready = true
	end)
end

---@private
function HeistEditor:SetSetupCosts()
	for _, t in ipairs(heistData.CostTunables) do
		if (not t:IsReady()) then
			t:SaveDefaultValue()
		end

		---@diagnostic disable: discard-returns
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


	self.m_running_script = GetRunningFmmcScript()
	self:TickMVC()

	for _, heist in ipairs(self.m_heists) do
		heist:OnTick()
		s:yield()
	end
end

return HeistEditor:init()
