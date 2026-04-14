-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local AssetBrowserBase = require("includes.services.asset_browsers.AssetBrowserBase")

---@class ObjectBrowserParams : BrowserBaseParams
---@field max_entries? integer
---@field filter_combo_width? float
---@field show_blacklist_filters? boolean
---@field show_mp_only_filters? boolean
---@field show_preview? boolean


---@class ObjectBrowser : AssetBrowserBase
---@field private m_items array<string>?
---@field private m_selected_item string?
---@field private m_blacklisted_objects set<string> -- TODO
---@field private m_mp_only_objects set<string> -- TODO
---@field private m_wants_blacklist_filters boolean
---@field private m_wants_mp_filters boolean
---@field private m_filter_combo_width float
local ObjectBrowser <const> = setmetatable({}, AssetBrowserBase)
ObjectBrowser.__index       = ObjectBrowser

---@param opts? ObjectBrowserParams
---@return ObjectBrowser
function ObjectBrowser.new(opts)
	opts           = opts or {}
	local base     = AssetBrowserBase.new(opts)
	local instance = setmetatable(base, ObjectBrowser)


	instance.m_wants_mp_filters        = opts.show_mp_only_filters or false
	instance.m_filter_combo_width      = opts.filter_combo_width or 144.0
	instance.m_wants_blacklist_filters = opts.show_blacklist_filters or false

	---@diagnostic disable-next-line
	return instance
end

--#region overloads

---@override
---@param v string
---@return joaat_t
function ObjectBrowser:GetModelFromIterable(_, v)
	return _J(v)
end

---@override
---@param v string
---@return string
function ObjectBrowser:GetNameFromIterable(_, v)
	return v
end

--#endregion

---@param region? vec2
---@return string? selectedObject, boolean clicked
function ObjectBrowser:Draw(region)
	if (not self.m_items) then
		self.m_items = require("includes.data.objects")
	end

	return self:__DrawImpl(region)
end

return ObjectBrowser
