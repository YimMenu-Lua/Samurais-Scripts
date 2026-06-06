-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local __fmt                     = string.format
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


---@enum eTranslatorState
Enums.eTranslatorState = {
	NONE      = 0,
	RUNNING   = 1,
	RELOADING = 2,
	DISABLED  = 3
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
---@field private m_cache table<integer, table<string, string>>
---@field private m_last_load_time TimePoint
---@field private m_state eTranslatorState
---@field private m_deferred_batches array<array<string>|dict<string>>
---@field private m_gxt_labels table<string, string>
---@field protected m_initialized boolean
local Translator   = {}
Translator.__index = Translator

---@return Translator
function Translator:init()
	if (self.m_initialized) then return self end
	if (_G.Translator) then return _G.Translator end

	return setmetatable({
		default_labels     = en_loaded and en or {},
		locales            = locales_loaded and __locales or { "en-US" },
		labels             = {},
		m_cache            = {},
		m_log_history      = {},
		m_deferred_batches = {},
		m_gxt_labels       = {},
		m_last_load_time   = TimePoint.new(),
		m_initialized      = true,
		m_state            = Enums.eTranslatorState.NONE
	}, Translator)
end

---@private
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

---@public
---@param debugBreak? boolean
function Translator:Load(debugBreak)
	ThreadManager:Run(function()
		self.m_log_history = {}
		self.m_cache       = {}

		if (GVars.backend.use_game_language) then
			if (not self:MatchGameLanguage() and self:IsReloading()) then
				Notifier:ShowError("Translator", "Failed to match game language. Falling back to English (US).")
				GVars.backend.use_game_language = false
				GVars.backend.language_index    = 1
			end
		end

		local idx = GVars.backend.language_index
		if (debugBreak and Backend.debug_mode) then
			idx = 69
		end

		local iso = self.locales[idx]
		local ok, result
		if (iso and iso ~= "en-US") then
			local path = "lib.translations." .. iso
			ok, result = pcall(require, path)
			if (not ok) then
				log.warning("[Translator]: Failed to load translations file! Falling back to English (US).")
				GVars.backend.language_index = 1
			end
		end

		result = result or self.default_labels
		if (iso == nil or next(result) == nil) then
			log.warning("[Translator]: Failed to load! Translations will be disabled.")
			self.m_state = Enums.eTranslatorState.DISABLED
		else
			table.overwrite(self.labels, result)
			self.m_state = Enums.eTranslatorState.RUNNING
		end

		self.lang_idx = idx
		self.m_last_load_time:Reset()
		self:OnPostLoad()
	end)
end

---@public
---@param debugBreak? boolean
function Translator:Reload(debugBreak)
	if (not self.m_initialized or not self.m_last_load_time:HasElapsed(3e3)) then
		return
	end

	self.m_state = Enums.eTranslatorState.RELOADING
	self:Load(debugBreak)
end

---@public
---@return boolean
function Translator:IsReady()
	return self.m_initialized and self.m_state == Enums.eTranslatorState.RUNNING
end

---@public
---@return boolean
function Translator:IsDisabled()
	return self.m_state == Enums.eTranslatorState.DISABLED
end

---@public
---@return boolean
function Translator:IsReloading()
	return self.m_state == Enums.eTranslatorState.RELOADING
end

---@public
---@return boolean
function Translator:CanReload()
	return self:IsReady() and self.m_last_load_time:HasElapsed(3e3)
end

---@private
---@param message string
function Translator:Warn(message)
	if (self.m_log_history[message]) then
		return
	end

	log.warning(message)
	self.m_log_history[message] = true
end

---@private
---@param label string
---@return string
function Translator:GetCachedLabel(label)
	if (self:IsDisabled()) then return "" end

	local langIndex = self.lang_idx
	self.m_cache[langIndex] = self.m_cache[langIndex] or {}
	return self.m_cache[langIndex][label]
end

---@private
---@param label string
---@param text string
function Translator:CacheLabel(label, text)
	if (self:IsDisabled()) then return end

	local langIndex = self.lang_idx
	local ref = self.m_cache[langIndex] or {}
	ref[label] = text
	self.m_cache[langIndex] = ref
end

---@public
---@return eTranslatorState
function Translator:GetState()
	return self.m_state
end

---@public
---@return table<integer, table<string, string>>
function Translator:GetCache()
	return self.m_cache
end

-- Translates text to the user's language.
---@public
---@param label string
---@param ... any optional string formatting
---@return string
function Translator:Translate(label, ...)
	if (not string.isvalid(label)) then
		local msg = __fmt("Missing label! %s", label)
		self:Warn(msg)
		return msg
	end

	if (not self:IsReady()) then
		return label
	end

	if (self.lang_idx ~= GVars.backend.language_index) then
		self.wants_reload = self.wants_reload or true
		return label
	end

	local cached = self:GetCachedLabel(label)
	if (cached) then
		if (...) then
			-- it would be better to cache the formatted text to
			-- avoid string formatting in UI loops but we have several
			-- instances where we're formatting a dynamic variable like
			-- a cooldown time or some other non-constant value.
			return __fmt(cached, ...)
		end
		return cached
	end

	local text = self.labels[label] or self.m_gxt_labels[label]
	if (not string.isvalid(text)) then
		self:Warn(__fmt("Missing translation for label: '%s'", label))
		return __fmt("[!MISSING TEXT] %s", label)
	end

	self:CacheLabel(label, text)

	if (...) then
		return __fmt(text, ...)
	end
	return text
end

---@param gxt string
---@return string
function Translator:TranslateGXT(gxt)
	if (not self:IsReady()) then
		table.insert(self.m_deferred_batches, { gxt })
		return "NULL"
	end

	local translated = Game.GetLabelText(gxt)
	self.m_gxt_labels[gxt] = translated
	return translated
end

---@param labels array<string>|dict<string>
function Translator:TranslateGXTList(labels)
	if (not self:IsReady()) then
		table.insert(self.m_deferred_batches, labels)
		return
	end

	for k, v in pairs(labels) do
		labels[k] = Game.GetLabelText(v)
	end
end

---@private
function Translator:OnPostLoad()
	for _, batch in ipairs(self.m_deferred_batches) do
		for k, v in pairs(batch) do
			local translated     = Game.GetLabelText(v)
			batch[k]             = translated
			self.m_gxt_labels[v] = translated
		end
	end

	self.m_deferred_batches = {}
end

-- This is called in `Backend`'s main thread.
function Translator:OnTick()
	-- currently only handles reload requests.
	if (self.wants_reload and not self:IsReloading()) then
		self.wants_reload = false
		self:Reload()
	end
end

local singleInstance = Translator:init()
_G.Translator        = singleInstance
return singleInstance
