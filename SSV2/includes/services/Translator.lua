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
---@field lang_code string
---@field locales array<{ name: string, iso: string }>
---@field wants_reload boolean
---@field private m_log_history table
---@field private m_cache table<string, table<string, string>>
---@field private m_last_load_time TimePoint
---@field private m_reloading boolean
---@field protected m_initialized boolean
local Translator   = {}
Translator.__index = Translator

---@return Translator
function Translator:init()
	if (self.m_initialized) then return self end
	if (_G.Translator) then return _G.Translator end

	return setmetatable({
		default_labels   = en_loaded and en or {},
		locales          = locales_loaded and __locales or { { name = "English", iso = "en-US" } },
		labels           = {},
		m_cache          = {},
		m_log_history    = {},
		m_last_load_time = TimePoint.new(),
		m_initialized    = false,
		m_reloading      = false,
	}, Translator)
end

function Translator:MatchGameLanguage()
	local current = LOCALIZATION.GET_CURRENT_LANGUAGE()
	local idx     = GameLangToCustom[current] or 1
	local match   = self.locales[idx]

	if (not match) then return false end

	GVars.backend.language_index = idx
	GVars.backend.language_code  = match.iso
	GVars.backend.language_name  = match.name

	return true
end

function Translator:Load()
	ThreadManager:Run(function()
		if (GVars.backend.use_game_language) then
			if (not self:MatchGameLanguage() and self.m_reloading) then
				Notifier:ShowError("Translator", "Failed to match game language.")
				GVars.backend.use_game_language = false
				return
			end
		end

		GVars.backend.language_index = GVars.backend.language_index or 1
		GVars.backend.language_code  = GVars.backend.language_code or "en-US"
		GVars.backend.language_name  = GVars.backend.language_name or "English"

		local ok, res
		if (GVars.backend.language_code ~= "en-US") then
			local path = "lib.translations." .. GVars.backend.language_code
			ok, res = pcall(require, path)
		end

		local newLabels = (ok and (type(res) == "table")) and res or self.default_labels
		table.overwrite(self.labels, newLabels)

		self.m_log_history = {}
		self.m_cache       = {}
		self.lang_code     = GVars.backend.language_code
		self.m_initialized = true
		self.m_reloading   = false
		self.m_last_load_time:Reset()
	end)
end

---@private
function Translator:Reload()
	if (not self.m_initialized or not self.m_last_load_time:HasElapsed(3e3)) then -- 3. we have this though so reload can not be called twice. I'm a bit confused
		return
	end

	self.m_initialized = false
	self.m_reloading   = true
	self:Load()
	Notifier:ShowMessage("Translator", "Reloaded.")
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

---@return table<string, table<string, string>>
function Translator:GetCache()
	return self.m_cache
end

---@param label string
---@return string
function Translator:GetCachedLabel(label)
	self.m_cache[self.lang_code] = self.m_cache[self.lang_code] or {}
	return self.m_cache[self.lang_code][label]
end

---@param label string
---@param text string
function Translator:CacheLabel(label, text)
	self.m_cache[self.lang_code] = self.m_cache[self.lang_code] or {}
	self.m_cache[self.lang_code][label] = text
end

-- Translates text to the user's language.
---@param label string
---@return string
function Translator:Translate(label)
	if (not self:IsReady()) then return "" end

	if (self.lang_code ~= GVars.backend.language_code) then
		self.wants_reload = true
		return ""
	end

	local cached = self:GetCachedLabel(label)
	if (cached) then return cached end

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
