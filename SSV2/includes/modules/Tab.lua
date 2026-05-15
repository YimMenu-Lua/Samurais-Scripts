-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local GridRenderer = require("includes.services.GridRenderer")

---@class BoolCommandParams
---@field gvar_key string -- A key to insert into GVars (global variables)
---@field on_enable? function
---@field on_disable? function
---@field meta? CommandMeta
---@field registerCommand? boolean -- register with CommandExecutor
---@field isTranslatorLabel? boolean If you want to pass a translator key as the label, provide it as is without the `_T` function and set this to true.
---@field global_table? table a table where the global variable lives (defaults to GVars if available or _G)
---@field fineTuning? { callback: function, condition: boolean|fun(): boolean } -- adds a fine tuning button to the command's widget

---@class LoopedCommandParams : BoolCommandParams
---@field callback function

--------------------------------------
-- Tab Struct
--------------------------------------
---@ignore
---@class Tab : ClassMeta<Tab>
---@field private m_name string
---@field private m_id joaat_t
---@field private m_selected_tab_name string
---@field private m_callback? GuiCallback
---@field private m_subtabs? table<string, Tab>
---@field private m_grid_layout? GridRenderer
---@field private m_has_error boolean
---@field private m_traceback string
---@field public m_has_translator_label boolean
---@overload fun(name: string, drawable?: GuiCallback, subtabs?: Tab, isTranslatorLabel?: boolean) : Tab
local Tab = Class("Tab")

---@param name string
---@param drawable? GuiCallback
---@param subtabs? Tab[]
---@param isTranslatorLabel? boolean If you want to pass a translator key as the label, provide it as is without the `_T` function and set this to true.
---@return Tab
function Tab.new(name, drawable, subtabs, isTranslatorLabel)
	return setmetatable(
		{
			m_name                 = name,
			m_id                   = joaat(name),
			m_callback             = drawable,
			m_subtabs              = subtabs or {},
			m_has_error            = false,
			m_has_translator_label = isTranslatorLabel or false
		},
		---@diagnostic disable-next-line
		Tab
	)
end

---@param name string
---@param drawable? GuiCallback
---@param subtabs? Tab[]
---@param isTranslatorLabel? boolean If you want to pass a translator key as the label, provide it as is without the `_T` function and set this to true.
---@return Tab
function Tab:RegisterSubtab(name, drawable, subtabs, isTranslatorLabel)
	assert((type(name) == "string" and #name > 0),
		"Attempt to register a new tab with no name."
	)

	local subtab = Tab(name, drawable, subtabs, isTranslatorLabel)
	self.m_subtabs[name] = subtab
	return subtab
end

---@param drawable GuiCallback
function Tab:RegisterGUI(drawable)
	if (type(drawable) ~= "function") then
		return
	end

	if (self:HasGUI()) then
		log.fwarning("Tab %s already had a GUI callback. Did you mean to overwrite it?", self:GetName())
	end

	self.m_callback = drawable
end

---@return boolean
function Tab:HasGUI()
	return (type(self.m_callback) == "function")
end

---@return boolean
function Tab:HasSubtabs()
	return next(self.m_subtabs) ~= nil
end

---@return boolean
function Tab:HasGridLayout()
	return self.m_grid_layout ~= nil
end

---@return number
function Tab:GetTabCount()
	return table.getlen(self.m_subtabs)
end

---@param name string
---@return Tab?
function Tab:GetSubtab(name)
	return self.m_subtabs[name]
end

---@return string
function Tab:GetName()
	return self.m_has_translator_label and _T(self.m_name) or self.m_name
end

---@return joaat_t
function Tab:GetID()
	if (not self.m_id) then
		self.m_id = joaat(self.m_name)
	end

	return self.m_id
end

---@return GuiCallback
function Tab:GetGUICallback()
	return self.m_callback
end

---@return table<string, Tab>
function Tab:GetSubtabs()
	return self.m_subtabs
end

---@return GridRenderer|nil
function Tab:GetGridRenderer()
	return self.m_grid_layout
end

---@param columns? number
---@param padding_x? number
---@param padding_y? number
---@return GridRenderer
function Tab:GetOrCreateGrid(columns, padding_x, padding_y)
	if (not self.m_grid_layout) then
		local spacing = ImGui.GetStyle().ItemSpacing
		self.m_grid_layout = GridRenderer.new(
			columns or 1,
			padding_x or spacing.x,
			padding_y or spacing.y
		)
	end

	return self.m_grid_layout
end

function Tab:RemoveGrid()
	self.m_grid_layout = nil
end

function Tab:RemoveGUI()
	self.m_callback = nil
end

---@param label string
---@param opts BoolCommandParams
function Tab:AddBoolCommand(label, opts)
	opts           = opts or {}
	local gvar_key = opts.gvar_key
	local g_table  = opts.global_table or GVars or _G
	if (type(label) ~= "string" or type(gvar_key) ~= "string") then
		error(_F("[%s]: AddBoolCommand requires a label and global variable key string.", label))
	end

	local function onClick(value)
		if (type(value) ~= "boolean") then
			return
		end

		local onEnable, onDisable = opts.on_enable, opts.on_disable
		if (value and type(onEnable) == "function") then
			onEnable()
		elseif (not value and type(onDisable) == "function") then
			onDisable()
		end
	end

	local meta = opts.meta or {}
	self:GetOrCreateGrid():AddCheckbox(
		label,
		gvar_key,
		{
			persistent        = true,
			tooltip           = meta.description,
			isTranslatorLabel = opts.isTranslatorLabel,
			fineTuning        = opts.fineTuning,
			onClick           = function()
				local v = table.get_nested_key(g_table, gvar_key)
				onClick(v)
			end,
		}
	)

	if not (opts.registerCommand and CommandExecutor and type(table.get_nested_key(g_table, gvar_key)) == "boolean") then
		return
	end

	local command_name = label:lower():gsub("%s+", "_")
	CommandExecutor:RegisterCommand(command_name, function()
		local v = table.get_nested_key(g_table, gvar_key)
		v = not v
		table.set_nested_key(g_table, gvar_key, v)
		onClick(v)
		CommandExecutor:notify(
			"%s %s",
			label,
			v and "Enabled" or "Disabled"
		)
	end, meta)
end

---@param label string
---@param opts LoopedCommandParams
function Tab:AddLoopedCommand(label, opts)
	opts           = opts or {}
	local gvar_key = opts.gvar_key
	local g_table  = opts.global_table or GVars or _G
	if (type(label) ~= "string" or type(gvar_key) ~= "string") then
		error(_F("[%s] AddBoolCommand requires a label and global variable key string.", label))
	end

	local meta             = opts.meta or {}
	local command_name     = label:lower():gsub("%s+", ""):trim()
	local config_value     = table.get_nested_key(g_table, gvar_key)
	local suspended_thread = not config_value
	local thread           = ThreadManager:RegisterLooped(_F("SS_%s", command_name:upper()), opts.callback, suspended_thread)

	local function toggle()
		local v = table.get_nested_key(g_table, gvar_key)
		local onDisable = opts.on_disable
		if (table.get_nested_key(g_table, gvar_key)) then
			if thread then thread:Resume() end
		else
			if thread then thread:Suspend() end
			if onDisable then onDisable() end
		end

		if (not opts.registerCommand) then
			CommandExecutor:notify(
				"%s %s.",
				label,
				v and "Enabled" or "Disabled"
			)
		end
	end

	self:GetOrCreateGrid():AddCheckbox(
		label,
		gvar_key,
		{
			persistent        = true,
			tooltip           = meta.description,
			isTranslatorLabel = opts.isTranslatorLabel,
			onClick           = toggle,
			fineTuning        = opts.fineTuning
		}
	)

	if not (opts.registerCommand and CommandExecutor and type(table.get_nested_key(g_table, gvar_key)) == "boolean") then
		return
	end

	local command_callback = function()
		local v = table.get_nested_key(g_table, gvar_key)
		table.set_nested_key(g_table, gvar_key, not v)
		toggle()
	end

	CommandExecutor:RegisterCommand(command_name, command_callback, meta)
end

function Tab:Notify(fmt, ...)
	local msg = (... ~= nil) and _F(fmt, ...) or fmt
	Notifier:ShowMessage(self:GetName(), msg, false, 5)
end

---@parivate
function Tab:DrawInternal()
	if (not self.m_callback) then
		return
	end

	if (self.m_has_error) then
		ImGui.TextColored(0.8, 0.8, 0, 1, _F("Tab '%s' has crashed. Please contact a developer.", self.m_name))
		if (self.m_traceback) then
			ImGui.Spacing()
			ImGui.BulletText("Traceback most recent call:") -- not an actual trace because Lua's debug is disabled in this sandbox
			ImGui.Indent()
			ImGui.PushTextWrapPos()
			ImGui.TextColored(1, 0, 0, 1, self.m_traceback)
			ImGui.PopTextWrapPos()
			ImGui.Unindent()
			if (ImGui.Button("Copy Trace")) then
				ImGui.SetClipboardText(self.m_traceback)
			end
		end
		return
	end

	local ok, err = pcall(self.m_callback)
	if (not ok) then
		log.fwarning("[%s]: Callback error: %s", self.m_name, err)
		self.m_has_error = true
		self.m_traceback = err
		return
	end
end

function Tab:Draw()
	if (not self:HasSubtabs()) then
		self:DrawInternal()
		return
	end

	local __next = nil
	if (ImGui.BeginTabBar("ss_tabs")) then
		local __label = _F("%s##%d", self:GetName(), self:GetID())
		if (ImGui.BeginTabItem(__label)) then
			self:DrawInternal()
			ImGui.EndTabItem()
		end

		for _, tab in pairs(self.m_subtabs) do
			local label = _F("%s##%d", tab:GetName(), tab:GetID())
			if (ImGui.BeginTabItem(label)) then
				if (tab:HasSubtabs()) then
					__next = tab
				else
					tab:DrawInternal()
				end
				ImGui.EndTabItem()
			end
		end
		ImGui.EndTabBar()
	end

	if (__next) then __next:Draw() end
end

return Tab
