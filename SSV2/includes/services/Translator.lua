-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local en_loaded, en = pcall(require, "lib.translations.en-US")
local locales_loaded, t = pcall(require, "lib.translations.__locales")

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
Translator = {}
Translator.__index = Translator
Translator.default_labels = en_loaded and en or {}
Translator.m_last_load_time = TimePoint.new()
Translator.m_cache = {}
Translator.locales = locales_loaded and t or { { name = "English", iso = "en-US" } }

function Translator:Load()
	local iso = GVars.backend.language_code or "en-US"
	local ok, res         -- fwd decl

	if (iso ~= "en-US") then -- skip already loaded default
		local path = _F("lib.translations.%s", iso)
		ok, res = pcall(require, path)
	end

	self.labels = (ok and (type(res) == "table")) and res or self.default_labels
	self.lang_code = iso
	self.m_log_history = {}
	self.m_last_load_time:reset()
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
	if (not self.m_last_load_time:has_elapsed(3e3)) then
		return
	end

	-- We can't even unload files because package is fully disabled. loadfile? in your dreams... 🥲
	self:Load()
	Notifier:ShowMessage("Translator", "Reloaded.")
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
