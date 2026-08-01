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
local GameLangToIndex <const>   = {
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
local eTranslatorState <const> = {
	NONE      = 0,
	RUNNING   = 1,
	RELOADING = 2,
	DISABLED  = 3
}; Enums.eTranslatorState = eTranslatorState


--------------------------------------
-- Class: Translator
--------------------------------------
---@class Translator
---@field private m_labels dict<string>
---@field private m_bad_labels dict<string>
---@field private m_default_labels dict<string>
---@field private m_lang_idx integer
---@field private m_locales array<string>
---@field private m_log_history set<string>
---@field private m_cache table<integer, table<string, string>>
---@field private m_last_load_time TimePoint
---@field private m_state eTranslatorState
---@field private m_deferred_gxt_batches array<table<GXT>> -- A container of references to GXT arrays and/or dicts to be mutated in place.
---@field private m_deferred_gxt_labels array<GXT> -- A container of references to GXT arrays and dicts to be mutated in place.
---@field private m_initialized boolean
---@field public wants_reload boolean
local Translator   = { gxt_labels = require("includes.lib.translations.__gxt_labels") }
Translator.__index = Translator

---@return Translator
function Translator:init()
	if (self.m_initialized) then return self end
	if (_G.Translator) then return _G.Translator end


	self.m_default_labels       = en_loaded and en or {}
	self.m_locales              = locales_loaded and __locales or { "en-US" }
	self.m_labels               = {}
	self.m_bad_labels           = {}
	self.m_cache                = {}
	self.m_log_history          = {}
	self.m_deferred_gxt_batches = {}
	self.m_deferred_gxt_labels  = {}
	self.m_state                = eTranslatorState.NONE
	self.m_last_load_time       = TimePoint()
	self.m_initialized          = true

	return self
end

---@private
---@return boolean
function Translator:MatchGameLanguage()
	local current = LOCALIZATION.GET_CURRENT_LANGUAGE()
	local idx     = GameLangToIndex[current] or 1
	if (self.m_locales[idx]) then
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
		local cfg          = GVars.backend

		if (cfg.use_game_language) then
			if (not self:MatchGameLanguage() and self:IsReloading()) then
				Notifier:ShowError("Translator", "Failed to match game language. Falling back to English (US).")
				cfg.use_game_language = false
				cfg.language_index    = 1
			end
		end

		local idx = cfg.language_index
		if (debugBreak and Backend.is_debug) then
			idx = 69
		end

		local iso = self.m_locales[idx]
		local ok, result
		if (iso and iso ~= "en-US") then
			local path = "lib.translations." .. iso
			ok, result = pcall(require, path)
			if (not ok) then
				log.warning("[Translator]: Failed to load translations file! Falling back to English (US).")
				cfg.language_index = 1
			end
		end

		result = result or self.m_default_labels
		if (iso == nil or next(result) == nil) then
			log.warning("[Translator]: Failed to load! Translations will be disabled.")
			self.m_state = eTranslatorState.DISABLED
		else
			table.overwrite(self.m_labels, result)
			self.m_state = eTranslatorState.RUNNING
		end

		self.m_lang_idx = idx
		self.m_last_load_time:Reset()
		self:FlushGXTQueue()
	end)
end

---@public
---@param debugBreak? boolean
function Translator:Reload(debugBreak)
	if (not self.m_initialized or not self.m_last_load_time:HasElapsed(3e3)) then
		return
	end

	self.m_state = eTranslatorState.RELOADING
	self:Load(debugBreak)
end

---@public
---@return boolean
function Translator:IsReady()
	return self.m_initialized and self.m_state == eTranslatorState.RUNNING
end

---@public
---@return boolean
function Translator:IsDisabled()
	return self.m_state == eTranslatorState.DISABLED
end

---@public
---@return boolean
function Translator:IsReloading()
	return self.m_state == eTranslatorState.RELOADING
end

---@public
---@return boolean
function Translator:CanReload()
	return not self:IsReloading() and self.m_last_load_time:HasElapsed(3e3)
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
---@return string?
function Translator:GetCachedLabel(label)
	if (self:IsDisabled()) then return end

	local langIndex         = self.m_lang_idx
	self.m_cache[langIndex] = self.m_cache[langIndex] or {}
	return self.m_cache[langIndex][label]
end

---@private
---@param label string
---@param text string
function Translator:CacheLabel(label, text)
	if (self:IsDisabled()) then return end

	local cache = self.m_cache
	local idx   = self.m_lang_idx
	local ref   = cache[idx] or {}
	ref[label]  = text
	cache[idx]  = ref
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

---@public
---@return array<string>
function Translator:GetLocales()
	return self.m_locales
end

-- Translates text to the user's language. This performs an O(1) lookup and caches results as well
--
-- so it's almost free *(except some sanity checks)* to call inside your UI loop.
---@public
---@param label string
---@param ... any optional string formatting
---@return string
function Translator:Translate(label, ...)
	if (not self:IsReady()) then
		return label
	end

	if (self.m_lang_idx ~= GVars.backend.language_index) then
		self.wants_reload = self.wants_reload or true
		return label
	end

	local bad_labels = self.m_bad_labels
	local junk = bad_labels[label]
	if (junk) then return junk end

	if (not string.isvalid(label)) then
		local msg = "[!MISSING LABEL] " .. label
		self:Warn(msg)
		bad_labels[label] = msg
		return msg
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

	local gxt = self.gxt_labels[label]
	if (gxt) then return gxt end -- no need to continue if it's a GXT; it's already tranlated and cached.

	local text = self.m_labels[label]
	if (not text) then
		self:Warn("Missing translation for label: " .. label)
		local msg = "[!MISSING TEXT] " .. label
		bad_labels[label] = msg
		return msg
	end

	self:CacheLabel(label, text)

	if (...) then
		return __fmt(text, ...)
	end
	return text
end

-- Translates a game label and stores it so it can be either directly indexed in the public [gxt_labels](lua://Translator.gxt_labels) class member
--
-- or passed to the [_T](lua://_T) macro. If the function is called early *(before Translator is ready)*, the label will be queued
--
-- then processed as soon as `Translator` loads.
---@param gxt GXT
---@return string
function Translator:TranslateGXT(gxt)
	if (not self:IsReady()) then
		table.insert(self.m_deferred_gxt_labels, gxt)
		return gxt
	end

	local s = Game.GetLabelText(gxt)
	self.gxt_labels[gxt] = s
	return s
end

-- Similar to [TranslateGXT](lua://Translator.TranslateGXT), this function instead takes a reference to an array
--
-- or a dictionnary of GXT labels and mutates it in place, allowing you to bulk-translate
--
-- all your labels once then directly index translated GXTs from your table.
---@param labels array<string>|dict<string>
function Translator:TranslateGXTList(labels)
	if (not self:IsReady()) then
		table.insert(self.m_deferred_gxt_batches, labels)
		return
	end

	for k, v in pairs(labels) do
		labels[k] = self:TranslateGXT(v)
	end
end

---@private
function Translator:FlushGXTQueue()
	for key in pairs(self.gxt_labels) do
		self.gxt_labels[key] = Game.GetLabelText(key)
	end

	for _, batch in ipairs(self.m_deferred_gxt_batches) do
		for k, v in pairs(batch) do
			local translated   = Game.GetLabelText(v)
			batch[k]           = translated
			self.gxt_labels[v] = translated
		end
	end

	for _, gxt in ipairs(self.m_deferred_gxt_labels) do
		self.gxt_labels[gxt] = Game.GetLabelText(gxt)
	end

	self.m_deferred_gxt_batches = {}
	self.m_deferred_gxt_labels  = {}
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
local __translate    = Translator.Translate
_G.Translator        = singleInstance

-- Macro for the [Translator:Translate](lua://Translator.Translate) method.
--
-- Translates text to the user's language. This performs an O(1) lookup and caches results as well
--
-- so it's almost free *(except some sanity checks)* to call inside your UI loop.
---@param label string
---@param ... any optional string formatting
---@return string
function _T(label, ...)
	return __translate(singleInstance, label, ...)
end

return singleInstance
