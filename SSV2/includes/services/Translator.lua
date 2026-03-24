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
--**Global Singleton.**
---@class Translator
---@field labels table<string, string>
---@field lang_code string
---@field private m_log_history table
---@field private m_cache table<string, table<string, string>>
---@field private m_last_load_time TimePoint
---@field protected m_initialized boolean
Translator         = {
	default_labels   = en_loaded and en or {},
	m_last_load_time = TimePoint.new(),
	m_cache          = {},
	locales          = locales_loaded and __locales or { { name = "English", iso = "en-US" } },
	m_initialized    = false
}
Translator.__index = Translator

function Translator:MatchGameLanguage()
	self.m_last_game_lang_idx = LOCALIZATION.GET_CURRENT_LANGUAGE()
	local idx                 = GameLangToCustom[self.m_last_game_lang_idx] or 1
	local match               = self.locales[idx]
	if (not match) then
		return false
	end

	GVars.backend.language_index = idx
	GVars.backend.language_code  = match.iso
	GVars.backend.language_name  = match.name
	return true
end

function Translator:Load()
	ThreadManager:Run(function()
		if (GVars.backend.use_game_language) then
			self:MatchGameLanguage()
		end

		GVars.backend.language_code = GVars.backend.language_code or "en-US"
		local iso = GVars.backend.language_code
		local ok, res

		if (iso ~= "en-US") then
			local path = _F("lib.translations.%s", iso)
			ok, res = pcall(require, path)
		end

		self.labels        = (ok and (type(res) == "table")) and res or self.default_labels
		self.lang_code     = iso
		self.m_log_history = {}
		self.m_initialized = true
		self.m_last_load_time:Reset()
	end)
end

---@param msg string
---@return boolean
function Translator:WasLogged(msg)
	if (#self.m_log_history == 0) then
		return false
	end

	return table.find(self.m_log_history, msg)
end

function Translator:Log(message)
	if self:WasLogged(message) then
		return
	end

	log.warning(message)
	table.insert(self.m_log_history, message)
end

function Translator:Reload()
	if (not self.m_initialized or not self.m_last_load_time:HasElapsed(3e3)) then
		return
	end

	-- We can't even unload files because package is fully disabled. loadfile? in your dreams... 🥲
	self.m_initialized = false
	self:Load()
	Notifier:ShowMessage("Translator", "Reloaded.")
end

function Translator:IsReady()
	return self.m_initialized
end

---@param label string
---@return string
function Translator:GetCache(label)
	self.m_cache[self.lang_code] = self.m_cache[self.lang_code] or {}
	return self.m_cache[self.lang_code][label]
end

---@param label string
---@param text string
function Translator:SetCache(label, text)
	self.m_cache[self.lang_code] = self.m_cache[self.lang_code] or {}
	self.m_cache[self.lang_code][label] = text
end

-- Translates text to the user's language.
---@param label string
---@return string
function Translator:Translate(label)
	if (self.lang_code ~= GVars.backend.language_code) then
		self:Reload()
		return ""
	end

	local cached = self:GetCache(label)
	if (cached) then
		return cached
	end

	local text = self.labels[label]
	if (not text) then
		local msg = _F("Missing label! %s", label)
		self:Log(msg)
		return msg
	end

	if (not string.isvalid(text)) then
		self:Log(_F("Missing translation for: '%s' in '%s'", label, self.lang_code))
		return _F("[!MISSING LABEL]: %s", label)
	end

	if (not cached) then
		self:SetCache(label, text)
	end

	return text
end

-- Wrapper for `Translator:Translate`
---@param label string
---@return string
function _T(label)
	return Translator:Translate(label)
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
