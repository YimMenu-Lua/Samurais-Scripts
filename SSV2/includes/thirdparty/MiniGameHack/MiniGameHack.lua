-- This code was implemented from MiniGameHack: https://github.com/YimMenu-Lua/MiniGameHack with the author's permission.
--
-- Original Author: sch-ida (sch): https://github.com/sch-lda
--
-- License: None.


local Keybind        = require("includes.structs.Keybind")
local mghData        = require("includes.thirdparty.MiniGameHack.mgh_data")
local SGSL           = require("includes.services.SGSL")
local sgslData       = SGSL.data
local isScriptActive = script.is_active


---@class MiniGameHack
---@field private m_initialized boolean
---@field private m_tmp_v2_g ScriptGlobal
---@field private m_is_busy boolean
---@field private m_is_disabled boolean
---@field private m_quarantine table<string, set<integer>>
local MiniGameHack   = {}
MiniGameHack.__index = MiniGameHack

function MiniGameHack:init()
	if (self.m_initialized) then
		return self
	end

	local defKeybinds    = Serializer:GetDefaultConfig().keybinds
	local rtKeybinds     = GVars.keybinds
	local runtimeKeybind = rtKeybinds.minigamehack

	if (not runtimeKeybind or Keybind.IsRawTable(runtimeKeybind)) then
		runtimeKeybind = defKeybinds.minigamehack
		rtKeybinds.minigamehack = runtimeKeybind
	end

	KeyManager:RegisterKeybind(runtimeKeybind, function()
		self:OnCall()
	end)

	self.m_quarantine  = {}
	self.m_tmp_v2_g    = SGSL:Get(sgslData.mgh_tmp_v2_global):AsGlobal()
	self.m_is_busy     = false
	self.m_is_disabled = false
	self.m_initialized = true

	return self
end

---@public
---@return boolean
function MiniGameHack:IsDisabled()
	return self.m_is_disabled
end

---@public
---@return boolean
function MiniGameHack:IsBusy()
	return self.m_is_busy
end

---@private
---@param scrName string
---@param index integer
---@return boolean
function MiniGameHack:IsEntryInQuarantine(scrName, index)
	local q   = self.m_quarantine
	local set = q[scrName]
	if (not set) then
		return false
	end

	return set[index] == true
end

---@private
---@param scrName string
---@param index integer
function MiniGameHack:QuarantineEntry(scrName, index)
	local q    = self.m_quarantine
	local set  = q[scrName] or {}
	set[index] = true
	q[scrName] = set
end

---@public
function MiniGameHack:OnCall()
	if (self.m_is_busy or self.m_is_disabled) then
		return
	end

	if (not Game.IsOnline()) then
		return
	end

	self.m_is_busy = true
	ThreadManager:Run(function(s)
		local main      = mghData.main_locals
		local bs_l      = mghData.bs_locals
		local found_scr = false

		for scr, t in pairs(main) do
			if (not isScriptActive(scr)) then
				goto continue
			end

			found_scr = true
			for i, v in ipairs(t) do
				if (self:IsEntryInQuarantine(scr, i)) then
					goto skip
				end

				local scrLocal = SGSL:Get(sgslData[v.sgsl_entry]):AsLocal()
				local ok, err = pcall(v.callback, scrLocal, s)
				if (not ok) then
					log.fwarning("[MiniGameHack]: An error occured. This miningame will be skipped next time. Error: %s", err)
					self:QuarantineEntry(scr, i)
				end
				::skip::
			end

			::continue::
		end

		for scr, t in pairs(bs_l) do
			if (not isScriptActive(scr)) then
				goto continue
			end

			found_scr = true
			for _, v in ipairs(t) do
				local scrLocal   = SGSL:Get(sgslData[v.sgsl_entry]):AsLocal()
				local offset_sum = math.sum(v.offsets)
				if (offset_sum > 0) then
					scrLocal = scrLocal:At(offset_sum)
				end

				scrLocal:SetBits(v.bits)
			end

			::continue::
		end

		self.m_tmp_v2_g:SetBits({ 9, 18, 26 })
		self.m_is_busy = false

		if (not found_scr) then
			Notifier:ShowWarning("MiniGameHack", _T("YH_MGH_NONE_FOUND_WARN"))
		end
	end)
end

local singleInstance <const> = MiniGameHack:init()
return singleInstance
