-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--[[
	// Summary:

	- An instance must be tied to exactly one action type (see eActionType). It must never change during the lifetime of the object.

	- This browser allows mode changing so that the same instance can be used to draw different "modes". This means we can reuse the same nstance to draw "main" player,
	"favorites", "history", etc. but does not mean we can change for example an animation browser instance to draw scenarios.

	- As long as the mode name doesn't change (see ActionBrowserMode), this browser draws the same exact items anywhere its called. This also means that we shouldn't
	draw the same browser in the same window because that would just be a mirror that serves no purpose.

	- When switching modes, the browser will attempt to restore search buffer, filters, selected item, and item context logic fron previous view state so if the user for
	example filters the main animation list by the "Looped" type then switches to the favorites tab and filters the anim list there by category and types something in the
	searchbae then switches back and fourth between the two tabs, all changes made in each view will be restored accordingly.
	
	- Although this browser allows hot swapping data, m_items must never be mutated after being set (see AssetBrowserBase).
]]


local AssetBrowserBase          = require("includes.services.asset_browsers.AssetBrowserBase")
local RawDataService            = require("includes.services.RawDataService")
local Action                    = require("includes.structs.Action")
local AnimCategories <const>    = {
	"All",
	"Actions",
	"Activities",
	"Gestures",
	"In-Vehicle",
	"Movements",
	"MISC",
	"NSFW",
}

local AnimTypes <const>         = {
	"All",
	"Looped",
	"Full Body",
	"Has Props",
	"Has PTFX",
	"Has SFX",
}

---@type table<string, fun(v: AnimData): boolean>
local AnimTypeResolvers <const> = {
	["All"]       = function(_) return true end,
	["Looped"]    = function(v) return Bit.IsBitSet(v.flags, Enums.eAnimFlags.LOOPING) end,
	["Full Body"] = function(v) return not Bit.IsBitSet(v.flags, Enums.eAnimFlags.UPPERBODY) end,
	["Has PTFX"]  = function(v) return v.ptfx ~= nil and next(v.ptfx) ~= nil end,
	["Has SFX"]   = function(v) return v.sfx ~= nil and next(v.sfx) ~= nil end,
	["Has Props"] = function(v)
		if (not v.props or not v.propPeds) then return false end
		return next(v.props) ~= nil or next(v.propPeds) ~= nil
	end,
}

---@param array array<ActionData>
local function sort_data_array(array)
	table.sort(array, function(a, b)
		if (a.Name and b.Name) then
			return a.Name < b.Name
		end

		return a.label < b.label
	end)
end

---@alias ActionBrowserMode
---| "main"
---| "favorites"
---| "history"
---| "other"

---@class ActionBrowserParams : BrowserBaseParams
---@field show_category_filters? boolean
---@field show_type_filters? boolean
---@field filter_combo_width? float
---@field max_entries? integer
---@field browser_mode? ActionBrowserMode
---@field show_preview nil
-- -@field show_preview? boolean -- [TODO]

---@class ActionsBrowserSwitchModeParams
---@field mode_name ActionBrowserMode
---@field new_data? array<ActionData>|dict<ActionData>
---@field str_id? string

---@class ActionBrowserViewState
---@field search_buffer string
---@field selected_type string
---@field selected_category string
---@field selected_item? ActionData

--------------------------------------
-- ActionBrowser
--------------------------------------
-- A simple action browser UI class.
--
-- Draws all `YimActions` data sets inside an ImGui Listbox and provides search and filtering controls.
---@class ActionBrowser : AssetBrowserBase
---@field private m_items? array<ActionData>|dict<ActionData>
---@field private m_items_ready boolean
---@field private m_selected_item? ActionData
---@field private m_search_buffer string
---@field private m_require_path string
---@field private m_mode { name: ActionBrowserMode, can_add_favorite: boolean, can_remove_favorite: boolean, can_remove_command: boolean, can_add_command: boolean, show_commands: boolean }
---@field private m_category_name ActionCategory
---@field private m_type eActionType
---@field private m_wants_category_filters boolean
---@field private m_selected_category string
---@field private m_selected_type string
---@field private m_wants_type_filters boolean
---@field private m_clicked boolean
---@field private m_filter_combo_width float
---@field private m_name_resolver fun(v: ActionData): string
---@field private m_str_id? string
---@field private m_should_update_scroll_y? boolean
---@field private m_view_state table<ActionBrowserMode, ActionBrowserViewState>
---@field public GetSelectedItem fun(self: ActionBrowser): ActionData
---@field GetModelFromIterable nil
local ActionBrowser <const> = setmetatable({}, AssetBrowserBase)
ActionBrowser.__index       = ActionBrowser

---@param actionType eActionType
---@param opts? ActionBrowserParams
---@return ActionBrowser
function ActionBrowser.new(actionType, opts)
	opts                  = opts or {}
	opts.has_context_menu = true
	local isAnim          = actionType == Enums.eActionType.ANIM
	local base            = AssetBrowserBase.new(opts)
	local instance        = setmetatable(base, ActionBrowser)
	local basePath        = "includes.data.actions"
	local defaultPath     = basePath .. ".animations"

	Switch(actionType) {
		---@diagnostic disable
		[Enums.eActionType.ANIM]     = function()
			instance.m_require_path  = defaultPath
			instance.m_category_name = "anims"
		end,
		[Enums.eActionType.CLIPSET]  = function()
			instance.m_require_path  = basePath .. ".movement_clipsets"
			instance.m_category_name = "clipsets"
		end,
		[Enums.eActionType.SCENARIO] = function()
			instance.m_require_path  = basePath .. ".scenarios"
			instance.m_category_name = "scenarios"
		end,
		[Enums.eActionType.SCENE]    = function()
			instance.m_require_path  = basePath .. ".synchronized_scenes"
			instance.m_category_name = "scenes"
		end,
		default                      = function()
			instance.m_require_path  = defaultPath
			instance.m_category_name = "anims"
		end
		---@diagnostic enable
	}

	instance.m_type                   = actionType
	instance.m_selected_category      = "All"
	instance.m_selected_type          = "All"
	instance.m_wants_category_filters = (isAnim and opts.show_category_filters) or false
	instance.m_wants_type_filters     = (isAnim and opts.show_type_filters) or false
	instance.m_filter_combo_width     = opts.filter_combo_width or 144.0
	instance.m_clicked                = false
	instance.m_name_resolver          = (actionType == Enums.eActionType.CLIPSET)
		and function(v) return v.Name end
		or function(v) return v.label end


	local modeName        = opts.browser_mode or "main"
	local isMainMode      = modeName == "main"
	local isClipset       = actionType == Enums.eActionType.CLIPSET
	instance.m_mode       = {
		name                = modeName,
		show_commands       = isMainMode,
		can_add_favorite    = isMainMode,
		can_remove_favorite = isMainMode,
		can_add_command     = isMainMode and not isClipset,
		can_remove_command  = isMainMode and not isClipset,
	}
	instance.m_view_state = {
		[modeName] = {
			search_buffer     = "",
			selected_category = "All",
			selected_type     = "All",
			selected_item     = nil
		}
	}

	---@diagnostic disable-next-line
	return instance
end

---@private
---@param curr_mode_name string
---@param curr_item ActionData?
function ActionBrowser:CaptureViewState(curr_mode_name, curr_item)
	local prev_state                  = self.m_view_state[curr_mode_name] or {}
	prev_state.search_buffer          = self.m_search_buffer
	prev_state.selected_category      = self.m_selected_category
	prev_state.selected_type          = self.m_selected_type
	prev_state.selected_item          = curr_item
	self.m_view_state[curr_mode_name] = prev_state
end

---@private
---@param mode_name string
function ActionBrowser:AppendViewState(mode_name)
	local new_state = self.m_view_state[mode_name]
	if (not new_state) then
		new_state = {
			search_buffer     = "",
			selected_category = "All",
			selected_type     = "All",
			selected_item     = nil
		}
	end
	self.m_view_state[mode_name] = new_state
	self.m_search_buffer         = new_state.search_buffer
	self.m_selected_category     = new_state.selected_category
	self.m_selected_type         = new_state.selected_type
	self.m_selected_item         = new_state.selected_item
end

---@param params ActionsBrowserSwitchModeParams
---@return ActionBrowser
function ActionBrowser:SwitchMode(params)
	local new_mode_name    = params.mode_name
	local new_data         = params.new_data
	local prev_mode        = self.m_mode
	local curr_mode_name   = prev_mode.name
	local prev_item        = self.m_selected_item
	local reset_view_state = false

	if (new_mode_name ~= curr_mode_name) then
		prev_mode.name                = new_mode_name
		local cond                    = (new_mode_name == "main" or new_mode_name == "other")
		prev_mode.show_commands       = cond
		prev_mode.can_add_favorite    = cond
		prev_mode.can_add_command     = cond
		prev_mode.can_remove_command  = cond
		prev_mode.can_remove_favorite = cond or (new_mode_name == "favorites")
		reset_view_state              = true
	end

	if (new_data and self.m_items ~= new_data) then
		self.m_items_ready   = false
		self.m_selected_item = nil
		self.m_is_array      = table.is_array(new_data)
		self.m_items         = new_data
		self.m_items_ready   = true
		reset_view_state     = true
	end

	if (params.str_id and params.str_id ~= self.m_str_id) then
		self.m_str_id                 = params.str_id
		self.m_should_update_scroll_y = true
		reset_view_state              = true
	end

	if (reset_view_state) then
		self:CaptureViewState(curr_mode_name, prev_item)
		self:AppendViewState(new_mode_name)
	end

	return self
end

---@param str_id? string
---@return ActionBrowser
function ActionBrowser:ResetMode(str_id)
	local current_mode = self.m_mode
	if (current_mode.name ~= "main") then
		self:CaptureViewState(current_mode.name, self.m_selected_item)

		local isClipset                  = self.m_type == Enums.eActionType.CLIPSET
		self.m_items_ready               = false
		current_mode.name                = "main"
		current_mode.show_commands       = true
		current_mode.can_add_favorite    = true
		current_mode.can_remove_favorite = true
		current_mode.can_add_command     = not isClipset
		current_mode.can_remove_command  = not isClipset
		self.m_items                     = nil

		self:AppendViewState("main")
	end

	if (str_id and str_id ~= self.m_str_id) then
		self.m_str_id                 = str_id
		self.m_should_update_scroll_y = true
	end

	return self
end

---@private
---@param v ActionData
---@return string
function ActionBrowser:GetNameFromIterable(_, v)
	return self.m_name_resolver(v)
end

---@private
---@param v AnimData
---@return boolean
function ActionBrowser:FilterByCategory(v)
	if (not self.m_wants_category_filters or self.m_selected_category == "All") then
		return true
	end

	return v.category == self.m_selected_category
end

---@private
---@param v AnimData
---@return boolean
function ActionBrowser:FilterByType(v)
	if (not self.m_wants_type_filters) then
		return true
	end

	local resolver = AnimTypeResolvers[self.m_selected_type]
	if (not resolver) then return false end

	return resolver(v)
end

---@private
---@param v AnimData
function ActionBrowser:TryFilters(_, v)
	return self:FilterByCategory(v) and self:FilterByType(v)
end

---@private
function ActionBrowser:DrawCategoryFilter()
	if (not self.m_wants_category_filters) then
		return
	end

	local selected = self.m_selected_category
	local preview  = selected == "All" and "Category" or selected
	ImGui.SetNextItemWidth(self.m_filter_combo_width)
	if (ImGui.BeginCombo("##categoryCombo", preview)) then
		for _, v in ipairs(AnimCategories) do
			if (ImGui.Selectable(v, (v == self.m_selected_category))) then
				self.m_selected_category = v
			end
		end
		ImGui.EndCombo()
	end
end

---@private
function ActionBrowser:DrawTypeFilter()
	if (not self.m_wants_type_filters) then
		return
	end

	local comboWidth = self.m_filter_combo_width
	if (self.m_wants_category_filters) then
		ImGui.SameLineIfAvail(comboWidth)
	end

	local selected = self.m_selected_type
	local preview  = selected == "All" and "Type" or selected
	ImGui.SetNextItemWidth(comboWidth)
	if (ImGui.BeginCombo("##typeCombo", preview)) then
		for _, v in ipairs(AnimTypes) do
			if (ImGui.Selectable(v, (v == self.m_selected_type))) then
				self.m_selected_type = v
			end
		end
		ImGui.EndCombo()
	end
end

---@private
function ActionBrowser:DrawFilters()
	self:DrawCategoryFilter()
	self:DrawTypeFilter()
end

---@private
---@param k string|integer
---@param v ActionData
function ActionBrowser:DrawItemContext(k, v)
	if (self.m_type == Enums.eActionType.UNK) then return end

	local context_label = "##context_" .. k
	if (ImGui.IsItemHovered() and ImGui.IsItemClicked(1)) then
		GUI:PlaySound("Click")
		ImGui.OpenPopup(context_label)
	end

	local current_label = self.m_name_resolver(v)
	local current_cat   = self.m_category_name
	local current_mode  = self.m_mode
	local is_favorite   = YimActions:DoesFavoriteExist(current_cat, current_label)
	-- local is_user_gen   = current_cat == "anims" and (Backend.debug_mode and YimActions:GetUGA()[current_label] ~= nil) or false -- TODO: Add an option to create new anim defs
	local has_command   = YimActions.Commands[current_label] ~= nil
	local indicators    = ""

	if (is_favorite and current_mode.name ~= "favorites") then
		indicators = indicators .. "[*] "
	end

	if (has_command) then
		indicators = indicators .. "[C] "
	end

	-- if (is_user_gen) then
	-- 	indicators = indicators .. "[U] "
	-- end

	local avail     = ImGui.GetContentRegionAvail()
	local textWidth = ImGui.CalcTextSize(indicators)
	ImGui.SameLine(avail - textWidth)
	ImGui.TextDisabled(indicators)

	if (ImGui.BeginPopup(context_label)) then
		if (is_favorite) then
			if (current_mode.can_remove_favorite and ImGui.MenuItem("Remove From Favorites")) then
				GUI:PlaySound("Click")
				YimActions:RemoveFromFavorites(current_cat, current_label)
			end
		else
			if (current_mode.can_add_favorite and ImGui.MenuItem("Add To Favorites")) then
				GUI:PlaySound("Click")
				YimActions:AddToFavorites(current_cat, current_label, v, self.m_type)
			end
		end

		if (self.m_type ~= Enums.eActionType.CLIPSET) then
			if (has_command) then
				if (current_mode.can_remove_command and ImGui.MenuItem("Remove Command")) then
					GUI:PlaySound("Click")
					YimActions:RemoveCommandAction(current_label)
				end
			else
				if (current_mode.can_add_command and ImGui.MenuItem("Create Command")) then
					GUI:PlaySound("Click")
					YimActions.DrawNewCommandWindow = true
				end
			end
		end

		ImGui.EndPopup()
	end
end

---@param region? vec2
---@return Action? selectedAction, boolean clicked
function ActionBrowser:Draw(region)
	if (self.m_type == Enums.eActionType.UNK) then -- should never happen
		return nil, false
	end

	if (not self.m_items_ready) then
		local err = RawDataService:GetPathError(self.m_require_path)
		if (err and not self.m_on_load_error) then
			-- AssetBrowserBase draws this inside the listbox to make it clear that
			-- this is a listbox but something went wrong when fetching data
			self.m_on_load_error = function()
				GUI:Text(err, { color = Color.RED })
			end
			return nil, false
		end
	end

	if (not self.m_items) then
		self.m_items, self.m_items_ready = RawDataService:BaseRequire(self.m_require_path, sort_data_array)
	end

	local __t, clicked = self:__DrawImpl(region or vec2:zero())
	if (not __t) then
		return nil, false
	end

	return Action.new(__t, self.m_type), clicked
end

return ActionBrowser
