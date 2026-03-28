-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local en_loaded, en             = pcall(require, "lib.translations.en-US")
local locales_loaded, __locales = pcall(require, "lib.translations.__locales")
local GameLangToCustom <const>  = {
	[0]  = 1,
	[1]  = 2,
	[2]  = 3,
	[3]  = 5,
	[4]  = 4,
	[5]  = 6,
	[6]  = 11,
	[7]  = 7,
	[8]  = 12,
	[9]  = 8,
	[10] = 10,
	[11] = 4,
	[12] = 9,
}


--------------------------------------
-- Class: Translator
--------------------------------------
---@class Translator
---@field labels dict<string>
---@field default_labels dict<string>
---@field lang_idx integer
---@field locales array<string>
---@field wants_reload boolean
---@field private m_log_history set<string>
---@field private m_cache table<string, table<string, string>>
---@field private m_last_load_time TimePoint
---@field private m_reloading boolean
---@field private m_disabled boolean
---@field protected m_initialized boolean
local Translator   = {}
Translator.__index = Translator

---@return Translator
function Translator:init()
	if (self.m_initialized) then return self end
	if (_G.Translator) then return _G.Translator end

	return setmetatable({
		default_labels   = en_loaded and en or {},
		locales          = locales_loaded and __locales or { "en-US" },
		labels           = {},
		m_cache          = {},
		m_log_history    = {},
		m_last_load_time = TimePoint.new(),
		m_initialized    = false,
		m_reloading      = false,
	}, Translator)
end

---@return boolean
function Translator:MatchGameLanguage()
	local current = LOCALIZATION.GET_CURRENT_LANGUAGE()
	local idx     = GameLangToCustom[current] or 1
	if (self.locales[idx]) then
		GVars.backend.language_index = idx
		return true
	end

	return false
end

---@param debugBreak? boolean
function Translator:Load(debugBreak)
	ThreadManager:Run(function()
		if (GVars.backend.use_game_language) then
			if (not self:MatchGameLanguage() and self.m_reloading) then
				Notifier:ShowError("Translator", "Failed to match game language. Falling back to English (US).")
				GVars.backend.use_game_language = false
				GVars.backend.language_index    = 1
			end
		end

		if (debugBreak and Backend.debug_mode) then
			GVars.backend.language_index = 69
		end

		local idx = GVars.backend.language_index
		local iso = self.locales[idx]
		if (not iso) then
			log.warning("[Translator]: Invalid language code!")
		end

		local ok, result
		if (iso ~= "en-US") then
			local path = "lib.translations." .. iso
			ok, result = pcall(require, path)
			if (not ok) then
				log.warning("[Translator]: Failed to load translations file! Falling back to English (US).")
				GVars.backend.language_index = 1
			end
		end

		result = result or self.default_labels
		if (next(result) == nil) then
			log.warning("[Translator]: Failed to load! Translations will be disabled.")
			self.m_disabled = true
		end

		local newLabels = result
		table.overwrite(self.labels, newLabels)

		self.m_log_history = {}
		self.m_cache       = {}
		self.lang_idx      = GVars.backend.language_index
		self.m_initialized = true
		self.m_reloading   = false
		self.m_last_load_time:Reset()
	end)
end

---@private
---@param debugBreak? boolean
function Translator:Reload(debugBreak)
	if (not self.m_initialized or not self.m_last_load_time:HasElapsed(3e3)) then -- 3. we have this though so reload can not be called twice. I'm a bit confused
		return
	end

	self.m_disabled    = false
	self.m_initialized = false
	self.m_reloading   = true
	self:Load(debugBreak)
end

---@return boolean
function Translator:IsReady()
	return self.m_initialized and not self.m_reloading
end

---@return boolean
function Translator:IsReloading()
	return self.m_reloading
end

---@return boolean
function Translator:CanReload()
	return self:IsReady() and self.m_last_load_time:HasElapsed(3e3)
end

---@param message string
function Translator:Warn(message)
	if (self.m_log_history[message]) then
		return
	end

	log.warning(message)
	self.m_log_history[message] = true
end

---@return table<string, table<string, string>>
function Translator:GetCache()
	return self.m_cache
end

---@param label string
---@return string
function Translator:GetCachedLabel(label)
	if (self.m_disabled) then return "" end

	self.m_cache[self.lang_idx] = self.m_cache[self.lang_idx] or {}
	return self.m_cache[self.lang_idx][label]
end

---@param label string
---@param text string
function Translator:CacheLabel(label, text)
	if (self.m_disabled) then return end

	self.m_cache[self.lang_idx] = self.m_cache[self.lang_idx] or {}
	self.m_cache[self.lang_idx][label] = text
end

-- Translates text to the user's language.
---@param label string
---@return string
function Translator:Translate(label)
	if (self.m_disabled or not self:IsReady()) then
		return label
	end

	if (self.lang_idx ~= GVars.backend.language_index) then
		self.wants_reload = true
		return label
	end

	if (not label) then
		local msg = _F("Missing label! %s", label)
		self:Warn(msg)
		return msg
	end

	local cached = self:GetCachedLabel(label)
	if (cached) then return cached end

	local text = self.labels[label]
	if (not string.isvalid(text)) then
		self:Warn(_F("Missing translation for label: '%s'", label))
		return _F("[!MISSING TEXT] %s", label)
	end

	if (not cached) then self:CacheLabel(label, text) end

	return text
end

-- Translates text using GXTs if expected and available.
---@param label string
---@return string
function Translator:TranslateGXT(label)
	local GXT = Game.GetGXTLabel(label)
	if (string.isvalid(GXT) and GXT ~= "NULL") then
		return GXT             -- get label from the game.
	else
		return self:Translate(label) -- no GXT; use our own translations
	end
end

---@param labels array<string>
function Translator:TranslateGXTList(labels)
	for k, v in pairs(labels) do
		labels[k] = self:TranslateGXT(v)
	end
end

-- This is called in `Backend`'s main thread.
function Translator:OnTick()
	-- currently only handles reload requests.

	if (self.wants_reload and not self:IsReloading()) then
		self.wants_reload = false
		self:Reload()
	end
end

return Translator:init()
